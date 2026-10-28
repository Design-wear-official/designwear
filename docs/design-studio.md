# Design Studio

The editor lives in `lib/screens/studio/editor/`:

```
editor/
  design_studio_screen.dart      the screen and its state
  screen/                        layout and actions (parts of the screen's state)
  canvas/                        canvas, painters (garment overlays, sleeves), garment registry
  panels/                        tool panels and garment options
  widgets/{elements,text,tabs,dialogs}
  support/                       constants and helpers
```

Other studio screens: `community/` (feed, design detail, weekly challenge), `library/`
(your saved designs), `shared/design_preview.dart`.

## Views

The garment has four views: **Front**, **Back**, **Left** and **Right** (the sleeves).
Switch with the toggle at the top right of the canvas.

- Front and back use the garment photo, tinted with your garment colour.
- Left and right are drawn (there are no sleeve photos). They show a dashed print area,
  and the print-size label changes to 8 × 10 cm.
- Every element belongs to one view, so a design can carry artwork on all four.

## Tools

| Tool | Does |
|---|---|
| Layers | list of everything on the current view; select, drag to reorder, duplicate, delete |
| Colour | garment colour, trim, collar and pocket options (front, T-shirt) |
| Text | fonts, size, colour, effects |
| Emoji | recent and saved emoji; your own stickers (kept on this device, up to 12 of 300 KB each) |
| Shapes | basic shapes |
| Placement | print position presets |

Also: templates (built-in starter designs), undo/redo (30 steps), snap-to-centre guides,
auto-save to the device every 10 seconds, and a save dialog for named designs.

### Keyboard (desktop and web)

| Keys | Action |
|---|---|
| Arrow keys | nudge the selected element by 1 (hold **Shift** for 10) |
| Delete / Backspace | delete the selection |
| Ctrl + D | duplicate |
| Ctrl + ] / Ctrl + [ | bring forward / send back |
| Escape | deselect |

## DesignBot

Tap the sparkle button to open **DesignBot AI**. Ask for what you want ("navy shirt that
says SUNRISE", "make the text bigger") and the Studio applies the change. It is the only
chat bot in the app.

How it works: the app sends your message, the conversation and the current design JSON to
`POST /v1/ai/design-agent`. The API adds its private prompt and calls Gemini, then returns
text and, if the model made one, a new design. A reply without a design is just a message.
Graphics for a design use `POST /v1/ai/design-image`.

Needs `GEMINI_API_KEY` on the API and a signed-in user. Without them the bot says it isn't
connected and you can still design by hand.

## Saving and publishing

- **Save** keeps the design on this device (`Saved designs` in your profile).
- **Publish** (needs the API and a signed-in user) uploads the design JSON and front and back
  previews to the community. Limits: up to 60 elements, 400 KB of design data, previews of
  about 330 KB each. Publishing again updates the same design.
- **Remix** from a community design or a product opens it in the Studio. The new design
  records its parent, and the lineage is shown on the design page.
- **Weekly challenge:** open the challenge from Home, tap *Join and remix*, and publish. The
  design becomes an entry, ranked by likes. Challenges are created by an admin (see
  [api.md](api.md#admin)).

## Try-on

Product pages and the Studio offer virtual try-on: pick a photo of yourself and the API
returns an image of you wearing the product, or your own design.

## Not available yet

- 3D garment preview (the button shows a message).
