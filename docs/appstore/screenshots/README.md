# App Store Screenshots

Marketing screenshots for the App Store listing, designed in Penpot (page **Mockups**)
and rendered to PNG locally.

## Files

| Screen | Source | Render |
| --- | --- | --- |
| Today | `01-today.svg` | `01-today.png` |
| Pantry | `02-pantry.svg` | `02-pantry.png` |
| Scanner | `03-scanner.svg` | `03-scanner.png` |
| Meal Plan | `04-meals.svg` | `04-meals.png` |
| Shopping | `05-shopping.svg` | `05-shopping.png` |
| Profile | `06-profile.svg` | `06-profile.png` |

## Specs

- Logical canvas: `393 × 852` (iPhone 17 / 6.1" point size).
- Rendered PNGs: **1290 × 2796 px** — the App Store **6.7"** display size.
- Colors follow the app Design System tokens (accent `#34C759`, critical `#FF3B30`,
  warning `#FF9500`, upcoming `#FFCC00`).

## Regenerate

```sh
cd docs/appstore/screenshots
for f in *.svg; do
  rsvg-convert -w 1290 -h 2796 "$f" -o "${f%.svg}.png"
done
```
