# Stratégie de branches

```
main ─────────────────────────────────────────────●──────────────●── …
  │                                              ↑ M1 terminé   ↑ M2 terminé
  └─ jalon/M1-fondations ──●────●────●───────────┘
        ├─ feature/M1-calcul-periode ─┘    │
        ├─ feature/M1-modele-donnees ──────┘
        └─ …
```

| Type | Modèle | Part de | Merge dans | Quand |
|---|---|---|---|---|
| Stable | `main` | — | — | Ne reçoit que des jalons terminés |
| Jalon | `jalon/Mx-slug` | `main` | `main` (PR) | Definition of Done du jalon remplie |
| Fonctionnalité | `feature/Mx-slug` | `jalon/Mx-…` | `jalon/Mx-…` (PR) | Critères concernés cochés, CI verte |
| Outillage | `chore/…` | `main` | `main` (PR) | Infra, CI, docs transverses |

Règles :
- Avant de commencer une feature, la remettre à jour depuis son jalon : `git merge jalon/Mx-…` (ou rebase si personne d'autre ne l'utilise).
- Quand un jalon démarre, le remettre à jour depuis `main`.
- Les jalons s'enchaînent dans l'ordre M1 → M7 ; une feature d'un jalon futur peut démarrer plus tôt seulement si elle est pure (Core/) et sans dépendance.
- Commits en français : `feat(M2): capture Apple Pay via App Intent`, `test(M1): …`, `fix(M3): …`, `docs: …`, `ci: …`.
- Une PR coche les critères d'acceptation qu'elle remplit dans `docs/milestones/` : la CI publie l'avancement dans le résumé de chaque run.

## Automatisation

- `python3 scripts/jalons.py check` : vérifie la structure des jalons (sections, branches référencées, préfixes).
- `python3 scripts/jalons.py progress` : tableau d'avancement des critères.
- `python3 scripts/jalons.py branches` : liste des branches attendues, générée depuis les fichiers de jalons (source de vérité).
- CI (`.github/workflows/ci.yml`) : jalons + tests de l'outil, garde-fou anti-secrets ; puis, dès qu'ils existent : packages Swift (`swift test`, macOS), app iOS (`xcodebuild test`, warnings = erreurs), backend (`npm test`).

## Liste des branches

- `jalon/M1-fondations`
- `jalon/M2-capture-apple-pay`
- `jalon/M3-synchronisation-bancaire`
- `jalon/M4-budgets-alertes`
- `jalon/M5-analyses`
- `jalon/M6-patrimoine`
- `jalon/M7-ouverture`
- `feature/M1-projet-xcode`
- `feature/M1-calcul-periode`
- `feature/M1-modele-donnees`
- `feature/M1-transactions`
- `feature/M1-categories-tags`
- `feature/M1-split-remboursement`
- `feature/M1-actions-groupees`
- `feature/M1-reglages`
- `feature/M1-verrouillage`
- `feature/M1-donnees-demo`
- `feature/M2-parsing-montant`
- `feature/M2-normalisation-commercant`
- `feature/M2-capture-apple-pay`
- `feature/M2-moteur-regles`
- `feature/M2-categorisation`
- `feature/M2-notifications`
- `feature/M2-gestion-regles`
- `feature/M2-guide-raccourcis`
- `feature/M2-siri`
- `feature/M3-spike-agregateur`
- `feature/M3-backend-workers`
- `feature/M3-sign-in-apple`
- `feature/M3-connexion-banque`
- `feature/M3-dedoublonnage-rapprochement`
- `feature/M3-virements-internes`
- `feature/M3-synchronisation`
- `feature/M3-consentement`
- `feature/M4-calculs-budget`
- `feature/M4-cibles-categories`
- `feature/M4-enveloppes`
- `feature/M4-mode-budget`
- `feature/M4-alertes`
- `feature/M4-widgets`
- `feature/M5-flux-sankey`
- `feature/M5-repartition`
- `feature/M5-comparaisons`
- `feature/M5-analyse-tags-nature`
- `feature/M5-abonnements`
- `feature/M5-previsionnel`
- `feature/M5-rapport-mensuel`
- `feature/M5-recherche-avancee`
- `feature/M5-ticket-ocr`
- `feature/M5-export`
- `feature/M6-patrimoine-net`
- `feature/M6-actifs-manuels`
- `feature/M6-comptes-investissement`
- `feature/M6-snapshots-evolution`
- `feature/M6-objectifs`
- `feature/M6-epargne-precaution`
- `feature/M6-rapport-patrimoine`
- `feature/M7-onboarding`
- `feature/M7-suppression-donnees`
- `feature/M7-confidentialite`
- `feature/M7-accessibilite`
- `feature/M7-monetisation`
- `feature/M7-monitoring`
