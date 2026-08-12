import re
import sys

TOP_RE = re.compile(r"^(Feature|Background|Scenario|Scenario Outline|Examples):")
STEP_RE = re.compile(r"^(Given|When|Then|And|But)\s")
DESC_RE = re.compile(r"^(As a|I want|So that)\s")
PHASE_RE = re.compile(r"^(Given|When|Then)\s")
PLACEHOLDER_RE = re.compile(r"<([^<>]+)>")

CHECK_NAMES = [
    "01 keywords used correctly",
    "02 scenario keywords at column 0",
    "03 steps indented",
    "04 Then or Examples in every scenario",
    "05 outline placeholders bound in Examples",
    "06 Given/When/Then ordering",
    "07 no duplicate scenario names",
]


def extract_blocks(text):
    return re.findall(r"```gherkin\s*\n(.*?)```", text, re.S)


def analyze_block(block):
    scenarios = []
    cur = None
    top_kind = None
    examples_active = False
    errors = {i: [] for i in range(len(CHECK_NAMES))}
    for lineno, raw in enumerate(block.splitlines(), 1):
        stripped = raw.strip()
        if not stripped:
            continue
        if stripped.startswith("|"):
            if cur is not None and examples_active and cur["header"] is None:
                cells = [c.strip() for c in stripped.strip("|").split("|")]
                cur["header"] = cells
            continue
        m = TOP_RE.match(stripped)
        if m:
            kind = m.group(1)
            if raw != stripped:
                errors[1].append("line %d: %r not at column 0" % (lineno, stripped))
            if kind == "Examples":
                examples_active = cur is not None
                if cur is not None:
                    cur["has_examples"] = True
                continue
            if kind in ("Scenario", "Scenario Outline"):
                name = stripped[len(m.group(0)):].strip()
                cur = {"kind": kind, "name": name, "steps": [], "header": None,
                       "has_examples": False, "line": lineno}
                scenarios.append(cur)
            else:
                cur = None
                examples_active = False
            top_kind = kind
            continue
        if STEP_RE.match(stripped):
            if top_kind is None:
                errors[0].append("line %d: step %r outside a Feature/Background/Scenario" % (lineno, stripped))
            if raw == stripped:
                errors[2].append("line %d: step %r not indented" % (lineno, stripped))
            if cur is not None:
                cur["steps"].append((STEP_RE.match(stripped).group(1), stripped))
            examples_active = False
            continue
        if DESC_RE.match(stripped):
            continue
        if stripped.startswith("#"):
            continue
        if stripped.startswith("```"):
            continue
        errors[0].append("line %d: unrecognized line %r" % (lineno, stripped))
    return scenarios, errors


def report(scenarios, errors):
    for scen in scenarios:
        if scen["header"] is not None and not scen["header"]:
            errors[4].append("%s line %d: Examples table has an empty header row" % (scen["kind"], scen["line"]))
        if scen["kind"] == "Scenario Outline":
            placeholders = set()
            for _, text in scen["steps"]:
                placeholders.update(PLACEHOLDER_RE.findall(text))
            if placeholders and scen["header"] is None:
                errors[4].append("%r line %d: has placeholders %s but no Examples table" % (
                    scen["name"], scen["line"], sorted(placeholders)))
            if scen["header"] is not None:
                missing = sorted(p for p in placeholders if p not in scen["header"])
                if missing:
                    errors[4].append("%r line %d: placeholders %s not in Examples header %s" % (
                        scen["name"], scen["line"], missing, scen["header"]))
        if not scen["has_examples"]:
            has_then = any(kind == "Then" for kind, _ in scen["steps"])
            if not has_then:
                errors[3].append("%s %r line %d: no Then step and no Examples table" % (
                    scen["kind"], scen["name"], scen["line"]))
        last_phase = None
        for kind, text in scen["steps"]:
            pm = PHASE_RE.match(text)
            if not pm:
                continue
            phase = pm.group(1)
            if phase == "Given" and last_phase in ("When", "Then"):
                errors[5].append("%s %r line %d: Given after %s" % (scen["kind"], scen["name"], scen["line"], last_phase))
            if phase == "When" and last_phase == "Then":
                errors[5].append("%s %r line %d: When after Then" % (scen["kind"], scen["name"], scen["line"]))
            if phase in ("Given", "When", "Then"):
                last_phase = phase


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: python3 validate-gherkin.py <note.md>\n")
        return 2
    path = sys.argv[1]
    with open(path, encoding="utf-8") as fh:
        blocks = extract_blocks(fh.read())
    all_scenarios = []
    results = []
    for idx, check in enumerate(CHECK_NAMES):
        results.append(dict(name=check, errors=[]))
    for block in blocks:
        scenarios, errors = analyze_block(block)
        all_scenarios.extend(scenarios)
        for idx, errs in errors.items():
            results[idx]["errors"].extend(errs)
    seen = {}
    for scen in all_scenarios:
        seen.setdefault(scen["name"], []).append(scen)
    dups = {name: scen for name, scen in seen.items() if len(scen) > 1}
    for name, scen in dups.items():
        results[6]["errors"].append("%r used by %d scenarios (first at line %d)" % (
            name, len(scen), min(s["line"] for s in scen)))
    report(all_scenarios, {i: results[i]["errors"] for i in range(len(CHECK_NAMES))})

    print("note: %s" % path)
    print("gherkin blocks: %d (%d scenario(s))" % (len(blocks), len(all_scenarios)))
    print()
    passed = 0
    for idx, result in enumerate(results):
        ok = not result["errors"]
        if ok:
            passed += 1
        print("%-42s %s" % (result["name"], "PASS" if ok else "FAIL"))
        for err in result["errors"]:
            print("    - %s" % err)
    print()
    total = len(CHECK_NAMES)
    status = "PASS" if passed == total else "FAIL"
    print("result: %s (%d/%d)" % (status, passed, total))
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())