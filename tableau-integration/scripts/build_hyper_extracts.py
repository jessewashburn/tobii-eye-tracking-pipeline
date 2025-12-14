import argparse
import csv
import datetime as dt
import json
import fnmatch
from pathlib import Path
from typing import Dict, List, Optional

try:
    from tableauhyperapi import (Connection, HyperProcess, TableDefinition, SqlType, TableName, CreateMode,
                                 Inserter, Telemetry)
except Exception as e:
    print("Tableau Hyper API not available. Install with: pip install tableauhyperapi")
    raise

# Known folders and simple schema hints per dataset (override/augment if needed)
RESULT_FOLDERS = [
    Path("cluster-analysis/results"),
    Path("sequence-analysis/results"),
    Path("visualizations/aoi-gaze-map/results"),
]

DATE_FIELDS = {"timestamp", "start_time", "end_time", "date"}
INT_FIELDS = {"participant_id", "trial", "cluster_id", "aoi_id"}
FLOAT_FIELDS = {"x", "y", "duration", "probability", "score", "value"}

# Optional fixed schema mapping loaded from schemas/schema_config.json
SCHEMA_CONFIG_PATH = Path(__file__).resolve().parents[1] / "schemas" / "schema_config.json"
SCHEMA_MAP: Dict[str, Dict[str, Dict[str, str]]] = {}

def load_schema_map():
    global SCHEMA_MAP
    if SCHEMA_CONFIG_PATH.exists():
        try:
            with open(SCHEMA_CONFIG_PATH, "r", encoding="utf-8") as f:
                SCHEMA_MAP = json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load schema_config.json: {e}")
            SCHEMA_MAP = {}
    else:
        SCHEMA_MAP = {}

def lookup_fixed_types(root: Path, csv_path: Path) -> Optional[Dict[str, str]]:
    rel_dir = str(csv_path.parent.relative_to(root)).replace("\\", "/")
    file_name = csv_path.name
    if rel_dir in SCHEMA_MAP:
        patterns = SCHEMA_MAP[rel_dir]
        for pattern, mapping in patterns.items():
            if fnmatch.fnmatch(file_name, pattern):
                return mapping
    return None


def str_to_sqltype(t: str) -> SqlType:
    t = t.lower()
    if t == "int":
        return SqlType.int()
    if t == "double" or t == "real" or t == "float":
        return SqlType.double()
    if t == "timestamp" or t == "datetime":
        return SqlType.timestamp()
    return SqlType.text()

def infer_type(field: str, sample_values: List[str]) -> SqlType:
    f = field.lower()
    if f in INT_FIELDS:
        return SqlType.int()
    if f in FLOAT_FIELDS:
        return SqlType.double()
    if f in DATE_FIELDS:
        return SqlType.timestamp()
    # Fallback: inspect samples
    def is_int(s: str) -> bool:
        try:
            int(s)
            return True
        except:
            return False
    def is_float(s: str) -> bool:
        try:
            float(s)
            return True
        except:
            return False
    def is_ts(s: str) -> bool:
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
            try:
                dt.datetime.strptime(s, fmt)
                return True
            except:
                continue
        return False
    non_empty = [v for v in sample_values if v]
    if non_empty and all(is_int(v) for v in non_empty[:10]):
        return SqlType.int()
    if non_empty and all(is_float(v) for v in non_empty[:10]):
        return SqlType.double()
    if non_empty and any(is_ts(v) for v in non_empty[:10]):
        return SqlType.timestamp()
    return SqlType.text()


def build_table_def(csv_path: Path, table_name: TableName, fixed_types: Optional[Dict[str, str]] = None) -> TableDefinition:
    with csv_path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames or []
        # sample values by column
        samples: Dict[str, List[str]] = {h: [] for h in headers}
        for i, row in enumerate(reader):
            if i >= 50:
                break
            for h in headers:
                samples[h].append(row.get(h, ""))
    table_def = TableDefinition(table_name)
    for h in headers:
        if fixed_types and h in fixed_types:
            col_type = str_to_sqltype(fixed_types[h])
        else:
            col_type = infer_type(h, samples.get(h, []))
        table_def.add_column(h, col_type)
    return table_def


def insert_csv(connection: Connection, table_def: TableDefinition, csv_path: Path):
    # Ensure table exists
    connection.catalog.create_table(table_def)
    # Insert rows
    with csv_path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            values = []
            for col in table_def.columns:
                v = row.get(col.name, None)
                if v is None or v == "":
                    values.append(None)
                    continue
                # Convert based on type
                if col.type == SqlType.int():
                    try:
                        values.append(int(float(v)))
                    except:
                        values.append(None)
                elif col.type == SqlType.double():
                    try:
                        values.append(float(v))
                    except:
                        values.append(None)
                elif col.type == SqlType.timestamp():
                    # Try common formats
                    parsed: Optional[dt.datetime] = None
                    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
                        try:
                            parsed = dt.datetime.strptime(v, fmt)
                            break
                        except:
                            continue
                    values.append(parsed)
                else:
                    values.append(v)
            rows.append(values)
            if len(rows) >= 5000:
                with Inserter(connection, table_def) as inserter:
                    inserter.add_rows(rows)
                    inserter.execute()
                rows = []
        if rows:
            with Inserter(connection, table_def) as inserter:
                inserter.add_rows(rows)
                inserter.execute()


def convert_csv_to_hyper(csv_path: Path, out_dir: Path, root: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    hyper_path = out_dir / (csv_path.stem + ".hyper")
    table_name = TableName("Extract", csv_path.stem.replace(" ", "_"))
    fixed_types = lookup_fixed_types(root, csv_path)
    table_def = build_table_def(csv_path, table_name, fixed_types)

    with HyperProcess(Telemetry.DO_NOT_SEND_USAGE_DATA_TO_TABLEAU) as hyper:
        with Connection(hyper.endpoint, str(hyper_path), CreateMode.CREATE_AND_REPLACE) as connection:
            insert_csv(connection, table_def, csv_path)
    return hyper_path


def find_csvs(root: Path) -> List[Path]:
    all_csvs: List[Path] = []
    for rel in RESULT_FOLDERS:
        p = root / rel
        if p.exists():
            for file in p.glob("**/*.csv"):
                if file.stat().st_size > 0:
                    all_csvs.append(file)
    return all_csvs


def main():
    parser = argparse.ArgumentParser(description="Build Tableau Hyper extracts from project CSV results")
    parser.add_argument("--root", type=str, default=str(Path(__file__).resolve().parents[2]), help="Project root path")
    parser.add_argument("--out", type=str, default=str(Path(__file__).resolve().parents[1] / "hyper-outputs"), help="Output directory for .hyper files")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out_dir = Path(args.out).resolve()
    load_schema_map()

    csvs = find_csvs(root)
    print(f"Found {len(csvs)} CSV files to convert.")
    for csv_path in csvs:
        rel = csv_path.relative_to(root)
        target_dir = out_dir / rel.parent
        target_dir.mkdir(parents=True, exist_ok=True)
        print(f"Converting {rel} → {target_dir}")
        hyper_path = convert_csv_to_hyper(csv_path, target_dir, root)
        print(f"✓ Created {hyper_path}")


if __name__ == "__main__":
    main()
