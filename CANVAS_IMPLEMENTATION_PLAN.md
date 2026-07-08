# Canvas (ArtBoard) Implementation Plan — Distill

> **Audience:** the engineer/model implementing this feature (DeepSeek).
> **Reviewer:** the change will be audited afterwards, so follow the
> conventions and constraints below **exactly**. When a decision is ambiguous,
> the plan states a recommended default — use it unless told otherwise.

---

## 0. One-paragraph summary

The app already extracts **4 dominant colors** from a photo the user picks.
Your job is to build the **painting canvas** (the "ArtBoard") that opens after
the user taps **Start Painting**. On this screen the user paints on a white
canvas using **only those 4 locked colors** — no other colors are ever
selectable. The chosen photo is shown in a floating, draggable, toggleable
"Chosen Moment" reference panel. When the user leaves, their real drawing is
saved as the painting for today's journal entry (replacing the current *fake*
generated painting).

The target design is the reference screenshot: a white canvas on a grid
background, a floating bottom "pill" toolbar (3 ink tools + a ruler + a 2×2
grid of the 4 locked color swatches), a floating "Chosen Moment" photo panel,
and a top bar with a back chevron and an ellipsis menu (Toggle Reference /
Share Painting / Reset Canvas).

---

## 1. Where this fits — current code you must integrate with

### 1.1 The existing flow (do not break it)

```
HomeView
  └─ picks photo → GenerationView (extracts 4 colors)
       └─ PaletteConfirmationView (shows photo + scattered palette cards)
            ├─ "Change Moment" → re-pick photo
            └─ "Start Painting"  ← YOU CHANGE THIS DESTINATION
```

**Today**, `onStartPainting` in `GenerationView` calls
`viewModel.createJournalEntry(...)` which uses `PaintingGenerator` to make a
**fake** painting (colored rectangles) and dismisses. That was placeholder
behavior.

**After your change**, `onStartPainting` must instead navigate to the new
**`ArtBoardView`**, passing the reference image and the 4 extracted colors.
The journal entry is created *when the user finishes painting on the ArtBoard*,
using the **real drawing** — not `PaintingGenerator`.

### 1.2 Key existing types you will reuse (do not rewrite these)

| Type | File | What it gives you |
| --- | --- | --- |
| `ImageStore` | `Services/ImageStore.swift` | `saveReference(_:) -> String`, `savePainting(_:) -> String`. Save the reference photo and the rendered painting to disk; returns file identifiers. |
| `JournalEntry` (`@Model`) | `Models/JournalEntry.swift` | SwiftData model: `referenceImageIdentifier`, `paintingImageIdentifier`, `paletteHex: [String]`. Persist one per finished painting. |
| `Color(hex:)` / `color.hex` | `Common/Extensions/Color+Storage.swift` | Convert `Color` ↔ `"#RRGGBB"`. Use `.map(\.hex)` to store the palette. |
| `GridBackgroundView` | `Common/Components/GridBackgroundView.swift` | The faint grid behind the canvas (see screenshot). |
| `PaletteConfirmationView` | `Features/PaletteConfirmation/` | Already receives `referenceImage: UIImage` and `colors: [Color]` — these are the two values you pass into the ArtBoard. |

### 1.3 Files you will fill in (they exist but are empty / skeletons)

```
Features/ArtBoard/
├── ArtBoardView.swift                 (EMPTY — main screen, build this)
├── ArtBoardViewModel.swift            (EMPTY — state + logic, build this)
├── Canvas/
│   ├── PencilCanvasView.swift         (SKELETON — replace body with real PencilKit canvas)
│   └── CanvasToolbar.swift            (EMPTY — the floating bottom tool pill)
└── ReferencePhoto/
    ├── ReferencePhotoOverlay.swift    (EMPTY — floating "Chosen Moment" panel)
    └── DeviceOrientationObserver.swift(EMPTY — optional: react to iPad rotation)
```

> The folder structure is the intended architecture — keep each concern in its
> named file. Do not collapse everything into one giant view.

---

## 2. Hard constraints (the audit will check these)

1. **Locked palette — the whole point.** The canvas must expose **only** the 4
   extracted colors. **Never** present `PKToolPicker` (Apple's system tool
   picker) — it includes an unlimited color wheel and would break the lock.
   You build a **custom** toolbar and set the canvas tool's color yourself.
2. **The reference image on the canvas is the photo the user chose** — the same
   `UIImage` passed from `PaletteConfirmationView`. Not a thumbnail from disk,
   not a re-extraction.
3. **Match the existing code style** (see §7). This codebase has a distinctive
   look — generous blank lines, `// MARK: -` sections, `@Observable @MainActor
   final class` view models, small `struct` services.
4. **No new third-party packages.** Use Apple's **PencilKit** (system
   framework) + SwiftUI + UIKit only. The only SPM dependency in the project is
   `DominantColors`, and you don't touch it.
5. **The real drawing is saved**, not a `PaintingGenerator` output. The old
   fake path is removed from this flow.

---

## 3. Data flow (end to end)

```
PaletteConfirmationView.onStartPainting
        │  passes: referenceImage: UIImage, colors: [Color]  (exactly 4)
        ▼
ArtBoardView(referenceImage:palette:)                 ← new screen
        │  owns ArtBoardViewModel(referenceImage:palette:)
        │
        │  user paints (PencilKit) using ONE of the 4 locked colors
        │  user can: pick tool, pick color, toggle ruler,
        │            move/hide the reference panel, reset, share
        ▼
On finish (see §5.6 for the trigger):
        │  1. render PKDrawing → UIImage over white  (viewModel.renderPainting())
        │  2. ImageStore.saveReference(referenceImage) → refID
        │  3. ImageStore.savePainting(renderedImage)   → paintID
        │  4. insert JournalEntry(refID, paintID, palette.map(\.hex)) into modelContext
        │  5. try modelContext.save()
        ▼
Dismiss back to Home → the new entry appears in the grid.
```

---

## 4. Component specifications

### 4.1 `ArtBoardViewModel` — `@Observable @MainActor final class`

Holds all canvas state and the save/reset logic. The View owns SwiftUI
concerns (`@Environment`, navigation); the ViewModel owns data + operations,
mirroring how `HomeViewModel` is written.

**Stored inputs (init):**
- `let referenceImage: UIImage`
- `let palette: [Color]` — the 4 locked colors.

**Observable state:**
- `var drawing = PKDrawing()` — the current strokes. Two-way bound into the
  `PencilCanvasView`.
- `var selectedColor: Color` — initialize to `palette.first ?? .black`.
- `var selectedTool: CanvasTool` — see enum below; default `.pen`.
- `var isRulerActive: Bool = false`.
- `var isReferenceVisible: Bool = true`.
- `var showResetConfirmation: Bool = false`.

**Derived:**
- `var currentInkTool: PKTool` — builds a `PKInkingTool` (or `PKEraserTool`)
  from `selectedTool`, `selectedColor`, and the tool's width. This is what the
  `PencilCanvasView` applies to `PKCanvasView.tool`.

**Nested type — the tool set (matches the screenshot):**
```swift
enum CanvasTool: CaseIterable, Identifiable {
    case pen        // PKInkingTool(.pen,    width ~ 8)
    case marker     // PKInkingTool(.marker, width ~ 18)  (highlighter-like)
    case pencil     // PKInkingTool(.pencil, width ~ 6)
    case eraser     // PKEraserTool(.vector) — optional but recommended
    // id, an SF Symbol name, and a display width for the label under each tool
}
```
> The screenshot shows 3 pen-like tools with small width numbers (50/80/80) and
> a ruler. Include an **eraser** too — it's expected on a paint canvas and cheap
> to add. If you keep the widths as shown, expose them per-tool.

**Methods:**
- `func selectColor(_ color: Color)` → sets `selectedColor`.
- `func selectTool(_ tool: CanvasTool)` → sets `selectedTool`.
- `func toggleReference()` → flips `isReferenceVisible`.
- `func toggleRuler()` → flips `isRulerActive`.
- `func requestReset()` → sets `showResetConfirmation = true`.
- `func resetCanvas()` → `drawing = PKDrawing()` (clears all strokes).
- `func renderPainting(size: CGSize) -> UIImage` → renders `drawing` onto a
  **white** background at `size` (see §6.1).
- `func save(into context: ModelContext)` — performs steps 1–5 of §3. Reuse an
  `ImageStore()` instance. Log + surface errors the same way `HomeViewModel`
  does (`Logger`, `errorMessage`/`isShowingError`). Include those two error
  properties on this VM as well.

### 4.2 `PencilCanvasView` — `UIViewRepresentable` wrapping `PKCanvasView`

Replace the current placeholder body. This is the actual drawing surface.

**Bindings / inputs:**
- `@Binding var drawing: PKDrawing`
- `let tool: PKTool` — apply to `canvasView.tool` in `updateUIView`.
- `let isRulerActive: Bool` — apply to `canvasView.isRulerActive`.

**`makeUIView`:**
- Create `PKCanvasView`.
- `canvasView.drawingPolicy = .anyInput` — **important:** allows finger drawing
  so the app is usable in the Simulator and without an Apple Pencil. (If you
  ever want pencil-only, make it a setting; default to `.anyInput`.)
- `canvasView.backgroundColor = .white` (the canvas paper). `isOpaque = true`.
- Set `canvasView.tool = tool` and `canvasView.drawing = drawing`.
- **Do NOT call `PKToolPicker.setVisible(true, ...)`.** No system tool picker.
- Assign `canvasView.delegate = context.coordinator`.

**`updateUIView`:**
- If `uiView.tool` differs, set `uiView.tool = tool`.
- Set `uiView.isRulerActive = isRulerActive`.
- Only assign `uiView.drawing = drawing` when it actually differs, to avoid a
  feedback loop with the delegate (compare, or guard with a coordinator flag).

**`Coordinator: PKCanvasViewDelegate`:**
- `canvasViewDrawingDidChange` → push `canvasView.drawing` back into the
  `@Binding` (on the main actor). Use a flag so this write doesn't immediately
  bounce back through `updateUIView`.

> Wrap PencilKit imports in the files that need them: `import PencilKit`.

### 4.3 `CanvasToolbar` — the floating bottom pill

A SwiftUI view pinned near the bottom center (see screenshot). Rounded,
material/`.regularMaterial` background, subtle shadow, a small grabber line at
top.

**Contents, left→right:**
1. **Tool buttons** — one per `CanvasTool` (pen, marker, pencil, eraser). Each
   shows an SF Symbol (e.g. `pencil.tip`, `highlighter`, `pencil`, `eraser`)
   and its small width number underneath (like `50 / 80 / 80` in the design).
   The selected tool is visually highlighted (raised / tinted).
2. **Ruler toggle** — SF Symbol `ruler`; highlighted when `isRulerActive`.
3. **Color swatches** — a **2×2 grid of exactly the 4 palette colors** (matches
   the screenshot). Each swatch is a filled circle/rounded square; the selected
   color gets a ring/border. Tapping selects that color.

**Inputs:** the `ArtBoardViewModel` (or explicit bindings + callbacks). Prefer
passing the view model so selection state stays in one place. No color other
than the 4 in `palette` may appear here — build the grid straight from
`viewModel.palette` and never from a system picker.

### 4.4 `ReferencePhotoOverlay` — the floating "Chosen Moment" panel

A draggable card that floats over the canvas (see screenshot, top-right).

**Contents:**
- Header row: a **minimize** button (SF Symbol `arrow.down.right.and.arrow.up.left`
  or `arrow.down.forward.and.arrow.up.backward`) on the left, centered title
  **"Chosen Moment"**.
- Below: `Image(uiImage: referenceImage)` — `.resizable().scaledToFill()`,
  clipped to a rounded rectangle.
- Card: `.regularMaterial` / white background, `RoundedRectangle`, shadow.

**Behavior:**
- **Draggable:** track an `@State offset: CGSize` updated by a `DragGesture`
  (accumulate onEnded into a stored base offset). Keep it within screen bounds.
- **Minimize:** collapses to a small floating pill/thumbnail; tap to expand.
- **Visibility:** shown only when `viewModel.isReferenceVisible`. "Toggle
  Reference" in the top menu and the minimize control both drive this / the
  collapsed state. Keep the model simple: `isReferenceVisible` (present at all)
  + a local `isMinimized` (expanded vs. collapsed) is enough.

**Inputs:** `referenceImage: UIImage` and a binding to visibility (or the VM).

### 4.5 `DeviceOrientationObserver` — optional, keep minimal

The canvas is an **iPad** landscape/portrait screen. If you want the reference
panel to reposition sensibly on rotation, add a tiny `@Observable` that watches
`UIDevice.orientationDidChangeNotification` and publishes the current
orientation. **This is optional polish** — if it risks complexity, leave the
file with a small stub `@Observable` exposing `orientation` and don't block the
core feature on it. Do not over-engineer.

### 4.6 `ArtBoardView` — the screen that composes everything

`ZStack`:
1. `GridBackgroundView()` (bottom).
2. The white canvas: `PencilCanvasView(drawing:tool:isRulerActive:)`, inset with
   padding so the grid shows around it and shadowed like the screenshot.
3. `ReferencePhotoOverlay(...)` when `isReferenceVisible`.
4. `CanvasToolbar(viewModel:)` pinned bottom-center.

**Navigation bar** (`.toolbar`, `.navigationBarBackButtonHidden()`):
- **Leading:** back chevron (`chevron.left`). Its action **saves then
  dismisses** — see §5.6.
- **Trailing:** ellipsis (`ellipsis`) `Menu` with:
  - **Toggle Reference** (`eye`) → `viewModel.toggleReference()`.
  - **Share Painting** (`square.and.arrow.up`) → render current drawing and
    present a share sheet (see §6.2).
  - **Reset Canvas** (`trash`, `role: .destructive`) → `viewModel.requestReset()`.

**Reset confirmation alert** (`.alert(..., isPresented: $viewModel.showResetConfirmation)`):
- Title **"Reset Canvas?"**, message **"This can't be undone."**
- Destructive **"Reset"** → `viewModel.resetCanvas()`; **"Cancel"** role
  `.cancel`. (Mirror the existing delete-confirmation pattern in `HomeView`.)

**Error alert:** same pattern as `HomeView` using the VM's `errorMessage` /
`isShowingError`.

---

## 5. Wiring & flow details

### 5.1 Presenting the ArtBoard
In `GenerationView`, the `PaletteConfirmationView(... onStartPainting:)` closure
currently creates a journal entry and dismisses. Change it to navigate to
`ArtBoardView(referenceImage: currentImage, palette: extractedColors)`.

Use a `navigationDestination` (there is already a `NavigationStack` in
`GenerationView`) driven by a new `@State private var showArtBoard = false`,
set to `true` inside `onStartPainting`. Keep the existing `NavigationStack`
usage consistent with the file.

### 5.2 Do NOT create the journal entry in `onStartPainting` anymore
Remove the `viewModel.createJournalEntry(...)` call from that closure. The entry
is now created by `ArtBoardViewModel.save(into:)` when the user finishes.

### 5.3 Passing SwiftData context
`ArtBoardView` reads `@Environment(\.modelContext)` and passes it into
`viewModel.save(into:)`. (Same pattern `HomeView`/`GenerationView` use.)

### 5.4 The palette is the lock — pass it straight through
`extractedColors` (already exactly 4, capped by `DominantColorExtractor`'s
`maxCount: 4`) becomes `viewModel.palette`. Guard defensively: if fewer than 4
colors come through, still show whatever count exists — never pad with an
arbitrary color, and never add a color the extractor didn't produce.

### 5.5 Saving the reference image
`ArtBoardViewModel.save(into:)` must persist **both** the reference photo
(`ImageStore.saveReference(referenceImage)`) and the rendered painting, then
store both identifiers on the `JournalEntry`, plus `palette.map(\.hex)`.

### 5.6 What triggers the save (decide clearly — recommended default)
The screenshot has **no explicit Save/Done button**. Recommended default:
**auto-save on exit.** When the user taps the back chevron:
- If the drawing has at least one stroke → `viewModel.save(into: context)` then
  `dismiss()`.
- If the canvas is empty → just `dismiss()` (don't save a blank painting).

Keep it simple and predictable. (If the auditor later wants an explicit "Done"
button, that's a small change — but ship auto-save-on-exit first.)

---

## 6. Rendering & sharing

### 6.1 Render the drawing to a saved painting (`renderPainting`)
`PKDrawing.image(from:scale:)` returns an image with a **transparent**
background. The journal grid + share need a solid painting, so composite onto
white:

```swift
func renderPainting(size: CGSize) -> UIImage {
    let bounds = CGRect(origin: .zero, size: size)
    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = true
    return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
        UIColor.white.setFill()
        ctx.fill(bounds)
        let strokes = drawing.image(from: bounds, scale: format.scale)
        strokes.draw(in: bounds)
    }
}
```
Use the on-screen canvas size (or a fixed square like `PaintingGenerator`'s
`650×650`) so saved paintings are consistent. A fixed square is simplest and
matches the existing generator — **recommend 650×650** unless the canvas aspect
must be preserved.

### 6.2 Share Painting
Render via `renderPainting(...)`, then present a `UIActivityViewController`
. Note `Features/Share/ShareService.swift` exists but is currently **empty** —
either implement a small reusable share service there, or wrap a minimal
`UIActivityViewController` for SwiftUI inline. Sharing does **not** create a
journal entry.

---

## 7. Code-style rules (match the existing codebase — the audit checks this)

- **View models:** `@Observable @MainActor final class`, `// MARK: -` sections
  (`Dependencies`, `State`, methods), a private `Logger(subsystem:
  "com.morad.Distill", category: ...)`, and `errorMessage` / `isShowingError`
  for surfacing failures. Copy the shape of `HomeViewModel`.
- **Services** are small `struct`s (see `ImageStore`, `DominantColorExtractor`).
- **Spacing:** this codebase uses **generous blank lines** between statements
  and closure bodies (look at `GenerationView`, `PencilCanvasView`). Match it —
  don't reformat existing files to be denser.
- **Comments:** short, explain *why* not *what*, like the existing files
  (e.g. the "Ignore duplicate fires" comment in `HomeView`). Document each new
  type with a one-line doc comment. Keep it clean and readable — this is a
  learning project and the code will be read by people.
- **Every new `View`** should keep a `#Preview` with sample data (4 hard-coded
  hex colors + `UIImage(systemName: "photo")!`), matching existing previews.
- **SF Symbols** for all icons; no custom assets.
- **Naming:** keep the file/type names already present (`ArtBoardView`,
  `ArtBoardViewModel`, `PencilCanvasView`, `CanvasToolbar`,
  `ReferencePhotoOverlay`, `DeviceOrientationObserver`).

---

## 8. Step-by-step build order (do in this sequence)

1. **`ArtBoardViewModel`** — state, `CanvasTool` enum, `currentInkTool`,
   `renderPainting`, `save(into:)`, reset/toggle methods. No UI yet.
2. **`PencilCanvasView`** — the `UIViewRepresentable` + Coordinator. Verify you
   can draw with a single hard-coded tool/color first.
3. **`CanvasToolbar`** — tools + ruler + 4-swatch grid, wired to the VM.
4. **`ReferencePhotoOverlay`** — static card first, then drag, then minimize.
5. **`ArtBoardView`** — compose 1–4 in a `ZStack`, add nav bar, reset alert,
   error alert.
6. **`GenerationView`** — change `onStartPainting` to navigate into
   `ArtBoardView`; remove the old `createJournalEntry` call from that closure.
7. **`DeviceOrientationObserver`** — optional polish, last.
8. Build & run; walk the acceptance checklist (§9).

---

## 9. Acceptance criteria (self-check before handing back)

- [ ] From Home → pick photo → Start Painting opens the **canvas**, not Home.
- [ ] The canvas shows the **grid background** and a **white paper** area.
- [ ] Drawing works with finger (Simulator) **and** Apple Pencil.
- [ ] The toolbar shows **exactly the 4 extracted colors** and **no other color
      is reachable** (no system color wheel, no `PKToolPicker`).
- [ ] Selecting a swatch changes the stroke color; selecting a tool changes the
      tool; the selected tool/color are visually indicated.
- [ ] Ruler toggle enables PencilKit's ruler.
- [ ] The **"Chosen Moment"** panel shows the exact photo the user chose, and
      can be **dragged, minimized, and toggled** via the menu.
- [ ] **Reset Canvas** shows the confirmation alert and clears all strokes.
- [ ] **Share Painting** renders and presents a share sheet (no journal entry
      created).
- [ ] Leaving the canvas (back) with strokes present **saves the real drawing**
      as the painting, saves the reference photo, and creates one
      `JournalEntry` with `paletteHex` = the 4 colors; the entry appears on
      Home. Leaving with an empty canvas creates nothing.
- [ ] `PaintingGenerator` is **not** used in this flow.
- [ ] Code style matches §7; each new view has a `#Preview`; it builds with no
      warnings you introduced.

---

## 10. Explicit "do NOT" list

- ❌ Do **not** use `PKToolPicker` or any system color picker.
- ❌ Do **not** add any color outside the 4 extracted ones.
- ❌ Do **not** add new SPM dependencies.
- ❌ Do **not** keep calling `PaintingGenerator` in the Start-Painting flow.
- ❌ Do **not** reformat or densify the existing files' spacing/style.
- ❌ Do **not** collapse the feature into one file — respect the folder layout.
- ❌ Do **not** block the core feature on the optional orientation observer.
```
