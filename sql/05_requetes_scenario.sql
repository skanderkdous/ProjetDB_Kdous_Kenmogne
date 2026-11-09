-- Désactive le mode sécurisé de MySQL pour autoriser les UPDATE/DELETE du scénario
SET SQL_SAFE_UPDATES = 0;

-- Réservations au départ de Paris Gare de Lyon dans les 7 prochains jours
SELECT c.num_contrat,
       c.date_heure_depart_prevu,
       c.date_heure_retour_prevu,
       CONCAT(cl.prenom_client, ' ', cl.nom_client) AS client,
       cl.num_telephone_client
FROM contrat c
JOIN client cl ON cl.numero_client = c.numero_client
WHERE c.id_agence_depart = 'PAR01'
  AND c.statut_contrat   = 'reserve'
  AND c.date_heure_depart_prevu BETWEEN '2026-11-07 10:00:00' AND '2026-11-14 23:59:59'
ORDER BY c.date_heure_depart_prevu;

-- Véhicules ECMR présents à PAR01 et libres (ni location ni intervention) du 10 au 14/11
SELECT v.immatriculation_voiture,
       v.marque_voiture,
       v.modele_vehicule,
       v.id_agence AS agence_de_rattachement,
       (SELECT MAX(c.kilometrage_retour) FROM contrat c
        WHERE c.immatriculation_voiture = v.immatriculation_voiture) AS dernier_km
FROM voiture v
WHERE v.id_categorie = 'ECMR'
  AND COALESCE((SELECT c.id_agence_retour
                FROM contrat c
                WHERE c.immatriculation_voiture = v.immatriculation_voiture
                  AND c.statut_contrat = 'cloture'
                ORDER BY c.date_heure_depart_prevu DESC
                LIMIT 1), v.id_agence) = 'PAR01'
  AND NOT EXISTS (SELECT 1 FROM contrat c
                  WHERE c.immatriculation_voiture = v.immatriculation_voiture
                    AND (c.statut_contrat = 'en cours'
                         OR (c.statut_contrat <> 'annule'
                             AND c.date_heure_depart_prevu < '2026-11-14 09:00:00'
                             AND COALESCE(c.date_heure_retour_reelles, c.date_heure_retour_prevu)
                                 > '2026-11-10 09:00:00')))
  AND NOT EXISTS (SELECT 1 FROM intervention i
                  WHERE i.immatriculation_voiture = v.immatriculation_voiture
                    AND i.date_intervention >= '2026-11-10'
                    AND i.date_intervention <  '2026-11-14');

-- État des ECMR rattachées à PAR01 : location en cours et prochaine intervention
SELECT v.immatriculation_voiture,
       v.modele_vehicule,
       c.num_contrat             AS location_en_cours,
       c.date_heure_retour_prevu AS retour_prevu,
       (SELECT MIN(i.date_intervention)
        FROM intervention i
        WHERE i.immatriculation_voiture = v.immatriculation_voiture
          AND i.date_intervention >= '2026-11-07') AS prochaine_intervention
FROM voiture v
LEFT JOIN contrat c ON c.immatriculation_voiture = v.immatriculation_voiture
                   AND c.statut_contrat = 'en cours'
WHERE v.id_agence = 'PAR01'
  AND v.id_categorie = 'ECMR';

-- Locations en cours en retard, avec le nombre de jours et le téléphone du client
SELECT c.num_contrat,
       a.nom_agence,
       c.immatriculation_voiture,
       c.date_heure_retour_prevu,
       DATEDIFF('2026-11-07 10:00:00', c.date_heure_retour_prevu) AS jours_de_retard,
       CONCAT(cl.prenom_client, ' ', cl.nom_client) AS client,
       cl.num_telephone_client
FROM contrat c
JOIN client cl ON cl.numero_client = c.numero_client
JOIN agence a  ON a.id_agence      = c.id_agence_depart
WHERE c.statut_contrat = 'en cours'
  AND c.date_heure_retour_prevu < '2026-11-07 10:00:00'
ORDER BY c.date_heure_retour_prevu;

-- Conducteurs de Batiself SARL : ont-ils 2 ans de permis au 23/11 pour louer un 12 m3 ?
SELECT cl.numero_client,
       cl.raison_sociale_client,
       CONCAT(cl.prenom_client, ' ', cl.nom_client) AS conducteur,
       p.date_obtention_permis,
       DATEDIFF('2026-11-23', p.date_obtention_permis) AS anciennete_jours,
       CASE WHEN DATEDIFF('2026-11-23', p.date_obtention_permis) >= 730
            THEN 'oui' ELSE 'non' END AS peut_louer_un_12m3
FROM client cl
JOIN permis p ON p.numero_permis = cl.numero_permis
WHERE cl.raison_sociale_client = 'Batiself SARL';

-- Nouvelle réservation pour CLI00008 du 23 au 25/11 à PAR01 (véhicule attribué plus tard)
INSERT INTO contrat (num_contrat, statut_contrat, date_heure_depart_prevu, date_heure_retour_prevu,
                     numero_client, matricule_employe, id_agence_depart, id_agence_retour)
VALUES ('CT2026-00083', 'reserve', '2026-11-23 08:00:00', '2026-11-25 18:00:00',
        'CLI00008', 'EMP00002', 'PAR01', 'PAR01');

-- Départ du contrat CT2026-00076 : attribution du véhicule et relevé du compteur
UPDATE contrat
SET statut_contrat          = 'en cours',
    immatriculation_voiture = 'GP-873-LC',
    kilometrage_depart      = 17463
WHERE num_contrat = 'CT2026-00076';

-- Retour du contrat CT2026-00076 : clôture avec date et kilométrage de retour
UPDATE contrat
SET statut_contrat            = 'cloture',
    date_heure_retour_reelles = '2026-11-14 08:40:00',
    kilometrage_retour        = 17859
WHERE num_contrat = 'CT2026-00076';

-- Facture du contrat CT2026-00076 : km parcourus, jours facturés (1 minimum) et montant
SELECT c.num_contrat,
       CONCAT(cl.prenom_client, ' ', cl.nom_client) AS client,
       CONCAT(v.marque_voiture, ' ', v.modele_vehicule) AS vehicule,
       k.libelle_categorie,
       c.kilometrage_retour - c.kilometrage_depart AS km_parcourus,
       GREATEST(DATEDIFF(c.date_heure_retour_reelles, c.date_heure_depart_prevu), 1) AS jours_factures,
       k.tarif_journalier_categorie,
       k.tarif_journalier_categorie
         * GREATEST(DATEDIFF(c.date_heure_retour_reelles, c.date_heure_depart_prevu), 1) AS montant_ttc
FROM contrat c
JOIN client    cl ON cl.numero_client          = c.numero_client
JOIN voiture   v  ON v.immatriculation_voiture = c.immatriculation_voiture
JOIN categorie k  ON k.id_categorie            = v.id_categorie
WHERE c.num_contrat = 'CT2026-00076';

-- Véhicules restés dans une autre agence que leur agence de rattachement après leur dernière location
SELECT v.immatriculation_voiture,
       v.modele_vehicule,
       rat.nom_agence AS agence_de_rattachement,
       pos.nom_agence AS se_trouve_a
FROM voiture v
JOIN contrat c  ON c.immatriculation_voiture = v.immatriculation_voiture
JOIN agence rat ON rat.id_agence = v.id_agence
JOIN agence pos ON pos.id_agence = c.id_agence_retour
WHERE c.statut_contrat = 'cloture'
  AND c.date_heure_depart_prevu = (SELECT MAX(c2.date_heure_depart_prevu)
                                   FROM contrat c2
                                   WHERE c2.immatriculation_voiture = v.immatriculation_voiture
                                     AND c2.statut_contrat IN ('en cours', 'cloture'))
  AND c.id_agence_retour <> v.id_agence
ORDER BY rat.nom_agence;

-- Interventions planifiées à partir du 07/11, avec le véhicule et son agence
SELECT i.date_intervention,
       i.type_intervention,
       i.immatriculation_voiture,
       CONCAT(v.marque_voiture, ' ', v.modele_vehicule) AS vehicule,
       a.nom_agence
FROM intervention i
JOIN voiture v ON v.immatriculation_voiture = i.immatriculation_voiture
JOIN agence a  ON a.id_agence = v.id_agence
WHERE i.date_intervention >= '2026-11-07'
ORDER BY i.date_intervention;

-- Effectif par agence et par poste
SELECT a.nom_agence,
       e.poste_employe,
       COUNT(*) AS nb_employes
FROM employe e
JOIN agence a ON a.id_agence = e.id_agence
GROUP BY a.id_agence, a.nom_agence, e.poste_employe
ORDER BY a.nom_agence, e.poste_employe;

-- Nombre de contrats établis par chaque employé de PAR01 (y compris ceux à 0)
SELECT CONCAT(e.prenom_employe, ' ', e.nom_employe) AS employe,
       e.poste_employe,
       COUNT(c.num_contrat) AS nb_contrats_etablis
FROM employe e
LEFT JOIN contrat c ON c.matricule_employe = e.matricule_employe
WHERE e.id_agence = 'PAR01'
GROUP BY e.matricule_employe, e.prenom_employe, e.nom_employe, e.poste_employe
ORDER BY nb_contrats_etablis DESC;

-- Chiffre d'affaires et panier moyen des locations clôturées par agence de départ
SELECT a.nom_agence,
       COUNT(*) AS nb_locations,
       SUM(k.tarif_journalier_categorie
           * GREATEST(DATEDIFF(c.date_heure_retour_reelles, c.date_heure_depart_prevu), 1)) AS chiffre_affaires,
       ROUND(AVG(k.tarif_journalier_categorie
           * GREATEST(DATEDIFF(c.date_heure_retour_reelles, c.date_heure_depart_prevu), 1)), 2) AS panier_moyen
FROM contrat c
JOIN agence a    ON a.id_agence = c.id_agence_depart
JOIN voiture v   ON v.immatriculation_voiture = c.immatriculation_voiture
JOIN categorie k ON k.id_categorie = v.id_categorie
WHERE c.statut_contrat = 'cloture'
GROUP BY a.id_agence, a.nom_agence
ORDER BY chiffre_affaires DESC;

-- Activité par catégorie : nombre de locations clôturées et part des retours en retard
SELECT k.libelle_categorie,
       COUNT(c.num_contrat) AS nb_locations,
       SUM(CASE WHEN c.date_heure_retour_reelles > c.date_heure_retour_prevu THEN 1 ELSE 0 END) AS nb_retards,
       ROUND(100 * SUM(CASE WHEN c.date_heure_retour_reelles > c.date_heure_retour_prevu THEN 1 ELSE 0 END)
             / NULLIF(COUNT(c.num_contrat), 0), 1) AS pct_retards
FROM categorie k
LEFT JOIN voiture v ON v.id_categorie = k.id_categorie
LEFT JOIN contrat c ON c.immatriculation_voiture = v.immatriculation_voiture
                   AND c.statut_contrat = 'cloture'
GROUP BY k.id_categorie, k.libelle_categorie
ORDER BY nb_locations DESC;

-- Les 5 véhicules les moins rentables (chiffre d'affaires moins coût de maintenance)
SELECT v.immatriculation_voiture,
       CONCAT(v.marque_voiture, ' ', v.modele_vehicule) AS vehicule,
       COALESCE(ca.chiffre_affaires, 0) AS chiffre_affaires,
       COALESCE(m.cout_maintenance, 0)  AS cout_maintenance,
       COALESCE(ca.chiffre_affaires, 0) - COALESCE(m.cout_maintenance, 0) AS marge
FROM voiture v
LEFT JOIN (SELECT c.immatriculation_voiture,
                  SUM(k.tarif_journalier_categorie
                      * GREATEST(DATEDIFF(c.date_heure_retour_reelles, c.date_heure_depart_prevu), 1))
                      AS chiffre_affaires
           FROM contrat c
           JOIN voiture v2  ON v2.immatriculation_voiture = c.immatriculation_voiture
           JOIN categorie k ON k.id_categorie = v2.id_categorie
           WHERE c.statut_contrat = 'cloture'
           GROUP BY c.immatriculation_voiture) ca
       ON ca.immatriculation_voiture = v.immatriculation_voiture
LEFT JOIN (SELECT immatriculation_voiture, SUM(cout_intervention) AS cout_maintenance
           FROM intervention
           GROUP BY immatriculation_voiture) m
       ON m.immatriculation_voiture = v.immatriculation_voiture
ORDER BY marge ASC
LIMIT 5;

-- Clients professionnels ayant au moins 3 locations clôturées, classés par dépense
SELECT cl.raison_sociale_client,
       COUNT(*) AS nb_locations,
       SUM(k.tarif_journalier_categorie
           * GREATEST(DATEDIFF(c.date_heure_retour_reelles, c.date_heure_depart_prevu), 1)) AS total_depense
FROM client cl
JOIN contrat c   ON c.numero_client = cl.numero_client
JOIN voiture v   ON v.immatriculation_voiture = c.immatriculation_voiture
JOIN categorie k ON k.id_categorie = v.id_categorie
WHERE cl.type_client = 'professionnel'
  AND c.statut_contrat = 'cloture'
GROUP BY cl.numero_client, cl.raison_sociale_client
HAVING COUNT(*) >= 3
ORDER BY total_depense DESC;

-- Clients inactifs depuis le 01/10 (aucun contrat non annulé), à relancer par e-mail
SELECT cl.numero_client,
       CONCAT(cl.prenom_client, ' ', cl.nom_client) AS client,
       cl.mail_client
FROM client cl
WHERE NOT EXISTS (SELECT 1 FROM contrat c
                  WHERE c.numero_client = cl.numero_client
                    AND c.statut_contrat <> 'annule'
                    AND c.date_heure_depart_prevu >= '2026-10-01')
ORDER BY cl.nom_client;

-- Trajets aller simple les plus fréquents (agence de départ vers agence de retour)
SELECT dep.nom_agence AS agence_depart,
       ret.nom_agence AS agence_retour,
       COUNT(*)       AS nb_locations
FROM contrat c
JOIN agence dep ON dep.id_agence = c.id_agence_depart
JOIN agence ret ON ret.id_agence = c.id_agence_retour
WHERE c.id_agence_depart <> c.id_agence_retour
  AND c.statut_contrat <> 'annule'
GROUP BY dep.id_agence, dep.nom_agence, ret.id_agence, ret.nom_agence
ORDER BY nb_locations DESC, agence_depart;

-- PARTIE E : questions complémentaires du siège sur la flotte et les clients

-- Marques présentes dans la flotte en motorisation hybride ou électrique (DISTINCT, IN)
SELECT DISTINCT v.marque_voiture
FROM voiture v
WHERE v.energie_voiture IN ('hybride', 'electrique')
ORDER BY v.marque_voiture;

-- Utilitaires rattachés aux agences parisiennes (masques LIKE)
SELECT v.immatriculation_voiture,
       CONCAT(v.marque_voiture, ' ', v.modele_vehicule) AS vehicule,
       k.libelle_categorie,
       v.id_agence
FROM voiture v
JOIN categorie k ON k.id_categorie = v.id_categorie
WHERE k.libelle_categorie LIKE 'Utilitaire%'
  AND v.id_agence LIKE 'PAR%'
ORDER BY v.id_agence;

-- Clients ayant déjà loué une berline premium (IN imbriqués)
SELECT cl.numero_client,
       CONCAT(cl.prenom_client, ' ', cl.nom_client) AS client,
       cl.type_client
FROM client cl
WHERE cl.numero_client IN (SELECT c.numero_client
                           FROM contrat c
                           WHERE c.statut_contrat IN ('en cours', 'cloture')
                             AND c.immatriculation_voiture IN (SELECT v.immatriculation_voiture
                                                               FROM voiture v
                                                               WHERE v.id_categorie = 'PDAR'))
ORDER BY cl.nom_client;

-- Véhicules sans aucune location depuis le 1er octobre (NOT IN)
-- Le IS NOT NULL est indispensable : un seul NULL dans la sous-requête ferait renvoyer 0 ligne au NOT IN
SELECT v.immatriculation_voiture,
       CONCAT(v.marque_voiture, ' ', v.modele_vehicule) AS vehicule,
       v.id_agence
FROM voiture v
WHERE v.immatriculation_voiture NOT IN (SELECT c.immatriculation_voiture
                                        FROM contrat c
                                        WHERE c.immatriculation_voiture IS NOT NULL
                                          AND c.statut_contrat <> 'annule'
                                          AND c.date_heure_depart_prevu >= '2026-10-01')
ORDER BY v.id_agence;

-- Véhicule qui a coûté le plus cher en maintenance (>= ALL)
SELECT i.immatriculation_voiture,
       SUM(i.cout_intervention) AS cout_maintenance
FROM intervention i
GROUP BY i.immatriculation_voiture
HAVING SUM(i.cout_intervention) >= ALL (SELECT SUM(i2.cout_intervention)
                                        FROM intervention i2
                                        GROUP BY i2.immatriculation_voiture);

-- Catégories plus chères qu'au moins une catégorie d'utilitaire (> ANY)
SELECT k.id_categorie,
       k.libelle_categorie,
       k.tarif_journalier_categorie
FROM categorie k
WHERE k.libelle_categorie NOT LIKE 'Utilitaire%'
  AND k.tarif_journalier_categorie > ANY (SELECT k2.tarif_journalier_categorie
                                          FROM categorie k2
                                          WHERE k2.libelle_categorie LIKE 'Utilitaire%')
ORDER BY k.tarif_journalier_categorie DESC;

-- Véhicules passés au moins 2 fois en atelier, avec le coût moyen (GROUP BY, HAVING)
SELECT v.immatriculation_voiture,
       CONCAT(v.marque_voiture, ' ', v.modele_vehicule) AS vehicule,
       COUNT(*) AS nb_interventions,
       ROUND(AVG(i.cout_intervention), 2) AS cout_moyen
FROM voiture v
JOIN intervention i ON i.immatriculation_voiture = v.immatriculation_voiture
GROUP BY v.immatriculation_voiture, v.marque_voiture, v.modele_vehicule
HAVING COUNT(*) >= 2
ORDER BY nb_interventions DESC, cout_moyen DESC;

-- Hausse de 5 % du tarif journalier de la catégorie IFAR
UPDATE categorie
SET tarif_journalier_categorie = ROUND(tarif_journalier_categorie * 1.05, 2)
WHERE id_categorie = 'IFAR';

-- Purge des contrats annulés depuis plus de 6 mois
DELETE FROM contrat
WHERE statut_contrat = 'annule'
  AND date_heure_depart_prevu < '2026-05-07 00:00:00';
