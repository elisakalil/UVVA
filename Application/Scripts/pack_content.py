#!/usr/bin/env python3
"""Validates Application/Data and packs it into UVVA/Resources/Content for the app bundle.

Run it every time something in Data/ changes:

    python3 Application/Scripts/pack_content.py

It writes wines.json, recipes.json, learn.json, glossary.json, quiz.json and manifest.json.
manifest.version is a hash of the packed files: the app imports the content again whenever it changes
(ARCHITECTURE §2.2). The script stops with an error, and writes nothing, if the data breaks a rule.
"""
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "Data"
OUT = ROOT / "UVVA" / "Resources" / "Content"

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


def main():
    payloads = {
        "wines.json": {"wines": pack_wines()},
        "recipes.json": {"recipes": pack_recipes()},
        "learn.json": {"modules": pack_learn()},
        "glossary.json": {"terms": pack_glossary()},
        "quiz.json": {"questions": pack_quiz()},
    }
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
        "wines": len(payloads["wines.json"]["wines"]),
        "recipes": len(payloads["recipes.json"]["recipes"]),
        "modules": len(payloads["learn.json"]["modules"]),
        "lessons": sum(len(m["lessons"]) for m in payloads["learn.json"]["modules"]),
        "glossary": len(payloads["glossary.json"]["terms"]),
        "quiz": len(payloads["quiz.json"]["questions"]),
    }
    manifest = {"version": version, "counts": counts, "files": hashes}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Content {version}: " + ", ".join(f"{v} {k}" for k, v in counts.items()))


if __name__ == "__main__":
    main()
