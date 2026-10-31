# M2 — Capture Apple Pay et règles

> Branche d'intégration : `jalon/M2-capture-apple-pay` · Statut : 🔒 attend M1

## Objectif

Un paiement Apple Pay est enregistré et catégorisé en ~1 seconde.

## User stories

- Quand je paye avec Apple Pay, la dépense apparaît dans l'app sans que je l'ouvre. → `feature/M2-capture-apple-pay`
- Je reçois une notification avec des boutons de catégorie si l'app n'est pas sûre. → `feature/M2-notifications`
- Je crée des règles (conditions + actions) et l'app me propose une règle quand je corrige une catégorie. → `feature/M2-gestion-regles`
- L'app me guide pour créer l'automatisation Raccourcis. → `feature/M2-guide-raccourcis`

## Critères d'acceptation

- [ ] App Intent `CaptureTransactionIntent` (paramètres : `merchant`, `amount`, `card` en texte), `openAppWhenRun = false`, s'exécute en moins de 2 s. → `feature/M2-capture-apple-pay`
- [ ] Parsing du montant robuste (annexe E.1), couvert par au moins 15 cas de test. → `feature/M2-parsing-montant`
- [ ] Transaction créée en `source = .applePay`, `status = .pending`. → `feature/M2-capture-apple-pay`
- [ ] Moteur de règles (pure function) : priorité, conditions multiples, actions multiples ; tests. → `feature/M2-moteur-regles`
- [ ] Si aucune règle : suggestion IA (annexe E.5) ; sinon notification avec 3 catégories probables + « Autre ». → `feature/M2-categorisation`, `feature/M2-notifications`
- [ ] Les boutons de la notification catégorisent sans ouvrir l'app. → `feature/M2-notifications`
- [ ] Correction manuelle → proposition « Appliquer à toutes les transactions de [commerçant] ? » qui crée une règle (avec option rétroactive). → `feature/M2-gestion-regles`
- [ ] Écran de gestion des règles (liste, édition, activer/désactiver, réordonner, aperçu des transactions concernées). → `feature/M2-gestion-regles`
- [ ] Écran guide pas à pas de l'automatisation Raccourcis, avec test « J'ai payé, vérifier que ça marche ». → `feature/M2-guide-raccourcis`
- [ ] App Shortcut « Ajouter une dépense » utilisable par Siri. → `feature/M2-siri`

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M2-parsing-montant` | Parsing des montants E.1, pure function, ≥ 15 cas de test | — |
| `feature/M2-normalisation-commercant` | `merchantKey` E.2, pure function + tests (prérequis règles, historique, M3, M5) | — |
| `feature/M2-capture-apple-pay` | `CaptureTransactionIntent`, création de la transaction `.applePay` / `.pending` | parsing-montant, normalisation-commercant |
| `feature/M2-moteur-regles` | Moteur de règles pur : priorité, conditions, actions | normalisation-commercant |
| `feature/M2-categorisation` | Chaîne E.5 : utilisateur → règles → historique → IA on-device → `needsReview` | moteur-regles |
| `feature/M2-notifications` | Notification à 3 catégories + « Autre », actions sans ouvrir l'app | categorisation |
| `feature/M2-gestion-regles` | Écran des règles, règle créée depuis une correction (rétroactive) | moteur-regles |
| `feature/M2-guide-raccourcis` | Guide pas à pas + test « J'ai payé » | capture-apple-pay |
| `feature/M2-siri` | App Shortcut « Ajouter une dépense » | capture-apple-pay |

## Hors périmètre du jalon

- Rapprochement capture ↔ banque (M3) : les captures restent `.pending`.
- Synchronisation bancaire (M3), budgets et widgets (M4), abonnements (M5).

## 🧑 Actions humaines

- [ ] Créer l'automatisation sur iPhone réel, payer une fois, vérifier les noms de champs fournis par Raccourcis et les reporter dans DECISIONS.md.
