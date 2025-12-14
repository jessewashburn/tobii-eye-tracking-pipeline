import argparse
import csv
import fnmatch
import json
from pathlib import Path
from typing import Dict, List, Tuple

SCHEMA_CONFIG_PATH = Path(__file__).resolve().parents[1] / "schemas" / "schema_config.json"

TYPE_CHECKERS = {
    "int": lambda s: s == "" or s is None or _is_int(s),
    "double": lambda s: s == "" or s is None or _is_float(s),
    "timestamp": lambda s: s == "" or s is None or _is_ts(s),
    "text": lambda s: True,
}

def _is_int(s: str) -> bool:
    try:
        int(float(s))
        return True
    except:
        return False

def _is_float(s: str) -> bool:
    try:
        float(s)
        return True
    except:
        return False

def _is_ts(s: str) -> bool:
    import datetime as dt
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
        try:
            dt.datetime.strptime(s, fmt)
            return True
        except:
            continue
    return False


def load_schema_map() -> Dict[str, Dict[str, Dict[str, str]]]:
    if not SCHEMA_CONFIG_PATH.exists():
        return {}
    with open(SCHEMA_CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def lookup_schema(root: Path, csv_path: Path, schema_map: Dict[str, Dict[str, Dict[str, str]]]) -> Dict[str, str] | None:
    rel_dir = str(csv_path.parent.relative_to(root)).replace("\\", "/")
    file_name = csv_path.name
    if rel_dir in schema_map:
        patterns = schema_map[rel_dir]
        for pattern, mapping in patterns.items():
            if fnmatch.fnmatch(file_name, pattern):
                return mapping
    return None


def validate_csv(csv_path: Path, schema: Dict[str, str]) -> List[Tuple[int, str, str]]:
    errors: List[Tuple[int, str, str]] = []
    with csv_path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        missing_cols = [c for c in schema.keys() if c not in (reader.fieldnames or [])]
        for c in missing_cols:
            errors.append((0, c, "missing column"))
        for i, row in enumerate(reader, start=2):  # header is line 1
            for col, t in schema.items():
                checker = TYPE_CHECKERS.get(t, TYPE_CHECKERS["text"])
                val = row.get(col, "")
                if not checker(val):
                    errors.append((i, col, f"expected {t}"))
    return errors


def find_csvs(root: Path) -> List[Path]:
    return [p for p in root.glob("**/*.csv") if p.stat().st_size > 0]


def main():
    parser = argparse.ArgumentParser(description="Validate CSV files against schema_config.json")
    parser.add_argument("--root", type=str, default=str(Path(__file__).resolve().parents[2]), help="Project root path")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    schema_map = load_schema_map()
    csvs = find_csvs(root)

    total = 0
    for csv_path in csvs:
        schema = lookup_schema(root, csv_path, schema_map)
        if not schema:
            continue
        errs = validate_csv(csv_path, schema)
        if errs:
            print(f"Schema violations in {csv_path.relative_to(root)}:")
            for line, col, msg in errs[:50]:
                print(f"  L{line}: {col} - {msg}")
            if len(errs) > 50:
                print(f"  ... {len(errs)-50} more")
            total += 1
    if total == 0:
        print("All mapped CSVs conform to schema.")

if __name__ == "__main__":
    main()
