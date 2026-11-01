# Passation — reprise sur Mac (Claude Code local)

> Écrit par la session cloud précédente. À lire en premier, avec CLAUDE.md.

## Où en est le projet

- Branche de travail : **`jalon/M1-fondations`** (ne pas travailler sur `main`, qui ne reçoit que des jalons terminés).
- Tout le code de **M1 est écrit**. Les 10 branches `feature/M1-*` sont fusionnées dans le jalon.
- **CI verte** (GitHub Actions, macOS 26, Xcode 26.6, simulateur iPhone 17) : l'app, le widget et les tests
  compilent sans aucun warning, et tous les tests passent.
- Avancement : 3 critères sur 10 cochés dans `docs/milestones/M1-fondations.md`. On ne coche que ce
  qui est vérifié ; les 7 autres attendent une recette réelle sur Mac et sur iPhone.
- Décisions prises par défaut (réversibles) : ADR-007 à ADR-010 dans `docs/DECISIONS.md`.

## Ta mission : recette de M1 sur le Mac

1. `Config/Local.xcconfig` (ignoré par git) doit contenir :
   `PECULE_BUNDLE_ID_PREFIX = com.<nom>` et `PECULE_DEVELOPMENT_TEAM = <TEAM ID>`.
   Demande ces valeurs à l'humain si le fichier n'existe pas.
2. Build et tests :
   ```bash
   xcodebuild test -scheme Pecule -destination 'platform=iOS Simulator,name=iPhone 17'
   cd Core && swift test   # logique pure, rapide
   ```
3. Lance l'app sur le simulateur, va dans Réglages › Développement › « Générer 6 mois de données », puis
   vérifie chaque critère non coché de `docs/milestones/M1-fondations.md` (captures du simulateur
   bienvenues). Coche un critère seulement s'il est réellement vérifié.
4. Vérifie que chaque `#Preview` s'affiche (critère « Previews pour chaque écran »).
5. 🧑 Avec l'humain : signature avec son équipe (App Group + conteneur iCloud créés dans le portail
   développeur), synchro CloudKit réelle, Face ID sur iPhone réel.
6. Corrige ce qui ne va pas sur `jalon/M1-fondations` (ou sur une branche `feature/M1-*` si c'est gros),
   avec des commits courts en français (`fix(M1): …`), puis pousse. La CI doit rester verte.
7. Quand la Definition of Done est remplie (tous les critères cochés), propose la PR
   `jalon/M1-fondations` → `main`. **Ne démarre pas M2 sans un plan validé par l'humain.**

## Pièges déjà rencontrés (à ne pas réintroduire)

- **`MemberImportVisibility` est activé** : chaque fichier doit importer explicitement les modules
  dont il utilise des membres (`import PeculeCore`, `import SwiftData`, `import SwiftUI`), y compris
  dans les tests.
- **`Category` est ambigu** avec `ObjectiveC.Category` dans le module de test : écrire `Pecule.Category`.
- **Pas de `#Predicate<Category>`** avec un tri multiple dans les `@Query` (le vérificateur de types
  ne s'en sort pas) : utiliser `@Query(sort: Category.displayOrder)` et filtrer en mémoire.
- **Bug du compilateur Swift 6.3.3** : passer une référence de méthode en setter de `Binding`
  (`set: maMethode`) fait planter le compilateur pendant l'IRGen. Toujours écrire une closure
  (`set: { maMethode($0) }`).
- Dans `#expect`, préférer les closures aux key paths (`allSatisfy { $0.x }`).
- **Montants** : jamais de littéral `Double` (`-23.40`) ; utiliser `Decimal.exact("-23.40")`.
- `scripts/swift-parse-check.sh` : contrôle de syntaxe rapide ; `python3 scripts/jalons.py progress`
  affiche l'avancement des jalons.

## Question restée ouverte avec l'humain

- La CI iOS complète prend environ 6 minutes de runner macOS. C'est gratuit tant que le dépôt est
  public, mais ça compte 10 fois sur le quota s'il devient privé. Faut-il la garder sur chaque push de
  jalon et chaque PR ?
