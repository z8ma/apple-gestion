# M4 — Budgets et alertes

> Branche d'intégration : `jalon/M4-budgets-alertes` · Statut : 🔒 attend M3

## Objectif

L'utilisateur pilote son mois avec la méthode qu'il préfère.

## User stories

- Je choisis entre budget par catégorie et méthode des enveloppes, et je peux changer sans perdre mes données. → `feature/M4-mode-budget`
- Je fixe des cibles par catégorie et par sous-catégorie. → `feature/M4-cibles-categories`
- En mode enveloppes, je répartis mes revenus et je vois ce qui reste « à répartir ». → `feature/M4-enveloppes`
- Je suis alerté quand j'atteins mes seuils. → `feature/M4-alertes`
- Je vois mon « reste à dépenser » sur l'écran verrouillé. → `feature/M4-widgets`

## Critères d'acceptation

- [ ] Calculs de budget en pure functions, testés : remboursements déduits, splits comptés par partie, transactions exclues ignorées, compte joint pondéré par `budgetSharePercent`. → `feature/M4-calculs-budget`
- [ ] Cible de catégorie = somme des sous-catégories quand elles en ont. → `feature/M4-cibles-categories`
- [ ] Surcharge de cible pour un mois précis. → `feature/M4-cibles-categories`
- [ ] Enveloppes : allocation, montant « à répartir », report activable par enveloppe. → `feature/M4-enveloppes`
- [ ] Bascule de mode sans perte de données. → `feature/M4-mode-budget`
- [ ] Alertes locales aux seuils configurés, une seule fois par seuil et par période. → `feature/M4-alertes`
- [ ] Widgets : écran verrouillé (reste à dépenser) ; accueil petit (reste à dépenser) et moyen (3 catégories les plus consommées). → `feature/M4-widgets`
- [ ] Widgets rafraîchis après chaque capture ou synchro. → `feature/M4-widgets`

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M4-calculs-budget` | Moteur de calcul pur (remboursements, splits, exclusions, compte joint) | — |
| `feature/M4-cibles-categories` | Mode `.categoryMonthly` : cibles, somme des enfants, surcharge mensuelle | calculs-budget |
| `feature/M4-enveloppes` | Mode `.envelopes` : allocations, « à répartir », report | calculs-budget |
| `feature/M4-mode-budget` | Choix et bascule de mode sans perte | cibles-categories, enveloppes |
| `feature/M4-alertes` | Notifications locales aux seuils, une fois par seuil et par période | calculs-budget |
| `feature/M4-widgets` | Widgets écran verrouillé, petit, moyen ; rafraîchissement | calculs-budget |

## Hors périmètre du jalon

- Analyses, prévisionnel et « reste à vivre » (M5).
- Patrimoine (M6).

## 🧑 Actions humaines

Aucune identifiée dans la spec maître.
