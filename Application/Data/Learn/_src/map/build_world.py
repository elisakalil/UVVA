#!/usr/bin/env python3
"""Build the world map of You › Progress into the DesignSystem package.

countries-110m.json is world-atlas@2.0.2 (Natural Earth, public domain), the same geometry as the maps of
By region (build_map.py). This keeps the coastlines of the merged land (no borders, no Antarctica), the
middle of each country's mainland, and the true places of the wine regions the catalog uses, so a tasted
wine is pinned at its region, or at its country when the region is not listed.

The polar land is left out (Antarctica, Greenland, the Arctic islands) and the frame is fitted to what is left,
so every coastline is drawn whole and none is cut at the edge of the map.

Output: Packages/DesignSystem/Sources/DesignSystem/Resources/WorldMap.json
  {"box": [minLon, minLat, maxLon, maxLat],
   "land": [[lon, lat, lon, lat, ...]],
   "countries": {"<name>": [lon, lat]},
   "places": [{"name", "country", "at": [lon, lat]}]}
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
ATLAS = os.path.join(HERE, "countries-110m.json")
OUT = os.path.join(HERE, "../../../../Packages/DesignSystem/Sources/DesignSystem/Resources/WorldMap.json")

# Land whose middle lies past these latitudes is polar and stays off the map.
ARCTIC = 66.5
ANTARCTIC = -60.0
# A world this small needs only the shape of the coasts, as the maps of By region draw them: bends smaller than
# this (degrees) are smoothed away, and islands smaller than this (square degrees) are left out.
SIMPLIFY = 0.25
SMALLEST_ISLAND = 0.6

# The names the wines use, for the names Natural Earth gives.
COUNTRY_NAMES = {
    "United States of America": ["United States", "USA", "US"],
    "United Kingdom": ["UK", "England", "Great Britain", "Scotland", "Wales"],
    "Macedonia": ["North Macedonia"],
    "Czechia": ["Czech Republic"],
    "Bosnia and Herz.": ["Bosnia and Herzegovina"],
    "Dominican Rep.": ["Dominican Republic"],
    "eSwatini": ["Eswatini", "Swaziland"],
    "Côte d'Ivoire": ["Ivory Coast"],
}

# Countries too small for the 110m atlas, where wine is made.
SMALL_COUNTRIES = {
    "Malta": [14.4, 35.9], "Luxembourg": [6.13, 49.7], "Liechtenstein": [9.55, 47.15],
    "Andorra": [1.55, 42.5], "San Marino": [12.45, 43.94], "Monaco": [7.42, 43.74],
}

# Where each region sits, [lon, lat]: the wine-growing heart of it, not the middle of the province.
PLACES = {
    "France": {
        "Alsace": [7.3, 48.2], "Beaujolais": [4.6, 46.1], "Bordeaux": [-0.55, 44.85], "Burgundy": [4.75, 47.05],
        "Champagne": [4.0, 49.05], "Corsica": [9.0, 42.1], "Jura": [5.6, 46.8],
        "Languedoc-Roussillon": [3.3, 43.4], "Languedoc": [3.3, 43.5], "Roussillon": [2.8, 42.6],
        "Loire Valley": [0.7, 47.35], "Loire": [0.7, 47.35], "Provence": [6.0, 43.5],
        "Rhône Valley": [4.8, 44.6], "Rhône": [4.8, 44.6], "Northern Rhône": [4.8, 45.2],
        "Southern Rhône": [4.85, 44.1], "Savoie": [6.2, 45.6], "Southwest France": [0.5, 43.9],
        "Cahors": [1.44, 44.45], "Cognac": [-0.33, 45.7],
    },
    "Italy": {
        "Abruzzo": [13.9, 42.2], "Basilicata": [16.0, 40.6], "Calabria": [16.4, 39.0], "Campania": [14.8, 41.0],
        "Emilia-Romagna": [11.0, 44.5], "Friuli-Venezia Giulia": [13.2, 46.0], "Lazio": [12.7, 41.9],
        "Liguria": [8.9, 44.3], "Lombardy": [9.9, 45.6], "Marche": [13.2, 43.3], "Molise": [14.6, 41.7],
        "Piedmont": [8.0, 44.7], "Puglia": [16.6, 40.9], "Apulia": [16.6, 40.9], "Sardinia": [9.0, 40.1],
        "Sicily": [14.3, 37.5], "Trentino-Alto Adige": [11.2, 46.3], "Alto Adige": [11.35, 46.5],
        "Trentino": [11.1, 46.1], "Tuscany": [11.3, 43.4], "Umbria": [12.5, 42.9],
        "Valle d'Aosta": [7.4, 45.7], "Veneto": [11.8, 45.5],
    },
    "Spain": {
        "Andalusia": [-5.0, 37.4], "Aragón": [-1.2, 41.5], "Balearic Islands": [2.9, 39.6],
        "Basque Country": [-2.6, 43.0], "Canary Islands": [-15.6, 28.3], "Castilla y León": [-4.5, 41.7],
        "Castilla-La Mancha": [-3.0, 39.4], "Catalonia": [1.5, 41.6], "Extremadura": [-6.2, 39.0],
        "Galicia": [-8.2, 42.6], "Madrid": [-3.7, 40.3], "Murcia": [-1.4, 38.1], "Navarra": [-1.6, 42.6],
        "Rioja": [-2.5, 42.45], "La Rioja": [-2.5, 42.45], "Valencia": [-0.8, 39.2], "Jerez": [-6.1, 36.7],
        "Priorat": [0.8, 41.2], "Rías Baixas": [-8.7, 42.4], "Ribera del Duero": [-3.9, 41.6],
        "Toro": [-5.4, 41.5], "Rueda": [-4.95, 41.4], "Penedès": [1.7, 41.35], "Cava": [1.7, 41.35],
    },
    "Portugal": {
        "Alentejo": [-7.85, 38.35], "Bairrada": [-8.5, 40.4], "Beira": [-7.5, 40.3],
        "Beira Interior": [-7.2, 40.4], "Douro": [-7.55, 41.15], "Dão": [-7.9, 40.5], "Lisboa": [-9.1, 39.1],
        "Madeira": [-16.95, 32.75], "Península de Setúbal": [-8.9, 38.55], "Setúbal": [-8.9, 38.55],
        "Tejo": [-8.5, 39.3], "Trás-os-Montes": [-7.0, 41.7], "Vinho Verde": [-8.45, 41.75],
        "Minho": [-8.45, 41.75], "Algarve": [-8.2, 37.15], "Azores": [-28.5, 38.6], "Porto": [-7.55, 41.15],
    },
    "Germany": {
        "Ahr": [7.0, 50.53], "Baden": [8.0, 48.3], "Franken": [10.0, 49.8], "Mittelrhein": [7.7, 50.2],
        "Mosel": [6.9, 49.9], "Nahe": [7.7, 49.8], "Pfalz": [8.15, 49.3], "Rheingau": [8.0, 50.0],
        "Rheinhessen": [8.2, 49.8], "Württemberg": [9.2, 48.9], "Sachsen": [13.6, 51.1],
    },
    "Austria": {
        "Burgenland": [16.6, 47.6], "Niederösterreich": [15.6, 48.3], "Steiermark": [15.5, 46.8],
        "Wien": [16.37, 48.2], "Vienna": [16.37, 48.2], "Wachau": [15.4, 48.37], "Kamptal": [15.7, 48.5],
    },
    "Switzerland": {"Valais": [7.6, 46.2], "Vaud": [6.6, 46.5], "Zürich": [8.6, 47.4], "Ticino": [8.9, 46.1]},
    "Hungary": {"Eger": [20.4, 47.9], "Sopron": [16.6, 47.7], "Tokaj": [21.4, 48.12], "Villány": [18.45, 45.87]},
    "Greece": {
        "Aegean Islands": [25.4, 37.0], "Central Greece": [22.8, 38.6], "Crete": [24.9, 35.2],
        "Epirus": [20.8, 39.6], "Ionian Islands": [20.6, 38.5], "Macedonia": [22.5, 40.7],
        "Peloponnese": [22.3, 37.5], "Santorini": [25.43, 36.4], "Nemea": [22.66, 37.82],
        "Naoussa": [22.07, 40.63],
    },
    "Romania": {"Banat": [21.2, 45.7], "Dobrogea": [28.5, 44.4], "Muntenia": [26.0, 44.9],
                "Transylvania": [24.0, 46.5], "Moldova": [27.5, 46.8], "Dealu Mare": [26.4, 45.0]},
    "Bulgaria": {"Danube Plain": [25.0, 43.5], "Struma Valley": [23.1, 41.6], "Thracian Valley": [25.0, 42.2]},
    "Croatia": {"Dalmatia": [16.4, 43.5], "Istria": [13.9, 45.2], "Kvarner": [14.5, 45.1],
                "Slavonia": [18.0, 45.4]},
    "Slovenia": {"Podravje": [15.8, 46.5], "Primorska": [13.7, 45.9], "Posavje": [15.4, 45.9]},
    "Serbia": {"Župa": [21.1, 43.55]},
    "Slovakia": {"Južnoslovenská": [17.8, 48.1]},
    "North Macedonia": {"Tikveš": [22.0, 41.4]},
    "Moldova": {"Codru": [28.5, 47.0], "Stefan Voda": [29.7, 46.5]},
    "Ukraine": {"Crimea": [34.1, 44.9], "Odesa": [30.7, 46.5]},
    "Georgia": {"Kakheti": [45.6, 41.9], "Kartli": [44.2, 41.95], "Imereti": [42.7, 42.2]},
    "Armenia": {"Vayots Dzor": [45.4, 39.75], "Ararat Valley": [44.5, 40.0]},
    "Turkey": {"Central Anatolia": [34.5, 39.0], "Thrace": [27.0, 41.2], "Aegean": [27.5, 38.5],
               "Cappadocia": [34.85, 38.65]},
    "Cyprus": {"Commandaria": [32.9, 34.85]},
    "Israel": {"Galilee": [35.4, 32.9], "Golan Heights": [35.75, 33.0], "Judean Hills": [35.05, 31.75]},
    "Lebanon": {"Bekaa Valley": [35.9, 33.85]},
    "United Kingdom": {"Kent": [0.8, 51.2], "Sussex": [-0.3, 50.95], "Hampshire": [-1.3, 51.05],
                       "England": [-1.0, 51.3]},
    "Netherlands": {"Limburg": [5.9, 50.9]},
    "Luxembourg": {"Moselle": [6.35, 49.6]},
    "United States": {
        "California": [-122.3, 38.4], "Napa Valley": [-122.3, 38.5], "Sonoma County": [-122.85, 38.5],
        "Sonoma": [-122.85, 38.5], "Paso Robles": [-120.7, 35.6], "Santa Barbara": [-120.1, 34.7],
        "Idaho": [-116.7, 43.6], "New York": [-77.0, 42.6], "Finger Lakes": [-77.0, 42.6],
        "Oregon": [-123.1, 45.1], "Willamette Valley": [-123.1, 45.1], "Texas": [-98.9, 30.3],
        "Virginia": [-78.5, 38.0], "Washington": [-119.5, 46.5], "Washington State": [-119.5, 46.5],
        "Columbia Valley": [-119.5, 46.5],
    },
    "Canada": {"British Columbia": [-119.5, 49.6], "Okanagan Valley": [-119.5, 49.6],
               "Ontario": [-79.2, 43.1], "Niagara Peninsula": [-79.2, 43.1], "Nova Scotia": [-64.4, 45.1]},
    "Mexico": {"Baja California": [-116.6, 32.05], "Valle de Guadalupe": [-116.6, 32.05],
               "Coahuila": [-101.9, 25.4], "Querétaro": [-99.9, 20.6]},
    "Chile": {
        "Aconcagua": [-70.9, -32.8], "Central Valley": [-71.0, -34.5], "Coquimbo": [-71.2, -30.2],
        "Southern Chile": [-72.5, -37.5], "Maipo Valley": [-70.7, -33.7], "Maipo": [-70.7, -33.7],
        "Casablanca Valley": [-71.4, -33.3], "Casablanca": [-71.4, -33.3], "Colchagua Valley": [-71.3, -34.65],
        "Colchagua": [-71.3, -34.65], "Rapel Valley": [-71.0, -34.4], "Maule Valley": [-71.6, -35.5],
        "Limarí Valley": [-71.3, -30.6], "Elqui Valley": [-70.8, -30.0], "Leyda Valley": [-71.55, -33.6],
        "San Antonio Valley": [-71.55, -33.6], "Curicó Valley": [-71.2, -35.0], "Itata Valley": [-72.4, -36.6],
        "Bío-Bío Valley": [-72.4, -37.3],
    },
    "Argentina": {
        "Jujuy": [-65.4, -23.7], "La Rioja": [-67.5, -29.2], "Mendoza": [-68.8, -33.5],
        "Uco Valley": [-69.2, -33.6], "Patagonia": [-67.5, -39.0], "Neuquén": [-68.4, -38.9],
        "Río Negro": [-67.6, -39.1], "Salta": [-66.0, -25.9], "Cafayate": [-65.97, -26.07],
        "San Juan": [-68.5, -31.5], "Catamarca": [-66.9, -27.6],
    },
    "Brazil": {
        "Campanha Gaúcha": [-55.5, -30.9], "Minas Gerais": [-45.4, -21.8], "Rio Grande do Sul": [-51.5, -29.5],
        "Santa Catarina": [-50.9, -27.6], "Serra Gaúcha": [-51.5, -29.1], "Serra do Sudeste": [-53.0, -31.0],
        "São Paulo": [-46.8, -22.8], "Vale dos Vinhedos": [-51.55, -29.18], "Vale do São Francisco": [-40.5, -9.4],
    },
    "Uruguay": {"Canelones": [-56.2, -34.5], "Maldonado": [-55.0, -34.8], "Montevideo": [-56.2, -34.85],
                "San José": [-56.7, -34.4], "Colonia": [-57.8, -34.4], "Rivera": [-55.5, -30.9]},
    "Peru": {"Ica": [-75.7, -14.1]},
    "Bolivia": {"Tarija": [-64.7, -21.5]},
    "Australia": {
        "New South Wales": [150.5, -32.8], "Hunter Valley": [151.2, -32.8], "South Australia": [138.9, -34.6],
        "Barossa Valley": [138.95, -34.55], "Barossa": [138.95, -34.55], "McLaren Vale": [138.55, -35.2],
        "Clare Valley": [138.6, -33.8], "Coonawarra": [140.83, -37.28], "Adelaide Hills": [138.8, -34.95],
        "South Eastern Australia": [144.0, -35.5], "Tasmania": [147.2, -41.8], "Victoria": [145.0, -37.5],
        "Yarra Valley": [145.5, -37.7], "Western Australia": [115.2, -33.9], "Margaret River": [115.1, -33.95],
    },
    "New Zealand": {
        "Canterbury": [172.6, -43.3], "Hawke's Bay": [176.8, -39.6], "Marlborough": [173.9, -41.5],
        "Nelson": [173.1, -41.3], "Wairarapa": [175.5, -41.2], "Martinborough": [175.45, -41.2],
        "Central Otago": [169.2, -45.0], "Gisborne": [177.9, -38.6], "Auckland": [174.6, -36.8],
    },
    "South Africa": {"Western Cape": [18.9, -33.9], "Stellenbosch": [18.86, -33.93], "Swartland": [18.7, -33.35],
                     "Paarl": [18.97, -33.73], "Franschhoek": [19.12, -33.9], "Constantia": [18.42, -34.03],
                     "Walker Bay": [19.25, -34.4], "Elgin": [19.05, -34.15]},
    "China": {"Ningxia": [106.0, 38.4], "Shandong": [121.0, 37.3], "Xinjiang": [87.6, 43.8]},
    "Japan": {"Yamanashi": [138.6, 35.65], "Hokkaido": [141.35, 43.06]},
    "India": {"Nashik": [73.8, 20.0]},
}


def decode_land(topo):
    """The merged land as rings, holes included (the Caspian), each a list of (lon, lat)."""
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

    rings = []
    for geometry in topo["objects"]["land"]["geometries"]:
        polygons = {"Polygon": [geometry.get("arcs", [])],
                    "MultiPolygon": geometry.get("arcs", [])}.get(geometry["type"], [])
        for polygon in polygons:
            rings.extend(ring(indices) for indices in polygon)
    return rings, ring, arcs


def country_rings(topo, ring):
    shapes = {}
    for geometry in topo["objects"]["countries"]["geometries"]:
        polygons = {"Polygon": [geometry.get("arcs", [])],
                    "MultiPolygon": geometry.get("arcs", [])}.get(geometry["type"], [])
        shapes[geometry["properties"]["name"]] = [ring(rings[0]) for rings in polygons if rings]
    return shapes


def centroid(ring):
    """The area-weighted middle of a ring (shoelace)."""
    area = cx = cy = 0.0
    for (x0, y0), (x1, y1) in zip(ring, ring[1:] + ring[:1]):
        cross = x0 * y1 - x1 * y0
        area += cross
        cx += (x0 + x1) * cross
        cy += (y0 + y1) * cross
    if abs(area) < 1e-9:
        xs, ys = zip(*ring)
        return [sum(xs) / len(xs), sum(ys) / len(ys)]
    return [cx / (3 * area), cy / (3 * area)]


def area(ring):
    return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(ring, ring[1:] + ring[:1])))


def unwrap(points):
    """A ring that crosses the 180° meridian (Chukotka, Fiji) keeps going east past 180 instead of jumping back
    across the whole map; the part past the frame falls outside the drawing."""
    out, shift = [], 0.0
    for i, (lon, lat) in enumerate(points):
        if i and abs(lon + shift - out[-1][0]) > 180:
            shift += 360 if out[-1][0] > lon + shift else -360
        out.append((lon + shift, lat))
    return out


def simplify(ring, tolerance):
    """Douglas-Peucker on a closed ring, keeping its two farthest points so the ring stays closed."""
    def distance(p, a, b):
        dx, dy = b[0] - a[0], b[1] - a[1]
        if dx == dy == 0:
            return ((p[0] - a[0]) ** 2 + (p[1] - a[1]) ** 2) ** 0.5
        t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
        return ((p[0] - a[0] - t * dx) ** 2 + (p[1] - a[1] - t * dy) ** 2) ** 0.5

    def line(points):
        keep = [False] * len(points)
        keep[0] = keep[-1] = True
        stack = [(0, len(points) - 1)]
        while stack:
            start, end = stack.pop()
            far, index = 0.0, None
            for i in range(start + 1, end):
                d = distance(points[i], points[start], points[end])
                if d > far:
                    far, index = d, i
            if index is not None and far > tolerance:
                keep[index] = True
                stack += [(start, index), (index, end)]
        return [p for p, k in zip(points, keep) if k]

    if len(ring) < 4:
        return ring
    opposite = max(range(len(ring)), key=lambda i: (ring[i][0] - ring[0][0]) ** 2 + (ring[i][1] - ring[0][1]) ** 2)
    return line(ring[:opposite + 1])[:-1] + line(ring[opposite:] + ring[:1])[:-1]


def flat(points):
    out, last = [], None
    for lon, lat in points:
        point = (round(lon, 2), round(lat, 2))
        if point != last:
            out.extend(point)
        last = point
    return out


def main():
    topo = json.load(open(ATLAS))
    rings, ring, _ = decode_land(topo)
    kept = []
    for r in rings:
        r = unwrap(r)
        if len(r) < 4 or not ANTARCTIC < centroid(r)[1] < ARCTIC or area(r) / 2 < SMALLEST_ISLAND:
            continue
        r = simplify(r, SIMPLIFY)
        if len(r) < 4:
            continue
        # A piece of an island cut by the 180° meridian (Fiji) joins the rest of it, east of 180.
        if min(lon for lon, _ in r) < -180:
            r = [(lon + 360, lat) for lon, lat in r]
        kept.append(r)
    lons = [lon for r in kept for lon, _ in r]
    lats = [lat for r in kept for _, lat in r]
    box = [round(min(lons) - 0.5, 2), round(min(lats) - 0.5, 2), round(max(lons) + 0.5, 2), round(max(lats) + 0.5, 2)]
    land = [flat(r) for r in kept]

    countries = {}
    for name, shapes in country_rings(topo, ring).items():
        if not shapes or name == "Antarctica":
            continue
        middle = [round(v, 2) for v in centroid(max(shapes, key=area))]
        for alias in [name] + COUNTRY_NAMES.get(name, []):
            countries[alias] = middle
    countries.update(SMALL_COUNTRIES)

    places = [{"name": region, "country": country, "at": at}
              for country, regions in PLACES.items() for region, at in regions.items()]

    with open(OUT, "w") as f:
        json.dump({"box": box, "land": land, "countries": countries, "places": places}, f,
                  ensure_ascii=False, separators=(",", ":"))
    print(f"box {box}, {len(land)} rings, {sum(len(r) for r in land) // 2} points, {len(countries)} countries, {len(places)} places, "
          f"{os.path.getsize(OUT) // 1024} KB")


if __name__ == "__main__":
    main()
