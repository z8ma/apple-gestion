# Pécule — Spécification maître pour Claude Code

> **Nom de code provisoire : « Pécule »** (modifiable).
> App iOS native de gestion des dépenses, avec capture instantanée des paiements Apple Pay, synchronisation bancaire multi-banques, budgets personnalisables, analyses et suivi de patrimoine léger.
> Inspiration produit : Finary (patrimoine) — mais **centrée budget**, là où Finary est faible.

---

## 0. Instructions pour Claude Code — À LIRE EN PREMIER

Ce fichier est la **source de vérité unique** du projet. Ta première tâche n'est **pas** de coder :

1. Crée l'arborescence documentaire suivante à partir des sections de ce fichier :
   - `CLAUDE.md` ← contenu de la **section A**
   - `docs/SPEC.md` ← contenu de la **section B**
   - `docs/DECISIONS.md` ← contenu de la **section C**
   - `docs/milestones/M1-fondations.md` … `M7-ouverture.md` ← un fichier par jalon de la **section D**
   - `docs/ALGORITHMES.md` ← contenu de la **section E**
2. Garde ce fichier maître dans `docs/archive/SPEC_CLAUDE_CODE.md`.
3. **Arrête-toi** et présente un résumé. N'écris aucune ligne de Swift avant validation humaine.
4. Ensuite, on travaille **un jalon à la fois**, en commençant chaque jalon en **mode plan**.

Les étapes marquées **🧑 Action humaine** ne peuvent pas être faites par toi : signale-les clairement et attends confirmation.

---

## A. CLAUDE.md (règles permanentes du projet)

```markdown
# CLAUDE.md — Pécule

## Contexte
App iOS de gestion des dépenses perso, conçue pour être ouverte au public plus tard.
Spec complète : docs/SPEC.md. Jalons : docs/milestones/. Décisions : docs/DECISIONS.md.
Algorithmes métier : docs/ALGORITHMES.md.

## Stack (non négociable sans ADR dans DECISIONS.md)
- Swift 6, concurrence stricte activée (Complete), zéro warning.
- iOS 26 minimum. iPhone uniquement en V1.
- SwiftUI + Observation (@Observable). Pas d'UIKit sauf nécessité documentée.
- SwiftData pour la persistance, synchronisé via CloudKit (base privée de l'utilisateur).
- Swift Charts, WidgetKit, App Intents, UserNotifications, LocalAuthentication,
  AuthenticationServices (Sign in with Apple, ASWebAuthenticationSession),
  BackgroundTasks, Foundation Models (IA on-device, optionnelle).
- Tests : Swift Testing (`import Testing`). XCTest uniquement pour les UI tests.
- Backend : Cloudflare Workers en TypeScript + D1 (dossier /backend).
- Aucune dépendance tierce (SPM ou npm) sans accord explicite de l'humain.

## Architecture
- Dossiers : App/, Core/ (Models, Persistence, Money, Rules, Reconciliation,
  Budget, Insights, Notifications), Features/ (une feature = un dossier),
  Intents/, Widgets/, Shared/ (code partagé app + extensions), backend/, Tests/.
- La logique métier vit dans Core/ en **fonctions pures sur des types valeur**
  (structs), testables sans SwiftData. Les vues ne contiennent pas de règles métier.
- Services derrière des protocoles (ex. `BankSyncService`, `CategorizationService`)
  pour pouvoir les remplacer par des fakes en test et en preview.
- Le store SwiftData vit dans un **App Group** partagé avec les widgets et les intents.

## Contraintes SwiftData + CloudKit
- Toutes les propriétés ont une valeur par défaut ou sont optionnelles.
- Pas de `@Attribute(.unique)`. Relations optionnelles.
- Dédoublonnage géré en code (voir ALGORITHMES.md).

## Argent
- Jamais de Double/Float pour un montant. Toujours `Decimal` + code devise ISO 4217.
- Convention de signe : sortie d'argent = négatif, entrée = positif.
- Affichage via FormatStyle (`.currency(code:)`), locale de l'utilisateur.

## Personnalisation
- Tout ce qui est un choix utilisateur passe par le modèle `UserSettings` ou des
  entités éditables (catégories, règles, budgets). Rien de figé dans le code
  hormis les valeurs par défaut.

## Sécurité & confidentialité
- Aucun secret (clé API, clé privée) dans l'app ni dans le repo. Secrets backend
  via `wrangler secret`. `.dev.vars` dans .gitignore.
- Le backend ne stocke JAMAIS de transactions ni de soldes. Il relaie seulement.
- Jeton de session dans le Keychain. Aucun SDK d'analytics tiers.
- Pas de données personnelles dans les logs.

## Localisation
- Français d'abord, tout texte dans un String Catalog (Localizable.xcstrings).

## Méthode de travail
- Un jalon à la fois. Commencer par un plan, attendre validation.
- Écrire les tests du domaine avant ou avec le code.
- Definition of Done d'un jalon : build OK, tests verts, zéro warning,
  tous les critères d'acceptation du jalon cochés, previews SwiftUI fonctionnelles,
  DECISIONS.md à jour si un choix a été fait.
- Marquer **🧑 Action humaine** tout ce qui demande l'humain (comptes, appareil réel,
  entitlements, App Store Connect).
- Commits courts, en français, format : `feat(M2): capture Apple Pay via App Intent`.
- En cas d'ambiguïté dans la spec : poser la question, ne pas inventer.

## Outils
- MCP Xcode natif (xcrun mcpbridge) et XcodeBuildMCP pour build, tests, simulateur.
- Mode debug : menu « Données de démo » qui génère des transactions réalistes
  (le simulateur ne peut pas déclencher Apple Pay).
```

---

## B. SPEC.md (spécification produit)

### B.1 Vision

Une app de dépenses **native, rapide et privée** :
- **Instantanée** : chaque paiement Apple Pay est enregistré et catégorisé en une seconde, avant même que la banque ne l'affiche.
- **Complète** : toutes les banques synchronisées, rapprochées automatiquement avec les captures Apple Pay.
- **Personnalisable** : l'utilisateur choisit sa méthode de budget, ses catégories, ses règles, son début de mois.
- **Privée** : les données restent sur l'appareil et dans l'iCloud de l'utilisateur. Le serveur ne fait que relayer.
- **Patrimoine léger** : vue nette du patrimoine et objectifs, sans prétendre remplacer un outil d'investissement.

### B.2 Public

- V1 : l'auteur (usage personnel, TestFlight).
- V2 : ouverture App Store. L'architecture est multi-utilisateur dès le départ (Sign in with Apple, données par compte iCloud).

### B.3 Positionnement face à Finary (ce qu'on fait mieux)

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

### B.4 Hors périmètre (V1)

Investir depuis l'app, suivi des dividendes, scanner de frais, simulations Monte Carlo, initiation de paiement, comptes professionnels, Android/web, partage temps réel multi-utilisateurs (V2 via partage CloudKit), Apple Watch (V2).

### B.5 Contraintes techniques clés

**Capture Apple Pay.** FinanceKit n'est disponible qu'aux États-Unis pour Apple Card/Cash : non utilisable. On utilise l'**automatisation Raccourcis « Transaction »**, déclenchée à chaque paiement Wallet, qui appelle une App Intent de l'app avec commerçant, montant et carte. L'utilisateur crée l'automatisation lui-même (l'app le guide pas à pas). Les noms exacts des champs fournis par Raccourcis sont **à vérifier sur appareil réel** : les paramètres de l'intent sont donc des textes libres, parsés de façon robuste.

**Banques (DSP2).** Accès via un agrégateur agréé, à travers notre backend. Consentement à renouveler tous les 90 jours. Synchronisation plusieurs fois par jour, pas en temps réel. Choix de l'agrégateur : voir DECISIONS.md (ADR-004).

**Background.** Les rafraîchissements en arrière-plan (BGAppRefreshTask) ne sont pas garantis par iOS : l'app synchronise aussi à l'ouverture et sur action manuelle.

### B.6 Modèle de données (SwiftData)

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

### B.7 Écrans

1. **Accueil** : reste à dépenser de la période, dernières transactions, captures à catégoriser, alertes (consentement qui expire, budget dépassé).
2. **Transactions** : liste groupée par jour, recherche multicritères (texte, catégorie, tag, compte, montant, dates), filtres, multi-sélection + actions groupées (catégoriser, taguer, exclure, supprimer).
3. **Détail transaction** : édition de tous les champs, split, lien remboursement, photo de ticket, « Créer une règle à partir de cette transaction ».
4. **Budget** : selon le mode, cibles par catégorie/sous-catégorie ou enveloppes, avec barres de progression.
5. **Analyses** : flux entrées → sorties, répartition, tendances, abonnements, prévisionnel, rapport mensuel.
6. **Patrimoine** (M6) : net/brut, évolution, répartition, objectifs.
7. **Comptes** : liste, connexions bancaires, ajout manuel.
8. **Réglages** : tout `UserSettings`, catégories, règles, tags, guide Apple Pay, export, suppression des données.

### B.8 Backend (Cloudflare Workers + D1)

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

---

## C. DECISIONS.md (registre des décisions)

```markdown
# Décisions d'architecture

## ADR-001 — iOS 26 minimum, Swift 6 strict
Accès à Foundation Models (catégorisation IA on-device) et aux dernières API SwiftData.
Public cible : utilisateurs d'iPhone récents.

## ADR-002 — Données locales + CloudKit, backend sans stockage de transactions
Confidentialité, coût quasi nul, conformité RGPD simplifiée. Le backend ne fait que relayer.

## ADR-003 — Capture Apple Pay via automatisation Raccourcis « Transaction »
FinanceKit indisponible en France. L'automatisation est créée par l'utilisateur,
l'app fournit l'App Intent et un guide. Rapprochement ultérieur avec la banque.

## ADR-004 — Agrégateur bancaire : À TRANCHER au début de M3 (spike)
Candidats :
- Powens (français, utilisé par Finary, bonne couverture des banques FR,
  couvre potentiellement les comptes d'investissement → utile pour M6).
- Enable Banking (DSP2 comptes de paiement, offre d'entrée accessible).
GoCardless Bank Account Data : nouvelles inscriptions fermées depuis juillet 2025, écarté.
Critères : couverture des banques de l'utilisateur, prix pour 1 puis 1 000 utilisateurs,
support des comptes épargne/investissement, qualité des libellés, sandbox.
🧑 Action humaine : créer les comptes sandbox et fournir les identifiants via wrangler secret.

## ADR-005 — Backend Cloudflare Workers + D1 en TypeScript
Serverless, gratuit à petite échelle, déploiement simple via wrangler.

## ADR-006 — Montants en Decimal, signe négatif pour les sorties
```

---

## D. Jalons

Chaque jalon = un fichier `docs/milestones/Mx-….md` avec : objectif, user stories, critères d'acceptation (cases à cocher), hors périmètre du jalon, actions humaines.

### M1 — Fondations

**Objectif** : une app utilisable en saisie manuelle, avec le modèle de données complet du budget.

User stories :
- En tant qu'utilisateur, je crée des comptes manuels et j'ajoute/modifie/supprime des transactions.
- Je gère mes catégories et sous-catégories (créer, renommer, icône, couleur, réordonner, archiver).
- Je tague des transactions et je leur attribue une nature (Essentiel/Plaisir/Épargne).
- Je divise une transaction en plusieurs parts.
- Je marque une transaction comme remboursement d'une autre.
- Je sélectionne plusieurs transactions et je leur applique une action groupée.
- Je règle mon jour de début de période et ma devise.
- Je verrouille l'app avec Face ID.

Critères d'acceptation :
- [ ] Projet Xcode avec targets App, Widgets (vide), tests ; App Group configuré ; CloudKit activé.
- [ ] Toutes les entités de B.6 utiles à M1–M5 créées, conformes aux contraintes CloudKit.
- [ ] Jeu de catégories par défaut (annexe E.6) créé au premier lancement.
- [ ] Liste des transactions groupée par jour, recherche texte, filtres catégorie/compte/tag.
- [ ] Split : impossible d'enregistrer si la somme des parts ≠ montant (tests).
- [ ] Calcul de période selon `periodStartDay` couvert par tests (fin de mois, février, années bissextiles).
- [ ] Multi-sélection : catégoriser, taguer, exclure du budget, supprimer.
- [ ] Verrouillage biométrique + écran masqué dans le sélecteur d'apps.
- [ ] Menu debug « Données de démo » (6 mois de transactions réalistes).
- [ ] Previews SwiftUI pour chaque écran avec données fictives.

🧑 Action humaine : compte Apple Developer, identifiant de bundle, conteneur iCloud.

### M2 — Capture Apple Pay et règles

**Objectif** : un paiement Apple Pay est enregistré et catégorisé en ~1 seconde.

User stories :
- Quand je paye avec Apple Pay, la dépense apparaît dans l'app sans que je l'ouvre.
- Je reçois une notification avec des boutons de catégorie si l'app n'est pas sûre.
- Je crée des règles (conditions + actions) et l'app me propose une règle quand je corrige une catégorie.
- L'app me guide pour créer l'automatisation Raccourcis.

Critères d'acceptation :
- [ ] App Intent `CaptureTransactionIntent` (paramètres : `merchant`, `amount`, `card` en texte), `openAppWhenRun = false`, s'exécute en moins de 2 s.
- [ ] Parsing du montant robuste (annexe E.1), couvert par au moins 15 cas de test.
- [ ] Transaction créée en `source = .applePay`, `status = .pending`.
- [ ] Moteur de règles (pure function) : priorité, conditions multiples, actions multiples ; tests.
- [ ] Si aucune règle : suggestion IA (annexe E.5) ; sinon notification avec 3 catégories probables + « Autre ».
- [ ] Les boutons de la notification catégorisent sans ouvrir l'app.
- [ ] Correction manuelle → proposition « Appliquer à toutes les transactions de [commerçant] ? » qui crée une règle (avec option rétroactive).
- [ ] Écran de gestion des règles (liste, édition, activer/désactiver, réordonner, aperçu des transactions concernées).
- [ ] Écran guide pas à pas de l'automatisation Raccourcis, avec test « J'ai payé, vérifier que ça marche ».
- [ ] App Shortcut « Ajouter une dépense » utilisable par Siri.

🧑 Action humaine : créer l'automatisation sur iPhone réel, payer une fois, vérifier les noms de champs fournis par Raccourcis et les reporter dans DECISIONS.md.

### M3 — Synchronisation bancaire

**Objectif** : toutes les banques synchronisées, captures Apple Pay rapprochées automatiquement.

User stories :
- Je me connecte (Sign in with Apple) et j'ajoute plusieurs banques.
- Mes transactions arrivent automatiquement, sans doublon.
- Ma capture Apple Pay et la ligne bancaire fusionnent en une seule transaction.
- Mes virements entre mes propres comptes ne comptent pas dans le budget.
- Je suis prévenu avant l'expiration d'un consentement.

Critères d'acceptation :
- [ ] Spike agrégateur réalisé, ADR-004 tranché et documenté.
- [ ] Backend Workers déployé : tous les endpoints de B.8, tests (vitest) sur l'auth et la normalisation.
- [ ] Sign in with Apple côté app, jeton dans le Keychain.
- [ ] Ajout de banque via ASWebAuthenticationSession, retour par URL scheme.
- [ ] Import initial de l'historique disponible (jusqu'à 90 jours minimum).
- [ ] Synchronisation : à l'ouverture, manuelle (pull-to-refresh), et BGAppRefreshTask.
- [ ] Dédoublonnage (annexe E.3) : rejouer deux fois la même synchro ne crée aucun doublon (test).
- [ ] Rapprochement capture ↔ banque (annexe E.3) ; cas ambigus marqués `needsReview`.
- [ ] Détection des virements internes (annexe E.4).
- [ ] Règles appliquées aux nouvelles transactions bancaires.
- [ ] Notifications de consentement à J-7 et J-1 ; renouvellement en un tap.
- [ ] Soldes des comptes mis à jour.

🧑 Actions humaines : comptes agrégateur, `wrangler secret put`, déploiement Cloudflare, connexion de ses vraies banques.

### M4 — Budgets et alertes

**Objectif** : l'utilisateur pilote son mois avec la méthode qu'il préfère.

User stories :
- Je choisis entre budget par catégorie et méthode des enveloppes, et je peux changer sans perdre mes données.
- Je fixe des cibles par catégorie et par sous-catégorie.
- En mode enveloppes, je répartis mes revenus et je vois ce qui reste « à répartir ».
- Je suis alerté quand j'atteins mes seuils.
- Je vois mon « reste à dépenser » sur l'écran verrouillé.

Critères d'acceptation :
- [ ] Calculs de budget en pure functions, testés : remboursements déduits, splits comptés par partie, transactions exclues ignorées, compte joint pondéré par `budgetSharePercent`.
- [ ] Cible de catégorie = somme des sous-catégories quand elles en ont.
- [ ] Surcharge de cible pour un mois précis.
- [ ] Enveloppes : allocation, montant « à répartir », report activable par enveloppe.
- [ ] Bascule de mode sans perte de données.
- [ ] Alertes locales aux seuils configurés, une seule fois par seuil et par période.
- [ ] Widgets : écran verrouillé (reste à dépenser) ; accueil petit (reste à dépenser) et moyen (3 catégories les plus consommées).
- [ ] Widgets rafraîchis après chaque capture ou synchro.

### M5 — Analyses, abonnements, prévisionnel

**Objectif** : comprendre où va l'argent et anticiper.

Critères d'acceptation :
- [ ] Diagramme de flux entrées → catégories de sorties pour une période (style Sankey, en SwiftUI/Canvas).
- [ ] Répartition par catégorie et sous-catégorie ; drill-down vers les transactions.
- [ ] Comparaison période vs précédente et vs moyenne des 6 dernières périodes.
- [ ] Analyse par tag (ex. coût total d'un voyage) et par nature.
- [ ] Détection des abonnements (annexe E.7) ; écran pour confirmer/ignorer ; rappel avant échéance ; alerte de hausse de prix.
- [ ] Calendrier prévisionnel des prochains débits récurrents et « reste à vivre » estimé.
- [ ] Rapport mensuel (notification + écran récap) en début de période.
- [ ] Recherche multicritères avancée (montant, dates, comptes, tags combinés).
- [ ] Photo de ticket attachée à une transaction (OCR Vision pour proposer montant et commerçant).
- [ ] Export CSV et JSON (période choisie), via ShareLink.

### M6 — Patrimoine léger

**Objectif** : la vue d'ensemble « à la Finary », sans la partie investissement avancée.

Critères d'acceptation :
- [ ] Patrimoine brut, dettes, patrimoine net, sur tous les comptes `includeInNetWorth`.
- [ ] Actifs manuels : immobilier, véhicule, crypto, autre (valeur saisie, date de mise à jour).
- [ ] Comptes épargne/investissement synchronisés si l'agrégateur le permet (valorisation globale).
- [ ] Snapshot quotidien et graphique d'évolution (1 M, 6 M, 1 A, tout).
- [ ] Répartition par classe d'actifs.
- [ ] Objectifs : montant cible, date, comptes liés, progression et rythme mensuel nécessaire.
- [ ] Indicateur « épargne de précaution » : nombre de mois de dépenses couverts par l'épargne disponible.
- [ ] Le rapport mensuel inclut la variation du patrimoine net.

### M7 — Préparation à l'ouverture (V2)

Critères d'acceptation :
- [ ] Onboarding complet (méthode de budget, catégories, banques, Apple Pay).
- [ ] Suppression totale des données (app + CloudKit + backend) en un écran.
- [ ] Politique de confidentialité, étiquette de confidentialité App Store, mentions DSP2.
- [ ] Accessibilité : VoiceOver, Dynamic Type, contrastes.
- [ ] Stratégie de monétisation documentée (ADR) ; StoreKit 2 si abonnement.
- [ ] Monitoring backend et quotas agrégateur.

🧑 Actions humaines : contrat agrégateur en production, fiche App Store, validation Apple.

---

## E. ALGORITHMES.md (règles métier précises)

### E.1 Parsing des montants (capture Apple Pay)

Entrée : texte libre. Exemples à supporter : `12,50 €`, `€12.50`, `12.50 EUR`, `-12,50 €`, `1 234,56 €` (espace insécable ou fine), `1,234.56 $`, `12 €`, `0,99€`.
- Retirer symboles et codes devise (en déduire la devise si présente, sinon devise par défaut).
- Détecter le séparateur décimal : le dernier `,` ou `.` suivi de exactement 1 ou 2 chiffres en fin de chaîne.
- Supprimer les séparateurs de milliers.
- Le résultat est une **dépense** : stocker en négatif quel que soit le signe d'entrée.
- Échec de parsing → transaction créée avec `needsReview = true` et le texte brut en note, jamais d'erreur silencieuse.

### E.2 Normalisation du commerçant (`merchantKey`)

Minuscules, suppression des accents, des préfixes bancaires (`CB `, `CARTE `, `PRLV SEPA `, `VIR `, `PAIEMENT PAR CARTE`), des dates (`25/10`), des numéros de carte masqués (`X1234`), des suffixes de ville et des chiffres isolés ; espaces multiples réduits. Ex. : `CB CARREFOUR CITY 25/10 PARIS` → `carrefour city`.

### E.3 Dédoublonnage et rapprochement

Dédoublonnage bancaire : clé = `providerTransactionID` ; à défaut, hash de (compte, bookingDate, montant, rawLabel normalisé). Une transaction `pending` côté banque qui devient `booked` met à jour la ligne existante.

Rapprochement d'une capture Apple Pay (`status = .pending`) avec une transaction bancaire :
- Candidats : même devise, |montant| égal à 0,01 près, date banque entre J-1 et J+7 de la capture, transaction bancaire non encore rapprochée.
- Score = 0,6 × proximité de date (1 si même jour, décroît linéairement à 0 à J+7) + 0,4 × similarité des `merchantKey` (recouvrement de tokens).
- Meilleur score ≥ 0,5 et écart avec le second ≥ 0,1 → fusion automatique. Sinon → `needsReview` avec les candidats proposés.
- Fusion : une seule transaction subsiste ; montant, date et compte viennent de la banque ; catégorie, note, tags, nature et split viennent de la capture ; `status = .reconciled`.
- Capture non rapprochée après 10 jours → signalée « non retrouvée en banque ».

### E.4 Virements internes

Deux transactions de montants opposés (à 0,01 près), sur deux comptes de l'utilisateur, à 3 jours d'écart maximum, dont un libellé contient un indicateur de virement (`VIR`, `VIREMENT`, `TRANSFER`) ou le nom de l'autre compte → `kind = .transfer`, `excludedFromBudget = true`. Annulable par l'utilisateur.

### E.5 Catégorisation (ordre de priorité)

1. Catégorie choisie par l'utilisateur (jamais écrasée).
2. Règles utilisateur, par priorité.
3. Historique : si ≥ 2 transactions passées du même `merchantKey` ont la même catégorie utilisateur → cette catégorie.
4. IA on-device (si activée et disponible) : Foundation Models avec sortie structurée (`@Generable`) contrainte à la liste des catégories de l'utilisateur ; entrée = libellé, montant, commerçant. Résultat marqué `categorizationOrigin = .ai`.
5. Sinon `none` + `needsReview`.
Vérifier la disponibilité du modèle (`SystemLanguageModel.default.availability`) et dégrader proprement si indisponible.

### E.6 Catégories par défaut (sous-catégories entre parenthèses)

Dépenses : Logement (Loyer, Énergie, Internet & mobile, Assurance habitation) · Alimentation (Courses, Restaurants, Livraison, Cafés) · Transports (Carburant, Transports en commun, Taxi & VTC, Entretien véhicule, Parking & péage) · Santé (Médecin, Pharmacie, Mutuelle) · Loisirs (Sorties, Sport, Culture, Voyages) · Shopping (Vêtements, High-tech, Maison) · Abonnements (Streaming, Logiciels, Presse) · Impôts & taxes · Frais bancaires · Cadeaux & dons · Enfants · Animaux · Divers.
Revenus : Salaire · Remboursements · Aides · Revenus d'épargne · Autres revenus.
Autres : Virements internes (transfer) · Épargne (saving).

### E.7 Détection des abonnements

Grouper par `merchantKey` sur 13 mois. Candidat si ≥ 3 occurrences, intervalles réguliers (≈7, ≈30, ≈91 ou ≈365 jours, tolérance ±20 %), variation de montant ≤ 10 % hors dernière occurrence. Prochaine échéance = dernière date + intervalle médian. Hausse de prix si le dernier montant dépasse la médiane de plus de 5 %. Statut initial `.suggested`, l'utilisateur confirme ou ignore (un abonnement ignoré n'est plus proposé).

### E.8 Calcul de période

Période courante = [date du `periodStartDay` le plus récent ≤ aujourd'hui ; même jour du mois suivant[. `periodStartDay` est limité à 1–28 pour exister dans tous les mois. Toutes les dates en fuseau horaire de l'utilisateur.
