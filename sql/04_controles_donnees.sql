

SELECT 'R1 - contrat établi par un employé d''une autre agence' AS regle_de_gestion,
       COUNT(*) AS nb_anomalies
FROM contrat c
JOIN employe e ON e.matricule_employe = c.matricule_employe
WHERE e.id_agence <> c.id_agence_depart

UNION ALL

SELECT 'R2 - permis trop récent au moment du départ',
       COUNT(*)
FROM contrat c
JOIN client cl  ON cl.numero_client = c.numero_client
JOIN permis p   ON p.numero_permis  = cl.numero_permis
LEFT JOIN voiture v ON v.immatriculation_voiture = c.immatriculation_voiture
WHERE c.statut_contrat <> 'annule'
  AND DATEDIFF(c.date_heure_depart_prevu, p.date_obtention_permis)
      < CASE WHEN v.id_categorie IN ('PDAR', 'FKMD') THEN 730 ELSE 365 END

UNION ALL

SELECT 'R3 - deux locations du même véhicule qui se chevauchent',
       COUNT(*)
FROM contrat a
JOIN contrat b ON b.immatriculation_voiture = a.immatriculation_voiture
              AND b.num_contrat > a.num_contrat
WHERE a.statut_contrat <> 'annule'
  AND b.statut_contrat <> 'annule'
  AND a.date_heure_depart_prevu < COALESCE(b.date_heure_retour_reelles, b.date_heure_retour_prevu)
  AND b.date_heure_depart_prevu < COALESCE(a.date_heure_retour_reelles, a.date_heure_retour_prevu)

UNION ALL

SELECT 'R4 - intervention pendant une location du véhicule',
       COUNT(*)
FROM intervention i
JOIN contrat c ON c.immatriculation_voiture = i.immatriculation_voiture
WHERE c.statut_contrat <> 'annule'
  AND i.date_intervention >= DATE(c.date_heure_depart_prevu)
  AND i.date_intervention <  DATE(COALESCE(c.date_heure_retour_reelles, c.date_heure_retour_prevu))

UNION ALL

SELECT 'R5 - compteur qui recule entre deux locations',
       COUNT(*)
FROM contrat a
JOIN contrat b ON b.immatriculation_voiture = a.immatriculation_voiture
              AND b.date_heure_depart_prevu > a.date_heure_depart_prevu
WHERE b.kilometrage_depart < a.kilometrage_retour

UNION ALL

SELECT 'MCD - client sans contrat (signe 1,n)',
       COUNT(*)
FROM client cl
WHERE NOT EXISTS (SELECT 1 FROM contrat c WHERE c.numero_client = cl.numero_client)

UNION ALL

SELECT 'MCD - catégorie sans véhicule (appartient 1,n)',
       COUNT(*)
FROM categorie k
WHERE NOT EXISTS (SELECT 1 FROM voiture v WHERE v.id_categorie = k.id_categorie)

UNION ALL

SELECT 'MCD - agence sans employé (travaille 1,n)',
       COUNT(*)
FROM agence a
WHERE NOT EXISTS (SELECT 1 FROM employe e WHERE e.id_agence = a.id_agence);
