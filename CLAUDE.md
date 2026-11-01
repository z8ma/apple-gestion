# CLAUDE.md — Pécule

## Contexte
> Reprise en cours : lire d'abord **docs/HANDOFF.md**.

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

## Git & branches
- Stratégie complète : docs/BRANCHES.md.
- `main` : stable, ne reçoit que des jalons terminés (Definition of Done remplie).
- `jalon/Mx-…` : branche d'intégration d'un jalon, mergée dans `main` en fin de jalon.
- `feature/Mx-…` : une fonctionnalité, partie de `jalon/Mx-…` et mergée dedans par PR.
- Chaque PR coche les critères d'acceptation concernés dans docs/milestones/Mx-….md.
- La CI (.github/workflows/ci.yml) doit être verte avant tout merge.
