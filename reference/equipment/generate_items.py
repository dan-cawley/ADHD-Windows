import os
import csv
import json
import time
import base64
import zipfile
from io import BytesIO
from pathlib import Path
from typing import Dict, List

from PIL import Image
from openai import OpenAI

client = OpenAI()

# =========================================================
# CONFIG
# =========================================================
CSV_PATH = Path("equipment_items.csv")

OUTPUT_DIR = Path("gear_output")
OUTPUT_1024 = OUTPUT_DIR / "1024"
OUTPUT_512 = OUTPUT_DIR / "512"

ZIP_NAME = "adhd_warriors_gear.zip"

MODEL_NAME = "gpt-image-1"
GEN_SIZE = "1024x1024"
FINAL_SIZE = (512, 512)
IMAGE_QUALITY = "medium"
IMAGE_FORMAT = "png"

DELAY_SECONDS = 4.0
MAX_RETRIES = 5
RETRY_BACKOFF_SECONDS = 10

GLOBAL_STYLE = """
A high-definition hand-drawn graphite pencil illustration on an aged, textured parchment background,
with a subtle sepia central vignette. The overall impression is a focused, artifact-like illustration
for an alchemist's bestiary.

The image must show exactly one item only.
No character.
No hands holding the item.
No scene.
No background objects beyond parchment texture.
No text.
No labels.
No border frame.
No collage.
No multiple items.
No sprite sheet.
Centered composition.
Readable silhouette.
Detailed craftsmanship.
Black and white graphite and ink cross-hatching.
Only Epic items may contain restrained magical color accents.
""".strip()

SLOTS = {
    1: "head",
    2: "chest",
    3: "hands",
    4: "legs",
    5: "boots",
    6: "weapon",
    7: "amulet",
    8: "ring1",
    9: "ring2",
}

# =========================================================
# HELPERS
# =========================================================
def ensure_dirs() -> None:
    OUTPUT_1024.mkdir(parents=True, exist_ok=True)
    OUTPUT_512.mkdir(parents=True, exist_ok=True)


def slot_phrase(slot_num: int) -> str:
    mapping = {
        1: "helmet or hood",
        2: "chest armor or robe torso piece",
        3: "gloves or gauntlets",
        4: "leggings, trousers, or lower armor",
        5: "boots",
        6: "weapon",
        7: "amulet or pendant",
        8: "ring",
        9: "ring",
    }
    return mapping[slot_num]


def slot_detail(slot_num: int) -> str:
    details = {
        1: "clear silhouette, ornate profile, readable front and side structure",
        2: "front-facing torso gear, readable shape, layered materials, strong symmetry",
        3: "paired gloves or gauntlets shown as one item arrangement",
        4: "readable lower-body garment or armor item, centered as a standalone equipment study",
        5: "paired boots shown as one item arrangement",
        6: "single weapon shown prominently and centered",
        7: "single amulet or pendant with readable chain or mount details",
        8: "single ring shown large enough to read details clearly",
        9: "single ring shown large enough to read details clearly",
    }
    return details[slot_num]


def variant_phrase(variant: str) -> str:
    if variant == "f":
        return (
            "female-cut equipment version with silhouette and tailoring adjusted for a female character, "
            "while still depicted only as a standalone item"
        )
    return "neutral equipment version"


def filename_for(set_key: str, variant: str, slot_num: int) -> str:
    return f"{set_key}_{variant}_{slot_num}.png"


def normalize_rarity(value: str) -> str:
    return value.strip().lower()


def parse_variants(value: str) -> List[str]:
    parts = [p.strip().lower() for p in value.split("|") if p.strip()]
    valid = [p for p in parts if p in {"n", "f"}]
    return valid or ["n"]


def read_items_csv(csv_path: Path) -> List[Dict]:
    rows: List[Dict] = []

    with csv_path.open("r", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)

        required = {
            "set_key",
            "set_display",
            "theme",
            "epic_color",
            "slot_num",
            "item_name",
            "rarity",
            "variants",
        }

        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"CSV is missing required columns: {sorted(missing)}")

        for i, row in enumerate(reader, start=2):
            try:
                slot_num = int(row["slot_num"])
            except ValueError as exc:
                raise ValueError(f"Invalid slot_num on CSV line {i}: {row['slot_num']}") from exc

            if slot_num not in SLOTS:
                raise ValueError(f"slot_num must be 1-9 on CSV line {i}, got {slot_num}")

            rows.append(
                {
                    "set_key": row["set_key"].strip(),
                    "set_display": row["set_display"].strip(),
                    "theme": row["theme"].strip(),
                    "epic_color": row["epic_color"].strip(),
                    "slot_num": slot_num,
                    "item_name": row["item_name"].strip(),
                    "rarity": normalize_rarity(row["rarity"]),
                    "variants": parse_variants(row["variants"]),
                }
            )

    return rows


def build_prompt(item: Dict, variant: str) -> str:
    epic_line = ""
    if item["rarity"] == "epic":
        epic_line = (
            f"Add restrained magical color accents in {item['epic_color']}. "
            "Keep most of the rendering black-and-white graphite so the color stands out sparingly."
        )

    return f"""
{GLOBAL_STYLE}

Subject: {item['item_name']}

Depict a single centered medieval fantasy {slot_phrase(item['slot_num'])} from the {item['set_display']} equipment set.
Theme: {item['theme']}.
Rarity: {item['rarity']}.
Variant: {variant_phrase(variant)}.

Composition guidance:
- one item only
- centered object study
- fills most of the frame without touching the edges
- consistent visual language across the set
- high readability for game inventory use
- {slot_detail(item['slot_num'])}
- artifact illustration rather than concept art sheet

{epic_line}
""".strip()


# =========================================================
# IMAGE GENERATION
# =========================================================
def generate_image(prompt: str) -> Image.Image:
    last_error = None

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            result = client.images.generate(
                model=MODEL_NAME,
                prompt=prompt,
                size=GEN_SIZE,
                quality=IMAGE_QUALITY,
                output_format=IMAGE_FORMAT,
            )

            b64 = result.data[0].b64_json
            img_bytes = base64.b64decode(b64)
            image = Image.open(BytesIO(img_bytes)).convert("RGBA")
            return image

        except Exception as exc:
            last_error = exc
            if attempt < MAX_RETRIES:
                wait_time = RETRY_BACKOFF_SECONDS * attempt
                print(f"    error on attempt {attempt}: {exc}")
                print(f"    retrying in {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                raise last_error

    raise last_error


def save_both_versions(image: Image.Image, filename: str):
    path_1024 = OUTPUT_1024 / filename
    path_512 = OUTPUT_512 / filename

    image.save(path_1024, format="PNG")

    resized = image.resize(FINAL_SIZE, Image.LANCZOS)
    resized.save(path_512, format="PNG")

    return path_1024, path_512


# =========================================================
# MANIFESTS
# =========================================================
def build_manifest_row(item: Dict, variant: str) -> Dict[str, str]:
    return {
        "set_key": item["set_key"],
        "set_display": item["set_display"],
        "theme": item["theme"],
        "variant": variant,
        "slot_num": str(item["slot_num"]),
        "slot_name": SLOTS[item["slot_num"]],
        "item_name": item["item_name"],
        "rarity": item["rarity"],
        "filename_1024": f"1024/{filename_for(item['set_key'], variant, item['slot_num'])}",
        "filename_512": f"512/{filename_for(item['set_key'], variant, item['slot_num'])}",
    }


def write_naming_manifest_txt() -> Path:
    path = OUTPUT_DIR / "naming_manifest.txt"

    lines = [
        "Naming convention:",
        "{set_key}_{variant}_{slot_num}.png",
        "",
        "variant codes:",
        "n = neutral",
        "f = female-cut variant",
        "",
        "slot mapping:",
    ]

    for slot_num, slot_name in SLOTS.items():
        lines.append(f"{slot_num} = {slot_name}")

    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def write_manifest_csv(rows: List[Dict[str, str]]) -> Path:
    path = OUTPUT_DIR / "item_manifest.csv"
    fieldnames = [
        "set_key",
        "set_display",
        "theme",
        "variant",
        "slot_num",
        "slot_name",
        "item_name",
        "rarity",
        "filename_1024",
        "filename_512",
    ]

    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    return path


def write_manifest_json(rows: List[Dict[str, str]]) -> Path:
    path = OUTPUT_DIR / "item_manifest.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(rows, f, indent=2)
    return path


def zip_output() -> Path:
    zip_path = Path(ZIP_NAME)
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(OUTPUT_DIR):
            for file_name in files:
                full_path = Path(root) / file_name
                arcname = full_path.relative_to(OUTPUT_DIR)
                zf.write(full_path, arcname=str(arcname))
    return zip_path


# =========================================================
# MAIN
# =========================================================
def main() -> None:
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV file not found: {CSV_PATH}")

    ensure_dirs()
    items = read_items_csv(CSV_PATH)

    manifest_rows: List[Dict[str, str]] = []
    generated_count = 0
    skipped_count = 0

    current_set = None

    for item in items:
        if item["set_key"] != current_set:
            current_set = item["set_key"]
            print(f"\nGenerating set: {item['set_display']} ({item['set_key']})")

        for variant in item["variants"]:
            filename = filename_for(item["set_key"], variant, item["slot_num"])
            target_1024 = OUTPUT_1024 / filename
            target_512 = OUTPUT_512 / filename

            manifest_rows.append(build_manifest_row(item, variant))

            if target_1024.exists() and target_512.exists():
                print(f"  skip existing: {filename}")
                skipped_count += 1
                continue

            prompt = build_prompt(item, variant)
            print(f"  generating: {filename}")

            image = generate_image(prompt)
            save_both_versions(image, filename)
            generated_count += 1

            time.sleep(DELAY_SECONDS)

    txt_manifest = write_naming_manifest_txt()
    csv_manifest = write_manifest_csv(manifest_rows)
    json_manifest = write_manifest_json(manifest_rows)
    zip_path = zip_output()

    print("\nDone.")
    print(f"Generated new files: {generated_count}")
    print(f"Skipped existing files: {skipped_count}")
    print(f"Text manifest: {txt_manifest}")
    print(f"CSV manifest:  {csv_manifest}")
    print(f"JSON manifest: {json_manifest}")
    print(f"ZIP created:   {zip_path}")


if __name__ == "__main__":
    main()