## Étape 5 : interroger la base

**Fichier :** `sql/05_requetes_scenario.sql` (21 requêtes, à exécuter dans l'ordre, après 01, 02 et 03)

### 5.1 Scénario

On suit **une semaine à l'agence Paris Gare de Lyon (PAR01), du samedi 7 au samedi 14 novembre 2026**, puis le siège fait le bilan de l'activité du réseau. La « date du jour » est écrite en dur dans les requêtes (`2026-11-07 10:00`) : les résultats sont les mêmes quel que soit le jour d'exécution.

**Partie A : au comptoir.** Le samedi matin, Karim, agent de comptoir, regarde les départs de la semaine (A1). Inès Bonnet a réservé du 10 au 14 novembre et veut une citadine. Karim cherche une citadine présente à l'agence et libre sur cette période (A2). Les deux citadines de l'agence ne sont pas disponibles (A3) : la 208 n'a toujours pas été rendue (sa cliente a 2 jours de retard, A4) et la Clio part en révision le 13. Par contre, une Clio de l'agence de Lyon est garée à PAR01 depuis une location aller simple. Pendant ce temps, l'entreprise Batiself appelle pour louer un utilitaire de 12 m³. Karim vérifie que son conducteur a bien 2 ans de permis (A5), puis enregistre la réservation (A6). Le mardi, Inès part avec la Clio lyonnaise (A7). Elle la rend le samedi (A8), et Karim édite la facture (A9).

**Partie B : la responsable d'agence organise la semaine.** Elle repère les véhicules à rapatrier (B1), consulte le planning des interventions (B2), les effectifs du réseau (B3) et le nombre de contrats établis par chaque membre de son équipe (B4).

**Partie C : le siège analyse l'activité.** Chiffre d'affaires par agence (C1), activité et retards par catégorie (C2), rentabilité des véhicules (C3), meilleurs clients professionnels (C4), clients à relancer (C5), trajets aller simple (C6).

**Partie D : mises à jour.** Hausse du tarif des SUV (D1), puis purge des vieilles annulations (D2).

### 5.2 Requêtes et notions SQL utilisées

| Requête | Besoin | Notions SQL | Résultat |
|---|---|---|---|
| A1 | Réservations de la semaine à PAR01 | jointure, `BETWEEN` | CT2026-00076 (Inès Bonnet) |
| A2 | Citadines présentes à PAR01 et libres du 10 au 14/11 | sous-requêtes scalaires (`ORDER BY … LIMIT 1`), `NOT EXISTS`, `COALESCE` | GP-873-LC (Lyon) et GL-519-AZ (CDG) |
| A3 | Pourquoi les citadines de PAR01 ne sont pas libres | `LEFT JOIN` avec condition, sous-requête corrélée `MIN` | 208 en location, Clio en révision le 13/11 |
| A4 | Locations en retard dans tout le réseau | `DATEDIFF`, `CONCAT` | CT2026-00071, 2 jours de retard |
| A5 | Le conducteur de Batiself a-t-il 2 ans de permis ? | `DATEDIFF`, `CASE` | oui (permis de 2002) |
| A6 | Réservation de l'utilitaire | `INSERT` | CT2026-00083 créé |
| A7 | Départ : attribution du véhicule | `UPDATE` | statut « en cours » |
| A8 | Retour du véhicule | `UPDATE` | statut « clôturé » |
| A9 | Facture | jointures CONTRAT → VOITURE → CATÉGORIE, `GREATEST(DATEDIFF(…), 1)` | 4 jours × 39,90 € = 159,60 € (396 km) |
| B1 | Véhicules à rapatrier vers leur agence | deux jointures sur AGENCE, sous-requête `MAX` | 9 véhicules |
| B2 | Interventions à venir | jointures, tri | 4 interventions |
| B3 | Effectifs par agence et par poste | `GROUP BY` sur deux colonnes | 20 lignes |
| B4 | Contrats établis par chaque employé de PAR01 | `LEFT JOIN` + `COUNT` + `GROUP BY` | de 14 à 0 contrats |
| C1 | CA et panier moyen par agence | `SUM`, `AVG`, `ROUND`, `GROUP BY` | PAR01 en tête (5 415,70 €) |
| C2 | Activité par catégorie et % de retards | `LEFT JOIN` en chaîne, `CASE`, `NULLIF` | Citadine : 22 locations, 27,3 % de retards |
| C3 | Les 5 véhicules les moins rentables | tables dérivées agrégées, `LIMIT` | Peugeot 308 : −489,23 € |
| C4 | Clients professionnels avec au moins 3 locations | `HAVING` | 3 entreprises |
| C5 | Clients sans location depuis le 1er octobre | `NOT EXISTS` | 4 clients à relancer |
| C6 | Trajets aller simple | double jointure sur AGENCE, `GROUP BY` | 12 trajets |
| D1 | Tarif des SUV +5 % | `UPDATE` avec calcul | 74,90 € → 78,65 € |
| D2 | Purge des annulations de plus de 6 mois | `DELETE` | 2 contrats supprimés |

### 5.3 Ce que le scénario montre sur la conception

- **Les règles de gestion inter-tables sont vérifiées par des requêtes avant d'écrire.** Avant d'attribuer un véhicule (A7), la requête A2 vérifie qu'il est libre : pas de location qui se chevauche, pas d'intervention prévue. Avant de réserver un grand utilitaire (A6), la requête A5 vérifie l'ancienneté du permis. Les `CHECK` protègent ensuite chaque écriture : par exemple, A7 serait refusé sans véhicule ou sans kilométrage de départ.
- **La cardinalité 0,1 de « attribué »** est indispensable : la réservation CT2026-00083 (A6) est enregistrée sans véhicule, qui est attribué seulement au départ (A7).
- **La 3FN** : le tarif est stocké une seule fois, dans CATÉGORIE. La facture (A9), le CA (C1) et la rentabilité (C3) le retrouvent par les jointures CONTRAT → VOITURE → CATÉGORIE et calculent le montant au lieu de le stocker.
- **Limite mise en évidence par D1 :** comme le montant est recalculé avec le tarif *actuel*, relancer C1 après la hausse de 5 % augmenterait aussi le CA des locations de SUV déjà facturées, ce qui est faux. Pour corriger, il faudrait enregistrer dans le contrat le tarif appliqué au moment de la location.
- **Autre limite :** la catégorie demandée par le client à la réservation n'est pas enregistrée (dans A1, on ne sait pas qu'Inès veut une citadine). Elle n'apparaît que lorsque le véhicule est attribué. Il faudrait une association entre Contrat et Catégorie pour la garder.
