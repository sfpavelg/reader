import json
import re
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "dictionary"
OUT_DIR = ROOT / "assets" / "tetris_dictionary"

CYR_UPPER_RE = re.compile(r"^[А-ЯЁ]+$")


TRANSLIT = {
    "А": "a",
    "Б": "b",
    "В": "v",
    "Г": "g",
    "Д": "d",
    "Е": "e",
    "Ё": "yo",
    "Ж": "zh",
    "З": "z",
    "И": "i",
    "Й": "y",
    "К": "k",
    "Л": "l",
    "М": "m",
    "Н": "n",
    "О": "o",
    "П": "p",
    "Р": "r",
    "С": "s",
    "Т": "t",
    "У": "u",
    "Ф": "f",
    "Х": "h",
    "Ц": "ts",
    "Ч": "ch",
    "Ш": "sh",
    "Щ": "sch",
    "Ъ": "",
    "Ы": "y",
    "Ь": "",
    "Э": "e",
    "Ю": "yu",
    "Я": "ya",
}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def translit(text: str) -> str:
    return "".join(TRANSLIT.get(ch, "") for ch in text)


def normalize_text(text: str) -> str:
    return (
        text.strip()
        .upper()
        .replace(" ", "")
        .replace("-", "")
        .replace("'", "")
        .replace("`", "")
    )


def split_bigrams(text: str) -> list[str]:
    return [text[i : i + 2] for i in range(0, len(text), 2)]


def clamp_difficulty(value: int | None, parts_count: int) -> int:
    if isinstance(value, int):
        return min(3, max(1, value))
    if parts_count <= 2:
        return 1
    if parts_count <= 3:
        return 2
    return 3


def infer_category(tags: list[str] | None) -> str:
    if not tags:
        return "other"
    known = {
        "family",
        "people",
        "animals",
        "birds",
        "fish",
        "insects",
        "plants",
        "flowers",
        "trees",
        "vegetables",
        "fruits",
        "berries",
        "food",
        "drinks",
        "home",
        "furniture",
        "clothes",
        "school",
        "toys",
        "transport",
        "nature",
        "weather",
        "seasons",
        "space",
        "body",
        "colors",
        "numbers",
        "countries",
        "cities",
        "professions",
        "holidays",
        "fairy_tale",
        "other",
    }
    for tag in tags:
        tag_norm = tag.lower()
        if tag_norm in known:
            return tag_norm
    return "other"


def collect_source_entries() -> list[dict]:
    entries = []

    level2 = load_json(SRC_DIR / "level_2.json")
    for item in level2.get("entries", []):
        entries.append(
            {
                "source": "level_2",
                "id": item.get("id"),
                "text": item.get("text", ""),
                "difficulty": item.get("difficulty"),
                "tags": item.get("tags", []),
                "syllables": item.get("syllables"),
            }
        )

    schulte = load_json(SRC_DIR / "schulte_grid_words.json")
    for item in schulte.get("entries", []):
        entries.append(
            {
                "source": "schulte_grid_words",
                "id": item.get("id"),
                "text": item.get("text", ""),
                "difficulty": item.get("difficulty"),
                "tags": item.get("tags", []),
                "syllables": item.get("syllables"),
            }
        )

    return entries


def derive_parts(entry_text: str, syllables: list[str] | None) -> list[str] | None:
    text = normalize_text(entry_text)
    if not text or not CYR_UPPER_RE.match(text):
        return None

    if syllables and all(isinstance(s, str) for s in syllables):
        syl = [normalize_text(s) for s in syllables]
        if syl and all(len(s) == 2 and CYR_UPPER_RE.match(s) for s in syl):
            if "".join(syl) == text:
                return syl

    if len(text) % 2 != 0:
        return None

    parts = split_bigrams(text)
    if all(len(p) == 2 and CYR_UPPER_RE.match(p) for p in parts):
        return parts
    return None


def build():
    source_entries = collect_source_entries()
    words = []
    seen_texts = set()
    rejected = defaultdict(int)
    block_counts = Counter()

    for entry in source_entries:
        text = normalize_text(entry["text"])
        parts = derive_parts(entry["text"], entry.get("syllables"))
        if not text or not CYR_UPPER_RE.match(text):
            rejected["non_cyrillic_or_empty"] += 1
            continue
        if parts is None:
            rejected["cannot_decompose_strict_2"] += 1
            continue
        if text in seen_texts:
            rejected["duplicate_text"] += 1
            continue

        seen_texts.add(text)
        for p in parts:
            block_counts[p] += 1

        word_id = f"w_{translit(text)}"
        words.append(
            {
                "id": word_id,
                "text": text,
                "parts": parts,
                "difficulty": clamp_difficulty(entry.get("difficulty"), len(parts)),
                "category": infer_category(entry.get("tags")),
            }
        )

    words.sort(key=lambda w: (w["difficulty"], len(w["parts"]), w["text"]))

    max_freq = max(block_counts.values()) if block_counts else 1
    blocks = []
    for block_text, freq in sorted(block_counts.items()):
        weight = max(1, min(100, round(freq / max_freq * 100)))
        block_id = f"b_{translit(block_text)}"
        tag = "common" if weight >= 40 else "rare"
        blocks.append(
            {
                "id": block_id,
                "text": block_text,
                "difficulty": 1 if weight >= 60 else (2 if weight >= 30 else 3),
                "weight": weight,
                "tags": [tag],
            }
        )

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    words_payload = {"type": "word", "version": 1, "entries": words}
    blocks_payload = {"type": "block", "version": 1, "entries": blocks}
    stats_payload = {
        "version": 1,
        "source_entries_total": len(source_entries),
        "words_total": len(words),
        "blocks_total": len(blocks),
        "coverage_percent": round((len(words) / len(source_entries) * 100), 2)
        if source_entries
        else 0.0,
        "rejected": dict(sorted(rejected.items())),
        "distribution": {
            "difficulty": dict(
                sorted(Counter(w["difficulty"] for w in words).items())
            ),
            "category": dict(sorted(Counter(w["category"] for w in words).items())),
        },
    }

    (OUT_DIR / "words_v1.json").write_text(
        json.dumps(words_payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT_DIR / "blocks_v1.json").write_text(
        json.dumps(blocks_payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT_DIR / "statistics.json").write_text(
        json.dumps(stats_payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"Generated words: {len(words)}")
    print(f"Generated blocks: {len(blocks)}")
    print(f"Coverage: {stats_payload['coverage_percent']}%")


if __name__ == "__main__":
    build()
