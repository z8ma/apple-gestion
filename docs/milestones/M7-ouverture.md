# M7 — Préparation à l'ouverture (V2)

> Branche d'intégration : `jalon/M7-ouverture` · Statut : 🔒 attend M6

## Objectif

_Non formulé dans la spec maître (titre du jalon : « Préparation à l'ouverture (V2) »). À préciser en mode plan._

## User stories

_Non détaillées dans la spec maître : à rédiger en mode plan au démarrage du jalon, puis à valider._

## Critères d'acceptation

- [ ] Onboarding complet (méthode de budget, catégories, banques, Apple Pay). → `feature/M7-onboarding`
- [ ] Suppression totale des données (app + CloudKit + backend) en un écran. → `feature/M7-suppression-donnees`
- [ ] Politique de confidentialité, étiquette de confidentialité App Store, mentions DSP2. → `feature/M7-confidentialite`
- [ ] Accessibilité : VoiceOver, Dynamic Type, contrastes. → `feature/M7-accessibilite`
- [ ] Stratégie de monétisation documentée (ADR) ; StoreKit 2 si abonnement. → `feature/M7-monetisation`
- [ ] Monitoring backend et quotas agrégateur. → `feature/M7-monitoring`

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M7-onboarding` | Parcours de premier lancement complet | — |
| `feature/M7-suppression-donnees` | Suppression app + CloudKit + `DELETE /me` | — |
| `feature/M7-confidentialite` | Politique, étiquette App Store, mentions DSP2 | — |
| `feature/M7-accessibilite` | Audit et corrections VoiceOver, Dynamic Type, contrastes | — |
| `feature/M7-monetisation` | ADR de monétisation, StoreKit 2 le cas échéant | — |
| `feature/M7-monitoring` | Monitoring du Worker, suivi des quotas agrégateur | — |

## Hors périmètre du jalon

- Partage multi-utilisateurs via CloudKit et Apple Watch (V2, voir SPEC.md B.4).

## 🧑 Actions humaines

- [ ] Contrat agrégateur en production.
- [ ] Fiche App Store.
- [ ] Validation Apple.
