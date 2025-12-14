# Packaged Tableau Data Source (.tdsx)

Create a single clickable data source file that includes both the connection definition and the extract.

## Steps
1. Generate `.hyper` extracts using the builder:

```bash
pip install tableauhyperapi
python scripts/build_hyper_extracts.py --root .. --out ./hyper-outputs
```

2. Package a `.tds` with a `.hyper` into `.tdsx`:

```bash
python scripts/package_tdsx.py \
  --tds templates/cluster_results.tds \
  --hyper hyper-outputs/cluster-analysis/results/Classified_Participants_with_Clusters_condition1_chart1.hyper \
  --out packaged/cluster_results.tdsx
```

3. Open the `.tdsx` in Tableau Desktop directly.

## Notes
- You can repeat this for sequence and AOI templates.
- Distribute `.tdsx` via Releases for easy stakeholder access.

---

# Packaged Workbook (.twbx) — Without a Tableau License

You can prepare everything needed so that anyone with Tableau Desktop can save a packaged workbook in minutes. Since you don’t currently have an active subscription, follow these prep steps and share them with a collaborator who does.

## Prep Steps (You)
1. Generate `.hyper` extracts and place them in `tableau-integration/hyper-outputs/` (see above).
2. Package one or more `.tdsx` files using `package_tdsx.py` for each dataset.
3. Provide a minimal “Workbook Build Guide” (below) to a teammate who has Tableau Desktop.

## Workbook Build Guide (For Someone With Tableau Desktop)
1. Open Tableau Desktop.
2. From the start screen, click “Connect → Tableau Extract” and select the provided `.tdsx` (e.g., `tableau-integration/packaged/cluster_results.tdsx`).
3. Create 1–2 simple views:
  - Cluster overview: `probability` (SUM) by `cluster_id` (bar), color by `condition`.
  - Participant detail: `probability` (SUM) with `participant_id` as filter; optionally show `cluster_id` distribution.
  - AOI timeline (optional): plot `timestamp` vs `aoi_id` for a selected `participant_id`.
4. Arrange the views on a Dashboard and add filters for `participant_id`, `condition`.
5. Save as Packaged Workbook: “File → Save As…” and choose `.twbx`.
6. Share the `.twbx` with the team or attach it to a Release.

### Optional: Use the Starter Workbook
Provide [workbook/starter_workbook.twb](workbook/starter_workbook.twb) to your collaborator.
Steps:
1. Open the `.twb` in Tableau Desktop.
2. Replace the placeholder data source: “Data → Replace Data Source…” and select your `.tdsx` (e.g., `cluster_results.tdsx`).
3. Confirm fields map correctly; adjust marks and filters if needed.
4. “File → Save As…” and choose `.twbx`.

## Tips for a Polished Demo
- Use clear titles, captions, and tooltips (e.g., “Probability of Assigned Cluster”).
- Set default aggregations (SUM for `probability`, AVG for `duration`) where appropriate.
- Add default filters with a few representative `participant_id` values.

## Optional: Provide a Starter Workbook Template
If desired, include a placeholder `.twb` (XML) that references field names only (no live connections). A collaborator can open it, replace the data source with the `.tdsx`, and immediately Save As `.twbx`.
