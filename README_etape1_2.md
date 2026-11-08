# Mini-projet TI503N : base de données d'un loueur de véhicules

Domaine : location et gestion de flotte automobile (entreprise comparable à Sixt, Hertz ou Europcar).

## Étape 1 : analyse des besoins

### 1.1 Prompt utilisé (framework RICARDO)

Le prompt complète la base fournie par l'enseignante. Nous avons ajouté le **Contexte** (domaine, type d'entreprise, activités, données collectées) et les **Références** (site sixt.fr, articles sur la gestion de flotte).

```text
Tu travailles dans le domaine de la location et de la gestion de flotte automobile. Ton entreprise a comme activité de louer des véhicules légers et utilitaires à des particuliers et à des professionnels, de gérer les contrats de réservation, le suivi de la maintenance ainsi que le réseau d'agences. C'est une entreprise comme Sixt, Hertz ou Europcar. Des données ont été collectées sur : les clients, les véhicules et leurs catégories, les agences de départ et d'arrivée, les contrats de location, le personnel d'agence, ainsi que les entretiens et réparations des véhicules. Inspire-toi du site web / des offres de location présentés sur https://www.sixt.fr et des articles de présentation des services de gestion de flotte automobile.

Ton entreprise veut appliquer MERISE pour concevoir un système d'information. Tu es chargé de la partie analyse, c'est-à-dire de collecter les besoins auprès de l'entreprise. Elle a fait appel à un étudiant en ingénierie informatique pour réaliser ce projet, tu dois lui fournir les informations nécessaires pour qu'il applique ensuite lui-même les étapes suivantes de conception et développement de la base de données.

D'abord, établis les règles de gestions des données de ton entreprise, sous la forme d'une liste à puces. Elles doivent correspondre aux informations que fournit quelqu'un qui connaît le fonctionnement de l'entreprise, mais pas comment se construit un système d'information.

Ensuite, à partir de ces règles, fournis un dictionnaire de données brutes avec les colonnes suivantes, regroupées dans un tableau : signification de la donnée, type, taille en nombre de caractères ou de chiffres. Il doit y avoir entre 25 et 35 données. Il sert à fournir des informations supplémentaires sur chaque donnée (taille et type) mais sans a priori sur comment les données vont être modélisées ensuite.

Fournis donc les règles de gestion et le dictionnaire de données.
```

Le prompt est aussi enregistré dans `prompts/prompt_etape1_analyse.txt`.

### 1.2 Règles de gestion obtenues

**Clients**
- Un client est soit un particulier, soit un professionnel (entreprise). Pour un professionnel, on enregistre aussi sa raison sociale.
- Chaque client a un numéro unique. On garde son nom, son prénom, son adresse e-mail et son numéro de téléphone.
- Pour louer, le client doit présenter un permis de conduire valide. On relève son numéro et sa date d'obtention.
- Le permis doit avoir au moins 1 an, et au moins 2 ans pour les véhicules haut de gamme et les grands utilitaires.
- Un client peut signer plusieurs contrats au fil du temps, mais un contrat ne concerne qu'un seul client.

**Véhicules et catégories**
- Chaque véhicule est identifié par son immatriculation. On connaît sa marque, son modèle, sa date de mise en circulation et son énergie (essence, diesel, hybride, électrique).
- Chaque véhicule appartient à une seule catégorie (citadine, berline, SUV, utilitaire 12 m³…). Une catégorie regroupe plusieurs véhicules.
- Une catégorie a un code à 4 caractères (norme ACRISS utilisée par les loueurs), un libellé et un tarif journalier.
- Le tarif dépend de la catégorie, pas du véhicule précis.
- À la réservation, le client choisit une catégorie. Le véhicule précis lui est attribué au moment du départ.
- Chaque véhicule est rattaché à une agence d'attache.

**Agences et personnel**
- Chaque agence a un code, un nom et une adresse.
- Un employé travaille dans une seule agence, et une agence emploie plusieurs employés.
- Pour chaque employé, on connaît son matricule, son nom, son prénom et son poste (agent de comptoir, préparateur, responsable d'agence…).

**Contrats de location**
- Chaque contrat a un numéro unique et porte sur un seul véhicule.
- Le contrat est établi par un employé de l'agence de départ.
- Il précise une agence de départ et une agence de retour. Elles peuvent être différentes (location aller simple).
- On note la date et l'heure de départ prévues, la date et l'heure de retour prévues, puis la date et l'heure de retour réelles.
- Le kilométrage est relevé au départ et au retour.
- Un contrat passe par les statuts : réservé, en cours, clôturé ou annulé.
- Un véhicule ne peut pas faire l'objet de deux locations en cours en même temps.
- Le prix d'une location se calcule à partir du tarif journalier de la catégorie et de la durée de location.

**Maintenance**
- Un véhicule peut subir plusieurs interventions, et chaque intervention concerne un seul véhicule.
- Une intervention est soit un entretien (vidange, révision, pneus), soit une réparation (carrosserie, panne).
- Pour chaque intervention, on enregistre un numéro, une date, un type et un coût.
- Un véhicule en intervention ne peut pas être loué.

### 1.3 Dictionnaire de données obtenu

Types : A = alphabétique, AN = alphanumérique, N = numérique, D = date, DH = date et heure.

| # | Signification | Type | Taille |
|---|---|---|---|
| 1 | Numéro du client | AN | 8 |
| 2 | Nom du client | A | 50 |
| 3 | Prénom du client | A | 50 |
| 4 | Type de client (particulier/professionnel) | A | 13 |
| 5 | Raison sociale du client professionnel | AN | 100 |
| 6 | Adresse e-mail du client | AN | 100 |
| 7 | Téléphone du client | AN | 15 |
| 8 | Numéro de permis de conduire | AN | 20 |
| 9 | Date d'obtention du permis | D | 10 |
| 10 | Code de la catégorie de véhicule | AN | 4 |
| 11 | Libellé de la catégorie | AN | 50 |
| 12 | Tarif journalier de la catégorie (€) | N | 6 (dont 2 déc.) |
| 13 | Immatriculation du véhicule | AN | 9 |
| 14 | Marque du véhicule | AN | 30 |
| 15 | Modèle du véhicule | AN | 30 |
| 16 | Date de mise en circulation | D | 10 |
| 17 | Énergie du véhicule | A | 20 |
| 18 | Code de l'agence | AN | 6 |
| 19 | Nom de l'agence | AN | 50 |
| 20 | Adresse de l'agence | AN | 150 |
| 21 | Matricule de l'employé | AN | 8 |
| 22 | Nom de l'employé | A | 50 |
| 23 | Prénom de l'employé | A | 50 |
| 24 | Poste de l'employé | A | 30 |
| 25 | Numéro du contrat | AN | 12 |
| 26 | Date et heure de départ prévues | DH | 16 |
| 27 | Date et heure de retour prévues | DH | 16 |
| 28 | Date et heure de retour réelles | DH | 16 |
| 29 | Kilométrage au départ | N | 7 |
| 30 | Kilométrage au retour | N | 7 |
| 31 | Statut du contrat | A | 10 |
| 32 | Numéro de l'intervention | AN | 10 |
| 33 | Date de l'intervention | D | 10 |
| 34 | Type d'intervention | A | 30 |
| 35 | Coût de l'intervention (€) | N | 8 (dont 2 déc.) |

### 1.4 Analyse du résultat

- **35 données** : c'est dans la fourchette demandée (25 à 35).
- Chaque donnée a une signification, un type et une taille. Les types sont cohérents : par exemple, le téléphone et le numéro de permis sont alphanumériques, parce qu'on ne fait pas de calcul dessus et qu'ils peuvent commencer par 0.
- Les règles sont formulées comme le ferait quelqu'un du métier, sans vocabulaire MERISE.
- Les données calculées (montant d'une location, durée) ne sont pas dans le dictionnaire, puisqu'elles se déduisent des autres. C'est voulu.

Nous n'avons pas eu besoin de relancer le prompt.

## Étape 2 : MCD

### 2.1 MCD

![MCD](images/mcd_v2.png)

Fichier source Looping : `mcd_v2.loo`. La version rendue le 16/10 (`mcd_v1.png`, `mcd_v1.loo`) reste dans le dépôt.

**Entités** (identifiant souligné) :
- **Permis** (<u>numero_permis</u>, date_obtention_permis)
- **Client** (<u>numero_client</u>, nom_client, prenom_client, type_client, raison_sociale_client, mail_client, num_telephone_client)
- **Employé** (<u>matricule_employe</u>, nom_employe, prenom_employe, poste_employe)
- **Agence** (<u>id_agence</u>, nom_agence, adresse_agence)
- **Contrat** (<u>num_contrat</u>, statut_contrat, date_heure_depart_prevu, date_heure_retour_prevu, date_heure_retour_reelles, kilometrage_depart, kilometrage_retour)
- **Voiture** (<u>immatriculation_voiture</u>, marque_voiture, modele_vehicule, date_mise_circulation, energie_voiture)
- **Catégorie** (<u>id_categorie</u>, libelle_categorie, tarif_journalier_categorie)
- **Intervention** (<u>num_intervention</u>, date_intervention, type_intervention, cout_intervention)

**Associations :**

| Association | Entité A | Card. A | Card. B | Entité B | Lecture |
|---|---|---|---|---|---|
| possède | Permis | 1,1 | 1,1 | Client | un client a un seul permis, un permis appartient à un seul client |
| signe | Client | 1,n | 1,1 | Contrat | un client signe au moins un contrat, un contrat a un seul client |
| établir | Employé | 0,n | 1,1 | Contrat | un employé établit 0 ou plusieurs contrats, un contrat est établi par un seul employé |
| travaille | Employé | 1,1 | 1,n | Agence | un employé travaille dans une agence, une agence a au moins un employé |
| partir de | Contrat | 1,1 | 0,n | Agence | un contrat a une agence de départ |
| retourner | Contrat | 1,1 | 0,n | Agence | un contrat a une agence de retour |
| attribué | Contrat | 0,1 | 0,n | Voiture | le véhicule n'est attribué qu'au départ, d'où le 0 |
| subit | Intervention | 1,1 | 0,n | Voiture | une intervention concerne un seul véhicule |
| est rattaché | Voiture | 1,1 | 0,n | Agence | un véhicule a une agence d'attache |
| appartient | Voiture | 1,1 | 1,n | Catégorie | un véhicule a une catégorie, une catégorie regroupe au moins un véhicule |

### 2.2 Normalisation

- **1FN** : chaque attribut contient une seule valeur, sans liste ni groupe répétitif. Chaque entité a un identifiant.
- **2FN** : tous les identifiants sont composés d'un seul attribut. Aucun attribut ne peut donc dépendre d'une partie seulement de l'identifiant.
- **3FN** : aucun attribut non identifiant ne dépend d'un autre attribut non identifiant. Par exemple, le tarif journalier dépend de la catégorie et non du véhicule : il est donc dans **Catégorie** et pas dans Voiture (règle « le tarif dépend de la catégorie, pas du véhicule précis »). De même, les informations d'agence sont dans **Agence** et ne sont pas recopiées dans Contrat ou dans Voiture.
- Les **données calculées** (montant, durée de location) ne sont pas stockées.

### 2.3 Corrections par rapport au MCD rendu le 16/10

Le sujet autorise à corriger le MCD après le premier rendu. Nous n'avons rien ajouté de nouveau, nous avons seulement corrigé les erreurs :

| # | Correction | Raison |
|---|---|---|
| 1 | Cardinalités de **« établir »** : Employé **0,n** (avant 1,1), Contrat **1,1** (avant 1,n) | L'ancienne version disait qu'un employé établit un seul contrat dans sa vie, et qu'un contrat peut être établi par plusieurs employés. Le 0 vient de ce que les préparateurs n'établissent pas de contrat. |
| 2 | Ajout de **raison_sociale_client** dans Client | Donnée n°5 du dictionnaire, oubliée. Le sujet impose d'intégrer toutes les données du dictionnaire. |
| 3 | Ajout de **energie_voiture** dans Voiture | Donnée n°17 du dictionnaire, oubliée. |
| 4 | Noms d'attributs **sans accents** (`numero_permis`, `modele_vehicule`) | Pour qu'ils deviennent des noms de colonnes SQL valides sans guillemets. |
