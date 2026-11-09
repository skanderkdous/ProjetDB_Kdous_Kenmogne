DROP TABLE IF EXISTS intervention;
DROP TABLE IF EXISTS contrat;
DROP TABLE IF EXISTS voiture;
DROP TABLE IF EXISTS employe;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS permis;
DROP TABLE IF EXISTS categorie;
DROP TABLE IF EXISTS agence;

-- AGENCE (id_agence, nom_agence, adresse_agence)
CREATE TABLE agence (
    id_agence      VARCHAR(6)   NOT NULL,
    nom_agence     VARCHAR(50)  NOT NULL,
    adresse_agence VARCHAR(150) NOT NULL,
    CONSTRAINT pk_agence PRIMARY KEY (id_agence)
);

-- CATEGORIE (id_categorie, libelle_categorie, tarif_journalier_categorie)
CREATE TABLE categorie (
    id_categorie               CHAR(4)      NOT NULL,
    libelle_categorie          VARCHAR(50)  NOT NULL,
    tarif_journalier_categorie DECIMAL(6,2) NOT NULL,
    CONSTRAINT pk_categorie PRIMARY KEY (id_categorie)
);

-- PERMIS (numero_permis, date_obtention_permis)
CREATE TABLE permis (
    numero_permis         VARCHAR(20) NOT NULL,
    date_obtention_permis DATE        NOT NULL,
    CONSTRAINT pk_permis PRIMARY KEY (numero_permis)
);

-- CLIENT (numero_client, ..., #numero_permis)
CREATE TABLE client (
    numero_client         VARCHAR(8)   NOT NULL,
    nom_client            VARCHAR(50)  NOT NULL,
    prenom_client         VARCHAR(50)  NOT NULL,
    type_client           VARCHAR(13)  NOT NULL,
    raison_sociale_client VARCHAR(100),              -- vide pour un particulier
    mail_client           VARCHAR(100) NOT NULL,
    num_telephone_client  VARCHAR(15)  NOT NULL,
    numero_permis         VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_client PRIMARY KEY (numero_client),
    CONSTRAINT fk_client_permis FOREIGN KEY (numero_permis)
        REFERENCES permis (numero_permis)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- EMPLOYE (matricule_employe, ..., #id_agence)
-- "travaille" (1,1 - 1,n) -> clé étrangère vers AGENCE
CREATE TABLE employe (
    matricule_employe VARCHAR(8)  NOT NULL,
    nom_employe       VARCHAR(50) NOT NULL,
    prenom_employe    VARCHAR(50) NOT NULL,
    poste_employe     VARCHAR(30) NOT NULL,
    id_agence         VARCHAR(6)  NOT NULL,
    CONSTRAINT pk_employe PRIMARY KEY (matricule_employe),
    CONSTRAINT fk_employe_agence FOREIGN KEY (id_agence)
        REFERENCES agence (id_agence)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- VOITURE (immatriculation_voiture, ..., #id_categorie, #id_agence)
CREATE TABLE voiture (
    immatriculation_voiture VARCHAR(9)  NOT NULL,
    marque_voiture          VARCHAR(30) NOT NULL,
    modele_vehicule         VARCHAR(30) NOT NULL,
    date_mise_circulation   DATE        NOT NULL,
    energie_voiture         VARCHAR(20) NOT NULL,
    id_categorie            CHAR(4)     NOT NULL,
    id_agence               VARCHAR(6)  NOT NULL,
    CONSTRAINT pk_voiture PRIMARY KEY (immatriculation_voiture),
    CONSTRAINT fk_voiture_categorie FOREIGN KEY (id_categorie)
        REFERENCES categorie (id_categorie)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_voiture_agence FOREIGN KEY (id_agence)
        REFERENCES agence (id_agence)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- CONTRAT (num_contrat, ..., #numero_client, #matricule_employe,
CREATE TABLE contrat (
    num_contrat               VARCHAR(12) NOT NULL,
    statut_contrat            VARCHAR(10) NOT NULL,
    date_heure_depart_prevu   DATETIME    NOT NULL,
    date_heure_retour_prevu   DATETIME    NOT NULL,
    date_heure_retour_reelles DATETIME,
    kilometrage_depart        INT,
    kilometrage_retour        INT,
    numero_client             VARCHAR(8)  NOT NULL,
    matricule_employe         VARCHAR(8)  NOT NULL,
    id_agence_depart          VARCHAR(6)  NOT NULL,
    id_agence_retour          VARCHAR(6)  NOT NULL,
    immatriculation_voiture   VARCHAR(9),
    CONSTRAINT pk_contrat PRIMARY KEY (num_contrat),
    CONSTRAINT fk_contrat_client FOREIGN KEY (numero_client)
        REFERENCES client (numero_client)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_contrat_employe FOREIGN KEY (matricule_employe)
        REFERENCES employe (matricule_employe)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_contrat_agence_depart FOREIGN KEY (id_agence_depart)
        REFERENCES agence (id_agence)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_contrat_agence_retour FOREIGN KEY (id_agence_retour)
        REFERENCES agence (id_agence)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_contrat_voiture FOREIGN KEY (immatriculation_voiture)
        REFERENCES voiture (immatriculation_voiture)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- INTERVENTION (num_intervention, ..., #immatriculation_voiture)
CREATE TABLE intervention (
    num_intervention        VARCHAR(10)  NOT NULL,
    date_intervention       DATE         NOT NULL,
    type_intervention       VARCHAR(30)  NOT NULL,
    cout_intervention       DECIMAL(8,2) NOT NULL,
    immatriculation_voiture VARCHAR(9)   NOT NULL,
    CONSTRAINT pk_intervention PRIMARY KEY (num_intervention),
    CONSTRAINT fk_intervention_voiture FOREIGN KEY (immatriculation_voiture)
        REFERENCES voiture (immatriculation_voiture)
        ON DELETE CASCADE ON UPDATE CASCADE
);
