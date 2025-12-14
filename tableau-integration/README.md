# Tableau Integration

This folder provides utilities and templates to make the project "Tableau-friendly" by:
- Converting CSV result files into Tableau Hyper extracts (`.hyper`)
- Providing starter Tableau Data Source templates (`.tds`) with sensible field types
- Documenting recommended CSV schemas and naming for seamless joins

## Quick Start

1. Ensure Python 3.9+ is installed.
2. Install Tableau Hyper API:

```bash
pip install tableauhyperapi
```

3. Build Hyper extracts from project result CSVs:

```bash
python scripts/build_hyper_extracts.py --root .. --out ./hyper-outputs
## CI: CSV Schema Validation

This repo includes a GitHub Action that validates CSV results against `schemas/schema_config.json` on every push/PR. Update the schema map when adding new outputs to keep Tableau extracts consistent.

Run locally:

```bash
python scripts/validate_csv_schemas.py --root ..

## Packaged Data Sources (.tdsx)

Bundle a `.tds` and its `.hyper` into a single, shareable `.tdsx` for instant Tableau connections.

```bash
python scripts/package_tdsx.py \
   --tds templates/cluster_results.tds \
   --hyper hyper-outputs/cluster-analysis/results/Classified_Participants_with_Clusters_condition1_chart1.hyper \
   --out packaged/cluster_results.tdsx
```

See [README_PACKAGING.md](README_PACKAGING.md) for details.
```
```

4. Open Tableau Desktop:
   - Connect to `Tableau Extract` and select generated `.hyper` files in `hyper-outputs/`.
   - Optionally, use provided `.tds` templates to preconfigure field types.

## What Gets Converted

The script scans known results folders and converts CSVs into `.hyper` with normalized field names and types:
- `cluster-analysis/results/*.csv`
- `sequence-analysis/results/*.csv`
- `visualizations/*/results/*.csv` (if present and tabular)

## Notes
- Date/time columns are parsed if present (e.g., `timestamp`, `start_time`, `end_time`).
- Numeric columns become measures; non-numeric become dimensions.
- You can add new mappings in `scripts/build_hyper_extracts.py`.
