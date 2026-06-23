# Adding Open Concord to maxwellhowegis.com

Three changes to `mapzimus/maxwellhowegis`, plus one image file:

## 1. Copy the project detail page

```
docs/portfolio/concord.html  →  [repo root]/concord.html
```

## 2. Add the thumbnail

Convert or copy the SVG thumbnail:

```
docs/portfolio/open-concord-thumb.svg  →  [repo root]/images/projects/open-concord-thumb.png
```

Quick conversion (requires ImageMagick or Inkscape):
```bash
inkscape open-concord-thumb.svg --export-png=open-concord-thumb.png --export-width=800
# or
convert -background none open-concord-thumb.svg -resize 800x500 open-concord-thumb.png
```

Or export from any browser: open the SVG, right-click → Save As → PNG.

## 3. Add to `js/projects.js`

Copy the object from `docs/portfolio/projects-entry.js` and insert it near the top of the
`projects` array (after id 17, the Quabbin entry). It uses `status: "in development"` so it
will render with the dev badge, and `liveUrl: "concord.html"` so the card opens the detail page.

## 4. Add to "Currently Building" in `index.html`

Find the `.building-pills` div and add:

```html
<a href="concord.html" class="building-pill status-dev">Open Concord NH — in dev</a>
```

After the existing pills (TappyMaps, howe2math, OptiTrek).

## Once deployed

When `concord.maxwellhowegis.com` goes live, update two fields in `projects.js`:
- Remove `status: "in development"`
- Change `liveUrl` if you want the card to link directly to the live Shiny app instead of the detail page
- Move the pill from `status-dev` to `status-live` in `index.html`
