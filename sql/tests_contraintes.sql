INSERT INTO permis VALUES ('999999999999', '2015-01-01');
INSERT INTO client VALUES ('CLI00001', 'Test', 'Test', 'particulier', NULL,
                           'test@exemple.fr', '0600000000', '999999999999');

INSERT INTO voiture VALUES ('HA-100-AA', 'Renault', 'Clio', '2025-01-01', 'essence', 'ZZZZ', 'PAR01');

-- Démonstration ON UPDATE / ON DELETE (annulée par ROLLBACK, la base reste intacte)
START TRANSACTION;
-- ON UPDATE CASCADE : le nouveau numéro de permis est recopié dans CLIENT
UPDATE permis SET numero_permis = 'PERMIS-TEST' WHERE numero_permis = (SELECT numero_permis FROM client WHERE numero_client = 'CLI00001');
SELECT numero_client, numero_permis FROM client WHERE numero_client = 'CLI00001';
-- ON DELETE CASCADE : supprimer une voiture supprime ses interventions
SELECT COUNT(*) AS interventions_avant FROM intervention WHERE immatriculation_voiture = 'GA-214-KL';
-- ON DELETE SET NULL : ses contrats sont gardés, sans véhicule
DELETE FROM voiture WHERE immatriculation_voiture = 'GA-214-KL';
SELECT COUNT(*) AS interventions_apres FROM intervention WHERE immatriculation_voiture = 'GA-214-KL';
SELECT COUNT(*) AS contrats_sans_vehicule FROM contrat WHERE immatriculation_voiture IS NULL;
ROLLBACK;
INSERT INTO contrat (num_contrat, statut_contrat, date_heure_depart_prevu, date_heure_retour_prevu,
                     numero_client, matricule_employe, id_agence_depart, id_agence_retour)
VALUES ('CT2026-99901', 'reserve', '2026-12-10 09:00:00', '2026-12-12 09:00:00',
        NULL, 'EMP00002', 'PAR01', 'PAR01');

UPDATE client SET numero_permis = '090393100562' WHERE numero_client = 'CLI00001';
UPDATE client SET mail_client = 'm.dubois@exemple.fr' WHERE numero_client = 'CLI00001';
UPDATE client SET raison_sociale_client = NULL WHERE numero_client = 'CLI00006';
UPDATE client SET raison_sociale_client = 'Société Test' WHERE numero_client = 'CLI00001';
UPDATE client SET type_client = 'entreprise' WHERE numero_client = 'CLI00001';
UPDATE client SET mail_client = 'lea.martin.exemple.fr' WHERE numero_client = 'CLI00001';
UPDATE categorie SET tarif_journalier_categorie = -10 WHERE id_categorie = 'ECMR';
UPDATE employe SET poste_employe = 'stagiaire' WHERE matricule_employe = 'EMP00002';
INSERT INTO voiture VALUES ('AB123CD', 'Renault', 'Clio', '2025-01-01', 'essence', 'ECMR', 'PAR01');
UPDATE voiture SET energie_voiture = 'charbon' WHERE immatriculation_voiture = 'GA-214-KL';
UPDATE contrat SET statut_contrat = 'perdu' WHERE num_contrat = 'CT2026-00070';
INSERT INTO contrat (num_contrat, statut_contrat, date_heure_depart_prevu, date_heure_retour_prevu,
                     numero_client, matricule_employe, id_agence_depart, id_agence_retour)
VALUES ('CT2026-99902', 'reserve', '2026-12-10 09:00:00', '2026-12-08 09:00:00',
        'CLI00001', 'EMP00002', 'PAR01', 'PAR01');
UPDATE contrat SET kilometrage_retour = kilometrage_depart - 100 WHERE num_contrat = 'CT2026-00003';
UPDATE contrat SET statut_contrat = 'en cours' WHERE num_contrat = 'CT2026-00076';
UPDATE contrat SET kilometrage_retour = 12000 WHERE num_contrat = 'CT2026-00076';
UPDATE contrat SET statut_contrat = 'cloture' WHERE num_contrat = 'CT2026-00070';
UPDATE intervention SET type_intervention = 'lavage' WHERE num_intervention = 'INT0000001';
UPDATE intervention SET cout_intervention = -50 WHERE num_intervention = 'INT0000001';
DELETE FROM permis WHERE numero_permis = '999999999999';
