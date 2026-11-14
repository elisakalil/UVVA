#!/usr/bin/env python3
"""Validates Application/Data and packs it into UVVA/Resources/Content for the app bundle.

Run it every time something in Data/ changes:

    python3 Application/Scripts/pack_content.py

It writes recipes.json, learn.json, glossary.json, quiz.json and manifest.json, and the share of the catalog's wines
at each level of appellation and legal term for the "Top X%" of CELLAR-R30 (Match's QualityPrevalence+Packed.swift:
code, not a resource, so no build can leave it behind; the app uses it until it has the robot's).
manifest.version is a hash of the packed files: the app imports the content again whenever it changes
(ARCHITECTURE §2.2). The script stops with an error, and writes nothing, if the data breaks a rule.

The wines are not in the bundle: they are the seed of the public catalog (ARCHITECTURE §4.1). The robot
(Application/Robot, run by .github/workflows/catalog-robot.yml) asks for them, checked by the same rules:

    python3 Application/Scripts/pack_content.py --seed /path/to/seed.json
"""
import argparse
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "Data"
OUT = ROOT / "UVVA" / "Resources" / "Content"
PREVALENCE = ROOT / "Packages" / "Core" / "Sources" / "Match" / "QualityPrevalence+Packed.swift"

# Canonical chart order (QUIZ-R01, QUIZ-R02).
AXES = ["floral", "body", "tannin", "spice", "oak", "sweetness", "acidity", "fruit"]
WINE_TYPES = {"Red", "White", "Rosé", "Sparkling", "Fortified"}
STEP_FIELDS = {
    "concept": {"title", "body"},
    "tip": {"body"},
    "summary": {"title", "points"},
    "multipleChoice": {"prompt", "options", "answer", "explanation"},
    "trueFalse": {"prompt", "answer", "explanation"},
    "fillBlank": {"prompt", "options", "answer", "explanation"},
    "selectMultiple": {"prompt", "options", "answers", "explanation"},
    "matchPairs": {"prompt", "pairs", "explanation"},
    "ordering": {"prompt", "items", "explanation"},
}

# A note is aromas and flavours only: body, acidity, tannin and sweetness are the map's.
STRUCTURE = re.compile(r"\b(body|acidity|tannin|dry|sweet|fruit-led)\b", re.IGNORECASE)

errors = []


def fail(message):
    errors.append(message)


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def wine_key(producer, name, vintage):
    """ARCHITECTURE §2.2: slug of producer, name and vintage."""
    text = " ".join(str(p) for p in (producer, name, vintage) if p not in (None, ""))
    text = unicodedata.normalize("NFKD", text.lower())
    text = "".join(c for c in text if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]+", "-", text).strip("-")


def axis_map(entries, owner):
    """[{"floral": 6.2}, …] → {"floral": 6.2, …}, checking the eight axes and the 0…9 scale."""
    values = {}
    for entry in entries:
        values.update(entry)
    if sorted(values) != sorted(AXES):
        fail(f"{owner}: axes {sorted(values)}")
    for axis, value in values.items():
        if not isinstance(value, (int, float)) or not 0 <= value <= 9:
            fail(f"{owner}: {axis} = {value}")
    return {axis: values.get(axis, 0) for axis in AXES}


def unique(items, key, label):
    seen = set()
    for item in items:
        if item[key] in seen:
            fail(f"{label}: repeated {key} {item[key]}")
        seen.add(item[key])


def pack_wines():
    wines = []
    for wine in load(DATA / "UVVAWines.json"):
        owner = f"wine {wine['id']}"
        expected = wine_key(wine["producer"], wine["name"], wine.get("vintage"))
        if wine["id"] != expected:
            fail(f"{owner}: id should be {expected}")
        if wine["type"] not in WINE_TYPES:
            fail(f"{owner}: type {wine['type']}")
        packed = dict(wine)
        packed["map"] = axis_map(wine["map"], owner)
        if wine.get("note") and STRUCTURE.search(wine["note"]):
            fail(f"{owner}: note has structure, not only aromas: {wine['note']}")
        wines.append(packed)
    unique(wines, "id", "wines")
    return wines


def pack_recipes():
    recipes = []
    for recipe in load(DATA / "UVVARecipes.json"):
        packed = dict(recipe)
        packed["map"] = axis_map(recipe["map"], f"recipe {recipe['id']}")
        if recipe["twist"]["axis"] not in AXES:
            fail(f"recipe {recipe['id']}: twist axis {recipe['twist']['axis']}")
        recipes.append(packed)
    unique(recipes, "id", "recipes")
    return recipes


def pack_learn():
    modules = []
    for folder in ("Path", "Grapes", "Region"):
        index = load(DATA / "Learn" / folder / "index.json")
        for summary in index["modules"]:
            module = load(DATA / "Learn" / folder / summary["id"] / "module.json")
            lessons = []
            for lesson_id in module["lessons"]:
                lesson = load(DATA / "Learn" / folder / summary["id"] / f"{lesson_id}.json")
                if lesson["moduleId"] != module["id"]:
                    fail(f"lesson {lesson_id}: moduleId {lesson['moduleId']}")
                for number, step in enumerate(lesson["steps"], 1):
                    needed = STEP_FIELDS.get(step["type"])
                    if needed is None:
                        fail(f"lesson {lesson_id} step {number}: type {step['type']}")
                    elif not needed <= set(step):
                        fail(f"lesson {lesson_id} step {number}: missing {sorted(needed - set(step))}")
                lessons.append(lesson)
            if len(lessons) != module["lessonCount"]:
                fail(f"module {module['id']}: lessonCount {module['lessonCount']}, found {len(lessons)}")
            module["lessons"] = lessons
            modules.append(module)
    unique(modules, "id", "modules")
    unique([l for m in modules for l in m["lessons"]], "id", "lessons")
    return modules


def pack_glossary():
    terms = load(DATA / "Glossary" / "glossary.json")["terms"]
    unique(terms, "id", "glossary")
    return terms


def pack_quiz():
    questions = load(DATA / "Quiz" / "questions.json")["questions"]
    for axis in AXES:
        versions = sorted(q["version"] for q in questions if q["axis"] == axis)
        if versions != [1, 2, 3]:
            fail(f"quiz {axis}: versions {versions}")
    for q in questions:
        if len(q["answers"]) != 10:
            fail(f"quiz {q['axis']} v{q['version']}: {len(q['answers'])} answers")
    return questions


# CELLAR-R30, "Top X%": the categories and legal terms of CertificationKeywords.swift, folded the same way. Keep
# both in step.
TIERS = {"regional": 1, "protected": 2, "top": 3}
CATEGORY_TIERS = [
    ("denominazione di origine controllata e garantita", 3), ("docg", 3), ("d o c g", 3),
    ("denominacion de origen calificada", 3), ("doca", 3), ("d o ca", 3), ("doq", 3),
    ("premier grand cru classe", 3), ("grand cru classe", 3), ("grand cru", 3), ("premier cru", 3), ("1er cru", 3),
    ("cru classe", 3), ("grosse lage", 3),
    ("denominacao de origem controlada", 2), ("denominazione di origine controllata", 2), ("doc", 2), ("d o c", 2),
    ("denominacao de origem protegida", 2), ("dop", 2), ("denominacion de origen protegida", 2),
    ("denominacion de origen", 2), ("d o", 2), ("appellation d origine controlee", 2), ("aoc", 2),
    ("appellation d origine protegee", 2), ("aop", 2), ("american viticultural area", 2),
    ("districtus austriae controllatus", 2), ("dac", 2), ("vqa", 2), ("wine of origin", 2), ("pradikatswein", 2),
    ("qualitatswein", 2),
    ("indicazione geografica tipica", 1), ("igt", 1), ("indicacao geografica protegida", 1),
    ("indication geographique protegee", 1), ("igp", 1), ("vinho regional", 1), ("indicacao geografica", 1),
    ("vin de pays", 1), ("vino de la tierra", 1), ("landwein", 1),
]
DESIGNATIONS = ["grande reserva", "gran reserva", "riserva", "reserva", "crianza", "reserve"]
# The catalog has no medals or scores: the share of the world's wines at each level of recognition is an assumption,
# written here and in CELLAR-R30. 4: trophy, platinum or double gold at a major competition, or 95+ points;
# 3: gold at a major competition, or 92-94; 2: silver at a major competition, gold elsewhere, or 90-91; 1: any other.
RECOGNITION = {"4": 0.005, "3": 0.02, "2": 0.05, "1": 0.10}


def folded(text):
    text = unicodedata.normalize("NFKD", (text or "").lower())
    text = "".join(c for c in text if not unicodedata.combining(c))
    return " " + " ".join(re.findall(r"[a-z0-9]+", text)) + " "


def appellation_tier(wine):
    appellation = (wine.get("classification") or "").split(" · ")[0].strip()
    if not appellation or appellation.lower().endswith("% abv"):
        return 0
    text = folded(appellation)
    tier = 0
    if re.search(r" appellation( [a-z0-9]+){1,4} (controlee|protegee) ", text):
        tier = 2
    else:
        for phrase, value in sorted(CATEGORY_TIERS, key=lambda e: -len(e[0])):
            if f" {phrase} " in text:
                tier = value
                break
    if tier == 0 and wine.get("appellationInsight"):
        tier = 2
    if wine.get("hasNotableAppellation"):
        tier = 3
    return tier


def designation_strength(wine):
    text = folded(wine.get("name"))
    term = next((p for p in DESIGNATIONS if f" {p} " in text), None)
    iberian = wine.get("country") in ("Portugal", "Spain")
    if term in ("grande reserva", "gran reserva"):
        return 3 if iberian else 1
    if term == "riserva":
        return 3 if wine.get("country") == "Italy" else 1
    if term in ("reserva", "crianza"):
        return 2 if iberian else 1
    return 1 if term else 0


def quality_prevalence(wines):
    """The share of the catalog's wines at each level or above: the catalog stands for the world's wines."""
    total = len(wines)

    def shares(levels):
        return {name: round(sum(1 for level in levels if level >= value) / total, 4)
                for name, value in TIERS.items()} if total else {}

    appellation = shares([appellation_tier(w) for w in wines])
    designation = shares([designation_strength(w) for w in wines])
    designation = {"weak": designation["regional"], "aged": designation["protected"], "strong": designation["top"]}
    for name, value in list(appellation.items()) + list(designation.items()) + list(RECOGNITION.items()):
        if not 0 < value <= 1:
            fail(f"quality prevalence {name}: {value}")
    return {"wines": total, "appellation": appellation, "designation": designation, "recognition": RECOGNITION}


def prevalence_swift(prevalence):
    def literal(values):
        return "[" + ", ".join(f'"{k}": {v}' for k, v in values.items()) + "]"

    return f"""// Written by Scripts/pack_content.py from {prevalence['wines']} catalog wines. Do not edit: run the script.

public extension QualityPrevalence {{
    /// The share of the world's wines at each level or above (CELLAR-R30): appellation and legal term measured on the
    /// catalog, recognition assumed.
    static let packed = QualityPrevalence(
        appellation: {literal(prevalence['appellation'])},
        designation: {literal(prevalence['designation'])},
        recognition: {literal(prevalence['recognition'])})
}}
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=Path, help="also write the checked wines there, for the robot")
    arguments = parser.parse_args()

    wines = pack_wines()
    payloads = {
        "recipes.json": {"recipes": pack_recipes()},
        "learn.json": {"modules": pack_learn()},
        "glossary.json": {"terms": pack_glossary()},
        "quiz.json": {"questions": pack_quiz()},
    }
    prevalence = quality_prevalence(wines)
    if errors:
        print(f"{len(errors)} problem(s), nothing written:", file=sys.stderr)
        for message in errors[:50]:
            print("  " + message, file=sys.stderr)
        sys.exit(1)

    OUT.mkdir(parents=True, exist_ok=True)
    hashes = {}
    for name, payload in payloads.items():
        data = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        (OUT / name).write_bytes(data)
        hashes[name] = hashlib.sha256(data).hexdigest()
    version = hashlib.sha256("".join(hashes[n] for n in sorted(hashes)).encode()).hexdigest()[:16]
    counts = {
        "recipes": len(payloads["recipes.json"]["recipes"]),
        "modules": len(payloads["learn.json"]["modules"]),
        "lessons": sum(len(m["lessons"]) for m in payloads["learn.json"]["modules"]),
        "glossary": len(payloads["glossary.json"]["terms"]),
        "quiz": len(payloads["quiz.json"]["questions"]),
    }
    manifest = {"version": version, "counts": counts, "files": hashes}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    PREVALENCE.write_text(prevalence_swift(prevalence), encoding="utf-8")
    print(f"Content {version}: " + ", ".join(f"{v} {k}" for k, v in counts.items()))
    if arguments.seed:
        arguments.seed.parent.mkdir(parents=True, exist_ok=True)
        data = json.dumps({"wines": wines}, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        arguments.seed.write_bytes(data)
        print(f"Seed: {len(wines)} wines in {arguments.seed}")


if __name__ == "__main__":
    main()
