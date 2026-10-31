# Pécule — Algorithmes métier

> Source : docs/archive/SPEC_CLAUDE_CODE.md, section E. Toute implémentation dans Core/ doit suivre ces règles à la lettre.

## E.1 Parsing des montants (capture Apple Pay)

Entrée : texte libre. Exemples à supporter : `12,50 €`, `€12.50`, `12.50 EUR`, `-12,50 €`, `1 234,56 €` (espace insécable ou fine), `1,234.56 $`, `12 €`, `0,99€`.
- Retirer symboles et codes devise (en déduire la devise si présente, sinon devise par défaut).
- Détecter le séparateur décimal : le dernier `,` ou `.` suivi de exactement 1 ou 2 chiffres en fin de chaîne.
- Supprimer les séparateurs de milliers.
- Le résultat est une **dépense** : stocker en négatif quel que soit le signe d'entrée.
- Échec de parsing → transaction créée avec `needsReview = true` et le texte brut en note, jamais d'erreur silencieuse.

## E.2 Normalisation du commerçant (`merchantKey`)

Minuscules, suppression des accents, des préfixes bancaires (`CB `, `CARTE `, `PRLV SEPA `, `VIR `, `PAIEMENT PAR CARTE`), des dates (`25/10`), des numéros de carte masqués (`X1234`), des suffixes de ville et des chiffres isolés ; espaces multiples réduits. Ex. : `CB CARREFOUR CITY 25/10 PARIS` → `carrefour city`.

## E.3 Dédoublonnage et rapprochement

Dédoublonnage bancaire : clé = `providerTransactionID` ; à défaut, hash de (compte, bookingDate, montant, rawLabel normalisé). Une transaction `pending` côté banque qui devient `booked` met à jour la ligne existante.

Rapprochement d'une capture Apple Pay (`status = .pending`) avec une transaction bancaire :
- Candidats : même devise, |montant| égal à 0,01 près, date banque entre J-1 et J+7 de la capture, transaction bancaire non encore rapprochée.
- Score = 0,6 × proximité de date (1 si même jour, décroît linéairement à 0 à J+7) + 0,4 × similarité des `merchantKey` (recouvrement de tokens).
- Meilleur score ≥ 0,5 et écart avec le second ≥ 0,1 → fusion automatique. Sinon → `needsReview` avec les candidats proposés.
- Fusion : une seule transaction subsiste ; montant, date et compte viennent de la banque ; catégorie, note, tags, nature et split viennent de la capture ; `status = .reconciled`.
- Capture non rapprochée après 10 jours → signalée « non retrouvée en banque ».

## E.4 Virements internes

Deux transactions de montants opposés (à 0,01 près), sur deux comptes de l'utilisateur, à 3 jours d'écart maximum, dont un libellé contient un indicateur de virement (`VIR`, `VIREMENT`, `TRANSFER`) ou le nom de l'autre compte → `kind = .transfer`, `excludedFromBudget = true`. Annulable par l'utilisateur.

## E.5 Catégorisation (ordre de priorité)

1. Catégorie choisie par l'utilisateur (jamais écrasée).
2. Règles utilisateur, par priorité.
3. Historique : si ≥ 2 transactions passées du même `merchantKey` ont la même catégorie utilisateur → cette catégorie.
4. IA on-device (si activée et disponible) : Foundation Models avec sortie structurée (`@Generable`) contrainte à la liste des catégories de l'utilisateur ; entrée = libellé, montant, commerçant. Résultat marqué `categorizationOrigin = .ai`.
5. Sinon `none` + `needsReview`.
Vérifier la disponibilité du modèle (`SystemLanguageModel.default.availability`) et dégrader proprement si indisponible.

## E.6 Catégories par défaut (sous-catégories entre parenthèses)

Dépenses : Logement (Loyer, Énergie, Internet & mobile, Assurance habitation) · Alimentation (Courses, Restaurants, Livraison, Cafés) · Transports (Carburant, Transports en commun, Taxi & VTC, Entretien véhicule, Parking & péage) · Santé (Médecin, Pharmacie, Mutuelle) · Loisirs (Sorties, Sport, Culture, Voyages) · Shopping (Vêtements, High-tech, Maison) · Abonnements (Streaming, Logiciels, Presse) · Impôts & taxes · Frais bancaires · Cadeaux & dons · Enfants · Animaux · Divers.
Revenus : Salaire · Remboursements · Aides · Revenus d'épargne · Autres revenus.
Autres : Virements internes (transfer) · Épargne (saving).

## E.7 Détection des abonnements

Grouper par `merchantKey` sur 13 mois. Candidat si ≥ 3 occurrences, intervalles réguliers (≈7, ≈30, ≈91 ou ≈365 jours, tolérance ±20 %), variation de montant ≤ 10 % hors dernière occurrence. Prochaine échéance = dernière date + intervalle médian. Hausse de prix si le dernier montant dépasse la médiane de plus de 5 %. Statut initial `.suggested`, l'utilisateur confirme ou ignore (un abonnement ignoré n'est plus proposé).

## E.8 Calcul de période

Période courante = [date du `periodStartDay` le plus récent ≤ aujourd'hui ; même jour du mois suivant[. `periodStartDay` est limité à 1–28 pour exister dans tous les mois. Toutes les dates en fuseau horaire de l'utilisateur.
