#!/usr/bin/env python3
"""Generate kugire statistics CSV files for poems 1-1000."""

from __future__ import annotations

import csv
import re
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
XML_PATH = ROOT / "data" / "kokin-kugire.xml"
CACHE_DIR = ROOT / "tools" / "kugire" / "cache-direct"
OUT_DIR = ROOT / "analysis" / "data"

START_ID = 1
END_ID = 1000
POSITIONS = range(1, 5)
ALPHA_POSITIONS = range(1, 6)

TRANSLATORS = [
    "kaneko",
    "katagiri",
    "kojimaarai",
    "komachiya",
    "kubota",
    "kyusojin",
    "matsuda",
    "okumura",
    "ozawa",
    "takeoka",
]
TRANSLATOR_SET = set(TRANSLATORS)

MORPH_LEVELS = {
    "low": {"low"},
    "medium": {"mid"},
    "high": {"high"},
    "low_medium": {"low", "mid"},
    "medium_high": {"mid", "high"},
    "low_medium_high": {"low", "mid", "high"},
}

TAG_RE = re.compile(r"\[K:([^\]:]+)(?::[^\]]+)?\]")


def parse_cache() -> dict[int, dict[str, set[int]]]:
    annotations = {
        poem_id: {source: set() for source in TRANSLATORS}
        for poem_id in range(START_ID, END_ID + 1)
    }
    for poem_id in range(START_ID, END_ID + 1):
        path = CACHE_DIR / f"kugire-{poem_id}-translations.txt"
        content_index = 0
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if content_index < 4:
                for match in TAG_RE.finditer(raw_line):
                    source = match.group(1)
                    if source in TRANSLATOR_SET:
                        annotations[poem_id][source].add(content_index + 1)
            content_index += 1
    return annotations


def parse_morph() -> dict[int, dict[str, set[int]]]:
    result = {
        poem_id: {level: set() for level in MORPH_LEVELS}
        for poem_id in range(START_ID, END_ID + 1)
    }
    root = ET.parse(XML_PATH).getroot()
    for elem in root.iter():
        if local_name(elem.tag) != "l":
            continue
        raw_n = elem.attrib.get("n", "")
        if not raw_n.isdigit():
            continue
        poem_id = int(raw_n)
        if poem_id < START_ID or poem_id > END_ID:
            continue
        for child in elem:
            if local_name(child.tag) != "k":
                continue
            if child.attrib.get("source") != "morph":
                continue
            raw_pos = child.attrib.get("n", "")
            cert = child.attrib.get("cert", "")
            if not raw_pos.isdigit():
                continue
            pos = int(raw_pos)
            if pos not in POSITIONS:
                continue
            for level, certs in MORPH_LEVELS.items():
                if cert in certs:
                    result[poem_id][level].add(pos)
    return result


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def binary_vector(positions: set[int]) -> tuple[int, int, int, int]:
    return tuple(1 if pos in positions else 0 for pos in POSITIONS)


def alpha_vector(positions: set[int]) -> tuple[int, int, int, int, int]:
    """Encode kugire positions for alpha; position 5 means no kugire."""
    if not positions:
        return (0, 0, 0, 0, 1)
    return tuple(1 if pos in positions else 0 for pos in ALPHA_POSITIONS)


def alpha_for_items(items: list[list[int]]) -> float | None:
    if not items:
        return None
    annotator_count = len(items[0])
    if annotator_count < 2:
        return None

    agreements = []
    total_ones = 0
    total_ratings = 0
    for ratings in items:
        ones = sum(ratings)
        zeros = annotator_count - ones
        agreements.append(
            (zeros * (zeros - 1) + ones * (ones - 1))
            / (annotator_count * (annotator_count - 1))
        )
        total_ones += ones
        total_ratings += annotator_count

    observed = sum(agreements) / len(agreements)
    p1 = total_ones / total_ratings
    p0 = 1 - p1
    expected = p0 * p0 + p1 * p1
    if expected == 1:
        return None
    return (observed - expected) / (1 - expected)


def write_morph_translator_comparison(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    path = OUT_DIR / "morph_translator_comparison_1_1000.csv"
    rows = []
    for level in MORPH_LEVELS:
        for poem_id in range(START_ID, END_ID + 1):
            for translator in TRANSLATORS:
                tp = tn = fp = fn = 0
                t_positions = translator_ann[poem_id][translator]
                m_positions = morph_ann[poem_id][level]
                for pos in POSITIONS:
                    t_mark = pos in t_positions
                    m_mark = pos in m_positions
                    if t_mark and m_mark:
                        tp += 1
                    elif not t_mark and not m_mark:
                        tn += 1
                    elif t_mark and not m_mark:
                        fp += 1
                    else:
                        fn += 1
                total = tp + tn + fp + fn
                rows.append(
                    {
                        "poem_id": poem_id,
                        "morph_level": level,
                        "translator": translator,
                        "positions_per_poem": len(POSITIONS),
                        "items": total,
                        "tp": tp,
                        "tn": tn,
                        "fp": fp,
                        "fn": fn,
                        "matches": tp + tn,
                        "mismatches": fp + fn,
                        "match_rate": f"{(tp + tn) / total:.6f}",
                        "dissimilarity": f"{(fp + fn) / total:.6f}",
                        "translator_positions": positions_string(t_positions),
                        "morph_positions": positions_string(m_positions),
                        "poem_equal": int(t_positions == m_positions),
                    }
                )
    write_csv(path, rows)


def write_dissimilarity_matrix(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    labels = TRANSLATORS + ["morph_high"]
    vectors: dict[str, list[int]] = {}
    for translator in TRANSLATORS:
        values = []
        for poem_id in range(START_ID, END_ID + 1):
            values.extend(binary_vector(translator_ann[poem_id][translator]))
        vectors[translator] = values

    morph_values = []
    for poem_id in range(START_ID, END_ID + 1):
        morph_values.extend(binary_vector(morph_ann[poem_id]["high"]))
    vectors["morph_high"] = morph_values

    rows = []
    for left in labels:
        row = {"source": left}
        for right in labels:
            distance = sum(a != b for a, b in zip(vectors[left], vectors[right]))
            row[right] = f"{distance / len(vectors[left]):.6f}"
        rows.append(row)
    write_csv(OUT_DIR / "dissimilarity_matrix_1_1000.csv", rows, ["source"] + labels)


def write_poem_alpha(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    rows = []
    for poem_id in range(START_ID, END_ID + 1):
        items = []
        translator_vectors = {
            translator: alpha_vector(translator_ann[poem_id][translator])
            for translator in TRANSLATORS
        }
        for index, _pos in enumerate(ALPHA_POSITIONS):
            items.append([translator_vectors[t][index] for t in TRANSLATORS])
        alpha = alpha_for_items(items)
        break_count = sum(sum(item) for item in items)
        majority_positions = {
            pos
            for pos in POSITIONS
            if sum(pos in translator_ann[poem_id][t] for t in TRANSLATORS) >= 6
        }
        rows.append(
            {
                "poem_id": poem_id,
                "alpha": "" if alpha is None else f"{alpha:.6f}",
                "break_marks": break_count,
                "possible_marks": len(TRANSLATORS) * len(ALPHA_POSITIONS),
                "translator_disagreement": int(
                    len(
                        {
                            frozenset(translator_ann[poem_id][translator])
                            for translator in TRANSLATORS
                        }
                    )
                    > 1
                ),
                "majority_positions": positions_string(majority_positions),
                "morph_high_positions": positions_string(morph_ann[poem_id]["high"]),
            }
        )
    write_csv(OUT_DIR / "poem_alpha_1_1000.csv", rows)


def write_poem_morph_alpha(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    rows = []
    for level in MORPH_LEVELS:
        for poem_id in range(START_ID, END_ID + 1):
            translator_items = []
            translator_morph_items = []
            translator_vectors = {
                translator: alpha_vector(translator_ann[poem_id][translator])
                for translator in TRANSLATORS
            }
            morph_vector = alpha_vector(morph_ann[poem_id][level])
            for index, _pos in enumerate(ALPHA_POSITIONS):
                translator_ratings = [
                    translator_vectors[translator][index]
                    for translator in TRANSLATORS
                ]
                morph_rating = morph_vector[index]
                translator_items.append(translator_ratings)
                translator_morph_items.append(translator_ratings + [morph_rating])

            alpha_translators = alpha_for_items(translator_items)
            alpha_with_morph = alpha_for_items(translator_morph_items)
            rows.append(
                {
                    "poem_id": poem_id,
                    "morph_level": level,
                    "alpha_translators": ""
                    if alpha_translators is None
                    else f"{alpha_translators:.6f}",
                    "alpha_with_morph": ""
                    if alpha_with_morph is None
                    else f"{alpha_with_morph:.6f}",
                    "annotators": len(TRANSLATORS) + 1,
                    "positions_per_poem": len(ALPHA_POSITIONS),
                    "translator_break_marks": sum(
                        sum(item) for item in translator_items
                    ),
                    "morph_break_marks": len(morph_ann[poem_id][level]),
                }
            )
    write_csv(OUT_DIR / "poem_morph_alpha_1_1000.csv", rows)


def write_morph_translator_prf(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    rows = []
    for translator in [
        "kaneko",
        "kubota",
        "katagiri",
        "okumura",
        "takeoka",
        "ozawa",
        "kyusojin",
        "matsuda",
        "kojimaarai",
        "komachiya",
    ]:
        for level in MORPH_LEVELS:
            tp = tn = fp = fn = 0
            for poem_id in range(START_ID, END_ID + 1):
                t_positions = translator_ann[poem_id][translator]
                m_positions = morph_ann[poem_id][level]
                for pos in POSITIONS:
                    t_mark = pos in t_positions
                    m_mark = pos in m_positions
                    if t_mark and m_mark:
                        tp += 1
                    elif not t_mark and not m_mark:
                        tn += 1
                    elif t_mark and not m_mark:
                        fp += 1
                    else:
                        fn += 1
            precision = tp / (tp + fp) if tp + fp else None
            recall = tp / (tp + fn) if tp + fn else None
            f1 = (
                2 * precision * recall / (precision + recall)
                if precision is not None
                and recall is not None
                and precision + recall
                else None
            )
            rows.append(
                {
                    "translator": translator,
                    "morph_level": level,
                    "tp": tp,
                    "fp": fp,
                    "fn": fn,
                    "tn": tn,
                    "precision": "" if precision is None else f"{precision:.6f}",
                    "recall": "" if recall is None else f"{recall:.6f}",
                    "f1": "" if f1 is None else f"{f1:.6f}",
                }
            )
    write_csv(OUT_DIR / "morph_translator_prf_1_1000.csv", rows)


def write_11_judgement_agreement(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    poem_rows = []
    for poem_id in range(START_ID, END_ID + 1):
        counts = {pos: 0 for pos in ALPHA_POSITIONS}
        for translator in TRANSLATORS:
            positions = translator_ann[poem_id][translator]
            if positions:
                for pos in positions:
                    if pos in POSITIONS:
                        counts[pos] += 1
            else:
                counts[5] += 1

        morph_positions = morph_ann[poem_id]["high"]
        if morph_positions:
            for pos in morph_positions:
                if pos in POSITIONS:
                    counts[pos] += 1
        else:
            counts[5] += 1

        max_position = max(counts, key=lambda pos: counts[pos])
        poem_rows.append(
            {
                "poem_id": poem_id,
                "count_1": counts[1],
                "count_2": counts[2],
                "count_3": counts[3],
                "count_4": counts[4],
                "count_5": counts[5],
                "max_agreement": counts[max_position],
                "max_position": max_position,
            }
        )
    write_csv(OUT_DIR / "poem_11_judgement_agreement_1_1000.csv", poem_rows)

    total = END_ID - START_ID + 1
    summary_rows = []
    for threshold in range(6, 12):
        poems = sum(row["max_agreement"] >= threshold for row in poem_rows)
        summary_rows.append(
            {
                "threshold": threshold,
                "label": f">={threshold}",
                "poems": poems,
                "total": total,
                "percent": f"{poems / total:.6f}",
            }
        )
    write_csv(OUT_DIR / "cumulative_11_judgement_agreement_1_1000.csv", summary_rows)


def positions_string(positions: set[int]) -> str:
    return " ".join(str(pos) for pos in sorted(positions))


def write_summary(
    translator_ann: dict[int, dict[str, set[int]]],
    morph_ann: dict[int, dict[str, set[int]]],
) -> None:
    rows = []
    for level in MORPH_LEVELS:
        any_diff = all_diff = majority_diff = 0
        for poem_id in range(START_ID, END_ID + 1):
            morph_positions = morph_ann[poem_id][level]
            translator_sets = [
                translator_ann[poem_id][translator] for translator in TRANSLATORS
            ]
            if any(t != morph_positions for t in translator_sets):
                any_diff += 1
            if all(t != morph_positions for t in translator_sets):
                all_diff += 1
            majority_positions = {
                pos
                for pos in POSITIONS
                if sum(pos in translator_ann[poem_id][t] for t in TRANSLATORS) >= 6
            }
            if majority_positions != morph_positions:
                majority_diff += 1
        rows.append(
            {
                "morph_level": level,
                "poems": END_ID - START_ID + 1,
                "any_translator_differs_from_morph": any_diff,
                "any_translator_differs_rate": f"{any_diff / (END_ID - START_ID + 1):.6f}",
                "all_translators_differ_from_morph": all_diff,
                "all_translators_differ_rate": f"{all_diff / (END_ID - START_ID + 1):.6f}",
                "translator_majority_differs_from_morph": majority_diff,
                "translator_majority_differs_rate": f"{majority_diff / (END_ID - START_ID + 1):.6f}",
            }
        )

    disagreement = 0
    for poem_id in range(START_ID, END_ID + 1):
        if (
            len(
                {
                    frozenset(translator_ann[poem_id][translator])
                    for translator in TRANSLATORS
                }
            )
            > 1
        ):
            disagreement += 1

    rows.append(
        {
            "morph_level": "translator_disagreement",
            "poems": END_ID - START_ID + 1,
            "any_translator_differs_from_morph": disagreement,
            "any_translator_differs_rate": f"{disagreement / (END_ID - START_ID + 1):.6f}",
            "all_translators_differ_from_morph": "",
            "all_translators_differ_rate": "",
            "translator_majority_differs_from_morph": "",
            "translator_majority_differs_rate": "",
        }
    )
    write_csv(OUT_DIR / "cumulative_summary_1_1000.csv", rows)


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str] | None = None) -> None:
    if not rows:
        return
    if fieldnames is None:
        fieldnames = list(rows[0].keys())
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    translator_ann = parse_cache()
    morph_ann = parse_morph()
    write_morph_translator_comparison(translator_ann, morph_ann)
    write_dissimilarity_matrix(translator_ann, morph_ann)
    write_poem_alpha(translator_ann, morph_ann)
    write_poem_morph_alpha(translator_ann, morph_ann)
    write_morph_translator_prf(translator_ann, morph_ann)
    write_11_judgement_agreement(translator_ann, morph_ann)
    write_summary(translator_ann, morph_ann)


if __name__ == "__main__":
    main()
