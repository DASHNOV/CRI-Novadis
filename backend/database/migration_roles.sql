-- Normalisation des rôles utilisateur (PostgreSQL, idempotent).
-- Valeurs canoniques : 'Technician' et 'Admin' — les seules connues des policies
-- (Program.cs). L'ancienne version de ce script faisait l'inverse
-- ('Technician' → 'Technicien') et coupait l'accès API des techniciens.

UPDATE "Users" SET "Role" = 'Technician' WHERE "Role" IS NULL OR "Role" IN ('Technicien', 'technicien', 'technician');
UPDATE "Users" SET "Role" = 'Admin' WHERE "Role" IN ('admin', 'Administrator', 'Administrateur');
