import pandas as pd
from PyPDF2 import PdfReader
import os

# list of (input_pdf, output_csv) pairs
files = [
    # fill these in with your own paths
    (r"C:\Users\anind\Dropbox\Building Resilience IEIC\04 Data\01_data\01 Raw\02_secondary\01_cgwb\02_cgwb_groundwater_administrative_reports\01_block_level\Maharashtra_WL_Aug2022_WRIS.pdf", r"C:\Users\anind\Dropbox\Building Resilience IEIC\04 Data\01_data\02 Inter\02_secondary\01_cgwb\02_cgwb_groundwater_administrative_reports\01_block_level\Maharashtra_WL_Aug2022_WRIS.csv"),
    (r"C:\Users\anind\Dropbox\Building Resilience IEIC\04 Data\01_data\01 Raw\02_secondary\01_cgwb\02_cgwb_groundwater_administrative_reports\01_block_level\Maharashtra_WL_May2022_WRIS.pdf", r"C:\Users\anind\Dropbox\Building Resilience IEIC\04 Data\01_data\02 Inter\02_secondary\01_cgwb\02_cgwb_groundwater_administrative_reports\01_block_level\Maharashtra_WL_May2022_WRIS.csv"),
    (r"C:\Users\anind\Dropbox\Building Resilience IEIC\04 Data\01_data\01 Raw\02_secondary\01_cgwb\02_cgwb_groundwater_administrative_reports\01_block_level\Maharashtra_WL_Nov2022_WRIS.pdf", r"C:\Users\anind\Dropbox\Building Resilience IEIC\04 Data\01_data\02 Inter\02_secondary\01_cgwb\02_cgwb_groundwater_administrative_reports\01_block_level\Maharashtra_WL_Nov2022_WRIS.csv"),
]

# verify paths
for _, out in files:
    output_dir = os.path.dirname(out)
    print("Output directory is", output_dir)

columns = [
    "SITE_ID",
    "STATE_NAME",
    "DISTRICT_NAME",
    "TAHSIL_NAME",
    "BLOCK_NAME",
    "SITE_NAME",
    "SITE_TYPE",
    "SITE_SUB_TYPE",
    "AQUIFER_TYPE",
    "DEPTH",
    "WLS_DATE",
    "WLS_WTR_LEVEL"
]

def process_pdf(pdf_path, output_csv):
    """Read PDF `pdf_path`, parse groundwater rows, filter for
    Maharashtra, and write to `output_csv`."""
    rows = []
    reader = PdfReader(pdf_path)

    for page in reader.pages:
        text = page.extract_text()
        if not text:
            continue
        lines = text.split("\n")
        for line in lines:
            parts = line.split()
            if len(parts) < 12:
                continue
            if not parts[0].startswith("W"):
                continue
            try:
                # look for any token like '12-Aug' or '5-May' etc.
                months = ["Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"]
                date_index = next(
                    i for i, x in enumerate(parts)
                    if "-" in x and any(m in x for m in months)
                )

                site_id = parts[0]
                state = parts[1]
                district = parts[2]
                tahsil = parts[3]
                block = parts[4]

                depth = parts[date_index - 1]
                aquifer_type = parts[date_index - 2]
                site_sub_type = parts[date_index - 3]
                site_type = parts[date_index - 4]

                site_name = " ".join(parts[5:date_index - 4])

                wls_date = parts[date_index]
                wls_level = parts[date_index + 1]

                rows.append([
                    site_id,
                    state,
                    district,
                    tahsil,
                    block,
                    site_name,
                    site_type,
                    site_sub_type,
                    aquifer_type,
                    depth,
                    wls_date,
                    wls_level,
                ])
            except StopIteration:
                continue
            except Exception:
                continue

    df = pd.DataFrame(rows, columns=columns)
    df_maharashtra = df[df["STATE_NAME"] == "Maharashtra"]
    if df_maharashtra.empty:
        print(f"Warning: no Maharashtra rows found in {pdf_path}")

    out_dir = os.path.dirname(output_csv)
    if not out_dir:
        raise ValueError(f"Output path '{output_csv}' has no directory component")
    if os.path.isdir(output_csv):
        raise ValueError(f"Output path '{output_csv}' is a directory, please include a filename")
    os.makedirs(out_dir, exist_ok=True)
    df_maharashtra.to_csv(output_csv, index=False)
    print("Saved file:", output_csv, "rows:", len(df_maharashtra))


# iterate over each PDF/output pair
for pdf_path, output_csv in files:
    process_pdf(pdf_path, output_csv)
