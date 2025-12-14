import argparse
import zipfile
from pathlib import Path

"""
Package a Tableau Data Source (.tds) and its associated .hyper extract into a single .tdsx file.
This allows stakeholders to open the data source directly in Tableau Desktop without manual wiring.

Usage:
  python package_tdsx.py --tds tableau-integration/templates/cluster_results.tds \
                         --hyper tableau-integration/hyper-outputs/cluster-analysis/results/Classified_Participants_with_Clusters_condition1_chart1.hyper \
                         --out tableau-integration/packaged/cluster_results.tdsx
"""


def package_tdsx(tds: Path, hyper: Path, out: Path):
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        # In .tdsx, the .tds sits at root, and extracts typically under Data/Extracts
        z.write(tds, arcname=tds.name)
        z.write(hyper, arcname=f"Data/Extracts/{hyper.name}")
    print(f"Created {out}")


def main():
    parser = argparse.ArgumentParser(description="Package .tds + .hyper into a .tdsx")
    parser.add_argument("--tds", required=True, help="Path to .tds template")
    parser.add_argument("--hyper", required=True, help="Path to .hyper extract")
    parser.add_argument("--out", required=True, help="Output .tdsx path")
    args = parser.parse_args()

    tds = Path(args.tds).resolve()
    hyper = Path(args.hyper).resolve()
    out = Path(args.out).resolve()

    if not tds.exists():
        raise FileNotFoundError(f"Missing .tds: {tds}")
    if not hyper.exists():
        raise FileNotFoundError(f"Missing .hyper: {hyper}")

    package_tdsx(tds, hyper, out)


if __name__ == "__main__":
    main()
