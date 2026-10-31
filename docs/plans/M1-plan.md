# M1 — Plan proposé (à valider)

> Statut : **en attente de validation humaine**. Aucune ligne de Swift n'a été écrite (CLAUDE.md, section 0 de la spec).

## Ordre de réalisation proposé

1. `feature/M1-calcul-periode` : calcul de période E.8 en pure function + tests (fin de mois, février, années bissextiles, `periodStartDay` 1–28, fuseau horaire). Ne dépend de rien, donc idéal pour démarrer.
2. `feature/M1-projet-xcode` : projet, targets App / Widgets (vide) / Tests, App Group, CloudKit, String Catalog. **Bloquant, voir question 1.**
3. `feature/M1-modele-donnees` : entités B.6 (M1–M5) conformes CloudKit + catégories par défaut E.6 (création idempotente au premier lancement, testée).
4. `feature/M1-transactions` puis `feature/M1-categories-tags`, `feature/M1-reglages`.
5. `feature/M1-split-remboursement` (validation de la somme en pure function, testée) et `feature/M1-actions-groupees`.
6. `feature/M1-verrouillage` et `feature/M1-donnees-demo`.
7. Previews de chaque écran au fil de l'eau, puis revue de la Definition of Done et merge `jalon/M1-fondations` → `main`.

## Questions à trancher avant de coder

1. **Création du projet Xcode.** Cette session tourne dans un conteneur Linux sans Xcode : je ne peux ni créer, ni compiler, ni lancer le simulateur. Options :
   - a. *(recommandé)* Tu crées le projet vide dans Xcode 26 (App + Widget Extension + tests, bundle id, App Group, iCloud) et tu le pousses ; je prends le relais. Ou tu lances Claude Code sur ton Mac avec le MCP Xcode prévu dans CLAUDE.md.
   - b. Générer le projet avec XcodeGen ou Tuist : c'est une dépendance tierce, il faut donc ton accord.
   - c. Écrire le `.pbxproj` à la main : fragile, déconseillé.
2. **Proposition d'ADR-007 : la logique pure de Core/ dans un Swift Package local (`PeculeCore`, Foundation seule).** Elle se teste avec `swift test` sans simulateur (en CI macOS, et même sous Linux), ce qui garantit que les règles métier restent séparées de SwiftData, comme l'exige CLAUDE.md. Les modèles SwiftData resteraient dans l'app et seraient convertis en types valeur. D'accord ? Si oui, le package va-t-il dans `Core/` ou dans `Packages/PeculeCore/` ?
3. **Conflit de nom `Transaction`.** SwiftUI (`Transaction`) et StoreKit 2 (`Transaction`, prévu en M7) exposent déjà ce type. On garde `Transaction` et on qualifie les autres (`SwiftUI.Transaction`), ou on renomme (ex. `Operation`, `MoneyTransaction`) ?
4. **Identifiants.** Bundle id, App Group et conteneur iCloud (ex. `com.<toi>.pecule`, `group.com.<toi>.pecule`, `iCloud.com.<toi>.pecule`). 🧑 Action humaine.
5. **Énumérations persistées.** Je propose de stocker les enums SwiftData sous forme de `String` brute (rawValue) avec accesseur typé, ce qui est plus robuste face aux évolutions du schéma CloudKit. À consigner en ADR si tu valides.
6. **Minutes macOS de GitHub Actions.** Si le dépôt est privé, les runners macOS consomment le quota 10× plus vite. On garde la CI macOS sur chaque PR, ou seulement sur les PR vers `jalon/**` et `main` ?
