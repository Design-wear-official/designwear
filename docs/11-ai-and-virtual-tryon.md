# 11 · AI & Virtual Try-On

DesignWear has three AI surfaces, all proxied through the Next.js backend (so the
Gemini key never ships in the client):

1. **DesignBot** — conversational design editing (`/ai/agent`)
2. **AI design image generation** — a graphic for the garment (`/ai/generate-design`)
3. **Virtual Try-On** — render a design on a person photo (`/ai/try-on`)

For the user-facing DesignBot feature notes (image attachments, limitations) see
[DESIGN_BOT_AI_FEATURES.md](DESIGN_BOT_AI_FEATURES.md).

---

## Model & configuration

| Setting | Value | Source |
|---------|-------|--------|
| Model | `gemini-3.5-flash` | `GeminiConfig.model` + backend `MODEL_URL` |
| Temperature | `0.7` | `GeminiConfig.temperature` / backend `generationConfig` |
| Max output tokens | `8192` | `GeminiConfig.maxOutputTokens` |
| API key | `GEMINI_API_KEY` | **backend only** |

> Older feature docs mention "Gemini 2.0 Flash"; the code currently targets
> `gemini-3.5-flash`. Treat the code as authoritative. See
> [Configuration](04-configuration.md).

The client AI services resolve the base URL from `WEB_API_BASE_URL` (default
`https://designwear-backend.vishwamai.com/api`).

---

## 1. DesignBot — `AIAgentService`

[`ai_agent_service.dart`](../lib/services/ai_agent_service.dart). UI:
[`AgentChatWidget`](../lib/presentation/widgets/agent_chat_widget.dart) +
[`AiImageAttachmentWidget`](../lib/presentation/widgets/ai_image_attachment_widget.dart).

### `sendMessage(userMessage, currentDesign, {imageAttachments})`

```
1. Load assets/system_prompt.txt, replace {{CURRENT_STATE}} with currentDesign.toJson()
2. Encode any image attachments to base64 (mimeType image/jpeg)
3. Fire TWO requests in parallel:
     POST /ai/agent            (chat → text + ```json design``` block)
     POST /ai/generate-design  (graphic → base64 PNG)
4. Append the user turn + model turn to in-memory _history (multi-turn context)
5. Extract the fenced ```json {…} ``` via regex (greedy, dotAll)
6. If it contains {"design": {…}} → CustomDesign.fromJson(...)
7. If the image call succeeded → design.copyWith(designImageBase64: <png>)
8. Return AgentResponse(text: <conversational text before json>, updatedDesign)
```

Returns `AgentResponse { String text; CustomDesign? updatedDesign; }`.
`clearHistory()` resets the conversation.

### The design JSON contract
The model must emit conversational text **then** one fenced block:

````
Here's a sunrise vibe! 🌅
```json
{"design": {"baseColor": "0xFFFF8C00", "elements": [
  {"id":"el_1","type":"text","content":"SUNRISE VIBES","x":0,"y":-30,"size":32,
   "color":"0xFFFFFFFF","properties":{"fontFamily":"Bebas Neue","bold":true,"shadow":true}},
  {"id":"el_2","type":"sticker","content":"🌅","x":0,"y":30,"size":60,"properties":{}}
], "name":"Sunrise", "productType":"T-Shirt"}}
```
````

Rules (enforced by the system prompt): colors are `0xFFRRGGBB`, positions are
center-relative (`x −130..130`, `y −100..200`), all elements are always listed,
and the model cannot generate raster graphics itself. Full rules:
[Design Studio → AI contract](10-design-studio.md#the-ai-design-contract).

### Backend: `POST /ai/agent`
[`route.ts`](../designwear-backend/app/api/ai/agent/route.ts). Accepts
`{ systemPrompt, history, userMessage, imageAttachments }`, builds Gemini
`contents` (with `inline_data` for images) + `systemInstruction`, calls Gemini
`generateContent`, returns `{ success, data }` (raw Gemini response). `503` if
`GEMINI_API_KEY` is missing.

---

## 2. AI design image generation

### `generateDesignImage(prompt)` → base64 PNG or `null`
`POST /ai/generate-design` with `{ prompt }`, 45s timeout. On success reads
`imageData` (base64). Used standalone and in parallel inside `sendMessage`. The
result is stored on the design as `designImageBase64` (runtime-only, never
persisted to JSON).

---

## 3. Virtual Try-On — `VirtualTryOnService`

[`virtual_tryon_service.dart`](../lib/services/virtual_tryon_service.dart). UI:
[`VirtualTryOnScreen`](../lib/screens/virtual_tryon_screen.dart).

### `generateTryOn({personImageBytes, clothingImageBytes})` → `Uint8List`
```
1. base64-encode both images
2. POST /ai/try-on  { personImageBase64, clothingImageBase64 }
3. On success: base64-decode response.generateImageBase64 → bytes
4. On failure: throw VirtualTryOnException(message)
```

Helpers: `saveImage(bytes, fileName)` (writes to app documents dir),
`fileToBytes(file)`. `isConfigured` is always `true` (assumes the backend is
configured).

### Backend: `POST /ai/try-on`
[`route.ts`](../designwear-backend/app/api/ai/try-on/route.ts). Takes the two
base64 images, calls the image model, returns the composited result.

---

## Image attachment handling (DesignBot)

- Sources: **camera** capture or **gallery** pick (`image_picker`), with
  `permission_handler` for runtime permissions.
- Recommended: JPEG/PNG, ≤ 1024×1024, ~85% quality.
- Multiple images per message are supported; each is base64-encoded and sent as
  Gemini `inline_data`.
- The AI extracts color schemes, mood, typography ideas, and themes—it does
  **not** reproduce exact logos/graphics.

---

## Error handling & resilience

| Surface | Behavior |
|---------|----------|
| Agent error | `AgentResponse(text: 'API Error: …')` or `'Error: …'` (never throws to UI) |
| Image gen error | returns `null`; design still updates from the agent JSON |
| Try-on error | throws `VirtualTryOnException` (UI shows a message) |
| Missing key | backend returns `503`; the AI surface degrades gracefully |
| Demo mode | `DesignStudioDemoService` provides canned responses |

---

## End-to-end sequence (DesignBot)

```
User → AgentChatWidget → AIAgentService.sendMessage
         │
         ├── POST /ai/agent ─────────► Gemini generateContent ──► text + json
         └── POST /ai/generate-design ► image model ───────────► base64 PNG
         │
         ▼
   parse json → CustomDesign.fromJson → copyWith(designImageBase64)
         ▼
   DesignStudioScreen.setState(_design = updated) → canvas re-renders
```
