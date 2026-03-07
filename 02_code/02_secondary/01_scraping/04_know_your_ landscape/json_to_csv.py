import json, csv, sys, os

def flatten_dict(d, parent_key='', sep='.'):
    items = {}
    for k, v in (d or {}).items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.update(flatten_dict(v, new_key, sep=sep))
        else:
            items[new_key] = v
    return items

def flatten_feature(feat):
    props = {}
    if isinstance(feat, dict) and 'properties' in feat:
        props.update(flatten_dict(feat.get('properties') or {}))
        geom = feat.get('geometry')
        if geom:
            props['geometry.type'] = geom.get('type')
            coords = geom.get('coordinates')
            if geom.get('type') == 'Point' and isinstance(coords, (list, tuple)) and len(coords) >= 2:
                props['lon'] = coords[0]
                props['lat'] = coords[1]
            else:
                props['geometry.coordinates'] = json.dumps(coords, ensure_ascii=False)
    elif isinstance(feat, dict):
        props.update(flatten_dict(feat))
    else:
        props['value'] = feat
    return props

def json_to_csv(in_path, out_path):
    with open(in_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if isinstance(data, dict) and data.get('type') == 'FeatureCollection':
        items = data.get('features', [])
    elif isinstance(data, dict) and data.get('type') == 'Feature':
        items = [data]
    elif isinstance(data, list):
        items = data
    elif isinstance(data, dict) and 'features' in data and isinstance(data['features'], list):
        items = data['features']
    else:
        items = [data]

    rows = [flatten_feature(it) for it in items]

    fieldnames = []
    for key in ('geometry.type', 'lon', 'lat', 'geometry.coordinates'):
        if any(key in r for r in rows):
            fieldnames.append(key)
    other_keys = []
    for r in rows:
        for k in r.keys():
            if k not in fieldnames and k not in other_keys:
                other_keys.append(k)
    fieldnames.extend(other_keys)

    os.makedirs(os.path.dirname(out_path) or '.', exist_ok=True)
    with open(out_path, 'w', encoding='utf-8-sig', newline='') as csvf:
        writer = csv.DictWriter(csvf, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        for r in rows:
            safe = {}
            for k in fieldnames:
                v = r.get(k)
                if isinstance(v, (list, dict)):
                    safe[k] = json.dumps(v, ensure_ascii=False)
                else:
                    safe[k] = v
            writer.writerow(safe)

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__)) or "."
    if len(sys.argv) < 2:
        default = os.path.join(script_dir, 'nrega_features.json')
        if os.path.exists(default):
            inp = default
        else:
            print("Usage: python json_to_csv.py input.json [output.csv]")
            sys.exit(1)
    else:
        inp = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(inp)[0] + ".csv"
    json_to_csv(inp, out)
    print(f"Wrote CSV: {out}")