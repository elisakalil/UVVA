#!/usr/bin/env python3
"""Build the maps of By region (LEARN-R06) into the Learn package.

countries-110m.json is world-atlas@2.0.2 (Natural Earth, public domain), the same geometry as the
UVVA Telas canvas (regions-map.js). For each country of the region courses this keeps its outline,
the land around it clipped to a frame, and the frame the map is fitted to. Each region course gets
its true coordinates; a region far off the mainland (Madeira) is drawn in an inset.

Output: Packages/Features/Learn/Sources/Learn/Resources/RegionMaps.json
  {"countries": [{"name", "box": [minLon, minLat, maxLon, maxLat],
                  "land": [[lon, lat, lon, lat, ...]], "near": [[...]]}],
   "regions": {"<courseId>": [lon, lat]}, "insets": ["<courseId>"]}
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
ATLAS = os.path.join(HERE, "countries-110m.json")
OUT = os.path.join(HERE, "../../../../Packages/Features/Learn/Sources/Learn/Resources/RegionMaps.json")

# The frame each map is fitted to: the whole country, or the part its regions sit in.
COUNTRIES = {
    "France": ("France", [-5.2, 42.3, 8.3, 51.1]),
    "Italy": ("Italy", [6.6, 36.6, 18.6, 47.1]),
    "Spain": ("Spain", [-9.4, 36.0, 3.4, 43.8]),
    "Portugal": ("Portugal", [-9.6, 36.9, -6.1, 42.2]),
    "Germany": ("Germany", [5.8, 47.2, 15.1, 55.1]),
    "Austria": ("Austria", [9.5, 46.3, 17.2, 49.1]),
    "Hungary": ("Hungary", [16.1, 45.7, 22.9, 48.6]),
    "Greece": ("Greece", [19.3, 34.8, 28.3, 41.8]),
    "Georgia": ("Georgia", [40.0, 41.0, 46.8, 43.6]),
    "United States": ("United States of America", [-125.5, 36.0, -115.0, 49.5]),
    "Argentina": ("Argentina", [-73.6, -55.1, -53.6, -21.8]),
    "Chile": ("Chile", [-75.5, -38.5, -68.0, -28.0]),
    "Australia": ("Australia", [112.9, -43.7, 153.7, -10.6]),
    "New Zealand": ("New Zealand", [166.3, -47.4, 178.6, -34.4]),
    "South Africa": ("South Africa", [17.0, -35.0, 22.5, -31.0]),
}

REGIONS = {
    "region-fr-bordeaux": [-0.55, 44.85], "region-fr-burgundy": [4.75, 47.05],
    "region-fr-champagne": [4.0, 49.05], "region-fr-loire-valley": [0.7, 47.35],
    "region-fr-southern-rhone": [4.85, 44.1], "region-fr-alsace": [7.3, 48.2],
    "region-fr-northern-rhone": [4.8, 45.2], "region-fr-beaujolais": [4.6, 46.1],
    "region-it-piedmont": [8.0, 44.7], "region-it-tuscany": [11.3, 43.4],
    "region-it-veneto": [11.8, 45.5], "region-it-sicily": [14.3, 37.5],
    "region-it-trentino-alto-adige": [11.2, 46.3], "region-it-friuli-venezia-giulia": [13.2, 46.0],
    "region-it-campania": [14.8, 41.0],
    "region-es-rioja": [-2.5, 42.45], "region-es-jerez": [-6.1, 36.7],
    "region-es-ribera-del-duero": [-3.9, 41.6], "region-es-priorat": [0.8, 41.2],
    "region-es-rias-baixas": [-8.7, 42.4],
    "region-pt-douro": [-7.55, 41.15], "region-pt-madeira": [-16.95, 32.75],
    "region-pt-vinho-verde": [-8.45, 41.75], "region-pt-alentejo": [-7.85, 38.35],
    "region-pt-dao": [-7.9, 40.5],
    "region-de-mosel": [6.9, 49.9], "region-de-rheingau": [8.0, 50.0], "region-de-pfalz": [8.15, 49.3],
    "region-at-burgenland": [16.6, 47.6], "region-at-wachau": [15.4, 48.37],
    "region-hu-tokaj": [21.4, 48.12],
    "region-gr-santorini": [25.43, 36.4],
    "region-ge-kakheti": [45.6, 41.9],
    "region-us-napa-valley": [-122.3, 38.5], "region-us-sonoma-county": [-122.85, 38.5],
    "region-us-willamette-valley": [-123.1, 45.1], "region-us-washington-state": [-119.5, 46.5],
    "region-ar-mendoza": [-68.8, -33.5], "region-ar-salta": [-66.0, -25.9],
    "region-ar-patagonia": [-67.5, -39.0],
    "region-cl-maipo-valley": [-70.7, -33.7], "region-cl-casablanca-valley": [-71.4, -33.3],
    "region-au-barossa-valley": [138.95, -34.55], "region-au-margaret-river": [115.1, -33.95],
    "region-au-hunter-valley": [151.2, -32.8],
    "region-nz-marlborough": [173.9, -41.5], "region-nz-hawkes-bay": [176.8, -39.6],
    "region-nz-central-otago": [169.2, -45.0],
    "region-za-stellenbosch": [18.86, -33.93], "region-za-swartland": [18.7, -33.35],
}

INSETS = ["region-pt-madeira"]


def decode(topo):
    sx, sy = topo["transform"]["scale"]
    tx, ty = topo["transform"]["translate"]
    arcs = []
    for arc in topo["arcs"]:
        x = y = 0
        points = []
        for dx, dy in arc:
            x += dx
            y += dy
            points.append((x * sx + tx, y * sy + ty))
        arcs.append(points)

    def ring(indices):
        points = []
        for i in indices:
            arc = arcs[i] if i >= 0 else arcs[~i][::-1]
            points.extend(arc if not points else arc[1:])
        return points

    shapes = {}
    for geometry in topo["objects"]["countries"]["geometries"]:
        polygons = {"Polygon": [geometry.get("arcs", [])],
                    "MultiPolygon": geometry.get("arcs", [])}.get(geometry["type"], [])
        shapes[geometry["properties"]["name"]] = [ring(rings[0]) for rings in polygons if rings]
    return shapes


def clip(points, box):
    """Sutherland-Hodgman against a lon/lat rectangle."""
    edges = [(0, box[0], True), (0, box[2], False), (1, box[1], True), (1, box[3], False)]
    for axis, limit, keep_above in edges:
        if not points:
            return []
        inside = (lambda p: p[axis] >= limit) if keep_above else (lambda p: p[axis] <= limit)
        out = []
        for i, current in enumerate(points):
            previous = points[i - 1]
            if inside(current) != inside(previous):
                t = (limit - previous[axis]) / (current[axis] - previous[axis])
                out.append(tuple(previous[k] + (current[k] - previous[k]) * t for k in (0, 1)))
            if inside(current):
                out.append(current)
        points = out
    return points


def flat(points):
    out, last = [], None
    for lon, lat in points:
        point = (round(lon, 2), round(lat, 2))
        if point != last:
            out.extend(point)
        last = point
    return out


def main():
    shapes = decode(json.load(open(ATLAS)))
    countries = []
    for name, (feature, box) in COUNTRIES.items():
        w, h = box[2] - box[0], box[3] - box[1]
        frame = [box[0] - w * 0.8, box[1] - h * 0.8, box[2] + w * 0.8, box[3] + h * 0.8]
        land = [flat(clip(ring, frame)) for ring in shapes[feature]]
        near = [flat(clip(ring, frame)) for other, rings in shapes.items() if other != feature for ring in rings]
        countries.append({"name": name, "box": box,
                          "land": [r for r in land if len(r) >= 6], "near": [r for r in near if len(r) >= 6]})
    with open(OUT, "w") as f:
        json.dump({"countries": countries, "regions": REGIONS, "insets": INSETS}, f,
                  ensure_ascii=False, separators=(",", ":"))
    print(f"{len(countries)} countries, {len(REGIONS)} regions, {os.path.getsize(OUT) // 1024} KB")


if __name__ == "__main__":
    main()
