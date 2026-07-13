-- Flyway V3 : ajout colonne weight sur pets (nullable - expand/contract pattern)
ALTER TABLE pets ADD COLUMN IF NOT EXISTS weight DECIMAL(5,2);
