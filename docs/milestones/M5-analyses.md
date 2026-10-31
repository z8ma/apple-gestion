# M5 — Analyses, abonnements, prévisionnel

> Branche d'intégration : `jalon/M5-analyses` · Statut : 🔒 attend M4

## Objectif

Comprendre où va l'argent et anticiper.

## User stories

_Non détaillées dans la spec maître : à rédiger en mode plan au démarrage du jalon, puis à valider._

## Critères d'acceptation

- [ ] Diagramme de flux entrées → catégories de sorties pour une période (style Sankey, en SwiftUI/Canvas). → `feature/M5-flux-sankey`
- [ ] Répartition par catégorie et sous-catégorie ; drill-down vers les transactions. → `feature/M5-repartition`
- [ ] Comparaison période vs précédente et vs moyenne des 6 dernières périodes. → `feature/M5-comparaisons`
- [ ] Analyse par tag (ex. coût total d'un voyage) et par nature. → `feature/M5-analyse-tags-nature`
- [ ] Détection des abonnements (annexe E.7) ; écran pour confirmer/ignorer ; rappel avant échéance ; alerte de hausse de prix. → `feature/M5-abonnements`
- [ ] Calendrier prévisionnel des prochains débits récurrents et « reste à vivre » estimé. → `feature/M5-previsionnel`
- [ ] Rapport mensuel (notification + écran récap) en début de période. → `feature/M5-rapport-mensuel`
- [ ] Recherche multicritères avancée (montant, dates, comptes, tags combinés). → `feature/M5-recherche-avancee`
- [ ] Photo de ticket attachée à une transaction (OCR Vision pour proposer montant et commerçant). → `feature/M5-ticket-ocr`
- [ ] Export CSV et JSON (période choisie), via ShareLink. → `feature/M5-export`

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M5-flux-sankey` | Diagramme de flux en SwiftUI/Canvas | — |
| `feature/M5-repartition` | Répartition catégorie / sous-catégorie, drill-down | — |
| `feature/M5-comparaisons` | Période vs précédente et vs moyenne sur 6 périodes | — |
| `feature/M5-analyse-tags-nature` | Totaux par tag et par nature | — |
| `feature/M5-abonnements` | Détection E.7 (pure + tests), confirmation, rappels, hausses de prix | — |
| `feature/M5-previsionnel` | Calendrier des débits récurrents, « reste à vivre » | abonnements |
| `feature/M5-rapport-mensuel` | Notification et écran récap en début de période | comparaisons |
| `feature/M5-recherche-avancee` | Recherche multicritères combinée | — |
| `feature/M5-ticket-ocr` | Photo de ticket + OCR Vision | — |
| `feature/M5-export` | Export CSV / JSON via ShareLink | — |

## Hors périmètre du jalon

- Patrimoine et sa variation dans le rapport mensuel (M6).

## 🧑 Actions humaines

Aucune identifiée dans la spec maître.
