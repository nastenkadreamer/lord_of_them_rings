### This script converts GeoJSON geographic data files into CSV format for use in analysis tools. 
### It reads GeoJSON features and flattens them into tabular rows, extracting geographic coordinates (latitude/longitude), geometry types, and all property attributes as columns. 
### For time-stamped data, it intelligently splits creation_time into separate date and time columns. 
### The script handles multiple input formats (FeatureCollections, single Features, or arrays), quotes all output fields to prevent format auto-conversion in Excel, and can auto-detect GeoJSON files in the script folder or accept custom input/output paths as command-line arguments

############################################################
# File name: geojson.py
# Purpose: Convert GeoJSON files to CSV format for analysis
# Author: Anindya Singh 
# Date created: January 5, 2026
############################################################

import json, csv, sys, os

def flatten_feature(feat):
    # preserve original property text where possible:
    props = {}
    original_props = feat.get("properties") or {}
    for k, v in original_props.items():
        # keep strings exactly as-is; for other types keep their JSON representation
        if isinstance(v, str):
            props[k] = v
            # keep original creation_time and also split out date/time without changing formats
            if k == "creation_time":
                s = v.strip()
                if " " in s:
                    date_part, time_part = s.split(" ", 1)
                    props["creation_date"] = date_part
                    props["creation_time_only"] = time_part
                elif ":" in s:
                    # time-only value (no date)
                    props["creation_date"] = ""
                    props["creation_time_only"] = s
                else:
                    # date-only or other format
                    props["creation_date"] = s
                    props["creation_time_only"] = ""
        else:
            props[k] = json.dumps(v, ensure_ascii=False)
    geom = feat.get("geometry")
    if geom:
        props["geometry_type"] = geom.get("type")
        coords = geom.get("coordinates")
        if geom.get("type") == "Point" and isinstance(coords, (list, tuple)) and len(coords) >= 2:
            # keep numeric coordinates as numbers (no reformatting)
            props["lon"] = coords[0]
            props["lat"] = coords[1]
        else:
            props["coordinates"] = json.dumps(coords, ensure_ascii=False)
    return props

def geojson_to_csv(in_path, out_path):
    with open(in_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if data.get("type") == "FeatureCollection":
        features = data.get("features", [])
    elif data.get("type") == "Feature":
        features = [data]
    else:
        features = data if isinstance(data, list) else []

    rows = [flatten_feature(feat) for feat in features]

    fieldnames = []
    for key in ("geometry_type", "lon", "lat", "coordinates"):
        if any(key in r for r in rows):
            fieldnames.append(key)
    other_keys = []
    for r in rows:
        for k in r.keys():
            if k not in fieldnames and k not in other_keys:
                other_keys.append(k)
    fieldnames.extend(other_keys)

    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    # Quote all fields so tools like Excel are less likely to auto-convert formats
    with open(out_path, "w", encoding="utf-8-sig", newline="") as csvf:
        writer = csv.DictWriter(csvf, fieldnames=fieldnames, extrasaction="ignore", quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for r in rows:
            # ensure lists/dicts already serialized; keep strings as-is; numbers left as-is
            safe = {}
            for k in fieldnames:
                v = r.get(k)
                if isinstance(v, (list, dict)):
                    safe[k] = json.dumps(v, ensure_ascii=False)
                else:
                    safe[k] = v
            writer.writerow(safe)

if __name__ == "__main__":
    if len(sys.argv) < 2: # if no args, try to pick the first .geojson
        script_dir = os.path.dirname(os.path.abspath(__file__)) or "."
        candidates = [f for f in os.listdir(script_dir) if f.lower().endswith(('.geojson', '.json'))]
        if not candidates:
            print("No input file provided and no .geojson/.json found in script folder.")
            print("Usage: python geojson.py input.geojson [output.csv]")
            sys.exit(1)
        inp = os.path.join(script_dir, candidates[0])
        print(f"No args — using first file in folder: {inp}")
        out = os.path.splitext(inp)[0] + ".csv"
    else:
        inp = sys.argv[1]
        out = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(inp)[0] + ".csv"
    geojson_to_csv(inp, out)
    print(f"Wrote CSV: {out}")