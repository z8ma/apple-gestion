#!/usr/bin/env python3
"""Outil de suivi des jalons de Pécule (bibliothèque standard uniquement).

Commandes :
  check     Vérifie la structure et la cohérence de docs/milestones/*.md.
  progress  Affiche l'avancement des critères d'acceptation (tableau Markdown).
  branches  Liste les branches attendues (jalon/… puis feature/…), une par ligne.
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

REQUIRED_SECTIONS = (
    "Objectif",
    "User stories",
    "Critères d'acceptation",
    "Fonctionnalités et branches",
    "Hors périmètre du jalon",
    "🧑 Actions humaines",
)
CRITERIA_SECTION = "Critères d'acceptation"
FILE_RE = re.compile(r"^(M\d+)-([a-z0-9-]+)\.md$")
CHECKBOX_RE = re.compile(r"^- \[( |x|X)\] (.+)$")
BRANCH_RE = re.compile(r"`(feature/(M\d+)-[a-z0-9-]+)`")
TABLE_BRANCH_RE = re.compile(r"^\|\s*`(feature/[^`]+)`\s*\|")
INTEGRATION_RE = re.compile(r"Branche d'intégration : `(jalon/[^`]+)`")


@dataclass
class Criterion:
    text: str
    done: bool
    branches: list[str]
    transverse: bool


@dataclass
class Milestone:
    code: str
    slug: str
    title: str
    path: Path
    integration_branch: str | None
    sections: dict[str, list[str]] = field(default_factory=dict)
    criteria: list[Criterion] = field(default_factory=list)
    table_branches: list[str] = field(default_factory=list)

    @property
    def expected_integration_branch(self) -> str:
        return f"jalon/{self.code}-{self.slug}"

    @property
    def done_count(self) -> int:
        return sum(c.done for c in self.criteria)


def parse_milestone(path: Path) -> Milestone:
    m = FILE_RE.match(path.name)
    if not m:
        raise ValueError(f"{path.name} : nom de fichier attendu « Mx-slug.md »")
    lines = path.read_text(encoding="utf-8").splitlines()
    title = next((l[2:].strip() for l in lines if l.startswith("# ")), "")
    integration = None
    for l in lines:
        found = INTEGRATION_RE.search(l)
        if found:
            integration = found.group(1)
            break
    ms = Milestone(m.group(1), m.group(2), title, path, integration)
    current = None
    for line in lines:
        if line.startswith("## "):
            current = line[3:].strip()
            ms.sections[current] = []
        elif current is not None:
            ms.sections[current].append(line)
    for line in ms.sections.get(CRITERIA_SECTION, []):
        cb = CHECKBOX_RE.match(line)
        if cb:
            text = cb.group(2)
            ms.criteria.append(Criterion(
                text=text,
                done=cb.group(1) != " ",
                branches=[b for b, _ in BRANCH_RE.findall(text)],
                transverse=text.rstrip().endswith("→ transverse"),
            ))
    for line in ms.sections.get("Fonctionnalités et branches", []):
        tb = TABLE_BRANCH_RE.match(line)
        if tb:
            ms.table_branches.append(tb.group(1))
    return ms


def load(directory: Path) -> list[Milestone]:
    files = sorted(directory.glob("M*.md"), key=lambda p: int(re.match(r"M(\d+)", p.name).group(1)))
    return [parse_milestone(p) for p in files]


def check(milestones: list[Milestone]) -> list[str]:
    errors: list[str] = []
    if not milestones:
        return ["aucun fichier de jalon trouvé"]
    seen: set[str] = set()
    for ms in milestones:
        where = ms.path.name
        for section in REQUIRED_SECTIONS:
            if section not in ms.sections:
                errors.append(f"{where} : section manquante « ## {section} »")
        if ms.integration_branch != ms.expected_integration_branch:
            errors.append(f"{where} : branche d'intégration attendue `{ms.expected_integration_branch}`, trouvée `{ms.integration_branch}`")
        if not ms.criteria:
            errors.append(f"{where} : aucun critère d'acceptation (cases à cocher)")
        table = set(ms.table_branches)
        if len(table) != len(ms.table_branches):
            errors.append(f"{where} : branche en double dans le tableau")
        for b in ms.table_branches:
            if not b.startswith(f"feature/{ms.code}-"):
                errors.append(f"{where} : `{b}` n'a pas le préfixe feature/{ms.code}-")
            if b in seen:
                errors.append(f"{where} : `{b}` déjà déclarée dans un autre jalon")
            seen.add(b)
        referenced: set[str] = set()
        for line in ms.sections.get("User stories", []) + ms.sections.get(CRITERIA_SECTION, []):
            referenced.update(b for b, _ in BRANCH_RE.findall(line))
        for c in ms.criteria:
            if not c.branches and not c.transverse:
                errors.append(f"{where} : critère sans branche ni « → transverse » : {c.text[:60]}…")
        for b in sorted(referenced - table):
            errors.append(f"{where} : `{b}` référencée mais absente du tableau des branches")
    return errors


def bar(done: int, total: int, width: int = 10) -> str:
    filled = round(width * done / total) if total else 0
    return "█" * filled + "░" * (width - filled)


def progress(milestones: list[Milestone]) -> str:
    out = ["## Avancement des jalons", "", "| Jalon | Critères | Avancement |", "|---|---|---|"]
    total_done = total = 0
    for ms in milestones:
        n = len(ms.criteria)
        total_done += ms.done_count
        total += n
        pct = round(100 * ms.done_count / n) if n else 0
        out.append(f"| {ms.title} | {ms.done_count}/{n} | {bar(ms.done_count, n)} {pct} % |")
    pct = round(100 * total_done / total) if total else 0
    out.append(f"| **Total** | **{total_done}/{total}** | {bar(total_done, total)} {pct} % |")
    return "\n".join(out) + "\n"


def branches(milestones: list[Milestone]) -> list[str]:
    return [ms.expected_integration_branch for ms in milestones] + [b for ms in milestones for b in ms.table_branches]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=("check", "progress", "branches"))
    parser.add_argument("--dir", type=Path, default=Path(__file__).resolve().parent.parent / "docs" / "milestones")
    args = parser.parse_args(argv)
    try:
        milestones = load(args.dir)
    except ValueError as exc:
        print(f"erreur : {exc}", file=sys.stderr)
        return 1
    if args.command == "check":
        errors = check(milestones)
        for e in errors:
            print(f"✗ {e}", file=sys.stderr)
        if errors:
            return 1
        print(f"✓ {len(milestones)} jalons, {sum(len(m.table_branches) for m in milestones)} fonctionnalités : structure cohérente")
    elif args.command == "progress":
        print(progress(milestones), end="")
    else:
        print("\n".join(branches(milestones)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
