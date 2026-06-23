# Open Concord — Shiny frontend v3 ("full studio")
# =================================================
# MapLibre GL (via {mapgl}) + bslib Bootstrap 5. Four-tab sidebar:
#   Layers   — collapsible legend with search, feature counts, 3D toggle
#   Thematic — choropleth overlays (ACS / CDC PLACES)
#   Tools    — filter builder, draw-to-measure, export
#   Knowledge— Wikidata facts, notable people
# Plus: Nominatim geocoder, coordinate readout, permalink share, and a
# right-side inspector panel that opens on feature click.
#
# v2 (single-sidebar) retained at app-leaflet-v1.R; v2 code was preserved
# in git history. R not installed in the build container — validate locally:
#   shiny::runApp("shiny", host="127.0.0.1", port=3838)

library(shiny)
library(bslib)
library(mapgl)
library(sf)
library(DBI)
library(pool)
library(httr2)
library(jsonlite)

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# ---- DB pool ----------------------------------------------------------------
pool <- dbPool(
  RPostgres::Postgres(),
  host     = Sys.getenv("PGHOST",     "localhost"),
  port     = as.integer(Sys.getenv("PGPORT", "5432")),
  dbname   = Sys.getenv("PGDATABASE", "openconcord"),
  user     = Sys.getenv("PGUSER",     "openconcord"),
  password = Sys.getenv("PGPASSWORD", "")
)
onStop(function() poolClose(pool))

# ---- constants --------------------------------------------------------------
CATEGORIES <- list(
  city      = list(label = "City of Concord", color = "#2563eb"),
  schools   = list(label = "Schools",         color = "#dc2626"),
  business  = list(label = "Business",        color = "#db2777"),
  osm       = list(label = "OpenStreetMap",   color = "#7c3aed"),
  external  = list(label = "Federal & state", color = "#059669"),
  apis      = list(label = "APIs & sensors",  color = "#d97706"),
  knowledge = list(label = "Knowledge",       color = "#0891b2"),
  web       = list(label = "Web exports",     color = "#475569")
)
CATEGORY_ORDER <- names(CATEGORIES)
CONCORD_CENTER <- c(-71.538, 43.207)
DOWNTOWN       <- c(-71.5374, 43.2069)
CONCORD_BBOX   <- c(xmin = -71.668185, ymin = 43.151772,
                    xmax = -71.456903, ymax = 43.309419)

SATELLITE_STYLE <- list(
  version = 8,
  sources = list(esri = list(
    type = "raster", tileSize = 256,
    tiles = list("https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"),
    attribution = "Esri, Maxar, Earthstar Geographics")),
  layers = list(list(id = "esri-bg", type = "raster", source = "esri"))
)

CHOROPLETHS <- list(
  none = list(label = "None — remove overlay"),
  acs_income = list(
    label   = "Median household income (ACS)",
    schema  = "apis", table = "acs_tracts",
    col     = "median_household_incomeE",
    palette = c("#f7f7f7", "#d1e5f0", "#92c5de", "#4393c3", "#2166ac"),
    breaks  = c(30000, 50000, 70000, 90000, 120000),
    unit    = "$/yr", na_color = "#cccccc"
  ),
  acs_population = list(
    label   = "Total population (ACS)",
    schema  = "apis", table = "acs_tracts",
    col     = "total_populationE",
    palette = c("#f7f7f7", "#c7e9b4", "#7fcdbb", "#2c7fb8", "#253494"),
    breaks  = c(0, 2000, 4000, 6000, 10000),
    unit    = "people", na_color = "#cccccc"
  ),
  acs_rent = list(
    label   = "Median gross rent (ACS)",
    schema  = "apis", table = "acs_tracts",
    col     = "median_gross_rentE",
    palette = c("#f7f7f7", "#fee090", "#fc8d59", "#d73027"),
    breaks  = c(600, 900, 1200, 1500),
    unit    = "$/mo", na_color = "#cccccc"
  ),
  cdc_mental = list(
    label   = "CDC PLACES: mental health (% poor)",
    schema  = "apis", table = "cdc_places_tracts_poly",
    col     = "MHLTH_CrudePrev",
    palette = c("#f7f7f7", "#fee8c8", "#fdbb84", "#e34a33"),
    breaks  = c(10, 15, 20, 25),
    unit    = "%", na_color = "#cccccc"
  )
)

# ---- CSS + JS ---------------------------------------------------------------
OC_CSS <- "
html,body{height:100%;margin:0;overflow:hidden}
.bslib-page-fill{height:100vh}
.layout-sidebar>.sidebar-content{padding:0!important}
.oc-map-wrapper{position:relative;height:100%;display:flex;flex-direction:column}
.oc-topbar{display:flex;align-items:center;gap:8px;height:46px;padding:0 10px;
  border-bottom:1px solid #e5e7eb;background:#fff;flex-shrink:0;flex-wrap:nowrap;overflow:hidden}
.oc-title{font-weight:700;font-size:15px;letter-spacing:-.01em;white-space:nowrap;color:#111827}
.oc-geocoder{display:flex;gap:4px;flex:1;min-width:0}
.oc-geocoder .form-control{font-size:12.5px;height:30px;padding:3px 8px}
.oc-geocoder .btn{height:30px;padding:3px 9px;font-size:12.5px;flex-shrink:0}
.oc-geo-results{position:absolute;top:46px;left:320px;z-index:600;background:#fff;
  border:1px solid #e5e7eb;border-radius:8px;box-shadow:0 6px 20px rgba(0,0,0,.12);
  min-width:280px;max-width:420px;overflow:hidden}
.oc-geo-item{display:block;padding:7px 12px;font-size:12.5px;color:#111827;text-decoration:none;
  border-bottom:1px solid #f3f4f6;cursor:pointer;background:none;border-left:0;border-right:0;border-top:0;width:100%;text-align:left}
.oc-geo-item:hover{background:#f0f4ff;color:#1d4ed8}
.oc-geo-no-result{padding:10px 14px;font-size:12.5px;color:#9ca3af}
.oc-map-area{position:relative;flex:1;min-height:0}
.maplibregl-map,.html-widget{height:100%!important}
.oc-coord-readout{position:absolute;bottom:28px;left:10px;z-index:200;
  background:rgba(255,255,255,.84);padding:3px 8px;border-radius:5px;
  font-size:11px;pointer-events:none;color:#374151;font-family:monospace}
.oc-status{position:absolute;bottom:8px;right:10px;z-index:200;
  background:rgba(255,255,255,.88);padding:2px 8px;border-radius:5px;
  font-size:11.5px;color:#374151;max-width:480px}
.oc-inspector{position:absolute;top:8px;right:8px;width:340px;max-height:calc(100% - 16px);
  overflow-y:auto;background:#fff;border-radius:10px;
  box-shadow:0 4px 22px rgba(0,0,0,.14);padding:12px 14px;z-index:500}
.oc-inspector-header{display:flex;justify-content:space-between;align-items:flex-start;
  margin-bottom:8px;gap:8px}
.oc-inspector-title{font-weight:600;font-size:13.5px;color:#111827;line-height:1.3}
.oc-inspector-cat{font-size:11px;margin-top:1px}
.btn-close-sm{background:none;border:1px solid #e5e7eb;border-radius:50%;width:22px;height:22px;
  font-size:12px;cursor:pointer;flex-shrink:0;display:flex;align-items:center;justify-content:center;color:#6b7280;padding:0}
.btn-close-sm:hover{background:#f3f4f6;color:#111827}
.inspector-row{display:flex;gap:8px;border-bottom:1px solid #f3f4f6;padding:4px 0;font-size:12.5px}
.inspector-key{color:#9ca3af;min-width:100px;flex-shrink:0;word-break:break-word}
.inspector-val{color:#111827;word-break:break-word}
.accordion{--bs-accordion-border-color:transparent}
.accordion-item{border:0;margin-bottom:1px}
.accordion-button{padding:6px 10px;font-size:13px;border-radius:7px!important;background:transparent}
.accordion-button:not(.collapsed){background:#eef2f7;color:inherit;box-shadow:none}
.accordion-button:focus{box-shadow:none}
.accordion-button::after{width:.9rem;height:.9rem;background-size:.9rem}
.accordion-body{padding:2px 10px 8px}
.form-check{margin-bottom:1px;min-height:auto}
.form-check-label{width:100%;font-size:12.5px;cursor:pointer}
.form-check-input{cursor:pointer;margin-top:.18rem}
.oc-tool-section{margin-bottom:4px}
.oc-tool-heading{font-size:12px;font-weight:600;color:#374151;text-transform:uppercase;
  letter-spacing:.04em;margin-bottom:5px}
.oc-btn-row{display:flex;gap:4px;flex-wrap:wrap;margin-top:6px}
.oc-filter-row{display:flex;gap:4px;align-items:flex-end;margin-top:3px}
.oc-filter-row .form-select,.oc-filter-row .form-control{font-size:12px}
.navset-tab>.nav{padding:4px 6px 0;gap:2px}
.navset-tab>.nav .nav-link{font-size:12.5px;padding:5px 10px;border-radius:6px 6px 0 0}
#sidebar_tab{height:100%;display:flex;flex-direction:column}
#sidebar_tab>.tab-content{flex:1;overflow-y:auto;padding:8px 10px 10px}
.maplibregl-ctrl-attrib{font-size:10px;opacity:.7}
.maplibregl-ctrl-group button{width:27px;height:27px}
#b3d_box .form-check-label{font-size:12.5px;font-weight:500}
.layer-search input{font-size:12.5px}
.choro-legend-bar{height:12px;border-radius:3px;margin-top:6px}
.choro-legend-ticks{position:relative;height:16px;margin-top:2px}
.choro-tick{position:absolute;transform:translateX(-50%);font-size:10px;color:#6b7280}
.choro-unit{font-size:10px;color:#9ca3af;margin-top:1px}
.knowledge-chip{display:inline-block;background:#eff6ff;color:#1d4ed8;border-radius:12px;
  padding:2px 9px;font-size:11.5px;margin:2px;text-decoration:none}
.knowledge-chip:hover{background:#dbeafe;color:#1d4ed8}
"

OC_JS <- "
Shiny.addCustomMessageHandler('oc_copy_clipboard', function(txt) {
  var url = location.origin + location.pathname + txt;
  if (navigator.clipboard) {
    navigator.clipboard.writeText(url).catch(function(){});
  }
});
Shiny.addCustomMessageHandler('oc_alert', function(msg) {
  // no-op: status is surfaced via output$status
});
"

# ---- helpers ----------------------------------------------------------------
nice_label <- function(table) {
  s <- gsub("_", " ", table)
  for (a in c("nhd","nwi","epa","faa","fcc","cdc","usgs","osm","usa","gbif",
               "nrhp","tiger","fema","ev","acs","lodes","nwis","nwps","nps","nlcd"))
    s <- gsub(paste0("\\b", a, "\\b"), toupper(a), s, ignore.case = TRUE)
  paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s)))
}

build_popup <- function(g, schema, table) {
  df <- sf::st_drop_geometry(g)
  df <- df[, !grepl("^(geom|geometry|wkb|globalid|objectid|gid|fid|oid|id)$|_id$|code$|^se_anno|shape[_.]",
                    names(df), ignore.case = TRUE), drop = FALSE]
  cat_label <- CATEGORIES[[schema]]$label %||% schema
  cat_color  <- CATEGORIES[[schema]]$color %||% "#475569"
  tcands <- c("name","primary_name","title","sch_name","school_name","facility","fac_name","label")
  tmatch <- match(tcands, tolower(names(df)))
  title_col <- if (any(!is.na(tmatch))) names(df)[tmatch[which(!is.na(tmatch))[1]]] else NA_character_
  vapply(seq_len(nrow(df)), function(i) {
    row  <- df[i, , drop = FALSE]
    vals <- trimws(as.character(unlist(row)))
    keep <- which(!is.na(vals) & nzchar(vals) & vals != "NA" & nchar(vals) <= 80)
    if (!is.na(title_col)) keep <- setdiff(keep, match(title_col, names(row)))
    keep  <- head(keep, 6)
    title <- if (!is.na(title_col) && nzchar(trimws(as.character(row[[title_col]]))))
               as.character(row[[title_col]]) else nice_label(table)
    rows_html <- paste0(sprintf(
      "<tr><td style='color:#6b7280;padding:1px 10px 1px 0;white-space:nowrap'>%s</td><td style='color:#111827'>%s</td></tr>",
      nice_label(names(row)[keep]), vals[keep]), collapse = "")
    sprintf("<div style='font:13px/1.45 system-ui,-apple-system,sans-serif;min-width:150px;max-width:280px'><div style='font-weight:600;color:#111827'>%s</div><div style='font-size:11px;color:%s;margin:1px 0 6px'>%s</div><table style='font-size:11.5px;border-collapse:collapse'>%s</table></div>",
            htmltools::htmlEscape(title), cat_color, cat_label, rows_html)
  }, character(1))
}

get_layer <- function(schema, table, where = "1=1") {
  con <- poolCheckout(pool); on.exit(poolReturn(con))
  q <- sprintf('SELECT * FROM "%s"."%s" WHERE %s', schema, table, where)
  g <- tryCatch(sf::st_transform(sf::st_read(con, query = q, quiet = TRUE), 4326),
                error = function(e) NULL)
  if (is.null(g) || !nrow(g)) return(g)
  gt <- as.character(sf::st_geometry_type(g, by_geometry = FALSE))
  if (!grepl("POINT", gt) && nrow(g) > 4000) {
    old <- sf::sf_use_s2(FALSE)
    g <- tryCatch(sf::st_simplify(g, dTolerance = 0.00004, preserveTopology = TRUE),
                  error = function(e) g)
    sf::sf_use_s2(old)
  }
  if (nrow(g) <= 8000) g$popup_html <- build_popup(g, schema, table)
  g
}

get_buildings <- function() {
  con <- poolCheckout(pool); on.exit(poolReturn(con))
  g <- tryCatch(sf::st_transform(sf::st_read(con, query =
    'SELECT "HEIGHT","OCC_CLS","PROP_ADDR","SQFEET", geometry FROM external.usa_structures',
    quiet = TRUE), 4326), error = function(e) NULL)
  if (is.null(g) || !nrow(g)) return(g)
  g$HEIGHT[is.na(g$HEIGHT) | g$HEIGHT < 2] <- 3
  g
}

geom_kind <- function(g) {
  gt <- as.character(sf::st_geometry_type(g, by_geometry = FALSE))
  if (grepl("POLY", gt)) "poly" else if (grepl("LINE", gt)) "line" else "point"
}

add_oc_layer <- function(proxy, id, g, color, highlight = FALSE) {
  pop <- if ("popup_html" %in% names(g)) "popup_html" else NULL
  k   <- geom_kind(g)
  if (k == "poly") {
    add_fill_layer(proxy, id = id, source = g, fill_color = color,
      fill_opacity = if (highlight) 0.5 else 0.2,
      fill_outline_color = color, popup = pop)
  } else if (k == "line") {
    add_line_layer(proxy, id = id, source = g, line_color = color,
      line_width = if (highlight) 2.6 else 1.6, line_opacity = 0.9, popup = pop)
  } else {
    add_circle_layer(proxy, id = id, source = g, circle_color = color,
      circle_radius = if (highlight) 6.5 else 4.5,
      circle_stroke_color = "#ffffff", circle_stroke_width = 1.2,
      circle_opacity = 0.9, popup = pop)
  }
}

geocode_nominatim <- function(q, bbox = CONCORD_BBOX) {
  url <- paste0(
    "https://nominatim.openstreetmap.org/search?format=json&limit=5",
    "&q=", utils::URLencode(paste(q, "Concord NH"), reserved = TRUE),
    "&viewbox=", paste(bbox[c("xmin","ymax","xmax","ymin")], collapse = ","),
    "&bounded=0")
  tryCatch({
    res <- httr2::request(url) |>
      httr2::req_user_agent("open-concord/1.0 (mhowe.gis@gmail.com)") |>
      httr2::req_timeout(8) |>
      httr2::req_perform() |>
      httr2::resp_body_json(simplifyVector = TRUE)
    if (!length(res) || !is.data.frame(res)) return(NULL)
    data.frame(label = res$display_name, lon = as.numeric(res$lon),
               lat   = as.numeric(res$lat), stringsAsFactors = FALSE)
  }, error = function(e) NULL)
}

catalog <- function() {
  tryCatch(
    DBI::dbGetQuery(pool,
      "SELECT schema_name, table_name, n_features
         FROM public.catalog
        WHERE target = 'map+db' AND n_features > 0
          AND NOT (schema_name = 'external' AND table_name = 'usa_structures')
        ORDER BY schema_name, n_features DESC"),
    error = function(e) data.frame())
}

# ---- UI ---------------------------------------------------------------------
ui <- page_fillable(
  theme = bs_theme(version = 5, primary = "#2563eb",
                   base_font    = font_google("Inter", local = FALSE),
                   heading_font = font_google("Inter", local = FALSE)),
  tags$head(
    tags$style(HTML(OC_CSS)),
    tags$script(HTML(OC_JS))
  ),
  layout_sidebar(
    sidebar = sidebar(
      width = 300, gap = "0", padding = "0",
      style = "overflow:hidden;display:flex;flex-direction:column;height:100%",
      navset_tab(
        id = "sidebar_tab",
        nav_panel("Layers",    uiOutput("tab_layers")),
        nav_panel("Thematic",  uiOutput("tab_thematic")),
        nav_panel("Tools",     uiOutput("tab_tools")),
        nav_panel("Knowledge", uiOutput("tab_knowledge"))
      )
    ),
    div(class = "oc-map-wrapper",
      # ── top bar ──────────────────────────────────────────────────────────
      div(class = "oc-topbar",
        tags$span("Open Concord", class = "oc-title"),
        div(class = "oc-geocoder",
          textInput("geocoder_q", NULL, placeholder = "Search address or place…"),
          actionButton("geocode_btn", icon("search"), class = "btn-sm btn-outline-secondary")
        ),
        radioButtons("basemap", NULL, inline = TRUE,
          choices  = c(`☀ Light` = "positron",
                       `☾ Dark`  = "dark-matter",
                       `⊕ Sat`   = "satellite"),
          selected = "positron"),
        actionButton("share_btn", "⧂ Share",
                     class = "btn-sm btn-outline-secondary", style = "white-space:nowrap")
      ),
      # ── map area ─────────────────────────────────────────────────────────
      div(class = "oc-map-area",
        maplibreOutput("map", height = "100%"),
        # geocoder results dropdown
        uiOutput("geocoder_results"),
        # coord / zoom readout
        div(class = "oc-coord-readout", textOutput("coord_readout", inline = TRUE)),
        # status bar
        div(class = "oc-status", textOutput("status", inline = TRUE)),
        # inspector panel (shown when inspector_visible == "true")
        conditionalPanel(
          condition = "output.inspector_visible === 'true'",
          div(class = "oc-inspector",
            div(class = "oc-inspector-header",
              div(
                div(class = "oc-inspector-title", textOutput("inspector_title", inline = TRUE)),
                div(class = "oc-inspector-cat",   uiOutput("inspector_cat",  inline = TRUE))
              ),
              tags$button("×", class = "btn-close-sm", id = "inspector_close_btn",
                onclick = "Shiny.setInputValue('inspector_close', Math.random())")
            ),
            uiOutput("inspector_body"),
            div(style = "margin-top:8px",
              downloadButton("dl_inspector", "Export row as JSON",
                             class = "btn-sm btn-outline-secondary"))
          )
        )
      )
    )
  )
)

# ---- server -----------------------------------------------------------------
server <- function(input, output, session) {

  cat_df   <- reactivePoll(30000, session, function() Sys.time(), catalog)
  shown    <- reactiveVal(character())
  status_msg <- reactiveVal("")

  output$status <- renderText(status_msg())

  # ── coord readout (JS sets map_center / map_zoom via onRender) ───────────
  output$coord_readout <- renderText({
    lng <- input$map_center$lng; lat <- input$map_center$lat; z <- input$map_zoom
    if (is.null(lng)) return("")
    sprintf("%.4f, %.4f  z%.1f", lat, lng, z %||% 12)
  })

  # ── map (render once; JS forwards click + moveend) ───────────────────────
  output$map <- renderMaplibre({
    m <- maplibre(style = carto_style("positron"), center = CONCORD_CENTER, zoom = 12)
    m <- tryCatch(m |> add_navigation_control(position = "top-right"),  error = function(e) m)
    m <- tryCatch(m |> add_scale_control(position = "bottom-left", unit = "imperial"), error = function(e) m)
    m <- tryCatch(m |> add_fullscreen_control(position = "top-right"),  error = function(e) m)
    m <- tryCatch(m |> add_geolocate_control(position = "top-right"),   error = function(e) m)
    m <- m |> add_draw_control(position = "top-left", orientation = "horizontal")
    htmlwidgets::onRender(m, "function(el, x) {
      var map = this;
      if (!map || typeof map.on !== 'function') return;
      // fallback controls if not already added by mapgl
      if (!map._oc_nav) {
        try { map.addControl(new maplibregl.NavigationControl(), 'top-right'); } catch(e){}
        try { map.addControl(new maplibregl.ScaleControl({unit:'imperial'}), 'bottom-left'); } catch(e){}
        try { map.addControl(new maplibregl.FullscreenControl(), 'top-right'); } catch(e){}
        try { map.addControl(new maplibregl.GeolocateControl({trackUserLocation:false}), 'top-right'); } catch(e){}
        map._oc_nav = true;
      }
      map.on('click', function(e) {
        Shiny.setInputValue('map_click',
          {lng: e.lngLat.lng, lat: e.lngLat.lat},
          {priority: 'event'});
      });
      map.on('moveend', function() {
        var c = map.getCenter();
        Shiny.setInputValue('map_center', {lng: c.lng, lat: c.lat});
        Shiny.setInputValue('map_zoom', map.getZoom());
      });
    }")
  })

  # ── basemap switch ────────────────────────────────────────────────────────
  observeEvent(input$basemap, {
    style <- switch(input$basemap,
      positron      = carto_style("positron"),
      "dark-matter" = carto_style("dark-matter"),
      satellite     = SATELLITE_STYLE)
    maplibre_proxy("map") |> set_style(style)
  }, ignoreInit = TRUE)

  # ── share / permalink ─────────────────────────────────────────────────────
  observeEvent(input$share_btn, {
    ctr <- input$map_center; z <- input$map_zoom %||% 12
    sel <- shown()
    params <- Filter(Negate(is.null), list(
      c = if (!is.null(ctr)) sprintf("%.5f,%.5f", ctr$lat, ctr$lng) else NULL,
      z = round(z, 1),
      l = if (length(sel)) paste(sel, collapse = "|") else NULL
    ))
    qs <- paste(names(params), unlist(params), sep = "=", collapse = "&")
    session$sendCustomMessage("oc_copy_clipboard", paste0("?", qs))
    status_msg("Permalink copied to clipboard.")
  })

  # restore from URL params on load
  observe({
    q <- parseQueryString(session$clientData$url_search)
    if (!is.null(q$c) && !is.null(q$z)) {
      parts <- strsplit(q$c, ",")[[1]]
      if (length(parts) == 2) {
        maplibre_proxy("map") |>
          fly_to(center = c(as.numeric(parts[2]), as.numeric(parts[1])),
                 zoom = as.numeric(q$z))
      }
    }
  })

  # ══════════════════════════════════════════════════════════════════════════
  # TAB: LAYERS
  # ══════════════════════════════════════════════════════════════════════════
  output$tab_layers <- renderUI({
    div(
      div(id = "b3d_box",
        style = "border:1px solid #e5e7eb;border-radius:8px;padding:7px 10px;background:#f8fafc;margin-bottom:6px",
        checkboxInput("b3d", "3D buildings (LiDAR heights)", value = FALSE),
        div(style = "font-size:11px;color:#9ca3af;margin-top:-5px",
            "Extrudes ~15.5k buildings; tilts to downtown.")),
      div(class = "layer-search",
        textInput("layer_search", NULL, placeholder = "Search layers…", width = "100%")),
      div(style = "font-size:11px;color:#9ca3af;margin-bottom:3px",
          textOutput("summary", inline = TRUE)),
      uiOutput("legend")
    )
  })

  output$summary <- renderText({
    df <- cat_df()
    if (!nrow(df)) return("No layers loaded — run the ETL.")
    sprintf("%d map layers across %d groups", nrow(df), length(unique(df$schema_name)))
  })

  output$legend <- renderUI({
    df <- cat_df()
    validate(need(nrow(df) > 0, "No map+db layers in PostGIS yet."))
    q <- tolower(trimws(input$layer_search %||% ""))
    if (nzchar(q))
      df <- df[grepl(q, tolower(df$table_name), fixed = TRUE) |
               grepl(q, tolower(df$schema_name), fixed = TRUE), , drop = FALSE]
    validate(need(nrow(df) > 0, "No layers match that search."))
    updateSelectInput(session, "filter_layer",
      choices = sprintf("%s.%s", df$schema_name, df$table_name))
    updateSelectInput(session, "export_layer",
      choices = shown() %||% character())
    panels <- lapply(intersect(CATEGORY_ORDER, unique(df$schema_name)), function(sch) {
      sub  <- df[df$schema_name == sch, , drop = FALSE]
      ids  <- sprintf("%s.%s", sub$schema_name, sub$table_name)
      meta <- CATEGORIES[[sch]] %||% list(label = sch, color = "#475569")
      names_html <- lapply(seq_len(nrow(sub)), function(i) HTML(sprintf(
        "<span style='display:inline-flex;justify-content:space-between;width:100%%;gap:6px'><span>%s</span><span style='color:#9ca3af;font-size:11px'>%s</span></span>",
        nice_label(sub$table_name[i]), format(sub$n_features[i], big.mark = ","))))
      accordion_panel(
        value = sch,
        title = HTML(sprintf(
          "<span style='width:9px;height:9px;border-radius:50%%;background:%s;display:inline-block;margin-right:7px'></span>%s <span style='color:#9ca3af;font-size:11px;margin-left:4px'>%d</span>",
          meta$color, meta$label, nrow(sub))),
        checkboxGroupInput(paste0("grp_", sch), NULL,
          choiceNames = names_html, choiceValues = ids)
      )
    })
    open_grp <- intersect(CATEGORY_ORDER, unique(df$schema_name))[1]
    do.call(accordion, c(Filter(Negate(is.null), panels),
                         list(open = open_grp, multiple = TRUE)))
  })

  selected <- debounce(reactive({
    df <- cat_df()
    unlist(lapply(unique(df$schema_name), function(s) input[[paste0("grp_", s)]]))
  }), 350)

  # diff-based layer add/remove
  observeEvent(selected(), ignoreNULL = FALSE, {
    sel <- selected() %||% character()
    proxy <- maplibre_proxy("map")
    cur   <- shown()
    for (id in setdiff(cur, sel)) proxy |> clear_layer(id)
    for (id in setdiff(sel, cur)) {
      parts <- strsplit(id, ".", fixed = TRUE)[[1]]
      g <- get_layer(parts[1], parts[2])
      if (is.null(g) || !nrow(g)) next
      add_oc_layer(proxy, id, g, CATEGORIES[[parts[1]]]$color %||% "#2563eb")
    }
    shown(sel)
    updateSelectInput(session, "export_layer", choices = sel %||% character())
  })

  # 3D buildings
  observeEvent(input$b3d, {
    proxy <- maplibre_proxy("map")
    if (isTRUE(input$b3d)) {
      g <- get_buildings()
      if (is.null(g) || !nrow(g)) { status_msg("Buildings layer unavailable."); return() }
      proxy |>
        add_fill_extrusion_layer(
          id = "buildings3d", source = g,
          fill_extrusion_base    = 0,
          fill_extrusion_opacity = 0.92,
          fill_extrusion_height  = get_column("HEIGHT"),
          fill_extrusion_color   = interpolate(
            column = "HEIGHT", values = c(2, 8, 20),
            stops  = c("#e2e8f0", "#7c93c0", "#1d4ed8"), na_color = "#cbd5e1"),
          tooltip = concat("Height: ", get_column("HEIGHT"), " m")) |>
        fly_to(center = DOWNTOWN, zoom = 15, pitch = 55, bearing = -17)
      status_msg("3D buildings on — LiDAR heights (downtown view).")
    } else {
      proxy |>
        clear_layer("buildings3d") |>
        fly_to(center = CONCORD_CENTER, zoom = 12, pitch = 0, bearing = 0)
      status_msg("")
    }
  }, ignoreInit = TRUE)

  # ══════════════════════════════════════════════════════════════════════════
  # TAB: GEOCODER (lives in topbar, results float)
  # ══════════════════════════════════════════════════════════════════════════
  geocoder_results <- reactiveVal(NULL)

  observeEvent(input$geocode_btn, {
    q <- trimws(input$geocoder_q); req(nzchar(q))
    r <- geocode_nominatim(q)
    geocoder_results(r)
    if (!is.null(r) && nrow(r)) {
      maplibre_proxy("map") |> fly_to(center = c(r$lon[1], r$lat[1]), zoom = 16)
      status_msg(sprintf("Found: %s", r$label[1]))
    } else {
      status_msg("No geocoder results found.")
    }
  })

  output$geocoder_results <- renderUI({
    r <- geocoder_results(); req(!is.null(r))
    if (!nrow(r)) return(div(class = "oc-geo-results",
      div(class = "oc-geo-no-result", "No results found")))
    div(class = "oc-geo-results",
      lapply(seq_len(min(nrow(r), 5)), function(i) {
        local({
          ii <- i
          actionLink(paste0("geo_pick_", ii), r$label[ii], class = "oc-geo-item")
        })
      }))
  })

  # click a result -> fly + clear dropdown
  lapply(seq_len(5), function(i) {
    observeEvent(input[[paste0("geo_pick_", i)]], {
      r <- geocoder_results(); req(!is.null(r) && nrow(r) >= i)
      maplibre_proxy("map") |> fly_to(center = c(r$lon[i], r$lat[i]), zoom = 16)
      geocoder_results(NULL)
      status_msg(sprintf("Flew to: %s", r$label[i]))
    }, ignoreInit = TRUE)
  })

  # ══════════════════════════════════════════════════════════════════════════
  # TAB: THEMATIC
  # ══════════════════════════════════════════════════════════════════════════
  output$tab_thematic <- renderUI({
    div(
      p(style = "font-size:12px;color:#6b7280;margin-bottom:8px",
        "Overlay census tracts with a demographic or health indicator."),
      selectInput("choropleth_sel", "Overlay:", width = "100%",
        choices = setNames(names(CHOROPLETHS),
                           vapply(CHOROPLETHS, `[[`, character(1), "label"))),
      uiOutput("choropleth_legend"),
      hr(style = "margin:8px 0"),
      div(style = "font-size:11px;color:#9ca3af",
          "Data: US Census ACS 2023 · CDC PLACES 2023 · live PostGIS query.")
    )
  })

  observeEvent(input$choropleth_sel, {
    proxy <- maplibre_proxy("map")
    proxy |> clear_layer("choropleth")
    cfg <- CHOROPLETHS[[input$choropleth_sel]]
    if (is.null(cfg$schema)) return()
    g <- get_layer(cfg$schema, cfg$table)
    if (is.null(g) || !nrow(g)) {
      status_msg(paste("Choropleth layer unavailable:", cfg$label))
      return()
    }
    n_breaks <- length(cfg$breaks)
    # build interpolate stops: values at each break
    all_vals  <- c(cfg$breaks[1] - 1, cfg$breaks)
    all_stops <- cfg$palette[seq_len(n_breaks + 1)]
    add_fill_layer(proxy, id = "choropleth", source = g,
      fill_color = interpolate(
        column   = cfg$col,
        values   = all_vals,
        stops    = all_stops,
        na_color = cfg$na_color),
      fill_opacity       = 0.72,
      fill_outline_color = "rgba(0,0,0,0.08)",
      tooltip = concat(cfg$label, ": ", get_column(cfg$col)))
    status_msg(paste("Choropleth:", cfg$label))
  }, ignoreInit = TRUE)

  output$choropleth_legend <- renderUI({
    cfg <- CHOROPLETHS[[req(input$choropleth_sel)]]
    if (is.null(cfg$schema)) return(NULL)
    pal    <- cfg$palette; breaks <- cfg$breaks; unit <- cfg$unit
    bar    <- paste0("linear-gradient(to right,", paste(pal, collapse = ","), ")")
    n_brk  <- length(breaks)
    pcts   <- seq(0, 100, length.out = n_brk)
    ticks  <- paste(vapply(seq_along(breaks), function(j) {
      lbl <- if (breaks[j] >= 1000) paste0(round(breaks[j]/1000, 0), "k") else breaks[j]
      sprintf("<span class='choro-tick' style='left:%.1f%%'>%s</span>", pcts[j], lbl)
    }, character(1)), collapse = "")
    div(style = "margin-top:6px",
      div(class = "choro-legend-bar", style = sprintf("background:%s", bar)),
      div(class = "choro-legend-ticks", HTML(ticks)),
      div(class = "choro-unit", unit)
    )
  })

  # ══════════════════════════════════════════════════════════════════════════
  # TAB: TOOLS
  # ══════════════════════════════════════════════════════════════════════════
  output$tab_tools <- renderUI({
    div(
      # -- Filter builder ---------------------------------------------------
      div(class = "oc-tool-section",
        tags$p(class = "oc-tool-heading", "Filter layer"),
        selectInput("filter_layer", NULL, choices = NULL, width = "100%"),
        uiOutput("filter_col_ui"),
        div(class = "oc-filter-row",
          selectInput("filter_op", NULL, width = "42%",
            choices = c("=","!=",">","<",">=","<=","LIKE","ILIKE","IS NULL","IS NOT NULL")),
          conditionalPanel(
            "!['IS NULL','IS NOT NULL'].includes(input.filter_op)",
            textInput("filter_val", NULL, placeholder = "value…", width = "100%"))
        ),
        div(class = "oc-btn-row",
          actionButton("apply_filter",  "Filter",    class = "btn-sm btn-primary"),
          actionButton("clear_filter",  "Clear",     class = "btn-sm btn-outline-secondary"),
          downloadButton("dl_filtered", "⬇ GeoJSON", class = "btn-sm btn-outline-success")
        )
      ),
      hr(style = "margin:8px 0"),
      # -- Draw / identify / measure ----------------------------------------
      div(class = "oc-tool-section",
        tags$p(class = "oc-tool-heading", "Draw to identify & measure"),
        div(style = "font-size:12px;color:#6b7280;margin-bottom:4px",
            "Use the draw toolbar (top-left of map) to draw a polygon or rectangle."),
        uiOutput("draw_results_ui")
      ),
      hr(style = "margin:8px 0"),
      # -- Export -----------------------------------------------------------
      div(class = "oc-tool-section",
        tags$p(class = "oc-tool-heading", "Export a visible layer"),
        selectInput("export_layer", NULL, choices = NULL, width = "100%"),
        div(class = "oc-btn-row",
          downloadButton("dl_layer_geojson", "⬇ GeoJSON", class = "btn-sm btn-outline-primary"),
          downloadButton("dl_layer_csv",     "⬇ CSV",     class = "btn-sm btn-outline-primary")
        )
      )
    )
  })

  # dynamic column picker from information_schema
  output$filter_col_ui <- renderUI({
    id <- input$filter_layer; req(nzchar(id %||% ""))
    parts <- strsplit(id, ".", fixed = TRUE)[[1]]
    con   <- poolCheckout(pool); on.exit(poolReturn(con))
    cols  <- tryCatch(DBI::dbGetQuery(con, sprintf(
      "SELECT column_name FROM information_schema.columns
        WHERE table_schema = '%s' AND table_name = '%s'
          AND data_type NOT IN ('USER-DEFINED')
          AND column_name NOT IN ('geometry','geom','wkb_geometry','gid','objectid',
                                  'globalid','fid','oid','popup_html')
        ORDER BY ordinal_position",
      parts[1], parts[2]))$column_name,
      error = function(e) character(0))
    selectInput("filter_col", NULL, choices = cols, width = "100%")
  })

  filter_sf <- reactiveVal(NULL)

  observeEvent(input$apply_filter, {
    id  <- input$filter_layer; req(nzchar(id %||% ""))
    col <- input$filter_col;   req(nzchar(col %||% ""))
    op  <- input$filter_op  %||% "="
    val <- trimws(input$filter_val %||% "")
    con <- poolCheckout(pool); on.exit(poolReturn(con))
    where <- if (op %in% c("IS NULL", "IS NOT NULL")) {
      sprintf('"%s" %s', col, op)
    } else if (op %in% c("LIKE", "ILIKE")) {
      sprintf('"%s" %s %s', col, op, DBI::dbQuoteString(con, paste0("%", val, "%")))
    } else {
      num_val <- suppressWarnings(as.numeric(val))
      if (!is.na(num_val)) sprintf('"%s" %s %s', col, op, num_val)
      else sprintf('"%s" %s %s', col, op, DBI::dbQuoteString(con, val))
    }
    parts <- strsplit(id, ".", fixed = TRUE)[[1]]
    g     <- get_layer(parts[1], parts[2], where)
    proxy <- maplibre_proxy("map")
    fid   <- paste0("filter::", id)
    proxy |> clear_layer(fid)
    if (!is.null(g) && nrow(g)) {
      add_oc_layer(proxy, fid, g, "#f59e0b", highlight = TRUE)
      status_msg(sprintf("%s: %d features match — %s %s '%s'.",
        nice_label(parts[2]), nrow(g), nice_label(col), op, val))
      filter_sf(g)
    } else {
      status_msg("No matches, or query error.")
      filter_sf(NULL)
    }
  })

  observeEvent(input$clear_filter, {
    id <- input$filter_layer; req(id)
    maplibre_proxy("map") |> clear_layer(paste0("filter::", id))
    filter_sf(NULL)
    status_msg("")
  })

  output$dl_filtered <- downloadHandler(
    filename = function() paste0("filtered_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".geojson"),
    content  = function(file) {
      g <- filter_sf(); req(!is.null(g))
      sf::st_write(g, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
    }
  )

  # draw -> measure + count
  draw_results_rv <- reactiveVal(NULL)

  observeEvent(input$map_drawn_features, {
    sel <- shown()
    feats <- tryCatch(get_drawn_features(maplibre_proxy("map")), error = function(e) NULL)
    if (is.null(feats) || !nrow(feats)) return()
    feats_utm  <- sf::st_transform(feats, 32619)
    area_m2    <- sum(as.numeric(sf::st_area(feats_utm)))
    area_acres <- area_m2 / 4046.86
    perim_m    <- tryCatch(
      sum(as.numeric(sf::st_length(sf::st_boundary(sf::st_union(feats_utm))))),
      error = function(e) NA_real_)
    perim_ft   <- if (!is.na(perim_m)) perim_m * 3.28084 else NA_real_
    wkt <- sf::st_as_text(sf::st_union(sf::st_geometry(feats)))
    counts <- list()
    if (length(sel)) {
      con <- poolCheckout(pool); on.exit(poolReturn(con))
      counts <- lapply(sel, function(id) {
        parts <- strsplit(id, ".", fixed = TRUE)[[1]]
        n <- tryCatch(DBI::dbGetQuery(con, sprintf(
          'SELECT count(*) n FROM "%s"."%s" WHERE ST_Intersects(geometry, ST_GeomFromText(%s,4326))',
          parts[1], parts[2], DBI::dbQuoteString(con, wkt)))$n,
          error = function(e) NA_integer_)
        list(label = nice_label(parts[2]),
             n     = n,
             color = CATEGORIES[[parts[1]]]$color %||% "#6b7280")
      })
    }
    draw_results_rv(list(area_m2 = area_m2, area_acres = area_acres,
                         perim_m = perim_m, perim_ft = perim_ft, counts = counts))
    status_msg(sprintf("Drawn area: %.2f acres  (%.0f m²)", area_acres, area_m2))
  })

  output$draw_results_ui <- renderUI({
    r <- draw_results_rv()
    if (is.null(r)) return(div(style = "font-size:12px;color:#9ca3af",
      "Draw a shape to see area, perimeter, and feature counts."))
    count_rows <- lapply(r$counts, function(x)
      div(style = sprintf("display:flex;justify-content:space-between;font-size:12px;margin:1px 0;color:%s", x$color),
          span(x$label), span(format(x$n, big.mark = ","))))
    div(
      div(style = "font-size:12.5px;font-weight:600;margin-bottom:3px", "Drawn area"),
      div(style = "font-size:12px;color:#374151",
          sprintf("Area:  %.2f acres  (%.0f m²)", r$area_acres, r$area_m2)),
      if (!is.na(r$perim_ft))
        div(style = "font-size:12px;color:#374151",
            sprintf("Perimeter:  %.0f ft  (%.0f m)", r$perim_ft, r$perim_m)),
      if (length(r$counts))
        div(style = "margin-top:5px",
          div(style = "font-size:11px;font-weight:600;color:#9ca3af;text-transform:uppercase;letter-spacing:.04em;margin-bottom:2px",
              "Features inside"),
          div(count_rows))
    )
  })

  # export visible layer
  output$dl_layer_geojson <- downloadHandler(
    filename = function() paste0(gsub("\\.", "_", input$export_layer %||% "layer"), ".geojson"),
    content  = function(file) {
      id <- input$export_layer; req(nzchar(id %||% ""))
      parts <- strsplit(id, ".", fixed = TRUE)[[1]]
      g <- get_layer(parts[1], parts[2]); req(!is.null(g) && nrow(g))
      sf::st_write(g, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
    }
  )

  output$dl_layer_csv <- downloadHandler(
    filename = function() paste0(gsub("\\.", "_", input$export_layer %||% "layer"), ".csv"),
    content  = function(file) {
      id <- input$export_layer; req(nzchar(id %||% ""))
      parts <- strsplit(id, ".", fixed = TRUE)[[1]]
      g <- get_layer(parts[1], parts[2]); req(!is.null(g) && nrow(g))
      utils::write.csv(sf::st_drop_geometry(g), file, row.names = FALSE)
    }
  )

  # ══════════════════════════════════════════════════════════════════════════
  # TAB: KNOWLEDGE
  # ══════════════════════════════════════════════════════════════════════════
  output$tab_knowledge <- renderUI({
    div(
      tags$h6("About Concord, NH", style = "font-weight:600;margin-bottom:6px"),
      uiOutput("wikidata_facts_ui"),
      hr(style = "margin:10px 0"),
      tags$h6("Notable people", style = "font-weight:600;margin-bottom:6px"),
      uiOutput("notable_people_ui"),
      hr(style = "margin:10px 0"),
      div(style = "font-size:11px;color:#9ca3af",
          "Sources: Wikidata Q28249 · Wikipedia. Live from PostGIS.")
    )
  })

  output$wikidata_facts_ui <- renderUI({
    con <- poolCheckout(pool); on.exit(poolReturn(con))
    df  <- tryCatch(DBI::dbGetQuery(con,
      "SELECT \"propLabel\", \"valueLabel\" FROM knowledge.wikidata_facts
        WHERE \"propLabel\" IS NOT NULL AND \"valueLabel\" IS NOT NULL
          AND \"valueLabel\" NOT LIKE 'Q%'
        LIMIT 20"),
      error = function(e) NULL)
    if (is.null(df) || !nrow(df)) return(
      div(style = "font-size:12px;color:#9ca3af", "Run ETL to populate Wikidata facts."))
    rows <- lapply(seq_len(nrow(df)), function(i)
      div(style = "display:flex;gap:8px;border-bottom:1px solid #f9fafb;padding:3px 0;font-size:12px",
        span(style = "color:#9ca3af;min-width:130px;flex-shrink:0", df[[1]][i]),
        span(style = "color:#111827", df[[2]][i])))
    div(rows)
  })

  output$notable_people_ui <- renderUI({
    con <- poolCheckout(pool); on.exit(poolReturn(con))
    df  <- tryCatch(DBI::dbGetQuery(con,
      "SELECT name, url FROM knowledge.notable_people ORDER BY name LIMIT 40"),
      error = function(e) NULL)
    if (is.null(df) || !nrow(df)) return(
      div(style = "font-size:12px;color:#9ca3af", "Run ETL to populate notable people."))
    chips <- lapply(seq_len(nrow(df)), function(i)
      tags$a(href = df$url[i], target = "_blank",
             class = "knowledge-chip", df$name[i]))
    div(style = "line-height:2", chips)
  })

  # ══════════════════════════════════════════════════════════════════════════
  # INSPECTOR (click -> nearest feature in any visible layer)
  # ══════════════════════════════════════════════════════════════════════════
  inspector_visible <- reactiveVal(FALSE)
  inspector_feature <- reactiveVal(NULL)

  # conditionalPanel reads this as text
  output$inspector_visible <- renderText({
    if (inspector_visible()) "true" else "false"
  })
  outputOptions(output, "inspector_visible", suspendWhenHidden = FALSE)

  observeEvent(input$map_click, {
    click <- input$map_click; req(!is.null(click))
    sel   <- shown(); if (!length(sel)) return()
    lng   <- click$lng; lat <- click$lat
    con   <- poolCheckout(pool); on.exit(poolReturn(con))
    for (id in sel) {
      parts <- strsplit(id, ".", fixed = TRUE)[[1]]
      g <- tryCatch(sf::st_read(con, query = sprintf(
        'SELECT * FROM "%s"."%s" ORDER BY geometry <-> ST_SetSRID(ST_MakePoint(%.8f,%.8f),4326) LIMIT 1',
        parts[1], parts[2], lng, lat), quiet = TRUE),
        error = function(e) NULL)
      if (is.null(g) || !nrow(g)) next
      g_wgs   <- sf::st_transform(g, 4326)
      click_pt <- sf::st_sfc(sf::st_point(c(lng, lat)), crs = 4326)
      dist_m  <- tryCatch(
        as.numeric(sf::st_distance(g_wgs[1, ], click_pt, by_element = TRUE)),
        error = function(e) Inf)
      if (!is.na(dist_m) && dist_m < 200) {
        inspector_feature(list(schema = parts[1], table = parts[2], g = g_wgs))
        inspector_visible(TRUE)
        break
      }
    }
  })

  observeEvent(input$inspector_close, {
    inspector_visible(FALSE)
    inspector_feature(NULL)
  })

  output$inspector_title <- renderText({
    f <- inspector_feature(); req(!is.null(f))
    nice_label(f$table)
  })

  output$inspector_cat <- renderUI({
    f <- inspector_feature(); req(!is.null(f))
    meta <- CATEGORIES[[f$schema]] %||% list(label = f$schema, color = "#475569")
    tags$span(style = sprintf("color:%s", meta$color), meta$label)
  })

  output$inspector_body <- renderUI({
    f <- inspector_feature(); req(!is.null(f))
    df <- sf::st_drop_geometry(f$g)
    df <- df[, !grepl("^(geom|geometry|wkb|globalid|objectid|gid|fid|oid|id|popup_html)$|_id$|code$|^se_anno|shape[_.]",
                      names(df), ignore.case = TRUE), drop = FALSE]
    rows <- lapply(seq_len(ncol(df)), function(i) {
      v <- trimws(as.character(df[1, i]))
      if (is.na(v) || !nzchar(v) || v == "NA") return(NULL)
      div(class = "inspector-row",
        span(class = "inspector-key", nice_label(names(df)[i])),
        span(class = "inspector-val", v))
    })
    rows <- Filter(Negate(is.null), rows)
    wiki_block <- NULL
    if (f$schema == "knowledge" && "url" %in% names(df)) {
      wiki_block <- div(style = "margin-top:8px",
        tags$a(href = df$url[1], target = "_blank",
               style = "font-size:12px;color:#2563eb", "View on Wikipedia ↗"))
    }
    div(div(rows), wiki_block)
  })

  output$dl_inspector <- downloadHandler(
    filename = function() {
      f <- inspector_feature()
      if (is.null(f)) "feature.json" else paste0(f$table, ".json")
    },
    content = function(file) {
      f <- inspector_feature(); req(!is.null(f))
      df <- sf::st_drop_geometry(f$g)[1, , drop = FALSE]
      writeLines(jsonlite::toJSON(df, auto_unbox = TRUE, pretty = TRUE), file)
    }
  )
}

shinyApp(ui, server)
