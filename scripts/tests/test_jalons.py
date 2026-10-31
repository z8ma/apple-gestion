import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import jalons  # noqa: E402

VALID = """# M1 — Test

> Branche d'intégration : `jalon/M1-test` · Statut : test

## Objectif

Tester.

## User stories

- Je teste. → `feature/M1-a`

## Critères d'acceptation

- [x] Critère fait. → `feature/M1-a`
- [ ] Critère à faire. → `feature/M1-a`, `feature/M1-b`
- [ ] Previews. → transverse

## Fonctionnalités et branches

| Branche | Contenu | Dépend de |
|---|---|---|
| `feature/M1-a` | A | — |
| `feature/M1-b` | B | a |

## Hors périmètre du jalon

- Rien.

## 🧑 Actions humaines

- [ ] Une action humaine qui ne compte pas dans l'avancement.
"""


class JalonsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, content):
        (self.dir / name).write_text(content, encoding="utf-8")

    def test_valid_milestone_passes(self):
        self.write("M1-test.md", VALID)
        self.assertEqual(jalons.check(jalons.load(self.dir)), [])

    def test_progress_counts_only_acceptance_criteria(self):
        self.write("M1-test.md", VALID)
        ms = jalons.load(self.dir)[0]
        self.assertEqual((ms.done_count, len(ms.criteria)), (1, 3))
        self.assertIn("| M1 — Test | 1/3 |", jalons.progress([ms]))

    def test_uppercase_x_counts_as_done(self):
        self.write("M1-test.md", VALID.replace("- [ ] Previews", "- [X] Previews"))
        self.assertEqual(jalons.load(self.dir)[0].done_count, 2)

    def test_branches_lists_integration_then_features(self):
        self.write("M1-test.md", VALID)
        self.write("M2-suite.md", VALID.replace("M1", "M2").replace("jalon/M2-test", "jalon/M2-suite"))
        self.assertEqual(
            jalons.branches(jalons.load(self.dir)),
            ["jalon/M1-test", "jalon/M2-suite", "feature/M1-a", "feature/M1-b", "feature/M2-a", "feature/M2-b"],
        )

    def test_milestones_sorted_numerically(self):
        self.write("M10-dix.md", VALID.replace("M1", "M10").replace("jalon/M10-test", "jalon/M10-dix"))
        self.write("M2-deux.md", VALID.replace("M1", "M2").replace("jalon/M2-test", "jalon/M2-deux"))
        self.assertEqual([m.code for m in jalons.load(self.dir)], ["M2", "M10"])

    def test_missing_section_is_reported(self):
        self.write("M1-test.md", VALID.replace("## Hors périmètre du jalon", "## Autre"))
        self.assertTrue(any("Hors périmètre" in e for e in jalons.check(jalons.load(self.dir))))

    def test_criterion_without_branch_is_reported(self):
        self.write("M1-test.md", VALID.replace("- [ ] Previews. → transverse", "- [ ] Previews."))
        self.assertTrue(any("sans branche" in e for e in jalons.check(jalons.load(self.dir))))

    def test_referenced_branch_missing_from_table_is_reported(self):
        self.write("M1-test.md", VALID.replace("| `feature/M1-b` | B | a |\n", ""))
        self.assertTrue(any("feature/M1-b" in e for e in jalons.check(jalons.load(self.dir))))

    def test_wrong_milestone_prefix_is_reported(self):
        self.write("M1-test.md", VALID.replace("| `feature/M1-b`", "| `feature/M2-b`"))
        self.assertTrue(any("préfixe" in e for e in jalons.check(jalons.load(self.dir))))

    def test_wrong_integration_branch_is_reported(self):
        self.write("M1-test.md", VALID.replace("jalon/M1-test", "jalon/M1-autre"))
        self.assertTrue(any("intégration" in e for e in jalons.check(jalons.load(self.dir))))

    def test_duplicate_branch_across_milestones_is_reported(self):
        self.write("M1-test.md", VALID)
        other = VALID.replace("jalon/M1-test", "jalon/M1-bis")
        self.write("M1-bis.md", other)
        self.assertTrue(any("déjà déclarée" in e for e in jalons.check(jalons.load(self.dir))))

    def test_bad_filename_is_rejected(self):
        self.write("M1_Mauvais.md", VALID)
        with self.assertRaises(ValueError):
            jalons.load(self.dir)

    def test_empty_directory_is_an_error(self):
        self.assertEqual(jalons.check([]), ["aucun fichier de jalon trouvé"])

    def test_real_repository_milestones_are_consistent(self):
        real = Path(__file__).resolve().parents[2] / "docs" / "milestones"
        self.assertEqual(jalons.check(jalons.load(real)), [])


if __name__ == "__main__":
    unittest.main()
