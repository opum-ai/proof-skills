"""Generate `claude plugin eval` cases from the skill-creator eval data in this directory.

    python3 plugins/proof-skills/evals/make_cases.py      # rewrites cases/ from scratch

Sources (the single source of truth for both harnesses):
  triggers/make_trigger_sets.py  -> cases/trigger/<skill>/<nn>/   (80 cases, cheap)
  evals.json + fixtures/         -> cases/bughunt/<name>/         (5 cases, 20-40 min each)

Both kinds need a starting repo, so every case has a scaffold.sh and must be run with
--scaffold. Trigger cases get the stub monorepo from triggers/make_trigger_root.py; bug-hunt
cases get a copy of their fixture, and scaffold_env.sh clones your toolchains into the run's
throwaway $HOME. See docs/runbooks/run-plugin-evals.md.
"""
import json
import pathlib
import re
import shutil
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "triggers"))
from make_trigger_sets import SETS  # noqa: E402

SKILLS = ["formal-verify", "tlaplus-model", "lean-model", "proof-simplify"]
BUGHUNT_SKILL = {"orders-simplify-belt-and-braces": "proof-simplify"}  # others: formal-verify


def skill_re(name: str) -> str:
    # Skill tool input is {"skill": "proof-skills:<name>", ...}; the namespace is optional.
    return r'"skill"\s*:\s*"(?:[\w-]+:)?' + name + '"'


def write(path: pathlib.Path, text: str, mode: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    if mode:
        path.chmod(mode)


def yq(s: str) -> str:
    """Single-quoted YAML scalar."""
    return "'" + s.replace("'", "''") + "'"


def tool_grader(name: str, weight: int, positive: bool, note: str) -> str:
    bounds = "" if positive else "min: 0\nmax: 0\n"
    return f"---\ntype: tool_used\ntool: Skill\ninput_match: {yq(skill_re(name))}\n{bounds}weight: {weight}\n---\n\n{note}\n"


def trigger_cases(out: pathlib.Path) -> int:
    n = 0
    for skill, items in SETS.items():
        for i, (query, positive) in enumerate(items, 1):
            d = out / "trigger" / skill / f"{i:02d}-{'pos' if positive else 'neg'}"
            name = f"trigger-{skill}-{i:02d}"
            write(d / "case.yaml", f'schema_version: "1.1"\nname: {name}\ncontext:\n  scaffold_script: scaffold.sh\n')
            write(d / "prompt.md", (
                "---\n"
                f"description: {yq(('Should trigger ' if positive else 'Near miss: should NOT trigger ') + skill)}\n"
                f"tags: [trigger, {skill}, {'positive' if positive else 'negative'}]\n"
                "runs: 2\nmax_turns: 6\ntimeout_seconds: 150\n"
                "allowed_tools: [Read, Glob, Grep, Skill]\n"
                "---\n\n" + query + "\n"))
            write(d / "scaffold.sh", (
                "#!/usr/bin/env bash\n"
                "# Stub monorepo so queries that name files (controllers/quota.go, ...) are answerable.\n"
                'exec python3 "$(dirname "$0")/../../../../triggers/make_trigger_root.py" --no-claude-dir . >/dev/null\n'),
                0o755)
            if positive:
                write(d / "graders" / f"fired-{skill}.md",
                      tool_grader(skill, 2, True, f"The {skill} skill was loaded."))
                any_skill = "(?:" + "|".join(SKILLS) + ")"
                write(d / "graders" / "fired-any-proof-skill.md",
                      tool_grader(any_skill, 1, True, "Some proof-skills skill was loaded (partial credit for routing through a sibling)."))
            else:
                write(d / "graders" / f"not-fired-{skill}.md",
                      tool_grader(skill, 1, False, f"The {skill} skill was NOT loaded for this near miss."))
            n += 1
    return n


BUGHUNT_SYSTEM = (
    "This is an offline evaluation run. There is no Artifact tool and no user to ask: make "
    "reasonable choices yourself. Write any report to formal/reports/<concern>.html in the "
    "repo, and end with a final message that summarizes findings, fixes, what was verified "
    "(with bounds), and what was not. git does not work in this sandbox; that is expected."
)


def bughunt_cases(out: pathlib.Path) -> int:
    evals = json.loads((HERE / "evals.json").read_text())["evals"]
    for e in evals:
        d = out / "bughunt" / e["name"]
        skill = BUGHUNT_SKILL.get(e["name"], "formal-verify")
        write(d / "case.yaml", (
            'schema_version: "1.1"\n'
            f"name: bughunt-{e['name']}\n"
            f"expected_outcome: {yq(e['expected_output'])}\n"
            "context:\n  scaffold_script: scaffold.sh\n"))
        write(d / "prompt.md", (
            "---\n"
            f"description: {yq('Bug hunt on the ' + e['fixture'] + ' fixture')}\n"
            f"tags: [bughunt, {skill}]\n"
            "runs: 1\nmax_turns: 200\ntimeout_seconds: 3600\n"
            "allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]\n"
            f"append_system_prompt: {yq(BUGHUNT_SYSTEM)}\n"
            "---\n\n" + e["prompt"] + "\n"))
        write(d / "scaffold.sh", f"""#!/usr/bin/env bash
# Copy the fixture repo into the run's workspace and commit it as the baseline, then make
# your toolchains usable inside the sandboxed run (see scaffold_env.sh).
set -euo pipefail
FIX="$(cd "$(dirname "$0")/../../../fixtures/{e['fixture']}" && pwd)"
cp -R "$FIX"/. .
git init -q && git add -A && git -c user.email=eval@example.invalid -c user.name=eval commit -qm "fixture: {e['fixture']}"
source "$(dirname "$0")/../../../scaffold_env.sh"
""", 0o755)
        gd = d / "graders"
        for i, a in enumerate(e["assertions"], 1):
            slug = re.sub(r"[^a-z0-9]+", "-", a.lower()).strip("-")[:48].rstrip("-")
            # focus: last_message. A trace judge sees only the first and last 12 messages
            # of a 500-line run and missed facts the final report states plainly.
            write(gd / f"a{i:02d}-{slug}.md", (
                "---\ntype: llm\nfocus: last_message\n---\n\n"
                "You are grading the final report of an agent that investigated a codebase. "
                "PASS if the report states or shows the following, with specifics (names, "
                "files, numbers, commands or results) rather than a vague claim:\n\n"
                f"{a}\n\nFAIL if it is absent, only vaguely gestured at, or contradicted.\n"))
        write(gd / "z1-findings-json.md", "---\ntype: file_exists\npath: formal/findings.json\n---\n\nThe run wrote formal/findings.json.\n")
        write(gd / "z2-report-html.md", "---\ntype: file_exists\npath: 'formal/reports/*.html'\n---\n\nThe run wrote an HTML report.\n")
        write(gd / f"z3-fired-{skill}.md", tool_grader(skill, 1, True, f"The {skill} skill was loaded (with-arm indicator)."))
    return len(evals)


def main() -> None:
    out = HERE / "cases"
    if out.exists():
        shutil.rmtree(out)
    t = trigger_cases(out)
    b = bughunt_cases(out)
    print(f"wrote {t} trigger cases and {b} bug-hunt cases under {out}")


if __name__ == "__main__":
    main()
