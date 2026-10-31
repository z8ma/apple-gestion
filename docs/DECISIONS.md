# Décisions d'architecture

## ADR-001 — iOS 26 minimum, Swift 6 strict
Accès à Foundation Models (catégorisation IA on-device) et aux dernières API SwiftData.
Public cible : utilisateurs d'iPhone récents.

## ADR-002 — Données locales + CloudKit, backend sans stockage de transactions
Confidentialité, coût quasi nul, conformité RGPD simplifiée. Le backend ne fait que relayer.

## ADR-003 — Capture Apple Pay via automatisation Raccourcis « Transaction »
FinanceKit indisponible en France. L'automatisation est créée par l'utilisateur,
l'app fournit l'App Intent et un guide. Rapprochement ultérieur avec la banque.

## ADR-004 — Agrégateur bancaire : À TRANCHER au début de M3 (spike)
Candidats :
- Powens (français, utilisé par Finary, bonne couverture des banques FR,
  couvre potentiellement les comptes d'investissement → utile pour M6).
- Enable Banking (DSP2 comptes de paiement, offre d'entrée accessible).
GoCardless Bank Account Data : nouvelles inscriptions fermées depuis juillet 2025, écarté.
Critères : couverture des banques de l'utilisateur, prix pour 1 puis 1 000 utilisateurs,
support des comptes épargne/investissement, qualité des libellés, sandbox.
🧑 Action humaine : créer les comptes sandbox et fournir les identifiants via wrangler secret.

## ADR-005 — Backend Cloudflare Workers + D1 en TypeScript
Serverless, gratuit à petite échelle, déploiement simple via wrangler.

## ADR-006 — Montants en Decimal, signe négatif pour les sorties
