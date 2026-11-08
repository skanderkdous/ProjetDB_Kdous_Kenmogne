## Étape 3 : MLD, MPD et contraintes additionnelles

**Fichiers :**
- `sql/01_creation_tables.sql` : création des tables (MPD), avec clés primaires, clés étrangères et `NOT NULL`
- `sql/02_contraintes.sql` : contraintes additionnelles (`UNIQUE` et `CHECK`), ajoutées par `ALTER TABLE`
- `sql/tests_contraintes.sql` : 22 requêtes invalides, qui doivent toutes être rejetées

**SGBD :** MySQL 8.0.16 ou plus récent. Avant cette version, MySQL accepte les `CHECK` mais ne les applique pas.

### 3.1 Modèle logique de données (MLD)

Obtenu à partir du MCD de l'étape 2. Notation : **clé primaire** en gras, `#` = clé étrangère.

- **AGENCE** (**id_agence**, nom_agence, adresse_agence)
- **CATEGORIE** (**id_categorie**, libelle_categorie, tarif_journalier_categorie)
- **PERMIS** (**numero_permis**, date_obtention_permis)
- **CLIENT** (**numero_client**, nom_client, prenom_client, type_client, raison_sociale_client, mail_client, num_telephone_client, #numero_permis)
- **EMPLOYE** (**matricule_employe**, nom_employe, prenom_employe, poste_employe, #id_agence)
- **VOITURE** (**immatriculation_voiture**, marque_voiture, modele_vehicule, date_mise_circulation, energie_voiture, #id_categorie, #id_agence)
- **CONTRAT** (**num_contrat**, statut_contrat, date_heure_depart_prevu, date_heure_retour_prevu, date_heure_retour_reelles, kilometrage_depart, kilometrage_retour, #numero_client, #matricule_employe, #id_agence_depart, #id_agence_retour, #immatriculation_voiture)
- **INTERVENTION** (**num_intervention**, date_intervention, type_intervention, cout_intervention, #immatriculation_voiture)

### 3.2 Règles de passage MCD → MLD

1. Chaque **entité** devient une **relation** (une table). Son identifiant devient la clé primaire.
2. Pour une association **x,1 – x,n**, l'identifiant de l'entité côté *n* devient une **clé étrangère** dans l'entité côté *1*. L'association disparaît.
3. Si la cardinalité côté *1* est **0,1**, la clé étrangère peut être `NULL`. Si elle est **1,1**, elle est `NOT NULL`.
4. Pour une association **1,1 – 1,1**, la clé étrangère va d'un côté au choix, avec une contrainte `UNIQUE`.

| Association | Cardinalités | Traduction |
|---|---|---|
| possède (Client – Permis) | 1,1 – 1,1 | `numero_permis` dans CLIENT, `NOT NULL` + `UNIQUE` (règle 4) |
| signe (Client – Contrat) | 1,n – 1,1 | `numero_client` dans CONTRAT, `NOT NULL` |
| établir (Employé – Contrat) | 0,n – 1,1 | `matricule_employe` dans CONTRAT, `NOT NULL` |
| partir de (Contrat – Agence) | 1,1 – 0,n | `id_agence_depart` dans CONTRAT, `NOT NULL` |
| retourner (Contrat – Agence) | 1,1 – 0,n | `id_agence_retour` dans CONTRAT, `NOT NULL`. Ce sont deux associations vers la même entité, donc deux clés étrangères distinctes vers AGENCE. |
| attribué (Contrat – Voiture) | 0,1 – 0,n | `immatriculation_voiture` dans CONTRAT, **`NULL` autorisé** : une réservation n'a pas encore de véhicule (règle 3) |
| travaille (Employé – Agence) | 1,1 – 1,n | `id_agence` dans EMPLOYE, `NOT NULL` |
| appartient (Voiture – Catégorie) | 1,1 – 1,n | `id_categorie` dans VOITURE, `NOT NULL` |
| est rattaché (Voiture – Agence) | 1,1 – 0,n | `id_agence` dans VOITURE, `NOT NULL` |
| subit (Intervention – Voiture) | 1,1 – 0,n | `immatriculation_voiture` dans INTERVENTION, `NOT NULL` |

### 3.3 Modèle physique (MPD) : choix des types

Les types et les tailles viennent du dictionnaire de données :

| Dictionnaire | Type MySQL | Exemple |
|---|---|---|
| A / AN, taille fixe | `CHAR(n)` | code catégorie ACRISS : `CHAR(4)` |
| A / AN, taille variable | `VARCHAR(n)` | nom `VARCHAR(50)`, immatriculation `VARCHAR(9)` |
| N entier | `INT` | kilométrages (7 chiffres) |
| N décimal | `DECIMAL(p,2)` | tarif `DECIMAL(6,2)`, coût `DECIMAL(8,2)` |
| D | `DATE` | date d'obtention du permis |
| DH | `DATETIME` | dates et heures des contrats |

- Les montants sont en `DECIMAL`, pas en `FLOAT` : les valeurs sont exactes, sans erreur d'arrondi.
- Les téléphones et numéros de permis restent du texte : on ne fait pas de calcul dessus, et ils peuvent commencer par 0.
- Toutes les contraintes portent un nom (`pk_`, `fk_`, `uq_`, `ck_`), ce qui rend les messages d'erreur lisibles.
- Le montant et la durée d'une location ne sont pas stockés : ce sont des données calculées (3FN). L'étape 5 les calcule.

### 3.4 Contraintes additionnelles (`02_contraintes.sql`)

Au-delà des clés et des `NOT NULL` qui viennent du MLD, nous avons traduit les règles de gestion de l'étape 1 en contraintes `UNIQUE` et `CHECK` :

| Règle de gestion (étape 1) | Contrainte |
|---|---|
| Un client est soit un particulier, soit un professionnel | `ck_client_type` |
| Pour un professionnel, on enregistre sa raison sociale | `ck_client_raison_sociale` : obligatoire pour un pro, absente pour un particulier |
| Adresse e-mail du client | `ck_client_mail` (format texte@texte.texte), `uq_client_mail` (unique) |
| Un permis appartient à un seul client (possède 1,1 – 1,1) | `uq_client_permis` |
| Code catégorie à 4 caractères (ACRISS) | `ck_categorie_code` |
| Deux catégories n'ont pas le même libellé | `uq_categorie_libelle` |
| Le tarif journalier est positif | `ck_categorie_tarif` |
| Poste : agent de comptoir, préparateur, responsable d'agence… | `ck_employe_poste` |
| Immatriculation (format SIV AB-123-CD) | `ck_voiture_immat` |
| Énergie : essence, diesel, hybride, électrique | `ck_voiture_energie` |
| Statuts : réservé, en cours, clôturé, annulé | `ck_contrat_statut` |
| Retour prévu et retour réel après le départ | `ck_contrat_dates_prevues`, `ck_contrat_date_reelle` |
| Kilométrage relevé au départ et au retour | `ck_contrat_km_positifs`, `ck_contrat_km_coherents` (retour ≥ départ) |
| Le véhicule est attribué au départ | `ck_contrat_depart_effectue` : une location en cours ou clôturée a un véhicule et un km de départ |
| — | `ck_contrat_pas_de_retour_avant_depart` : une réservation n'a pas encore de retour |
| — | `ck_contrat_cloture` : un contrat clôturé a une date et un km de retour |
| Intervention : entretien (vidange, révision, pneus) ou réparation (carrosserie, panne) | `ck_intervention_type` |
| Coût d'une intervention | `ck_intervention_cout` (≥ 0) |
| Formats des identifiants (dictionnaire) | `ck_client_numero`, `ck_employe_matricule`, `ck_contrat_numero`, `ck_intervention_numero` |

### 3.5 Règles qu'un `CHECK` ne peut pas vérifier

Un `CHECK` ne voit que la ligne en cours d'écriture. Il ne peut donc pas comparer plusieurs lignes ni lire une autre table. Les règles suivantes ne sont pas imposées par la base :

- le contrat est établi par un employé **de l'agence de départ** (il faut lire la table EMPLOYE) ;
- le permis a **au moins 1 an**, ou 2 ans pour le haut de gamme (il faut lire PERMIS et CATEGORIE) ;
- un véhicule ne peut pas avoir **deux locations en même temps** (il faut comparer plusieurs contrats) ;
- un véhicule **en intervention** ne peut pas être loué (il faut lire INTERVENTION) ;
- les **cardinalités minimales 1** côté « n » (un client a au moins un contrat, etc.) : une clé étrangère ne garantit que le côté 1,1.

Nous les vérifions autrement :
- **sur les données insérées**, avec les requêtes de contrôle de `04_controles_donnees.sql` (étape 4), qui renvoient toutes 0 anomalie ;
- **au moment d'une opération**, avec une requête de vérification exécutée avant d'écrire (étape 5 : A2 vérifie qu'un véhicule est libre avant de l'attribuer, A5 vérifie l'ancienneté du permis avant la réservation).

### 3.6 Tests des contraintes (`tests_contraintes.sql`)

22 requêtes violent volontairement une contrainte chacune : clé primaire, clé étrangère (en insertion et en suppression), `NOT NULL`, les deux `UNIQUE` et 16 `CHECK`. Toutes sont rejetées, avec le message indiqué en commentaire au-dessus de chacune. Ce fichier s'exécute juste après `03` (avant `05`, qui modifie des contrats utilisés par les tests), en continuant malgré les erreurs (`mysql --force`, ou décocher « Stop script execution on errors » dans MySQL Workbench).

### 3.7 Exécution

```sql
CREATE DATABASE location_auto CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE location_auto;
```

Ensuite, exécuter dans l'ordre : `01_creation_tables.sql` → `02_contraintes.sql` → `03_insertion_donnees.sql` → `04_controles_donnees.sql` → `05_requetes_scenario.sql`. Pour tout recommencer, il suffit de relancer à partir de `01`, qui supprime les tables existantes.
