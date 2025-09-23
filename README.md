# Tobii Eye Tracking Analysis

This repository contains an end-to-end pipeline for analyzing Tobii eye-tracking data. The project is structured into modular pipelines, each focused on a specific type of analysis. Together, these pipelines provide tools for data cleanup, sequence analysis, clustering, visualization, and machine learning.

## Repository Structure

```
tobii-eye-tracking-analysis/
├── sequence-analysis/        # R scripts for sequence-based methods
│   ├── scripts/              # Processing & analysis scripts
│   ├── sample_data/          # Example input datasets
│   └── results/              # Sample outputs
├── cluster-analysis/         # R scripts for clustering gaze patterns
│   ├── scripts/
│   ├── sample_data/
│   └── results/
├── visualizations/           # R scripts for plotting and reporting
│   ├── scripts/
│   ├── sample_data/
│   └── results/
├── machine-learning/         # Python models for predictive analysis
│   ├── scripts/
│   ├── sample_data/
│   └── results/
└── README.md
```

Each pipeline folder includes:

* **scripts/**: Core code for that stage of analysis
* **sample\_data/**: Example inputs to demonstrate usage
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
