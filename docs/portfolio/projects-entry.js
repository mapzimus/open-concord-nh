// ── ADD THIS OBJECT to js/projects.js (mapzimus/maxwellhowegis) ──
// Insert it near the top of the projects array, after id:17 (Quabbin).
// Bump this id if 18 is already taken.

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
  thumb: "images/projects/open-concord-thumb.png",
  gallery: [],
  liveUrl: "concord.html",
  repoUrl: "https://github.com/mapzimus/open-concord-nh",
  status: "in development"
},
