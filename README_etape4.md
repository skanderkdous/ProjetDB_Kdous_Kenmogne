## Étape 4 : insertion des données

**Fichiers :**
- `prompts/prompt_etape4_insertion.txt` : prompt utilisé
- `sql/03_insertion_donnees.sql` : les données
- `sql/04_controles_donnees.sql` : la vérification des données

### 4.1 Démarche

Nous avons demandé les données à l'IAG avec un prompt structuré selon le framework RICARDO, comme à l'étape 1. Le prompt lui donne :
- en **références**, les scripts de création des tables et des contraintes, pour qu'elle connaisse exactement les colonnes, les types et les `CHECK` ;
- une **date de référence fixe** (samedi 7 novembre 2026, 10h00), pour que les statuts « en cours », « réservé » et les retards aient un sens ;
- les **règles de gestion qu'aucune contrainte SQL ne vérifie** (voir 3.5), pour que les données les respectent quand même ;
- les **situations particulières** dont le scénario de l'étape 5 a besoin : une location en retard, des allers simples, des réservations à venir, de jeunes conducteurs, des interventions planifiées.

### 4.2 Contenu de la base

| Table | Lignes | Remarques |
|---|---|---|
| agence | 6 | 2 gares parisiennes, 2 aéroports, Lyon, Marseille |
| categorie | 7 | codes ACRISS, de la Mini (34,90 €/jour) à la berline premium (129 €/jour) |
| permis | 20 | dont 2 permis récents (15/06/2025 et 02/12/2024) |
| client | 20 | 14 particuliers, 6 professionnels |
| employe | 22 | dans chaque agence : 1 responsable, des agents de comptoir et un préparateur, plus 2 mécaniciens |
| voiture | 24 | vrais modèles (Clio, 208, 3008, Master, Tesla Model 3…) |
| contrat | 82 | 67 clôturés, 6 en cours, 6 réservés, 3 annulés |
| intervention | 32 | dont 4 planifiées après le 07/11 |

Toutes les données sont fictives. Les e-mails sont en `@exemple.fr`.

### 4.3 Vérification des données générées

**1. Les contraintes SQL.** Le script `03` s'exécute après `01` et `02`. Chaque ligne passe donc par les clés, les `NOT NULL`, les `UNIQUE` et les `CHECK`. Le script s'exécute **sans aucune erreur**.

**2. Les règles de gestion inter-tables.** Le fichier `04_controles_donnees.sql` compte, pour chaque règle, le nombre de lignes qui ne la respectent pas. Résultat obtenu :

| Règle contrôlée | Anomalies |
|---|---|
| R1 : contrat établi par un employé d'une autre agence | 0 |
| R2 : permis trop récent au moment du départ (1 an, ou 2 ans pour PDAR et FKMD) | 0 |
| R3 : deux locations du même véhicule qui se chevauchent | 0 |
| R4 : intervention pendant une location du véhicule | 0 |
| R5 : compteur qui recule entre deux locations du même véhicule | 0 |
| MCD : client sans contrat (signe 1,n) | 0 |
| MCD : catégorie sans véhicule (appartient 1,n) | 0 |
| MCD : agence sans employé (travaille 1,n) | 0 |

Pour nous assurer que ces requêtes détectent vraiment les erreurs, nous avons inséré dans une transaction, ensuite annulée (`ROLLBACK`), un contrat établi par un employé d'une autre agence, une berline premium louée par une conductrice qui a son permis depuis moins de 2 ans, une location qui en chevauche une autre et une intervention pendant une location. Chaque contrôle est alors passé de 0 à au moins 1.

**3. La variété des situations** : 14 retours en retard parmi les locations clôturées, 12 locations aller simple, 1 location en cours en retard (CT2026-00071), 2 annulations de plus de 6 mois.

### 4.4 Problèmes relevés et corrections

| Problème | Correction |
|---|---|
| Le premier jeu contenait plus de 150 contrats, trop pour être relu et vérifié | Nous avons réduit la période (juillet → novembre) et espacé les locations : 82 contrats |
| Une intervention pouvait tomber pendant une location en cours (règle R4 non respectée) | Nous avons supprimé les interventions concernées |
| Un client fictif portait le nom d'une personnalité connue | Nous l'avons remplacé par un nom neutre |
