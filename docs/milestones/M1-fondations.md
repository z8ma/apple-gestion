# M1 — Fondations

> Branche d'intégration : `jalon/M1-fondations` · Statut : ⏳ plan à valider (voir docs/plans/M1-plan.md)

## Objectif

Une app utilisable en saisie manuelle, avec le modèle de données complet du budget.

## User stories

- En tant qu'utilisateur, je crée des comptes manuels et j'ajoute/modifie/supprime des transactions. → `feature/M1-transactions`
- Je gère mes catégories et sous-catégories (créer, renommer, icône, couleur, réordonner, archiver). → `feature/M1-categories-tags`
- Je tague des transactions et je leur attribue une nature (Essentiel/Plaisir/Épargne). → `feature/M1-categories-tags`
- Je divise une transaction en plusieurs parts. → `feature/M1-split-remboursement`
- Je marque une transaction comme remboursement d'une autre. → `feature/M1-split-remboursement`
- Je sélectionne plusieurs transactions et je leur applique une action groupée. → `feature/M1-actions-groupees`
- Je règle mon jour de début de période et ma devise. → `feature/M1-reglages`
- Je verrouille l'app avec Face ID. → `feature/M1-verrouillage`

## Critères d'acceptation

- [ ] Projet Xcode avec targets App, Widgets (vide), tests ; App Group configuré ; CloudKit activé. → `feature/M1-projet-xcode`
- [ ] Toutes les entités de B.6 utiles à M1–M5 créées, conformes aux contraintes CloudKit. → `feature/M1-modele-donnees`
- [x] Jeu de catégories par défaut (annexe E.6) créé au premier lancement. → `feature/M1-modele-donnees`
- [ ] Liste des transactions groupée par jour, recherche texte, filtres catégorie/compte/tag. → `feature/M1-transactions`
- [ ] Split : impossible d'enregistrer si la somme des parts ≠ montant (tests). → `feature/M1-split-remboursement`
- [x] Calcul de période selon `periodStartDay` couvert par tests (fin de mois, février, années bissextiles). → `feature/M1-calcul-periode`
- [ ] Multi-sélection : catégoriser, taguer, exclure du budget, supprimer. → `feature/M1-actions-groupees`
- [ ] Verrouillage biométrique + écran masqué dans le sélecteur d'apps. → `feature/M1-verrouillage`
- [ ] Menu debug « Données de démo » (6 mois de transactions réalistes). → `feature/M1-donnees-demo`
- [ ] Previews SwiftUI pour chaque écran avec données fictives. → transverse

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M1-projet-xcode` | Projet, targets App / Widgets / Tests, App Group, CloudKit, String Catalog | — |
| `feature/M1-calcul-periode` | Calcul de période (E.8), pure function + tests | — |
| `feature/M1-modele-donnees` | Entités SwiftData B.6 (M1–M5), catégories par défaut E.6 | projet-xcode |
| `feature/M1-transactions` | Comptes manuels, CRUD transactions, liste par jour, recherche, filtres | modele-donnees |
| `feature/M1-categories-tags` | Gestion catégories / sous-catégories, tags, nature | modele-donnees |
| `feature/M1-split-remboursement` | Split en N parts (validation de somme), lien remboursement | transactions |
| `feature/M1-actions-groupees` | Multi-sélection et actions groupées | transactions |
| `feature/M1-reglages` | Écran Réglages : `periodStartDay`, devise, nature | modele-donnees |
| `feature/M1-verrouillage` | Face ID + masquage dans le sélecteur d'apps | projet-xcode |
| `feature/M1-donnees-demo` | Menu debug « Données de démo » (6 mois) | modele-donnees |

## Hors périmètre du jalon

- Capture Apple Pay, règles, catégorisation automatique (M2).
- Synchronisation bancaire, rapprochement, virements internes (M3).
- Calculs de budget, enveloppes, alertes, widgets non vides (M4).
- Analyses, abonnements, prévisionnel, export (M5).
- Patrimoine (M6).

## 🧑 Actions humaines

- [ ] Compte Apple Developer.
- [ ] Identifiant de bundle.
- [ ] Conteneur iCloud.
