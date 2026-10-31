# M3 — Synchronisation bancaire

> Branche d'intégration : `jalon/M3-synchronisation-bancaire` · Statut : 🔒 attend M2

## Objectif

Toutes les banques synchronisées, captures Apple Pay rapprochées automatiquement.

## User stories

- Je me connecte (Sign in with Apple) et j'ajoute plusieurs banques. → `feature/M3-sign-in-apple`, `feature/M3-connexion-banque`
- Mes transactions arrivent automatiquement, sans doublon. → `feature/M3-synchronisation`, `feature/M3-dedoublonnage-rapprochement`
- Ma capture Apple Pay et la ligne bancaire fusionnent en une seule transaction. → `feature/M3-dedoublonnage-rapprochement`
- Mes virements entre mes propres comptes ne comptent pas dans le budget. → `feature/M3-virements-internes`
- Je suis prévenu avant l'expiration d'un consentement. → `feature/M3-consentement`

## Critères d'acceptation

- [ ] Spike agrégateur réalisé, ADR-004 tranché et documenté. → `feature/M3-spike-agregateur`
- [ ] Backend Workers déployé : tous les endpoints de B.8, tests (vitest) sur l'auth et la normalisation. → `feature/M3-backend-workers`
- [ ] Sign in with Apple côté app, jeton dans le Keychain. → `feature/M3-sign-in-apple`
- [ ] Ajout de banque via ASWebAuthenticationSession, retour par URL scheme. → `feature/M3-connexion-banque`
- [ ] Import initial de l'historique disponible (jusqu'à 90 jours minimum). → `feature/M3-synchronisation`
- [ ] Synchronisation : à l'ouverture, manuelle (pull-to-refresh), et BGAppRefreshTask. → `feature/M3-synchronisation`
- [ ] Dédoublonnage (annexe E.3) : rejouer deux fois la même synchro ne crée aucun doublon (test). → `feature/M3-dedoublonnage-rapprochement`
- [ ] Rapprochement capture ↔ banque (annexe E.3) ; cas ambigus marqués `needsReview`. → `feature/M3-dedoublonnage-rapprochement`
- [ ] Détection des virements internes (annexe E.4). → `feature/M3-virements-internes`
- [ ] Règles appliquées aux nouvelles transactions bancaires. → `feature/M3-synchronisation`
- [ ] Notifications de consentement à J-7 et J-1 ; renouvellement en un tap. → `feature/M3-consentement`
- [ ] Soldes des comptes mis à jour. → `feature/M3-synchronisation`

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M3-spike-agregateur` | Comparatif Powens / Enable Banking, ADR-004 tranché | — |
| `feature/M3-backend-workers` | Worker TypeScript + D1, endpoints B.8, `BankDataProvider`, tests vitest | spike-agregateur |
| `feature/M3-sign-in-apple` | Sign in with Apple, session dans le Keychain | backend-workers |
| `feature/M3-connexion-banque` | ASWebAuthenticationSession, URL scheme `pecule://bank-callback` | sign-in-apple |
| `feature/M3-dedoublonnage-rapprochement` | E.3 en pure functions + tests (idempotence, score, ambiguïtés) | — |
| `feature/M3-virements-internes` | E.4 en pure function + tests, annulable | — |
| `feature/M3-synchronisation` | `BankSyncService`, import initial, déclencheurs, règles, soldes | connexion-banque, dedoublonnage-rapprochement |
| `feature/M3-consentement` | Statut du consentement, notifications J-7 / J-1, renouvellement | connexion-banque |

## Hors périmètre du jalon

- Comptes d'investissement et valorisation (M6).
- Budgets, alertes et widgets (M4).

## 🧑 Actions humaines

- [ ] Comptes agrégateur (sandbox puis production).
- [ ] `wrangler secret put` des identifiants de l'agrégateur.
- [ ] Déploiement Cloudflare.
- [ ] Connexion de ses vraies banques.
