# CSV Schema Guide for Tableau

Standardize column names and data types to ensure seamless Tableau usage and consistent Hyper extracts.

## Conventions
- Naming: lower_snake_case, descriptive, stable across files.
- IDs as dimensions: `participant_id`, `cluster_id`, `aoi_id`, `condition`.
- Measures as numerics: `probability`, `duration`, `x`, `y`.
- Time as timestamps: `timestamp`, `start_time`, `end_time` in `%Y-%m-%d %H:%M:%S` or ISO `YYYY-MM-DDTHH:MM:SS`.

## Recommended Schemas

### Cluster Analysis (results)
- `participant_id` (int, dimension)
- `cluster_id` (int, dimension)
- `probability` (double, measure)
- `condition` (text, dimension)

### Sequence Analysis (results)
- `participant_id` (int, dimension)
- `sequence` (text, dimension)
- `start_time` (timestamp, dimension)
- `end_time` (timestamp, dimension)
- `duration` (double, measure)

### AOI Gaze Map (results)
- `participant_id` (int, dimension)
- `aoi_id` (int, dimension)
- `x` (double, measure)
- `y` (double, measure)
- `timestamp` (timestamp, dimension)
- `duration` (double, measure)

## Enforcing Schemas
The Hyper builder reads `schemas/schema_config.json` to apply fixed types per folder/file pattern. Update that file to add mappings for new datasets.

## Tips
- Keep categorical values normalized (e.g., `condition` should be consistent spellings).
- Avoid mixed-type columns; split into separate fields if necessary.
- Prefer one table per visualization/analysis output for simpler Tableau connections.
