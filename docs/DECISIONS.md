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

## ADR-007 — Logique pure dans le package local `PeculeCore`, modèles SwiftData dans `Shared/`
*Statut : adopté par défaut au démarrage de M1 (réversible).*
- `Core/` est un Swift Package (`PeculeCore`, Foundation seule, types valeur `Sendable`).
  Il se teste avec `swift test`, sans simulateur, en CI macOS et même sous Linux.
- Les modèles SwiftData et la persistance vivent dans `Shared/` (compilé dans l'app **et**
  les widgets, store dans l'App Group). Ils délèguent toute règle métier à `PeculeCore`.
- Écart avec l'arborescence de CLAUDE.md : `Core/Models` et `Core/Persistence` deviennent
  `Shared/Models` et `Shared/Persistence`, car SwiftData n'est pas « pur ».

## ADR-008 — Énumérations persistées en `String` (rawValue)
*Statut : adopté par défaut (réversible).* Chaque enum de B.6 est stockée dans un champ
`xxxRaw: String` avec un accesseur typé. Une valeur inconnue (ajoutée par une version plus
récente de l'app sur un autre appareil) est décodée vers une valeur par défaut au lieu de
faire échouer la lecture. Les `#Predicate` filtrent sur le champ `Raw`.

## ADR-009 — Le modèle s'appelle `Transaction`, comme dans la spec
*Statut : adopté par défaut (réversible).* Les types déclarés dans le module de l'app
masquent `SwiftUI.Transaction` ; StoreKit (M7) sera qualifié `StoreKit.Transaction`.

## ADR-010 — `Category.systemKey` pour dédoublonner les catégories par défaut
*Statut : adopté par défaut.* Ajout au modèle B.6 : clé stable (ex. `expense.housing.rent`)
posée sur les catégories système. Sans contrainte d'unicité possible avec CloudKit, deux
appareils peuvent créer chacun le jeu par défaut avant la première synchro : au lancement,
les doublons de même `systemKey` sont fusionnés dans le plus ancien (transactions,
sous-catégories, cibles, règles, enveloppes, abonnements). Le renommage reste libre.
