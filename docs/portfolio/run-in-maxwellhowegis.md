# Claude Code prompt — run this from the root of mapzimus/maxwellhowegis
#
#   claude < docs/portfolio/run-in-maxwellhowegis.md
#   (or paste into the Claude Code chat while in that repo)

Make the following four changes to this repository. Do all of them, commit everything in one commit with the message "feat: add Open Concord NH project to portfolio", and push to main.

---

## 1. Create `concord.html` in the repo root

Create the file with exactly this content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Open Concord, NH — Geospatial Data Platform | Maxwell Howe GIS</title>
  <meta name="description" content="A full-stack R + PostGIS geospatial data platform for Concord, NH — 165 layers from city ArcGIS, Census, OpenStreetMap, CDC, EPA, and biodiversity APIs, explored through a rich Shiny interactive map.">
  <meta property="og:title" content="Open Concord, NH — Geospatial Data Platform — Maxwell Howe">
  <meta property="og:description" content="165 PostGIS layers. R Shiny map with thematic choropleths, feature inspector, draw tools, and knowledge panel. Full ETL pipeline in {targets}.">
  <meta property="og:image" content="images/projects/open-concord-thumb.png">
  <meta property="og:type" content="article">
  <link rel="icon" type="image/svg+xml" href="images/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
</head>
<body>

<nav class="nav">
  <div class="nav-inner">
    <a href="index.html" class="nav-logo">Maxwell Howe</a>
    <ul class="nav-links" id="navLinks">
      <li><a href="about.html">About</a></li>
      <li><a href="portfolio.html">Projects</a></li>
      <li><a href="gallery.html">Map Gallery</a></li>
      <li><a href="side-projects.html">Beyond GIS</a></li>
      <li><a href="fieldnotes.html">Field Notes</a></li>
      <li><a href="contact.html">Contact</a></li>
    </ul>
    <button class="nav-hamburger" id="hamburger" aria-label="Menu">
      <span></span><span></span><span></span>
    </button>
  </div>
</nav>

<main id="main-content">

  <section class="section project-hero">
    <div class="section-label">// GIS Data Platform · R + PostGIS + MapLibre</div>
    <h1>Open Concord, <span class="gradient">NH</span></h1>
    <div class="project-meta">
      <span>Self-directed GIS Platform</span>
      <span>·</span>
      <span>2025–2026</span>
      <span>·</span>
      <span>165 Layers · MIT Open Source</span>
    </div>
    <div class="project-desc">
      <p>
        Open Concord is a full-stack geospatial data platform for Concord, New Hampshire,
        built entirely in R. A <code>{targets}</code> ETL pipeline acquires every public
        dataset touching the city — the municipal ArcGIS REST server (~91 layers: parcels,
        zoning, roads, utilities), federal and state ArcGIS services (USA Structures, FEMA
        NFHL, conservation lands, historic districts), OpenStreetMap, US Census ACS 2023,
        CDC PLACES health indicators, EPA FRS, USGS streamgages, GBIF biodiversity
        occurrences, and Wikidata/Wikipedia knowledge — and loads each into a self-hosted
        PostGIS database tagged as <em>map+db</em> (rendered on the map) or <em>db</em>
        (joined reference table).
      </p>
      <p>
        The frontend is an R Shiny app (bslib + mapgl) that queries PostGIS live. It ships
        with four capability panels: a searchable layer accordion, a thematic choropleth
        picker (ACS income, population, rent; CDC mental health), an analysis toolset
        (Nominatim geocoder, SQL filter builder, draw-to-measure, GeoJSON/CSV export), and
        a Knowledge tab surfacing Wikidata facts and notable people for Concord. Click any
        feature and a right-side inspector opens with the full attribute table and
        Wikipedia cross-links.
      </p>
    </div>
    <div class="project-tools">
      <span class="project-tag">R</span>
      <span class="project-tag">PostGIS</span>
      <span class="project-tag">MapLibre GL</span>
      <span class="project-tag">Shiny</span>
      <span class="project-tag">bslib</span>
      <span class="project-tag">mapgl</span>
      <span class="project-tag">targets</span>
      <span class="project-tag">sf</span>
      <span class="project-tag">arcgislayers</span>
      <span class="project-tag">tidycensus</span>
      <span class="project-tag">osmdata</span>
      <span class="project-tag">httr2</span>
      <span class="project-tag">Docker</span>
    </div>
    <div style="display:flex;gap:12px;flex-wrap:wrap;margin-top:24px;">
      <a href="https://github.com/mapzimus/open-concord-nh" target="_blank" rel="noopener"
         class="btn">View on GitHub ↗</a>
      <a href="portfolio.html" class="btn btn-secondary">← Back to Portfolio</a>
    </div>
  </section>

  <section class="section">
    <div class="section-header fade-in">
      <div class="section-label">// System Design</div>
      <h2 class="section-title">Architecture</h2>
    </div>
    <div class="project-desc fade-in">
      <p>
        The pipeline is a three-stage system: acquire, store, serve. Eight target groups
        (<code>concord</code>, <code>external</code>, <code>osm</code>, <code>apis</code>,
        <code>schools</code>, <code>knowledge</code>, <code>business</code>, <code>web</code>)
        run under <code>targets::tar_make()</code> with full dependency tracking — rerunning
        only what changed. Every load writes to a named PostGIS schema and upserts a row in
        <code>public.catalog</code>, which the Shiny app reads on startup to discover available
        layers.
      </p>
      <p>
        Self-hosting runs via <code>docker compose</code>: PostGIS + Shiny Server + Caddy TLS
        on a VPS, with the app served at <code>concord.maxwellhowegis.com</code>. Optional
        <code>--profile api</code> adds <code>pg_tileserv</code> and
        <code>pg_featureserv</code> for vector-tile performance at scale.
      </p>
    </div>
    <figure style="margin:32px 0;text-align:center;">
      <pre style="display:inline-block;text-align:left;background:#0d1117;color:#7dd3fc;
                  padding:28px 36px;border-radius:12px;font-family:'JetBrains Mono',monospace;
                  font-size:.82rem;line-height:1.75;box-shadow:0 8px 30px rgba(0,0,0,.3);
                  max-width:660px;width:100%;overflow-x:auto;">
 R package (openconcord)     live queries      R Shiny app
 ┌─────────────────────┐   ┌──────────────┐  ┌──────────────────┐
 │ targets::tar_make() │──►│   PostGIS    │◄─│  shiny/app.R     │
 │  oc_load_concord()  │ETL│  + catalog   │  │  bslib + mapgl   │
 │  oc_load_external() │   │  165 layers  │  │  (MapLibre GL)   │
 │  oc_load_apis() ... │   └──────────────┘  └────────┬─────────┘
 └─────────────────────┘                              │ Caddy TLS
                                           concord.maxwellhowegis.com</pre>
      <figcaption style="margin-top:14px;font-size:.85rem;color:#888;">
        ETL → PostGIS → Shiny frontend. The catalog table self-describes all loaded layers.
      </figcaption>
    </figure>
  </section>

  <section class="section">
    <div class="section-header fade-in">
      <div class="section-label">// Four Capability Panels</div>
      <h2 class="section-title">What the Map Can Do</h2>
    </div>
    <div class="project-desc fade-in" style="margin-bottom:32px;">
      <p>The Shiny app sidebar carries four tabs. Each is server-rendered from live PostGIS data — no bundled GeoJSON, no static tiles.</p>
    </div>
    <div class="fade-in" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:20px;">
      <div style="background:#0d1117;border:1px solid #1e2a3a;border-radius:12px;padding:22px;">
        <div style="font-size:1.3rem;margin-bottom:10px;">🗂</div>
        <h3 style="font-size:1rem;font-weight:600;margin-bottom:8px;color:#e2e8f0;">Layers</h3>
        <p style="font-size:.875rem;color:#94a3b8;line-height:1.6;">Searchable accordion grouped by schema (city, external, osm, apis, schools, knowledge). Each layer shows a live feature count, color-coded dot, and a checkbox. Toggle-all per group. 3D building extrusion toggle for ~15,500 LiDAR-height footprints.</p>
      </div>
      <div style="background:#0d1117;border:1px solid #1e2a3a;border-radius:12px;padding:22px;">
        <div style="font-size:1.3rem;margin-bottom:10px;">🎨</div>
        <h3 style="font-size:1rem;font-weight:600;margin-bottom:8px;color:#e2e8f0;">Thematic</h3>
        <p style="font-size:.875rem;color:#94a3b8;line-height:1.6;">Choropleth picker for census tracts: ACS median income, total population, median rent, and CDC PLACES mental-health prevalence. Data-driven step expression via MapLibre, with a live color-ramp legend and break labels.</p>
      </div>
      <div style="background:#0d1117;border:1px solid #1e2a3a;border-radius:12px;padding:22px;">
        <div style="font-size:1.3rem;margin-bottom:10px;">🔧</div>
        <h3 style="font-size:1rem;font-weight:600;margin-bottom:8px;color:#e2e8f0;">Tools</h3>
        <p style="font-size:.875rem;color:#94a3b8;line-height:1.6;">Nominatim geocoder (no API key). SQL filter builder with column picker from PostGIS information_schema. Draw toolbar: polygon → area (acres), perimeter (ft), per-layer feature counts via <code>ST_Intersects</code>. GeoJSON &amp; CSV export.</p>
      </div>
      <div style="background:#0d1117;border:1px solid #1e2a3a;border-radius:12px;padding:22px;">
        <div style="font-size:1.3rem;margin-bottom:10px;">📖</div>
        <h3 style="font-size:1rem;font-weight:600;margin-bottom:8px;color:#e2e8f0;">Knowledge</h3>
        <p style="font-size:.875rem;color:#94a3b8;line-height:1.6;">Wikidata facts about Concord (Q28249) displayed as a property table. Notable people chips linked to Wikipedia. Click any feature on the map and a right-panel inspector shows the full attribute table with Wikipedia cross-links for knowledge-layer features.</p>
      </div>
    </div>
  </section>

  <section class="section">
    <div class="section-header fade-in">
      <div class="section-label">// Eight Source Families</div>
      <h2 class="section-title">Data Sources</h2>
    </div>
    <div class="fade-in" style="overflow-x:auto;">
      <table style="width:100%;border-collapse:collapse;font-size:.875rem;">
        <thead>
          <tr style="border-bottom:2px solid #1e2a3a;color:#94a3b8;text-align:left;">
            <th style="padding:10px 14px;font-weight:500;">Source</th>
            <th style="padding:10px 14px;font-weight:500;">Schema</th>
            <th style="padding:10px 14px;font-weight:500;">What</th>
            <th style="padding:10px 14px;font-weight:500;">License</th>
          </tr>
        </thead>
        <tbody style="color:#e2e8f0;">
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">City of Concord ArcGIS</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">city</td><td style="padding:10px 14px;">~91 layers: parcels, zoning, roads, utilities, trees</td><td style="padding:10px 14px;color:#94a3b8;">Public records</td></tr>
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">Federal / state ArcGIS</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">external</td><td style="padding:10px 14px;">USA Structures, FEMA NFHL, conservation, historic</td><td style="padding:10px 14px;color:#94a3b8;">Public domain</td></tr>
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">OpenStreetMap</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">osm</td><td style="padding:10px 14px;">Roads, buildings, POIs, businesses</td><td style="padding:10px 14px;color:#94a3b8;">ODbL</td></tr>
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">US Census ACS + TIGER</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">apis</td><td style="padding:10px 14px;">Demographics, tracts, school districts</td><td style="padding:10px 14px;color:#94a3b8;">Public domain</td></tr>
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">CDC PLACES 2023</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">apis</td><td style="padding:10px 14px;">Tract-level health indicators (27 measures)</td><td style="padding:10px 14px;color:#94a3b8;">Public domain</td></tr>
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">EPA FRS · USGS · NWS</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">apis</td><td style="padding:10px 14px;">Facilities, streamgages, earthquakes, weather alerts</td><td style="padding:10px 14px;color:#94a3b8;">Public domain</td></tr>
          <tr style="border-bottom:1px solid #1e2a3a;"><td style="padding:10px 14px;">GBIF · iNaturalist</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">apis</td><td style="padding:10px 14px;">Biodiversity occurrences</td><td style="padding:10px 14px;color:#94a3b8;">CC-BY / CC0</td></tr>
          <tr><td style="padding:10px 14px;">Wikidata · Wikipedia</td><td style="padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:.8rem;color:#7dd3fc;">knowledge</td><td style="padding:10px 14px;">Notable people, facts, history</td><td style="padding:10px 14px;color:#94a3b8;">CC0 / CC-BY-SA</td></tr>
        </tbody>
      </table>
    </div>
  </section>

  <section class="section parallax-section">
    <div class="section-header fade-in">
      <div class="section-label">// Reproducible by Design</div>
      <h2 class="section-title">The {targets} Pipeline</h2>
    </div>
    <div class="project-desc fade-in">
      <p>The ETL is structured as a <code>{targets}</code> pipeline with nine named targets, each corresponding to a source family. Running <code>targets::tar_make()</code> on a fresh PostGIS instance downloads and loads every layer in order, skipping any target whose inputs haven't changed. Every load records itself in <code>public.catalog</code> with a <code>validated</code> flag that gets flipped after the per-dataset visual QA check.</p>
      <p>Helper functions handle the cross-cutting concerns: <code>oc_arc_layer()</code> pages through ArcGIS REST with a bounding-box filter; <code>oc_write_layer()</code> upserts to PostGIS with consistent SRID 4326 enforcement and catalog registration; <code>oc_connect()</code> uses libpq env vars so no credentials live in source control.</p>
    </div>
  </section>

  <section class="section">
    <div class="section-header fade-in">
      <div class="section-label">// Current Status</div>
      <h2 class="section-title">In Development</h2>
    </div>
    <div class="project-desc fade-in">
      <p>The R codebase is complete and all ETL functions are written against known package APIs. The Shiny v3 interface has been fully implemented with all four capability panels. The live deployment to <code>concord.maxwellhowegis.com</code> — first run of <code>tar_make()</code> on the VPS, per-dataset validation, and Caddy TLS setup — is the next step.</p>
      <p>A GitHub Actions CI workflow runs on every push: R source syntax checks, offline config unit tests (no DB required), and lintr style linting.</p>
    </div>
    <div class="fade-in" style="display:flex;gap:12px;flex-wrap:wrap;margin-top:8px;">
      <a href="https://github.com/mapzimus/open-concord-nh" target="_blank" rel="noopener" class="btn">Browse the Source on GitHub ↗</a>
      <a href="portfolio.html" class="btn btn-secondary">← Back to Portfolio</a>
    </div>
  </section>

</main>

<footer class="footer">
  <div class="footer-inner">
    <p>&copy; 2026 Maxwell Howe</p>
    <ul class="footer-links">
      <li><a href="index.html">Home</a></li>
      <li><a href="portfolio.html">Projects</a></li>
      <li><a href="gallery.html">Map Gallery</a></li>
      <li><a href="contact.html">Contact</a></li>
    </ul>
  </div>
</footer>

<script src="js/main.js"></script>
</body>
</html>
```

---

## 2. Create `images/projects/open-concord-thumb.svg`

Create this file (the portfolio card thumbnail):

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 250" width="400" height="250">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#0d1117"/>
      <stop offset="100%" stop-color="#0f172a"/>
    </linearGradient>
    <linearGradient id="grd" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#3b82f6"/>
      <stop offset="100%" stop-color="#8b5cf6"/>
    </linearGradient>
    <clipPath id="map-clip">
      <rect x="90" y="0" width="310" height="250"/>
    </clipPath>
  </defs>
  <rect width="400" height="250" fill="url(#bg)"/>
  <g clip-path="url(#map-clip)" opacity="0.15">
    <line x1="130" y1="0" x2="130" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="170" y1="0" x2="170" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="210" y1="0" x2="210" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="250" y1="0" x2="250" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="290" y1="0" x2="290" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="330" y1="0" x2="330" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="370" y1="0" x2="370" y2="250" stroke="#334155" stroke-width="0.5"/>
    <line x1="90" y1="50" x2="400" y2="50" stroke="#334155" stroke-width="0.5"/>
    <line x1="90" y1="100" x2="400" y2="100" stroke="#334155" stroke-width="0.5"/>
    <line x1="90" y1="150" x2="400" y2="150" stroke="#334155" stroke-width="0.5"/>
    <line x1="90" y1="200" x2="400" y2="200" stroke="#334155" stroke-width="0.5"/>
  </g>
  <g opacity="0.5">
    <path d="M 110,80 Q 160,60 200,75 Q 240,90 290,70 Q 330,55 380,65" fill="none" stroke="#475569" stroke-width="1.5"/>
    <path d="M 120,125 L 380,125" fill="none" stroke="#475569" stroke-width="2"/>
    <path d="M 200,20 L 200,230" fill="none" stroke="#475569" stroke-width="1.5"/>
    <path d="M 155,20 Q 150,80 160,125 Q 165,175 150,230" fill="none" stroke="#475569" stroke-width="1"/>
    <path d="M 270,20 Q 268,80 265,125 Q 262,175 268,230" fill="none" stroke="#475569" stroke-width="1"/>
    <path d="M 110,170 Q 180,165 230,175 Q 290,185 380,175" fill="none" stroke="#475569" stroke-width="1"/>
  </g>
  <g opacity="0.65">
    <polygon points="110,30 200,30 200,125 110,125" fill="#1e40af" opacity="0.5"/>
    <polygon points="200,30 290,30 290,125 200,125" fill="#2563eb" opacity="0.45"/>
    <polygon points="290,30 400,30 400,125 290,125" fill="#3b82f6" opacity="0.4"/>
    <polygon points="110,125 200,125 200,220 110,220" fill="#1d4ed8" opacity="0.55"/>
    <polygon points="200,125 290,125 290,220 200,220" fill="#60a5fa" opacity="0.35"/>
    <polygon points="290,125 400,125 400,220 290,220" fill="#93c5fd" opacity="0.3"/>
  </g>
  <g fill="none" stroke="#1e3a5f" stroke-width="0.8" opacity="0.7">
    <rect x="110" y="30" width="90" height="95"/>
    <rect x="200" y="30" width="90" height="95"/>
    <rect x="290" y="30" width="110" height="95"/>
    <rect x="110" y="125" width="90" height="95"/>
    <rect x="200" y="125" width="90" height="95"/>
    <rect x="290" y="125" width="110" height="95"/>
  </g>
  <circle cx="160" cy="75" r="4" fill="#f59e0b" opacity="0.9"/>
  <circle cx="240" cy="95" r="4" fill="#f59e0b" opacity="0.9"/>
  <circle cx="320" cy="65" r="4" fill="#f59e0b" opacity="0.9"/>
  <circle cx="175" cy="165" r="5" fill="#22c55e" opacity="0.85"/>
  <circle cx="330" cy="175" r="4" fill="#22c55e" opacity="0.85"/>
  <circle cx="210" cy="140" r="5.5" fill="#f43f5e" opacity="0.9"/>
  <circle cx="260" cy="110" r="3.5" fill="#f43f5e" opacity="0.8"/>
  <circle cx="145" cy="195" r="3.5" fill="#a78bfa" opacity="0.85"/>
  <circle cx="360" cy="140" r="3.5" fill="#a78bfa" opacity="0.85"/>
  <circle cx="210" cy="140" r="10" fill="none" stroke="#f43f5e" stroke-width="1.5" opacity="0.4"/>
  <circle cx="210" cy="140" r="16" fill="none" stroke="#f43f5e" stroke-width="0.8" opacity="0.2"/>
  <rect x="0" y="0" width="90" height="250" fill="#0f172a"/>
  <line x1="90" y1="0" x2="90" y2="250" stroke="#1e2a3a" stroke-width="1"/>
  <rect x="6" y="10" width="78" height="22" rx="4" fill="#1e3a5f"/>
  <text x="45" y="25" text-anchor="middle" fill="#7dd3fc" font-size="8" font-family="'JetBrains Mono', monospace" font-weight="500">Layers</text>
  <rect x="6" y="34" width="37" height="18" rx="3" fill="#0d1117"/>
  <text x="24" y="46" text-anchor="middle" fill="#64748b" font-size="7" font-family="'JetBrains Mono', monospace">Thematic</text>
  <rect x="46" y="34" width="38" height="18" rx="3" fill="#0d1117"/>
  <text x="65" y="46" text-anchor="middle" fill="#64748b" font-size="7" font-family="'JetBrains Mono', monospace">Tools</text>
  <g font-family="'Inter', sans-serif" font-size="7">
    <rect x="8" y="60" width="6" height="6" rx="1" fill="#2563eb"/>
    <text x="18" y="67" fill="#94a3b8">city.parcels</text>
    <rect x="8" y="72" width="6" height="6" rx="1" fill="#22c55e"/>
    <text x="18" y="79" fill="#94a3b8">osm.parks</text>
    <rect x="8" y="84" width="6" height="6" rx="1" fill="#f59e0b"/>
    <text x="18" y="91" fill="#94a3b8">schools</text>
    <rect x="8" y="96" width="6" height="6" rx="1" fill="#f43f5e"/>
    <text x="18" y="103" fill="#94a3b8">city.roads</text>
    <rect x="8" y="108" width="6" height="6" rx="1" fill="#a78bfa"/>
    <text x="18" y="115" fill="#94a3b8">knowledge</text>
    <text x="8" y="128" fill="#475569">+ 160 more…</text>
  </g>
  <rect x="0" y="234" width="400" height="16" fill="#0a0f1a"/>
  <text x="95" y="245" fill="#334155" font-size="7" font-family="'JetBrains Mono', monospace">165 layers · PostGIS · Concord, NH  43.2°N 71.5°W</text>
  <text x="395" y="16" text-anchor="end" fill="#3b82f6" font-size="9" font-family="'JetBrains Mono', monospace" font-weight="500" opacity="0.7">Open Concord NH</text>
  <rect x="90" y="0" width="310" height="3" fill="url(#grd)" opacity="0.6"/>
</svg>
```

---

## 3. Edit `js/projects.js`

Find the `projects` array. Insert the following object **after the entry with `id: 17`** (the Quabbin project). If id 18 is already taken, use the next available id.

```javascript
  {
    id: 18,
    era: "current",
    title: "Open Concord, NH",
    category: "GIS Data Platform",
    type: "map",
    tags: ["R", "PostGIS", "MapLibre GL", "Shiny", "targets", "ETL Pipeline", "165 Layers"],
    summary: "Full-stack R + PostGIS geospatial data platform for Concord, NH — 165 layers from city ArcGIS, federal, OSM, Census, CDC, EPA, biodiversity, and knowledge APIs, explored through a rich interactive Shiny map.",
    description: "A complete, self-hosted GIS data platform for Concord, NH built entirely in R. A {targets} ETL pipeline acquires every public dataset — city ArcGIS (~91 layers: parcels, zoning, roads, utilities), federal/state ArcGIS, OpenStreetMap, US Census ACS 2023, CDC PLACES health indicators, EPA FRS, USGS streamgages, GBIF biodiversity, and Wikidata/Wikipedia — loading each into PostGIS tagged as map+db or db. The R Shiny frontend (bslib + mapgl) queries PostGIS live with four panels: a searchable layer accordion, a thematic choropleth picker (ACS income/population/rent, CDC mental health), analysis tools (Nominatim geocoder, SQL filter, draw-to-measure, GeoJSON/CSV export), and a Knowledge tab with Wikidata facts and notable people. Click any feature → right-panel inspector with full attributes and Wikipedia links.",
    tools: ["R", "PostGIS", "Shiny", "bslib", "mapgl", "MapLibre GL", "targets", "sf", "arcgislayers", "tidycensus", "osmdata", "httr2", "Docker", "Caddy"],
    year: "2025–2026",
    thumb: "images/projects/open-concord-thumb.svg",
    gallery: [],
    liveUrl: "concord.html",
    repoUrl: "https://github.com/mapzimus/open-concord-nh",
    status: "in development"
  },
```

---

## 4. Edit `index.html`

Find the `<div class="building-pills">` section. Add this pill as the last item inside it (before the closing `</div>`):

```html
            <a href="concord.html" class="building-pill status-dev">Open Concord NH — in dev</a>
```

---

After making all four changes, commit with:
```
feat: add Open Concord NH project to portfolio
```
and push to main.
