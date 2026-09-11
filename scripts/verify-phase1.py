#!/usr/bin/env python3
"""
Campagne de vérification de la phase 1 du plan de remédiation, contre une API
locale **réelle** (Postgres, pas base en mémoire).

Ce que ce script prouve, et ce qu'il ne prouve pas :
  - il rejoue le **format de payload** exact des clients Flutter installés
    (les 16 clés de saveCriProjet / saveCriService) et vérifie colonne par
    colonne ce qui est réellement écrit en base ;
  - il ne prouve PAS que l'application envoie bien ce format. Cette
    vérification-là reste manuelle, et c'est le mobile qui compte (règle 3).

Prérequis : API sur http://localhost:5200, Postgres dev accessible via
`docker exec <conteneur> psql`. Aucun secret n'est affiché.

Usage :
    python scripts/verify-phase1.py [--api URL] [--pg-container NOM]
"""

import argparse
import base64
import hashlib
import hmac
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone

ENV_PATH = os.path.join("backend", "src", "NovadisApi", ".env")
ISSUER = "NovadisAPI"
AUDIENCE = "NovadisApp"
NAMEID = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
ROLE = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"

results = []

# La console Windows est en cp1252 : sans cela, une fleche ou un accent fait
# planter le script au premier print et masque tout le resultat.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def check(name, ok, detail=""):
    results.append((name, ok, detail))
    print(f"  {'OK  ' if ok else 'ECHEC'}  {name}" + (f"  — {detail}" if detail else ""))
    return ok


# ── JWT ──────────────────────────────────────────────────────────────────────

def b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def read_secret() -> str:
    with open(ENV_PATH, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("Jwt__SecretKey="):
                return line.split("=", 1)[1].strip()
    sys.exit(f"Jwt__SecretKey introuvable dans {ENV_PATH}")


def make_token(secret: str, user_id: str, role: str, email: str) -> str:
    now = datetime.now(timezone.utc)
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub": user_id,
        "userId": user_id,
        NAMEID: user_id,
        ROLE: role,
        "email": email,
        "jti": str(uuid.uuid4()),
        "iss": ISSUER,
        "aud": AUDIENCE,
        "exp": int((now + timedelta(minutes=30)).timestamp()),
        "iat": int(now.timestamp()),
    }
    signing_input = f"{b64(json.dumps(header).encode())}.{b64(json.dumps(payload).encode())}"
    signature = hmac.new(secret.encode(), signing_input.encode(), hashlib.sha256).digest()
    return f"{signing_input}.{b64(signature)}"


# ── HTTP ─────────────────────────────────────────────────────────────────────

def call(api, method, path, token=None, body=None):
    req = urllib.request.Request(api + path, method=method)
    if token:
        req.add_header("Authorization", "Bearer " + token)
    data = None
    if body is not None:
        data = body.encode("utf-8") if isinstance(body, str) else json.dumps(body).encode()
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, data, timeout=30) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as err:
        return err.code, err.read().decode("utf-8", "replace")
    except urllib.error.URLError as err:
        return 0, str(err)


# ── SQL ──────────────────────────────────────────────────────────────────────

# Separateur de colonnes : surtout pas \x1f — Python le classe parmi les
# caracteres d'espacement, si bien qu'une derniere colonne NULL disparaissait
# au .strip() et decalait toute la ligne d'un cran.
SEP = "\x01"


def sql(container, query):
    out = subprocess.run(
        ["docker", "exec", container, "psql", "-U", "cri_user", "-d", "cri_novadis_dev",
         "-t", "-A", "-F", SEP, "-c", query],
        capture_output=True, text=True, encoding="utf-8",
    )
    if out.returncode != 0:
        sys.exit("psql: " + out.stderr.strip())
    return [line.split(SEP) for line in out.stdout.strip("\r\n").splitlines() if line]


# ── Blocs ────────────────────────────────────────────────────────────────────

def bloc1(api, admin, tech):
    print("\n[1.1] HealthController")
    expectations = [
        ("GET /health/live   anonyme", "/health/live", None, 200),
        ("GET /health        anonyme", "/health", None, 401),
        ("GET /health        technicien", "/health", tech, 403),
        ("GET /health        admin", "/health", admin, 200),
        ("GET /health/stats  anonyme", "/health/stats", None, 401),
        ("GET /health/stats  technicien", "/health/stats", tech, 403),
        ("GET /health/stats  admin", "/health/stats", admin, 200),
        ("GET /health/users  supprimee", "/health/users", admin, 404),
        ("GET /health/test-write supprimee", "/health/test-write", admin, 404),
    ]
    for label, path, token, expected in expectations:
        status, _ = call(api, "GET", path, token)
        check(f"{label} → {expected}", status == expected, f"reçu {status}")

    status, body = call(api, "GET", "/health/stats", admin)
    check("stats n'expose plus recentCris", "recentCris" not in body)


def bloc2(api, admin, tech, tech_id, container):
    print("\n[1.3] Rejeu du payload des clients installes")

    # ── Payload Projet : les 16 cles, valeurs distinctes pour tracer les pertes
    cri_id = str(uuid.uuid4())
    marker = f"VERIF-{int(time.time())}"
    projet = {
        "id": cri_id,
        "interventionType": "Project",
        "category": "Installation",
        "interventionDate": "2026-09-08T08:00:00Z",
        "clientName": f"Client {marker}",
        "clientAddress": "12 rue des Tests",
        "clientSite": "Site Alpha",
        "clientPhone": "0102030405",
        "clientEmail": "contact@legacy.fr",
        "workDescription": "Description des travaux",
        "materialsUsed": "Cable, connecteurs",
        "duration": 2.5,
        "status": "Draft",
        "technicianSignature": "data:image/png;base64,AAAA",
        "clientSignature": "data:image/png;base64,BBBB",
        "data": json.dumps({"projectName": "Chantier Alpha", "ville": "Lyon",
                            "codePostal": "69000", "startTime": "2026-09-08T08:00:00",
                            "endTime": "2026-09-08T10:30:00"}),
    }
    status, _ = call(api, "POST", "/CRI", tech, projet)
    check("POST /CRI brouillon Projet → 201", status == 201, f"reçu {status}")

    cols = ['ClientName', 'ClientAddress', 'ClientSite', 'ClientPhone', 'ClientEmail',
            'WorkDescription', 'MaterialsUsed', 'Duration', 'Status', 'Data',
            'TechnicianSignature', 'ClientSignature', 'ProjectName', 'Ville',
            'TechnicianId', 'SubmittedAt']
    select = ",".join(f'"{c}"' for c in cols)
    rows = sql(container, f"SELECT {select} FROM \"CRIForms\" WHERE \"Id\" = '{cri_id}';")
    if not check("le CRI est en base", bool(rows)):
        return
    row = dict(zip(cols, rows[0]))

    expected = {
        "ClientName": f"Client {marker}", "ClientAddress": "12 rue des Tests",
        "ClientSite": "Site Alpha", "ClientPhone": "0102030405",
        "ClientEmail": "contact@legacy.fr", "WorkDescription": "Description des travaux",
        "MaterialsUsed": "Cable, connecteurs", "Status": "Draft",
        "TechnicianSignature": "data:image/png;base64,AAAA",
        "ClientSignature": "data:image/png;base64,BBBB",
        "ProjectName": "Chantier Alpha", "Ville": "Lyon",
    }
    for col, want in expected.items():
        # Un champ absent du DTO serait perdu en silence : c'est ce que ce bloc traque.
        check(f"colonne {col}", row[col] == want, f"attendu {want!r}, lu {row[col]!r}")
    check("colonne Duration", row["Duration"].startswith("2.5"), f"lu {row['Duration']!r}")
    check("TechnicianId = porteur du jeton", row["TechnicianId"] == tech_id, f"lu {row['TechnicianId']!r}")
    check("SubmittedAt vide sur un brouillon", row["SubmittedAt"] == "", f"lu {row['SubmittedAt']!r}")

    # ── Meme identifiant, passage en Submitted + changement de site (upsert)
    soumis = dict(projet, status="Submitted", clientSite="Site Beta")
    status, _ = call(api, "POST", "/CRI", tech, soumis)
    check("POST /CRI même id, Submitted → 200", status == 200, f"reçu {status}")
    row2 = dict(zip(cols, sql(container, f"SELECT {select} FROM \"CRIForms\" WHERE \"Id\" = '{cri_id}';")[0]))
    check("Status passe à Submitted", row2["Status"] == "Submitted", f"lu {row2['Status']!r}")
    check("SubmittedAt renseigné", row2["SubmittedAt"] != "", f"lu {row2['SubmittedAt']!r}")
    check("ClientSite suit la mise à jour", row2["ClientSite"] == "Site Beta", f"lu {row2['ClientSite']!r}")

    # ── Payload Service
    svc_id = str(uuid.uuid4())
    service = dict(projet, id=svc_id, interventionType="Service", category="Maintenance",
                   clientName=f"Client SVC {marker}", status="Submitted",
                   data=json.dumps({"ticketNumber": "TCK-42", "resolutionStatus": "resolu",
                                    "interventionDurationMinutes": 90}))
    status, _ = call(api, "POST", "/CRI", tech, service)
    check("POST /CRI Service → 201", status == 201, f"reçu {status}")
    r = sql(container, f"SELECT \"TicketNumber\",\"ResolutionStatus\",\"DureeMinutes\" FROM \"CRIForms\" WHERE \"Id\" = '{svc_id}';")
    check("champs Service dérivés de Data", r and r[0] == ["TCK-42", "resolu", "90"], f"lu {r}")

    # ── Escalades : le corps ne doit plus decrire un graphe d'entites
    print("\n[1.3] Tentatives d'escalade")
    users_before = int(sql(container, 'SELECT count(*) FROM "Users";')[0][0])
    photos_before = int(sql(container, 'SELECT count(*) FROM "CRIPhotos";')[0][0])

    esc_id = str(uuid.uuid4())
    escalade = dict(projet, id=esc_id, clientName=f"Client ESC {marker}")
    escalade["technician"] = {"id": str(uuid.uuid4()), "email": f"pirate-{marker}@exemple.fr",
                              "role": "Admin", "firstName": "Pirate", "lastName": "Escalade",
                              "passwordHash": "x", "isActive": True}
    escalade["photos"] = [{"id": str(uuid.uuid4()), "fileName": "injecte.jpg",
                           "filePath": "/app/uploads/injecte.jpg"}]
    escalade["technicianId"] = "cccccccc-cccc-cccc-cccc-cccccccccccc"
    escalade["createdAt"] = "2000-01-01T00:00:00Z"
    status, _ = call(api, "POST", "/CRI", tech, escalade)
    check("POST /CRI avec technician + photos → 201 (clés ignorées)", status == 201, f"reçu {status}")

    users_after = int(sql(container, 'SELECT count(*) FROM "Users";')[0][0])
    photos_after = int(sql(container, 'SELECT count(*) FROM "CRIPhotos";')[0][0])
    check("aucun utilisateur créé", users_after == users_before, f"{users_before} → {users_after}")
    check("aucune photo créée", photos_after == photos_before, f"{photos_before} → {photos_after}")
    check("aucun compte pirate", not sql(container, f"SELECT 1 FROM \"Users\" WHERE \"Email\" = 'pirate-{marker}@exemple.fr';"))
    owner = sql(container, f"SELECT \"TechnicianId\" FROM \"CRIForms\" WHERE \"Id\" = '{esc_id}';")[0][0]
    check("TechnicianId du corps ignoré", owner == tech_id, f"lu {owner!r}")

    # ── Statut hors ensemble autorise
    status, _ = call(api, "POST", "/CRI", tech, dict(projet, id=str(uuid.uuid4()), status="Archived"))
    check("POST statut 'Archived' → 400", status == 400, f"reçu {status}")
    status, _ = call(api, "PUT", f"/CRI/{cri_id}", tech, dict(projet, status="Admin"))
    check("PUT statut 'Admin' → 400", status == 400, f"reçu {status}")

    return [cri_id, svc_id, esc_id]


def bloc3(api, tech):
    """
    Ces routes renvoient 404/400, pas 500 : elles vérifient qu'aucune réponse
    d'erreur courante ne fuit de trace, mais elles n'atteignent PAS le catch de
    l'export. Ce chemin-là n'est pas déclenchable proprement depuis l'extérieur
    (le service d'export encaisse même une signature base64 invalide) ; il est
    couvert par ExportControllerErrorTests, qui injecte un service en échec.
    """
    print("\n[1.2] Reponses d'erreur (voir docstring : le chemin 500 est couvert par les tests)")
    leaks = ("stackTrace", '"stack"', "StackTrace", "NovadisApi.Services", "   at ")
    checked = 0
    for path in ("/Export/cri/11111111-1111-1111-1111-111111111111.xlsx",
                 "/Export/period.xlsx?range=nawak",
                 "/CRI/11111111-1111-1111-1111-111111111111"):
        status, body = call(api, "GET", path, tech)
        found = [n for n in leaks if n in body]
        checked += check(f"GET {path} → {status}, corps sans trace", not found, ",".join(found))
    return checked


def cleanup(container):
    """
    Supprime tout ce que la campagne a écrit, y compris en cas d'échec en cours
    de route — sans quoi les exécutions successives laissent des CRI derrière
    elles. Le filtre porte sur le préfixe des noms de client, pas sur les seuls
    identifiants créés : ResolveRelations crée aussi une fiche client par CRI.
    """
    like = ("\"%s\" LIKE 'Client VERIF-%%' OR \"%s\" LIKE 'Client SVC VERIF-%%' "
            "OR \"%s\" LIKE 'Client ESC VERIF-%%'")
    cris = sql(container, 'SELECT "Id" FROM "CRIForms" WHERE '
               + like % ("ClientName", "ClientName", "ClientName") + ";")
    if cris:
        joined = ",".join(f"'{row[0]}'" for row in cris)
        sql(container, f'DELETE FROM "ExportedDocuments" WHERE "CriId" IN ({joined});')
        sql(container, f'DELETE FROM "CRIPhotos" WHERE "CRIFormId" IN ({joined});')
        sql(container, f'DELETE FROM "CRIForms" WHERE "Id" IN ({joined});')
    sql(container, 'DELETE FROM "ClientsNormalises" WHERE '
        + like % ("RaisonSociale", "RaisonSociale", "RaisonSociale") + ";")
    print(f"\nNettoyage : {len(cris)} CRI de test supprimés, fiches clients associées comprises.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--api", default="http://localhost:5200/api")
    parser.add_argument("--pg-container", default="postgres-dev")
    parser.add_argument("--keep", action="store_true", help="ne pas supprimer les CRI de test")
    args = parser.parse_args()

    secret = read_secret()
    users = {r[2]: (r[0], r[1]) for r in sql(args.pg_container,
             'SELECT "Id","Email","Role" FROM "Users" ORDER BY "CreatedAt";')}
    if "Admin" not in users or "Technician" not in users:
        sys.exit("Il faut au moins un Admin et un Technician dans cri_novadis_dev.")

    admin_id, admin_mail = users["Admin"]
    tech_id, tech_mail = users["Technician"]
    admin = make_token(secret, admin_id, "Admin", admin_mail)
    tech = make_token(secret, tech_id, "Technician", tech_mail)

    status, _ = call(args.api, "GET", "/health/live")
    if status != 200:
        sys.exit(f"API injoignable sur {args.api} (statut {status}). Lancer `dotnet run`.")

    try:
        bloc1(args.api, admin, tech)
        bloc2(args.api, admin, tech, tech_id, args.pg_container)
        bloc3(args.api, tech)
    finally:
        if not args.keep:
            cleanup(args.pg_container)

    failed = [n for n, ok, _ in results if not ok]
    print(f"\n{len(results) - len(failed)}/{len(results)} vérifications passées.")
    if failed:
        print("Échecs :")
        for name in failed:
            print("  - " + name)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
