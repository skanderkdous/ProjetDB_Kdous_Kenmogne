
ALTER TABLE client ADD CONSTRAINT ck_client_type
    CHECK (type_client IN ('particulier', 'professionnel'));


ALTER TABLE client ADD CONSTRAINT ck_client_raison_sociale
    CHECK (   (type_client = 'professionnel' AND raison_sociale_client IS NOT NULL)
           OR (type_client = 'particulier'   AND raison_sociale_client IS NULL));

-- Adresse e-mail bien formée (texte@texte.texte) et propre à un seul client
ALTER TABLE client ADD CONSTRAINT ck_client_mail
    CHECK (mail_client LIKE '%_@_%._%');
ALTER TABLE client ADD CONSTRAINT uq_client_mail UNIQUE (mail_client);

-- "possède" est en 1,1 des deux côtés : un permis appartient à un seul client
ALTER TABLE client ADD CONSTRAINT uq_client_permis UNIQUE (numero_permis);

-- Format du numéro client : CLI + 5 chiffres (8 caractères)
ALTER TABLE client ADD CONSTRAINT ck_client_numero
    CHECK (numero_client LIKE 'CLI_____');


-- "Une catégorie a un code à 4 caractères (norme ACRISS)"
ALTER TABLE categorie ADD CONSTRAINT ck_categorie_code
    CHECK (CHAR_LENGTH(id_categorie) = 4);

-- Deux catégories n'ont pas le même libellé
ALTER TABLE categorie ADD CONSTRAINT uq_categorie_libelle UNIQUE (libelle_categorie);

-- Un tarif journalier est strictement positif
ALTER TABLE categorie ADD CONSTRAINT ck_categorie_tarif
    CHECK (tarif_journalier_categorie > 0);


ALTER TABLE employe ADD CONSTRAINT ck_employe_poste
    CHECK (poste_employe IN ('agent de comptoir', 'preparateur',
                             'mecanicien', 'responsable d''agence'));


ALTER TABLE employe ADD CONSTRAINT ck_employe_matricule
    CHECK (matricule_employe LIKE 'EMP_____');



ALTER TABLE voiture ADD CONSTRAINT ck_voiture_immat
    CHECK (immatriculation_voiture LIKE '__-___-__');

ALTER TABLE voiture ADD CONSTRAINT ck_voiture_energie
    CHECK (energie_voiture IN ('essence', 'diesel', 'hybride', 'electrique'));

ALTER TABLE contrat ADD CONSTRAINT ck_contrat_statut
    CHECK (statut_contrat IN ('reserve', 'en cours', 'cloture', 'annule'));

ALTER TABLE contrat ADD CONSTRAINT ck_contrat_dates_prevues
    CHECK (date_heure_retour_prevu > date_heure_depart_prevu);


ALTER TABLE contrat ADD CONSTRAINT ck_contrat_date_reelle
    CHECK (date_heure_retour_reelles IS NULL
           OR date_heure_retour_reelles > date_heure_depart_prevu);

ALTER TABLE contrat ADD CONSTRAINT ck_contrat_km_positifs
    CHECK (    (kilometrage_depart IS NULL OR kilometrage_depart >= 0)
           AND (kilometrage_retour IS NULL OR kilometrage_retour >= 0));
ALTER TABLE contrat ADD CONSTRAINT ck_contrat_km_coherents
    CHECK (kilometrage_depart IS NULL OR kilometrage_retour IS NULL
           OR kilometrage_retour >= kilometrage_depart);

ALTER TABLE contrat ADD CONSTRAINT ck_contrat_depart_effectue
    CHECK (statut_contrat IN ('reserve', 'annule')
           OR (immatriculation_voiture IS NOT NULL AND kilometrage_depart IS NOT NULL));

ALTER TABLE contrat ADD CONSTRAINT ck_contrat_pas_de_retour_avant_depart
    CHECK (statut_contrat IN ('en cours', 'cloture')
           OR (date_heure_retour_reelles IS NULL AND kilometrage_retour IS NULL));

-- Un contrat clôturé a forcément une date et un kilométrage de retour
ALTER TABLE contrat ADD CONSTRAINT ck_contrat_cloture
    CHECK (statut_contrat <> 'cloture'
           OR (date_heure_retour_reelles IS NOT NULL AND kilometrage_retour IS NOT NULL));

-- Format du numéro de contrat : CT + année + tiret + 5 chiffres (12 caractères)
ALTER TABLE contrat ADD CONSTRAINT ck_contrat_numero
    CHECK (num_contrat LIKE 'CT____-_____');


ALTER TABLE intervention ADD CONSTRAINT ck_intervention_type
    CHECK (type_intervention IN ('vidange', 'revision', 'pneus', 'controle technique',
                                 'carrosserie', 'panne'));

-- Un coût est positif ou nul (intervention sous garantie)
ALTER TABLE intervention ADD CONSTRAINT ck_intervention_cout
    CHECK (cout_intervention >= 0);

-- Format du numéro d'intervention : INT + 7 chiffres (10 caractères)
ALTER TABLE intervention ADD CONSTRAINT ck_intervention_numero
    CHECK (num_intervention LIKE 'INT_______');
