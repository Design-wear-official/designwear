# Photo prompts for the remaining garment styles

V-neck, long sleeve, raglan, ringer, tank, hoodie, cap and tote are drawn as
vectors today. To replace one with a photo, generate each view with the prompts
below, then add it to `JOBS` in `build_garment_assets.py` and calibrate its
colour zones in `lib/models/garment_style.dart` (see the existing crew/polo
zones; coordinates are in 1024×1024 space, check them with a coloured preview).

## Rules for every image (so shirts line up)

- One garment, centred, front or back view, no model, no hanger, no props.
- Same camera distance and straight-on angle for every image; garment fills
  about 90% of the height.
- Plain flat light-grey background (#cfcfcf), soft studio light, no gradient,
  no text, no logo, no watermark.
- Plain WHITE garment (the studio tints it): no print, no colour, no stripes.
- 2752×1536 or larger, PNG.

## Prompts (append the rules above to each)

| File name                | Prompt |
|--------------------------|--------|
| `vneck_front`            | White short-sleeve V-neck T-shirt, front view, ghost mannequin |
| `vneck_back`             | White short-sleeve V-neck T-shirt, back view, ghost mannequin |
| `longsleeve_front`       | White long-sleeve crew-neck T-shirt with rib cuffs, front view, ghost mannequin |
| `longsleeve_back`        | Same long-sleeve T-shirt, back view |
| `raglan_front`           | White 3/4-sleeve raglan baseball T-shirt, seams from neck to underarm, front view |
| `raglan_back`            | Same raglan T-shirt, back view |
| `ringer_front`           | White short-sleeve ringer T-shirt with rib collar and sleeve bands, front view |
| `ringer_back`            | Same ringer T-shirt, back view |
| `tank_front`             | White sleeveless tank top with bound neck and armholes, front view |
| `tank_back`              | Same tank top, back view |
| `hoodie_front`           | White pullover hoodie, hood down, kangaroo pocket, drawstrings, rib cuffs and waistband, front view |
| `hoodie_back`            | Same hoodie, back view, hood visible |
| `cap_front`              | White six-panel baseball cap, curved brim, front view |
| `cap_back`               | Same cap, back view with adjustable strap |
| `tote_front`             | Plain white canvas tote bag, two flat handles, front view, flat |
| `tote_back`              | Same tote bag, back view |
| `henley_back`            | White short-sleeve henley T-shirt, back view, ghost mannequin |
| `crew_left`, `crew_right`| White crew T-shirt, exact side views (left and right), ghost mannequin |
| `polo_left`, `polo_right`| White polo shirt, exact side views |

Colour zones and the print guide will need re-checking for every new photo.
