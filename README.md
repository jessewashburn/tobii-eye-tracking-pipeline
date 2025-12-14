# Tobii Eye Tracking Analysis

Analysis pipeline for Tobii eye-tracking data, including R scripts for sequence and cluster analysis, data cleanup, and visualizations, plus Python models for machine learning — with Tableau-ready extracts, templates, and CI schema validation.

## Highlights

- **Tableau-ready outputs:** Convert result CSVs into fast Tableau Extracts (`.hyper`) via a one-command builder. Includes `.tds` templates with pre-set field roles.
- **Schema enforcement:** A machine-readable schema map and a validator script keep column names and data types consistent across outputs.
- **CI guardrails:** GitHub Actions automatically validate CSV schemas on every push/PR for reliable, "just works" Tableau connections.
- **Modular pipelines:** Separate folders for sequence analysis, clustering, ML, and visualizations, each with scripts, sample data, and example results.
- **Cross-language tooling:** R for sequence/clustering/visualizations; Python for ML and data utilities.

## Tableau Integration

See [tableau-integration/README.md](tableau-integration/README.md) for generating Tableau Hyper extracts and using `.tds` templates to quickly connect datasets in Tableau Desktop.

Quick start:

```bash
pip install tableauhyperapi
python tableau-integration/scripts/build_hyper_extracts.py --root . --out tableau-integration/hyper-outputs
python tableau-integration/scripts/validate_csv_schemas.py --root .
```

Templates:
- [tableau-integration/templates/cluster_results.tds](tableau-integration/templates/cluster_results.tds)
- [tableau-integration/templates/sequence_results.tds](tableau-integration/templates/sequence_results.tds)
- [tableau-integration/templates/aoi_gaze_results.tds](tableau-integration/templates/aoi_gaze_results.tds)

Schemas & CI:
- Guide: [tableau-integration/schemas/SCHEMA_GUIDE.md](tableau-integration/schemas/SCHEMA_GUIDE.md)
- Map: [tableau-integration/schemas/schema_config.json](tableau-integration/schemas/schema_config.json)
- CI: [.github/workflows/csv-schema-check.yml](.github/workflows/csv-schema-check.yml)

## Repository Structure


```
tobii-eye-tracking-pipeline/
├── sequence-analysis/           # Sequence-based analysis (R)
│   ├── scripts/
│   ├── sample-data/
│   └── results/
├── cluster-analysis/            # Clustering gaze patterns (R)
│   ├── scripts/
│   ├── sample-data/
│   └── results/
├── visualizations/              # All visualization types (R)
│   ├── box-plots/
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
│   ├── heat-maps/
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
│   ├── coordinate-gaze-map/
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
│   ├── aoi-gaze-map/
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
├── machine-learning/            # Predictive modeling (Python)
│   ├── regression/
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
│   ├── classification/
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
└── README.md
```


Each analysis or visualization folder includes:

* **scripts/**: Core code for that stage of analysis
* **sample-data/**: Example inputs to demonstrate usage
* **results/**: Representative outputs (plots, metrics, exports)

## Tech Stack

* **R**

  * Data cleanup and preprocessing
  * Sequence analysis
  * Cluster analysis
  * Data visualization (ggplot2, etc.)

* **Python**

  * Machine learning (scikit-learn, pandas, numpy, etc.)
  * Model training and evaluation

* **Tobii Pro Studio / Tobii data exports**

  * Source format for raw eye-tracking data

## Getting Started

1. Clone this repository:

   ```bash
   git clone https://github.com/USERNAME/tobii-eye-tracking-analysis.git
   cd tobii-eye-tracking-analysis
   ```

2. Explore each pipeline folder (e.g. `sequence-analysis/`). Each contains:

   * R or Python scripts for analysis
   * Sample datasets to test the workflow
   * Example outputs for reference

3. Dependencies:

   * R ≥ 4.0 (packages: `tidyverse`, `TraMineR`, `cluster`, `ggplot2`)
   * Python ≥ 3.9 (packages: `scikit-learn`, `pandas`, `numpy`, `matplotlib`)

## Research Context

This repository was developed to support the study **"Improving Data Visualization Comprehension and Sensemaking: An empirical study"**, which is currently under review at an academic journal.
