-- Flyway V2 : index sur owners.telephone pour les recherches par téléphone
CREATE INDEX IF NOT EXISTS owners_telephone_idx ON owners (telephone);
