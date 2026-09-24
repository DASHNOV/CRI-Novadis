# Tunnel Cloudflare — exposition publique de l'API

L'API n'a **aucun port ouvert sur Internet**. `cloudflared`, installé en service sur le
serveur, ouvre une connexion sortante vers Cloudflare ; Cloudflare y renvoie le trafic de
`api.cri-novadis.tech`.

Le tunnel est **géré depuis le tableau de bord** (mode « remotely-managed ») : la règle de
routage est stockée chez Cloudflare, et le serveur ne détient qu'un **jeton**. Il n'y a donc
pas de `config.yml` sur le serveur — ce dossier versionne la configuration attendue et la
procédure, pas un fichier lu par `cloudflared`.

## Configuration attendue

*Zero Trust → Networks → Tunnels → (tunnel de production) → Public Hostnames*

| Champ | Valeur |
|---|---|
| Subdomain / Domain | `api` / `cri-novadis.tech` |
| Service | `HTTP` → `localhost:5200` |

Zone `cri-novadis.tech` : *SSL/TLS → Overview* en **Full (Strict)**.

`localhost:5200` est l'adresse vue depuis le serveur : `docker-compose.yml` publie l'API
sur `127.0.0.1:5200` uniquement. Ne jamais la publier sur `0.0.0.0` : l'API deviendrait
joignable sans passer par Cloudflare.

## Secret

Le **jeton du tunnel** se trouve dans le gestionnaire de mots de passe, à côté du `.env`.
Il est aussi récupérable depuis le tableau de bord (*Configure → Install connector*).
Quiconque le détient peut faire passer le trafic de l'API par sa propre machine : ne
jamais le versionner.

## Vérifier l'état sur le serveur

```bash
systemctl status cloudflared                  # active (running)
journalctl -u cloudflared --since "1 hour ago" | grep -i "registered tunnel connection"
curl -s https://api.cri-novadis.tech/api/health/ready   # depuis n'importe où
```

## Réinstaller (serveur neuf — scénario B7 de la reprise)

```bash
# Debian/Ubuntu
curl -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
sudo cloudflared service install <JETON_DU_TUNNEL>
systemctl status cloudflared
```

Le même tunnel et le même jeton sont réutilisés : aucune modification DNS n'est
nécessaire, la règle de routage suit. Si le jeton est compromis : le faire renouveler
depuis le tableau de bord du tunnel ou, à défaut, créer un nouveau tunnel portant la
même règle, puis réinstaller le service avec le nouveau jeton.
