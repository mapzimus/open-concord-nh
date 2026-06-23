# Open Concord Shiny frontend (R). Built on rocker/geospatial (GDAL/GEOS/PROJ + sf).
FROM rocker/geospatial:4.4

# v3 frontend uses {bslib}+{mapgl}; {leaflet} only by the legacy app-leaflet-v1.R.
RUN install2.r --error --skipinstalled \
      shiny bslib mapgl pool RPostgres httr2 jsonlite htmlwidgets sf

WORKDIR /app
COPY shiny/app.R /app/app.R

EXPOSE 3838
# PG* connection vars are injected by docker-compose.
CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]
