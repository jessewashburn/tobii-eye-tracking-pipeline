# Tobii Eye Tracking Data Pipeline

> **Eye Tracking to Examine Engagement with Data Visualization**  
> This repository contains a production-ready pipeline for analyzing Tobii eye-tracking data, built to study how instructions and design choices affect user engagement with visual information. The pipeline supports reproducible research workflows and can be adapted to similar eye-tracking studies.

## Overview

This project examines fundamental questions about data visualization design: *How do instructions affect user engagement with different chart types?* Using eye-tracking technology to measure cognitive attention and interaction patterns, we process raw gaze data through a series of analysis stages, from sequence pattern recognition through statistical visualization. The result is a reusable template for eye-tracking research that prioritizes data integrity, reproducibility, and stakeholder communication.

**Core workflow:**
1. **Sequence Analysis** — Clean and preprocess raw eye-tracking data, then identify gaze patterns and attention sequences using the SPADE algorithm
2. **Visualizations** — Generate publication-ready charts and engagement metrics
3. **Tableau Integration** — Prepare outputs for interactive stakeholder dashboards


## Key Features

- **Reproducible research workflows:** Sample data and reference outputs in every module ensure others can validate and build on results
- **Schema enforcement:** Machine-readable schema and automated validation keep data consistent across analysis stages
- **Publication-ready visualizations:** R-based pipeline generates charts and metrics optimized for academic/stakeholder communication
- **Tableau integration:** Convert result CSVs into fast Tableau Extracts (`.hyper`) with pre-configured `.tds` templates for interactive dashboards
- **Modular & extensible:** Separate folders for sequence analysis, clustering, visualizations, and ML experiments—use what you need, extend as your research evolves
- **Cross-language tooling:** R for analysis and visualization; Python for ML pipelines and data utilities

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
│
├── CORE ANALYSIS
│   ├── sequence-analysis/           # Sequence-based gaze analysis (R)
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
│   └── visualizations/              # Publication-ready visualizations (R)
│       ├── box-plots/
│       ├── heat-maps/
│       ├── coordinate-gaze-map/
│       └── aoi-gaze-map/
│           ├── scripts/
│           ├── sample-data/
│           └── results/
│
├── EXPLORATORY WORK
│   ├── cluster-analysis/            # Clustering experiments (R)
│   │   ├── scripts/
│   │   ├── sample-data/
│   │   └── results/
│   └── machine-learning/            # ML experiments (Python)
│       ├── regression/
│       ├── classification/
│       ├── scripts/
│       ├── sample-data/
│       └── results/
│
└── UTILITIES
    └── tableau-integration/         # Tableau Hyper export & validation
        ├── scripts/
        ├── schemas/
        └── templates/
```

**Each module includes:**
- **scripts/**: Analysis code (R or Python)
- **sample-data/**: Example input data demonstrating the expected format
- **results/**: Representative outputs for validation and reference

## Tech Stack

* **R** — Data cleanup, sequence analysis, cluster analysis, and publication-ready visualizations (ggplot2, TraMineR, etc.)
* **Python** — Machine learning pipelines (scikit-learn, pandas, numpy)
* **Tableau** — Interactive dashboards for stakeholder communication
* **Tobii Pro Studio** — Raw eye-tracking data source

## Start Here (5-Minute Tour)

If you only review one part of this repository, start with **sequence analysis** and **AOI visualization**.

1. Open `sequence-analysis/scripts/eye_tracking_data_processor.py` to see how raw participant files are cleaned and transformed into analysis-ready AOI sequences.
2. Open `sequence-analysis/scripts/sequence_analysis.r` to see SPADE-based sequence mining and summary generation.
3. Open `sequence-analysis/results/sample_results_sequence_analysis.csv` for a concrete example output.
4. Open `visualizations/aoi-gaze-map/scripts/aoi_gaze_journey_map.r` and `visualizations/aoi-gaze-map/results/P14_Chart1_first10.png` to see gaze-journey visualization workflow and sample artifact.

This path gives a complete view from preprocessing -> sequence modeling -> visualization.

## Core Inputs and Outputs

| Module | Start Here | Primary Input(s) | Primary Output(s) |
|---|---|---|---|
| Sequence preprocessing | `sequence-analysis/scripts/eye_tracking_data_processor.py` | Participant Excel files (for example, `P2_Processed_Data.xlsx` ... `P49_Processed_Data.xlsx`) | `Combined_Data.xlsx`, `Abbreviated_Combined_Data.xlsx`, `AOI_Abbreviation_Legend.xlsx` |
| Sequence analysis (SPADE) | `sequence-analysis/scripts/sequence_analysis.r` | `cleaned_sequences_final_chart{chart}_cond_{cond}.csv` | `sequences_counts_summary_info_chart{chart}_cond_{cond}.csv` and `hits_chart{chart}_cond_{cond}.txt` |
| AOI gaze journey visualization | `visualizations/aoi-gaze-map/scripts/aoi_gaze_journey_map.r` | Participant AOI CSV (for example, `p14_TransformedAOIHits.csv`) plus chart image | PNG gaze-journey artifact (for example, `P14_Chart1_first10.png`) |

## Running the Core Workflow

1. Put your raw eye-tracking exports in a working directory.
2. Run `sequence-analysis/scripts/eye_tracking_data_processor.py` and provide that directory when prompted.
3. Ensure chart/condition cleaned CSV files are generated in the same working directory as `sequence-analysis/scripts/sequence_analysis.r` input naming conventions.
4. Set `chartNum` and `condNum` in `sequence-analysis/scripts/sequence_analysis.r`, then run the script.
5. For qualitative journey plots, run `visualizations/aoi-gaze-map/scripts/aoi_gaze_journey_map.r` and follow interactive prompts.

Success check:
- Sequence summary CSV appears with chart/condition naming.
- SPADE intermediate hits file is generated.
- AOI gaze journey PNG is generated.

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

**"Eye Tracking to Examine Engagement with Data Visualization"**

Eye tracking technology has been adopted in numerous studies to help understand the underlying cognitive processes employed by users when viewing visual information. This project examines whether the types of instructions provided affect how users interact with data visualizations. 

**Key findings:** Simple guidance by example could significantly improve the level of engagement with certain kinds of charts. This has implications for multiple domains including data visualization design and data literacy education curriculum design.

This repository serves as a reusable template—other researchers can adapt the pipeline, folder structure, and validation workflows to their own eye-tracking studies.
