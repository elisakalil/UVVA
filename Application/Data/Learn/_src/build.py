#!/usr/bin/env python3
"""Expand compact module sources (src/<kind>/<moduleId>.json) into
Data/Learn/<Kind>/<moduleId>/{module.json, <lessonId>.json} and validate
the writing rules of Documentation/Lesson/LESSON.md.

Source DSL
  module: {id, kind, order, title, description, complexity, ...meta, "L": [lesson]}
  lesson: [title, subtitle, [3 objectives], [6 steps]]
  steps:  ["c", title, body, highlight?]   concept
          ["t", body]                       tip
          ["mc", prompt, [4], answerIdx, expl]
          ["tf", prompt, bool, expl]
          ["fb", prompt, [4], answerIdx, expl]   (answer written as the word)
          ["sm", prompt, [4-5], [idx], expl]
          ["or", prompt, [items in right order], expl]
          ["mp", prompt, [[left, right]...], expl?]
          ["s", [points]]
"""
import json, os, re, sys, glob

SCRATCH = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(SCRATCH, "src")
OUT = "/Users/elisaelias/Documents/UVVA/Data/Learn"
KIND_DIR = {"path": "Path", "grape": "Grapes", "region": "Region"}
LESSONS_BY_C = {"path": {"A": 8, "B": 7, "C": 6, "D": 5},
                "grape": {"A": 7, "B": 6, "C": 5, "D": 4},
                "region": {"A": 7, "B": 6, "C": 5, "D": 4}}
QUESTIONS = {"mc", "tf", "fb", "sm", "or", "mp"}
TYPE = {"c": "concept", "t": "tip", "mc": "multipleChoice", "tf": "trueFalse",
        "fb": "fillBlank", "sm": "selectMultiple", "or": "ordering",
        "mp": "matchPairs", "s": "summary"}
FORBIDDEN = [("—", "em dash"), ("–", "en dash"), ("!", "exclamation"),
             ("WSET", "WSET"), ("Great job", "empty enthusiasm"),
             ("Let's dive", "empty enthusiasm"), ("Fun fact", "empty enthusiasm"),
             ("Amazing", "empty enthusiasm")]
RANGE = re.compile(r"\d\s*[-–—]\s*\d")
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿]")


def texts(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, list):
        for x in obj:
            yield from texts(x)
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from texts(v)


def expand_step(s, err):
    k = s[0]
    if k == "c":
        d = {"type": "concept", "title": s[1], "body": s[2]}
        if len(s) > 3 and s[3]:
            d["highlight"] = s[3]
        if len(s[2].split()) > 95:
            err(f"concept body {len(s[2].split())} words")
        return d
    if k == "t":
        return {"type": "tip", "body": s[1]}
    if k == "mc":
        if len(set(s[2])) != len(s[2]):
            err("duplicate options")
        if len(s[2]) != 4 or not 0 <= s[3] < 4:
            err("mc needs 4 options and valid answer")
        return {"type": "multipleChoice", "prompt": s[1], "options": s[2], "answer": s[3], "explanation": s[4]}
    if k == "tf":
        if not isinstance(s[2], bool):
            err("tf answer must be bool")
        return {"type": "trueFalse", "prompt": s[1], "answer": s[2], "explanation": s[3]}
    if k == "fb":
        if s[1].count("____") != 1 or len(s[2]) != 4 or not 0 <= s[3] < 4:
            err("fb needs one ____, 4 options, valid answer")
        return {"type": "fillBlank", "prompt": s[1], "options": s[2], "answer": s[2][s[3]], "explanation": s[4]}
    if k == "sm":
        if len(set(s[2])) != len(s[2]):
            err("duplicate options")
        if not 4 <= len(s[2]) <= 5 or not 2 <= len(s[3]) <= 3 or any(not 0 <= i < len(s[2]) for i in s[3]):
            err("sm needs 4-5 options and 2-3 answers")
        return {"type": "selectMultiple", "prompt": s[1], "options": s[2], "answers": sorted(s[3]), "explanation": s[4]}
    if k == "or":
        if not 4 <= len(s[2]) <= 6:
            err("ordering needs 4-6 items")
        return {"type": "ordering", "prompt": s[1], "items": s[2], "explanation": s[3]}
    if k == "mp":
        if not 4 <= len(s[2]) <= 5:
            err("matchPairs needs 4-5 pairs")
        if len({l for l, _ in s[2]}) != len(s[2]) or len({r for _, r in s[2]}) != len(s[2]):
            err("matchPairs sides must be unique")
        for l, r in s[2]:
            if len(r.split()) > 5:
                err(f"pair right side too long: {r}")
        d = {"type": "matchPairs", "prompt": s[1], "pairs": [{"left": l, "right": r} for l, r in s[2]]}
        if len(s) > 3 and s[3]:
            d["explanation"] = s[3]
        return d
    if k == "s":
        return {"type": "summary", "title": "What you learned", "points": s[1]}
    err(f"unknown step {k}")
    return {}


def build(path, write=True):
    errors = []
    m = json.load(open(path))
    mid, kind = m["id"], m["kind"]
    lessons_src = m.pop("L")
    expected = LESSONS_BY_C[kind][m["complexity"]]
    if len(lessons_src) != expected:
        errors.append(f"{mid}: {len(lessons_src)} lessons, expected {expected}")
    lessons = []
    for i, L in enumerate(lessons_src, 1):
        lid = f"{mid}-l{i:02d}"
        review = i == len(lessons_src)

        def err(msg, lid=lid):
            errors.append(f"{lid}: {msg}")
        title, subtitle, objectives, steps = L
        if len(objectives) != 3:
            err("needs 3 objectives")
        if len(steps) != 6:
            err(f"{len(steps)} steps")
        kinds = [s[0] for s in steps]
        if review:
            if title != "Module review":
                err("last lesson must be Module review")
            if any(k not in QUESTIONS for k in kinds[:5]) or kinds[5:] != ["s"]:
                err(f"review shape {kinds}")
            if len(set(kinds[:5])) < 3:
                err("review needs 3+ question types")
            if not 3 <= len(steps[5][1]) <= 4:
                err("review summary needs 3-4 points")
        else:
            if len(kinds) == 6 and not (kinds[0] == "c" and kinds[1] == "c" and kinds[2] in QUESTIONS
                                        and kinds[3] in ("c", "t") and kinds[4] in QUESTIONS and kinds[5] == "s"):
                err(f"lesson shape {kinds}")
            if len(kinds) == 6 and kinds[2] == kinds[4]:
                err("questions 3 and 5 must differ")
            if len(steps) == 6 and len(steps[5][1]) != 3:
                err("summary needs 3 points")
        for s in steps:
            if s[0] in QUESTIONS and s[0] != "mp":
                ex = s[-1]
                if re.match(r"\s*(Correct|Wrong)", ex):
                    err("explanation starts with Correct/Wrong")
        st = [expand_step(s, err) for s in steps]
        lesson = {"id": lid, "moduleId": mid, "order": i, "title": title, "subtitle": subtitle,
                  "xp": 15, "estimatedMinutes": 3, "isReview": review,
                  "objectives": objectives, "steps": st}
        for t in texts(lesson):
            for bad, name in FORBIDDEN:
                if bad in t:
                    err(f"forbidden {name}: {t[:70]}")
            if RANGE.search(t):
                err(f"dash range: {t[:70]}")
            if EMOJI.search(t):
                err(f"emoji: {t[:70]}")
        lessons.append(lesson)
    for t in texts(m):
        for bad, name in FORBIDDEN:
            if bad in t:
                errors.append(f"{mid}: forbidden {name} in module meta")
    m["lessonCount"] = len(lessons)
    m["xp"] = 15 * len(lessons)
    m["estimatedMinutes"] = 3 * len(lessons)
    m["lessons"] = [l["id"] for l in lessons]
    if write and not errors:
        d = os.path.join(OUT, KIND_DIR[kind], mid)
        os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, "*.json")):
            os.remove(f)
        json.dump(m, open(os.path.join(d, "module.json"), "w"), ensure_ascii=False, indent=2)
        for l in lessons:
            json.dump(l, open(os.path.join(d, l["id"] + ".json"), "w"), ensure_ascii=False, indent=2)
    return m, errors


def main():
    targets = sys.argv[1:] or sorted(glob.glob(os.path.join(SRC, "*", "*.json")))
    all_err = []
    for p in targets:
        try:
            _, e = build(p)
        except Exception as ex:
            e = [f"{p}: {ex!r}"]
        all_err += e
        print(("FAIL " if e else "ok   ") + os.path.basename(p))
    # indexes per kind
    for kind, kd in KIND_DIR.items():
        mods = []
        for f in glob.glob(os.path.join(OUT, kd, "*", "module.json")):
            m = json.load(open(f))
            mods.append({k: m[k] for k in m if k != "lessons"})
        if mods:
            mods.sort(key=lambda x: x["order"])
            json.dump({"kind": kind, "modules": mods}, open(os.path.join(OUT, kd, "index.json"), "w"),
                      ensure_ascii=False, indent=2)
    for e in all_err:
        print("  ", e)
    print(f"{len(all_err)} errors")


if __name__ == "__main__":
    main()
