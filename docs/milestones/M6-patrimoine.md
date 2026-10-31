# M6 — Patrimoine léger

> Branche d'intégration : `jalon/M6-patrimoine` · Statut : 🔒 attend M5

## Objectif

La vue d'ensemble « à la Finary », sans la partie investissement avancée.

## User stories

_Non détaillées dans la spec maître : à rédiger en mode plan au démarrage du jalon, puis à valider._

## Critères d'acceptation

- [ ] Patrimoine brut, dettes, patrimoine net, sur tous les comptes `includeInNetWorth`. → `feature/M6-patrimoine-net`
- [ ] Actifs manuels : immobilier, véhicule, crypto, autre (valeur saisie, date de mise à jour). → `feature/M6-actifs-manuels`
- [ ] Comptes épargne/investissement synchronisés si l'agrégateur le permet (valorisation globale). → `feature/M6-comptes-investissement`
- [ ] Snapshot quotidien et graphique d'évolution (1 M, 6 M, 1 A, tout). → `feature/M6-snapshots-evolution`
- [ ] Répartition par classe d'actifs. → `feature/M6-patrimoine-net`
- [ ] Objectifs : montant cible, date, comptes liés, progression et rythme mensuel nécessaire. → `feature/M6-objectifs`
- [ ] Indicateur « épargne de précaution » : nombre de mois de dépenses couverts par l'épargne disponible. → `feature/M6-epargne-precaution`
- [ ] Le rapport mensuel inclut la variation du patrimoine net. → `feature/M6-rapport-patrimoine`

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M6-patrimoine-net` | Brut / dettes / net, répartition par classe d'actifs | — |
| `feature/M6-actifs-manuels` | Saisie d'actifs manuels et date de mise à jour | — |
| `feature/M6-comptes-investissement` | Valorisation des comptes épargne/investissement via l'agrégateur | ADR-004 (M3) |
| `feature/M6-snapshots-evolution` | `NetWorthSnapshot` quotidien, graphique d'évolution | patrimoine-net |
| `feature/M6-objectifs` | `Goal` : progression, rythme mensuel nécessaire | — |
| `feature/M6-epargne-precaution` | Mois de dépenses couverts par l'épargne | patrimoine-net |
| `feature/M6-rapport-patrimoine` | Variation du patrimoine net dans le rapport mensuel | snapshots-evolution |

## Hors périmètre du jalon

- Voir SPEC.md B.4 : investir depuis l'app, dividendes, scanner de frais, simulations Monte Carlo.

## 🧑 Actions humaines

Aucune identifiée dans la spec maître (dépend de la couverture de l'agrégateur choisi en M3).
