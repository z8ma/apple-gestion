# Pécule

App iOS native de gestion des dépenses : capture instantanée des paiements Apple Pay, synchronisation bancaire multi-banques, budgets personnalisables, analyses et patrimoine léger. Données privées (appareil + iCloud), backend qui ne fait que relayer.

> Nom de code provisoire.

## Documentation

| Fichier | Contenu |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Règles permanentes du projet (stack, architecture, argent, sécurité, méthode) |
| [docs/SPEC.md](docs/SPEC.md) | Spécification produit |
| [docs/ALGORITHMES.md](docs/ALGORITHMES.md) | Règles métier précises (parsing, rapprochement, catégorisation…) |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Registre des décisions (ADR) |
| [docs/milestones/](docs/milestones/) | Un fichier par jalon : critères d'acceptation et branches |
| [docs/BRANCHES.md](docs/BRANCHES.md) | Stratégie Git et liste des branches |
| [docs/plans/](docs/plans/) | Plans de jalon soumis à validation |
| [docs/archive/SPEC_CLAUDE_CODE.md](docs/archive/SPEC_CLAUDE_CODE.md) | Spécification maître d'origine |

## Jalons

| Jalon | Branche | Thème |
|---|---|---|
| M1 | `jalon/M1-fondations` | Saisie manuelle, modèle de données, catégories, split, Face ID |
| M2 | `jalon/M2-capture-apple-pay` | Capture Apple Pay via Raccourcis, règles, catégorisation IA |
| M3 | `jalon/M3-synchronisation-bancaire` | Backend Workers, DSP2, dédoublonnage, rapprochement |
| M4 | `jalon/M4-budgets-alertes` | Budgets par catégorie ou enveloppes, alertes, widgets |
| M5 | `jalon/M5-analyses` | Flux, abonnements, prévisionnel, rapport mensuel, export |
| M6 | `jalon/M6-patrimoine` | Patrimoine net, objectifs, épargne de précaution |
| M7 | `jalon/M7-ouverture` | Onboarding, RGPD, accessibilité, App Store |

Avancement : `python3 scripts/jalons.py progress` (également publié dans le résumé de chaque run CI).
