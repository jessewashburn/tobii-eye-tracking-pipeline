# Summary Analysis

This module contains summary metrics generated from refined fixation-level eye-tracking exports.

## Folder Layout

- chart-level/scripts/: chart-specific AOI summary workflow
- chart-level/results/: representative chart-level outputs
- fixation-level/scripts/: participant-by-chart fixation summary workflows
- fixation-level/results/: representative fixation-level outputs
- sample data/: sample input reference files

## Inputs

Scripts in this module currently expect files in the working directory that match:

- P##_fixations_refined_clean.xlsx (case-insensitive)

Expected participant range is p6 to p49, excluding p25 and p28.

## Scripts

- chart-level/scripts/ChartLevelAOI.R
  - Produces per-chart AOI duration/count summaries in wide format.
- fixation-level/scripts/fixations_counts_durations.R
  - Produces total fixation duration and count per chart per participant.
- fixation-level/scripts/TotalTaskTime.R
  - Produces task-time summary per chart per participant.
- fixation-level/scripts/FirstAOIHitInfo.R
  - Produces first AOI hit and duration per chart per participant.

These scripts now write outputs to the corresponding results folders under each level.

## Outputs

Current representative outputs in this module:

- chart-level/results/sample_output_summary_analysis_chart_level.csv
- fixation-level/results/sample_output_fixations_summary_counts_durations.csv
- fixation-level/results/sample_output_fixations_task_time_summary.csv
- fixation-level/results/sample_output_first_aoi_hits_summary.csv

## Notes

- This module is wired into Tableau extraction and schema validation through:
  - tableau-integration/scripts/build_hyper_extracts.py
  - tableau-integration/schemas/schema_config.json
