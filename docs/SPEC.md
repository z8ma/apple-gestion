# Pécule — Spécification produit

> Source : docs/archive/SPEC_CLAUDE_CODE.md, section B.

## B.1 Vision

Une app de dépenses **native, rapide et privée** :
- **Instantanée** : chaque paiement Apple Pay est enregistré et catégorisé en une seconde, avant même que la banque ne l'affiche.
- **Complète** : toutes les banques synchronisées, rapprochées automatiquement avec les captures Apple Pay.
- **Personnalisable** : l'utilisateur choisit sa méthode de budget, ses catégories, ses règles, son début de mois.
- **Privée** : les données restent sur l'appareil et dans l'iCloud de l'utilisateur. Le serveur ne fait que relayer.
- **Patrimoine léger** : vue nette du patrimoine et objectifs, sans prétendre remplacer un outil d'investissement.

## B.2 Public

- V1 : l'auteur (usage personnel, TestFlight).
- V2 : ouverture App Store. L'architecture est multi-utilisateur dès le départ (Sign in with Apple, données par compte iCloud).

## B.3 Positionnement face à Finary (ce qu'on fait mieux)

Finary excelle en suivi de patrimoine. Son budget est historiquement critiqué. Les demandes récurrentes de leurs utilisateurs deviennent **nos fonctionnalités de base** :

| Manque côté Finary | Notre réponse | Jalon |
|---|---|---|
| Catégorisation auto peu fiable | Règles + IA on-device + apprentissage des corrections | M2, M3 |
| Budget cible impossible par sous-catégorie | Budgets par catégorie **et** sous-catégorie (somme auto) | M4 |
| Pas de labels/tags (« vacances Italie ») | Tags libres sur transactions + analyse par tag | M1, M5 |
| Impossible de diviser une transaction | Split d'une transaction en N parts catégorisées | M1 |
| Remboursements mal gérés | Type « remboursement » qui réduit la dépense de la catégorie | M1, M4 |
| Pas de prévisionnel des charges récurrentes | Calendrier prévisionnel + « reste à vivre » | M5 |
| Règles peu paramétrables | Règles multi-conditions (libellé, montant, compte) + renommage | M2 |
| Pointage une par une | Multi-sélection et actions groupées | M1 |
| Compte joint mal géré | Inclure/exclure un compte du budget, part personnelle en % | M4 |
| Double classification demandée | « Nature » optionnelle : Essentiel / Plaisir / Épargne (éditable) | M1, M5 |
| Export pour analyse par IA | Export CSV et JSON propre | M5 |
| Virements internes faussant le budget | Détection auto des virements entre comptes perso | M3 |

**Notre avantage unique** : capture Apple Pay instantanée + widgets iOS natifs + confidentialité locale.

**Ce qu'on reprend de Finary** (jalon M6) : patrimoine net/brut, évolution dans le temps, répartition par classe d'actifs, objectifs, rapport mensuel, flux entrées/sorties en diagramme.

## B.4 Hors périmètre (V1)

Investir depuis l'app, suivi des dividendes, scanner de frais, simulations Monte Carlo, initiation de paiement, comptes professionnels, Android/web, partage temps réel multi-utilisateurs (V2 via partage CloudKit), Apple Watch (V2).

## B.5 Contraintes techniques clés

**Capture Apple Pay.** FinanceKit n'est disponible qu'aux États-Unis pour Apple Card/Cash : non utilisable. On utilise l'**automatisation Raccourcis « Transaction »**, déclenchée à chaque paiement Wallet, qui appelle une App Intent de l'app avec commerçant, montant et carte. L'utilisateur crée l'automatisation lui-même (l'app le guide pas à pas). Les noms exacts des champs fournis par Raccourcis sont **à vérifier sur appareil réel** : les paramètres de l'intent sont donc des textes libres, parsés de façon robuste.

**Banques (DSP2).** Accès via un agrégateur agréé, à travers notre backend. Consentement à renouveler tous les 90 jours. Synchronisation plusieurs fois par jour, pas en temps réel. Choix de l'agrégateur : voir DECISIONS.md (ADR-004).

**Background.** Les rafraîchissements en arrière-plan (BGAppRefreshTask) ne sont pas garantis par iOS : l'app synchronise aussi à l'ouverture et sur action manuelle.

## B.6 Modèle de données (SwiftData)

Toutes les entités ont `id: UUID`, `createdAt`, `updatedAt`.

**UserSettings** (singleton)
- `budgetMode`: `.categoryMonthly` | `.envelopes`
- `periodStartDay`: Int (1–28, défaut 1 — ex. 27 pour un salaire versé le 27)
- `defaultCurrency`: String (défaut "EUR")
- `alertThresholds`: [Decimal] (défaut [0.8, 1.0])
- `subscriptionReminderDays`: Int (défaut 3)
- `lockWithBiometrics`: Bool
- `aiCategorizationEnabled`: Bool
- `captureNotificationEnabled`: Bool
- `natureLabels`: [String] (défaut ["Essentiel", "Plaisir", "Épargne"], éditable)
- `monthlyReportEnabled`: Bool

**Account**
- `name`, `institutionName?`, `type`: `.checking` | `.savings` | `.card` | `.investment` | `.lifeInsurance` | `.crypto` | `.loan` | `.realEstate` | `.otherAsset`
- `balance`: Decimal, `balanceDate`, `currency`
- `isManual`: Bool, `connection?`: BankConnection, `providerAccountID?`
- `includeInBudget`: Bool, `budgetSharePercent`: Decimal (défaut 100, ex. 50 pour un compte joint)
- `includeInNetWorth`: Bool, `colorHex`, `sortOrder`, `isArchived`

**BankConnection**
- `provider`: String, `providerConnectionID`, `institutionName`
- `consentExpiresAt`, `status`: `.active` | `.expiringSoon` | `.expired` | `.error`
- `lastSyncAt?`, `lastError?`

**Transaction**
- `amount`: Decimal (signé), `currency`
- `date` (date d'opération), `bookingDate?` (date de comptabilisation banque)
- `rawLabel` (libellé brut), `displayName` (renommé), `merchantKey` (normalisé, voir E.2)
- `category?`, `nature?`: String, `tags`: [Tag], `note?`
- `kind`: `.expense` | `.income` | `.transfer` | `.refund`
- `source`: `.manual` | `.applePay` | `.bank` | `.import`
- `status`: `.pending` (capture non rapprochée) | `.posted` | `.reconciled`
- `account?`, `providerTransactionID?`, `cardName?`
- `excludedFromBudget`: Bool, `needsReview`: Bool, `categorizationOrigin`: `.user` | `.rule` | `.ai` | `.none`
- `parent?` / `splits`: [Transaction] (split : la somme des enfants = montant du parent ; le parent est exclu des calculs, les enfants comptent)
- `linkedRefundOf?`: Transaction
- `receiptImage?`: Data (`.externalStorage`)

**Category**
- `name`, `symbol` (SF Symbol), `colorHex`
- `parent?` (un seul niveau de sous-catégorie), `children`
- `kind`: `.expense` | `.income` | `.transfer` | `.saving`
- `sortOrder`, `isArchived`, `isSystem` (les catégories système ne sont pas supprimables mais renommables)

**Tag** : `name`, `colorHex`

**Rule**
- `name`, `priority`: Int, `isEnabled`
- Conditions (toutes doivent être vraies) : `labelMatch?` (`.contains` | `.equals` | `.startsWith` | `.regex` + motif), `amountMin?`, `amountMax?`, `accounts?`, `sources?`
- Actions : `setCategory?`, `rename?`, `addTags?`, `setNature?`, `setKind?`, `excludeFromBudget?`
- `createdFromCorrection`: Bool, `matchCount`: Int

**BudgetTarget** (mode `.categoryMonthly`)
- `category`, `amount`: Decimal, `periodStart?` (nil = valeur récurrente par défaut ; renseigné = surcharge pour une période)
- Règle : si une catégorie a des sous-catégories avec cible, sa cible = somme des enfants (non éditable).

**Envelope** (mode `.envelopes`)
- `name`, `categories`: [Category], `symbol`, `colorHex`
- `rolloverEnabled`: Bool (le reste/dépassement est reporté au mois suivant)
- **EnvelopeAllocation** : `envelope`, `periodStart`, `amount`

**Subscription** (détectée ou ajoutée à la main)
- `merchantKey`, `displayName`, `expectedAmount`, `frequency`: `.weekly` | `.monthly` | `.quarterly` | `.yearly`
- `nextExpectedDate`, `category?`, `status`: `.suggested` | `.confirmed` | `.ignored` | `.cancelled`
- `lastAmount`, `priceChangeDetected`: Bool

**Goal** (M6) : `name`, `targetAmount`, `targetDate?`, `accounts`: [Account], `symbol`

**NetWorthSnapshot** (M6) : `date`, `assets`, `liabilities`, `breakdownJSON` (par type de compte)

## B.7 Écrans

1. **Accueil** : reste à dépenser de la période, dernières transactions, captures à catégoriser, alertes (consentement qui expire, budget dépassé).
2. **Transactions** : liste groupée par jour, recherche multicritères (texte, catégorie, tag, compte, montant, dates), filtres, multi-sélection + actions groupées (catégoriser, taguer, exclure, supprimer).
3. **Détail transaction** : édition de tous les champs, split, lien remboursement, photo de ticket, « Créer une règle à partir de cette transaction ».
4. **Budget** : selon le mode, cibles par catégorie/sous-catégorie ou enveloppes, avec barres de progression.
5. **Analyses** : flux entrées → sorties, répartition, tendances, abonnements, prévisionnel, rapport mensuel.
6. **Patrimoine** (M6) : net/brut, évolution, répartition, objectifs.
7. **Comptes** : liste, connexions bancaires, ajout manuel.
8. **Réglages** : tout `UserSettings`, catégories, règles, tags, guide Apple Pay, export, suppression des données.

## B.8 Backend (Cloudflare Workers + D1)

Rôle unique : **détenir les secrets de l'agrégateur et relayer**. Ne stocke aucune transaction.

Tables D1 :
- `users(id, apple_sub, created_at)`
- `connections(id, user_id, provider, provider_connection_id, institution_name, consent_expires_at, status, created_at)`

Endpoints (tous sauf `/auth/apple` exigent `Authorization: Bearer <session>`) :
- `POST /auth/apple` : vérifie l'identity token Apple (JWKS Apple, audience = bundle id), crée/retrouve l'utilisateur, renvoie un jeton de session signé (durée 30 jours).
- `GET /institutions?country=FR` : liste des banques (cache 24 h).
- `POST /connections` `{institutionId}` : démarre un consentement, renvoie l'URL de redirection bancaire.
- `GET /connections/callback` : retour de la banque, finalise et redirige vers l'app (`pecule://bank-callback?status=…`).
- `GET /connections` : connexions et état du consentement.
- `GET /connections/:id/accounts` : comptes et soldes.
- `GET /accounts/:id/transactions?since=YYYY-MM-DD` : transactions normalisées.
- `DELETE /connections/:id` : révoque le consentement.
- `DELETE /me` : supprime l'utilisateur et révoque tout (RGPD).

L'agrégateur est caché derrière une interface `BankDataProvider` (adaptateurs interchangeables). Format normalisé renvoyé à l'app : `{ id, accountId, amount (string décimale), currency, date, bookingDate, label, counterparty?, status: "booked"|"pending" }`.

Sécurité : rate limiting par utilisateur, CORS fermé, aucun log de libellé ni de montant.
