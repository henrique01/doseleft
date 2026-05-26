# Handoff: DoseLeft — "New medication" scan-first flow

## Overview

This handoff covers the **New medication** screen for DoseLeft, an iOS
medication-tracker app. The screen lets a user add a medication to track. The
redesign centers on a **photo-scan** entry path: the user points their camera
at the medication box, the app OCR/visually recognises the label, and the
fields are auto-filled. Manual entry remains available as a fallback.

The flow has four primary states:

1. **Scan landing** — empty state, dominated by a "Scan the box" hero card.
2. **Camera viewfinder** — full-bleed camera capture UI with detection
   brackets framing the box and a live "detected label" chip.
3. **Auto-filled review** — the populated form, with sparkle markers next to
   every field that was auto-detected and a "Retake" affordance at the top.
4. **Manual entry** — the same form, no scan provenance, used when the user
   opts out of scanning.

Two bottom-sheet pickers are also part of the flow:

- **Form (type) picker** — list of medication forms (Tablet, Capsule,
  Inhaler, Drops, Spray, Cream/gel, Patch, Injection/pen, Liquid).
- **Icon picker** — 4×2 grid of glyphs; the type's default icon is marked
  with a small accent dot.

## About the Design Files

The files in this bundle are **design references created in HTML** — React +
inline JSX prototypes that demonstrate the intended visual design, layout,
and interactive behaviour. **They are not production code to copy directly.**

The task is to **recreate these designs in the target codebase's existing
environment** (e.g. SwiftUI for an iOS app, React Native, Flutter, or
whichever framework the team has chosen) using its established patterns,
component library, and design tokens. The CSS-in-JS values in the HTML files
are spec-quality (every measurement is an iOS pt rendered 1:1 to px) — read
them as a precise visual specification, not as code to lift.

If no codebase exists yet, this is an iOS app and SwiftUI would be the
natural target.

## Fidelity

**High-fidelity.** Colors, type, spacing, and component anatomy are all
final. The developer should match them pixel-for-pixel.

The faux medicine-box illustration shown in the camera viewfinder and the
photo thumbnail in the auto-filled strip are **placeholders** — in
production these will be the user's actual camera feed and captured
photograph.

## Files in this bundle

- `NewMedicationForm.html` — runnable demo. Open it in a browser to see all
  artboards side-by-side on a pan/zoom canvas. Click any artboard label to
  open it fullscreen.
- `src/tokens.jsx` — design tokens (color, type, spacing helpers).
- `src/icons.jsx` — every SVG glyph used by the form (`DLIcon` component).
- `src/ui.jsx` — shared primitives: `DLPhone`, `DLStatusBar`, `DLNavBar`,
  `DLNavBtn`, `DLGroup`, `DLGroupHeader`, `DLRow`, `DLChip`, `DL_W`/`DL_H`.
- `src/screens-forms.jsx` — the actual form: `DLAdd` (entry-state machine),
  `DLScanCamera`, `DLScanBrackets`, `DLScanDot`, `DLBoxThumb`,
  `DLIconPickerSheet`, `DLTypePickerSheet`, `DLStepperBtn`, and the
  `DL_MED_TYPES` / `DL_PALETTE` / `DL_ICON_LIST` constants.
- `design-canvas.jsx` — pan/zoom canvas used to present artboards.

## Screens / Views

The screen is 393 × 852 pt (iPhone 15 Pro logical size). Status bar (54 pt)
and home indicator (34 pt) are part of the design.

### Screen 1 — Scan landing (`entry="scan-empty"`)

**Purpose:** Invite the user to scan the box; offer manual entry as a quiet
secondary path.

**Layout:**
- Nav bar (44 pt, compact): centered title **"New medication"**, leading
  "Cancel" button in `text2` gray. No trailing button on this state.
- Scrolling content area, padding `8px 20px 24px`.

**Components (top → bottom):**

1. **Scan hero card** — full-width white card, `border-radius: 20px`,
   padding `32px 24px 28px`, shadow
   `0 1px 3px rgba(0,0,0,0.04), 0 0 0 0.5px rgba(0,0,0,0.04)`.
   - Soft tinted background blobs (decorative, behind content):
     - Top-right: 180×180, `border-radius: 90px`, color
       `tint(lavender, 0.10)`, translated `top: -40 right: -40`.
     - Bottom-left: 160×160, `border-radius: 80px`, color
       `tint(sage, 0.08)`, translated `bottom: -60 left: -30`.
   - **Camera badge**: 76×76, `border-radius: 22px`, background `#1A1A1C`,
     rotated `-4deg`, drop shadow `0 8px 20px rgba(0,0,0,0.16)`. Inside:
     `camera` icon at 36 pt in white. Sparkle dot at `top: -6 right: -6`:
     22×22 circle in `accent.lavender` with the `sparkle` icon (12 pt) in
     white, plus shadow `0 2px 6px rgba(0,0,0,0.12)`.
   - **Headline**: "Scan the box" — 22/700, `letter-spacing: -0.5`,
     `color: text`.
   - **Subhead** (max-width 280): "We'll fill in the name, form and how many
     doses are inside automatically." — 15/400, `color: text2`,
     `line-height: 1.4`.
   - **CTA pill**: padding `12px 24px`, background `accent.lavender`,
     `border-radius: 14px`, font 16/600 white, gap 8, leading `camera` icon
     (18 pt white, stroke 2). Label: **"Open camera"**.
2. **Reassurance list** — three rows, gap 10, padding `0 4px`, marginTop 20:
   - Each row: 22×22 lavender-tinted circle (`tint(lavender, 0.16)`)
     containing a 11 pt lavender `sparkle` icon, then 14/400 `text2` label.
   - Labels: "Medication name", "Form (tablet, inhaler, drops…)", "Total
     doses in the container".
3. **OR divider** — flex row, margin `28px 0 16px`, gap 12. Two flex 0.5 pt
   `sep`-colored horizontal lines with a 12-pt, 0.4-letter-spacing uppercase
   "OR" label in `text3` between them.
4. **Manual entry button** — full-width, height 50, `border-radius: 14px`,
   background `fill`, 16/500 `text` color, leading `keyboard` icon (18 pt,
   stroke 1.8). Label: **"Enter manually"**.

**Interactions:**
- Tap hero card or CTA pill → transition to **Scanning** state.
- Tap "Enter manually" → transition to **Manual entry** state.
- Tap Cancel → dismiss the modal (out of scope for this screen).

### Screen 2 — Camera viewfinder (`entry="scanning"`)

**Purpose:** Capture the medication box and run on-device recognition.

**Layout:** Absolute-positioned, fills the entire `DLPhone` (393×852),
background `#0A0A0A`. Vertical flex column: status bar (54 pt, dark variant),
top bar (44 pt), viewfinder (flex 1), control bar (~100 pt with safe-area).

**Components:**

1. **Top bar** — flex row, padding `4px 18px`, height 44.
   - Leading: 34×34 circle, background `rgba(255,255,255,0.12)`, contains
     `close` icon (18 pt white, stroke 2). Tap → cancel and return to Scan
     landing.
   - Center: title "Scan medication" — 15/600 white.
   - Trailing: 34×34 circle, same style, `flash` icon (16 pt). Toggles flash
     (out of scope).
2. **Viewfinder area** (flex 1, position relative, overflow hidden):
   - Background: radial gradient
     `radial-gradient(ellipse at 50% 60%, #2a2520 0%, #100c0a 70%)`.
   - **Faux medication box** (placeholder — replace with live camera feed
     in production): 200×260 div, `border-radius: 6px`, centered, rotated
     `-3deg`, gradient `linear-gradient(180deg, #F5F0E4 0%, #E6E1D4 100%)`,
     padding `24px 18px`, drop shadow
     `0 30px 60px rgba(0,0,0,0.5), 0 8px 18px rgba(0,0,0,0.35)`. Inside:
     a 60×4 sage accent stripe, "SINGULAIR" 18/700 with `-0.4` tracking,
     "MONTELUKAST SODIUM" 9 pt micro caption, "10 mg film-coated tablets"
     8 pt, a "30 TABLETS" mini-card (white, hairline border), a faux
     barcode (rows of thin black rects).
   - **Detection brackets**: white L-shaped corners at 230×290 rotated `-3deg`
     centered, 3-pt border thickness, length 22 pt, slight outer offset.
   - **Status pill** (top, centered ~30 pt from top): padding `8px 14px`,
     `border-radius: 999`, background `rgba(0,0,0,0.55)` with
     `backdrop-filter: blur(8px)`, 13/500 white. Leading 8 pt sage dot with
     glow `0 0 8px sage`. Label: "Detecting label…".
   - **Detected chip** (positioned ~130 pt above viewfinder bottom): padding
     `6px 10px`, white background, `border-radius: 8`, drop shadow
     `0 4px 12px rgba(0,0,0,0.3)`. Leading 11 pt lavender `sparkle` icon,
     then 12/600 dark text "Singulair · 30 tablets".
3. **Control bar** — flex row, padding `20px 0 40px`, gap 56,
   center-aligned:
   - Left: text "Cancel" (15 pt white, opacity 0.8).
   - Center: **shutter** — 72×72 circle, 4 pt white border, transparent
     fill, padding 4. Inner 100% × 100% white circle. Tap → capture and
     transition to Auto-filled review.
   - Right: small "Auto" label (13 pt white, opacity 0.6), placeholder for
     mode switcher.

### Screen 3 — Auto-filled review (`entry="scanned"`)

**Purpose:** Show the user what was detected and let them confirm or edit.

**Layout:** Same scaffold as Manual entry (below). The differences:

- A **scan-provenance strip** sits just below the nav bar:
  - Margin `10px 16px 4px`, padding `8px 10px 8px 8px`, background
    `tint(lavender, 0.10)`, `border-radius: 12`.
  - Leading: 36 pt box-photo thumbnail (`DLBoxThumb` — placeholder; in
    production this is the cropped capture).
  - Middle (flex 1): 13/600 dark title "Auto-filled from photo" (with a
    leading 12 pt lavender sparkle), then 11/400 `text2` caption "Tap any
    field to edit · please verify".
  - Trailing: **Retake** pill — white background, padding `6px 12px`,
    `border-radius: 8`, 13/600 lavender, leading 13 pt lavender camera
    icon. Tap → returns to **Scanning** state.
- Each auto-detected value gets a **`DLScanDot`**: a 16-pt circle in
  `tint(lavender, 0.18)` containing a 9-pt lavender sparkle. Placed inline
  next to: medication name (centered hero), form value, the "Total · {unit}"
  label.
- The "Quantity" group header reads `"Quantity · detected on label"`, with
  the suffix rendered in 13 pt 500-weight lavender (non-uppercase, normal
  letter-spacing).

### Screen 4 — Manual entry (`entry="manual"`)

**Purpose:** Same form, used when the user skips scanning.

**Layout:**

- Nav bar (44 pt compact): "Cancel" leading, **"Save"** trailing (in
  whichever accent color is currently selected, 17/600).
- Scrolling content:
  1. **Hero badge + name** — flex column, gap 14, padding `12px 20px 20px`,
     center-aligned:
     - **Preview badge button**: 96×96 circle, background = selected accent
       color, drop shadow
       `0 10px 24px tint(color, 0.32), 0 2px 6px tint(color, 0.18)`. Contains
       the current `DLIcon` at 48 pt white. **Pencil chip** in bottom-right
       (`right: -4 bottom: -4`): 30×30 white circle, 2 pt `bg` border
       (creates a halo against the badge), drop shadow
       `0 1px 3px rgba(0,0,0,0.14)`, contains a 13 pt `pencil` icon in
       `text2` (stroke 2). **Tap → opens the Icon picker bottom sheet.**
     - **Name input**: full-width text input, no border/outline, 24/600,
       `letter-spacing: -0.5`, `color: text`, centered.
  2. **Form + Color group** (`DLGroup`, marginTop 4):
     - **Form row** (tappable): label "Form" (17/400 `text`), trailing value
       (17/400 `text2`) showing the selected type's label, then a 16 pt
       chev-down chevron in `text3`. **Tap → opens the Form picker sheet.**
     - **Color row** (last in group): label "Color", then a flex row of
       8 color "balls" (22×22 circles, gap 8). Each is a button. Selected
       state: 2 pt outline of the same color with `outline-offset: 2`. Order:
       lavender, sage, ochre, terracotta, dustyRose, plum, slate, moss.
  3. **Quantity group** (`DLGroupHeader` "Quantity"):
     - Single row: "Total · {plural}" (the unit name comes from the
       selected type — `tablets`, `puffs`, `drops`, etc.). Trailing stepper:
       28-pt round `−` and `+` buttons (fill bg) flanking a 24/700 number in
       `font.rounded`, tabular-nums, with `letter-spacing: -0.5`, min-width 40.
  4. **Schedule group** (`DLGroupHeader` "Schedule"):
     - Row 1: time chip "9:00 PM" (17/600 rounded) + caption "· 1 {unit} ·
       Every day" (13/400 `text2`), trailing chevron-right.
     - Row 2 (last): accent-colored "+ Add another time" (17/500).
  5. **Remind me group** (`DLGroupHeader` "Remind me"):
     - Single row: "Days before empty" + stepper (28-pt round buttons, 22/700
       rounded number, min-width 28).

### Bottom sheets

Both sheets render absolutely positioned inside the phone, with a backdrop
`rgba(0,0,0,0.32)` covering the rest of the screen. The sheet itself sits
flush to bottom with `border-radius: 20px 20px 0 0`, background `bg`, drop
shadow `0 -8px 30px rgba(0,0,0,0.16)`. Each starts with a 36×5 grab handle
in `rgba(0,0,0,0.18)`.

**Form (type) picker:**
- Title "Form" (17/600), centered, margin-bottom 12.
- List of nine rows. Each row: 12×20 padding, 14 gap, hairline `sep` border
  (last row none). Cursor pointer. Selected row has background
  `tint(selectedColor, 0.08)`.
- Leading: 36×36 circle. Selected → selected accent color background +
  white 18 pt icon. Unselected → `fill` background + 18 pt `text2`-gray icon.
- Label (flex 1, 17/400, 600 if selected).
- Trailing: 18 pt accent-colored `check` icon, stroke 2.2, when selected.

**Icon picker:**
- Title "Choose icon" (17/600), then 13/400 `text2` "Suggested for
  {type}" with the type label rendered in `text` weight 500.
- 4-column grid, padding `0 20px`, column-gap 8, row-gap 18.
- Each tile: column, gap 8, centered.
  - 60×60 circle. Selected → accent background, 2 pt accent border, 30 pt
    white icon. Unselected → white background, 0.5 pt `sep` border, 30 pt
    `#8A8A8E` icon.
  - **Default-for-type marker**: when the icon equals the type's default
    AND is not currently selected, render a 12×12 circle at `top: 0 right:
    0` filled with the accent color and a 2 pt `bg` outer ring.
  - Caption (11 pt) below the tile: "Default" if it's the type default,
    otherwise empty. Selected tiles use `text` 600; others `text2` 400.

## Interactions & Behavior

State machine — single `mode` variable on `DLAdd`:

```
scan-empty  ──tap "Open camera"──▶  scanning
scan-empty  ──tap "Enter manually"──▶  manual
scanning    ──tap shutter──▶  scanned
scanning    ──tap close / Cancel──▶  scan-empty
scanned     ──tap "Retake"──▶  scanning
```

Inside the form (both `scanned` and `manual`):

- Tap the hero preview badge → open icon picker (bottom sheet).
- Tap the Form row → open form (type) picker (bottom sheet).
- Tap any color ball → set selected color. Also live-updates the hero badge,
  the schedule's "+ Add another time" text color, and the Save button color.
- Picking a new type **also clears any icon override** so the badge falls
  back to that type's default icon. (Important: a previously-overridden icon
  should not persist into a new type's flow.)
- Picking a new type also changes the **unit name** rendered next to the
  Quantity total ("Total · tablets" → "Total · puffs") and inside the
  Schedule row ("· 1 tablet" → "· 1 puff").
- Both stepper plus/minus buttons mutate the visible number in place. (In
  this prototype the numbers are hard-coded; in production wire them to
  state.)
- Bottom-sheet backdrop tap → dismiss.

**Animations / transitions:**
- All easing is iOS-native; the design relies on system push/pop for the
  bottom sheets and standard nav-bar transitions. No custom curves required.
- The "Detecting label…" status pill could pulse subtly during scanning
  (sage glow on the leading dot).

**Error / loading states (not in the prototype, plan for them in code):**
- **Detection fails / low confidence**: stay on the camera screen, swap the
  status pill to a calm "Hold steady — can't read the label yet" caption.
  No red.
- **Detection succeeds with partial info**: transition to `scanned`, but
  only mark the fields that were actually detected with sparkles. Leave the
  rest empty for the user to fill.
- **Camera permission denied**: show a permission prompt sheet from the
  Scan landing screen with copy explaining the permission and a button that
  opens Settings. Manual entry remains available.

## State Management

Form state (component-local for the prototype; lift into your store as
appropriate):

```
{
  mode: 'scan-empty' | 'scanning' | 'scanned' | 'manual',
  type: <DL_MED_TYPES.id>,        // e.g. 'tablet'
  iconOverride: string | null,    // null = use type's default icon
  color: <hex>,                   // one of DL_PALETTE
  name: string,
  totalQuantity: number,          // not exposed in prototype, wire up
  daysBeforeEmpty: number,        // not exposed in prototype, wire up
  schedule: [ { time, dose, days } ],
  sheet: 'icon' | 'type' | null,
}
```

**Data fetching / detection:**
- The "scan → fields populated" transition is the only externally-dependent
  piece. The prototype simulates this with a static "Singulair · 30 tablets"
  detection. In production the shutter tap should:
  1. Capture a still frame.
  2. Run OCR + heuristics (or an on-device ML model) to extract: brand name,
     dosage form, total count.
  3. Heuristically map the detected form → `DL_MED_TYPES` and pick the
     corresponding default icon.
  4. Pick a color (initially: random unused color from `DL_PALETTE`).
  5. Transition to `scanned` and populate state. Each individually-detected
     field controls its own sparkle marker — only render the marker for
     fields that were actually detected.

## Design Tokens

All token values live in `src/tokens.jsx`. Reproduce them in the target
codebase's token system.

### Color

**Light mode**
- `bg` — `#FAFAF7` (screen background)
- `surface` — `#FFFFFF` (cards, list groups)
- `text` — `#1A1A1C`
- `text2` — `#8A8A8E`
- `text3` — `#B8B8BC`
- `sep` — `#E5E5E0`
- `fill` — `#F0F0EB` (filled stepper buttons, "Enter manually" bg)
- `tertiary` — `#D5D5CF`
- `chipBg` — `rgba(0,0,0,0.04)`

**Accent palette** (per-medication color, also drives the color balls):
- `lavender` — `#A78BD5` ← primary accent for scan affordances
- `sage` — `#9CAF88` ← default for tablets
- `ochre` — `#C9A961`
- `terracotta` — `#C97B5F`
- `dustyRose` — `#C49191`
- `plum` — `#8B6B8E`
- `slate` — `#6F8390`
- `moss` — `#7A8B6E`

**Helpers** (implement in your codebase):
- `tint(hex, alpha)` — returns an `rgba()` string with the given alpha.
  Used for soft accent backgrounds (`tint(lavender, 0.10)` etc).
- `saturate(hex)` — bumps saturation by ~15% in HSL space and darkens
  lightness ~6%. Used for the warning-state chip text; not used inside this
  form but defined in tokens.

### Typography

Two stacks (use the platform-appropriate equivalents):
- **`font.text`** — body / labels / nav.
  `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", system-ui,
  sans-serif`
- **`font.rounded`** — numbers (counts, times) and the app's identity numbers.
  `-apple-system, BlinkMacSystemFont, "SF Pro Rounded", "Nunito", system-ui,
  sans-serif`
- Tabular figures (`font-variant-numeric: tabular-nums`,
  `font-feature-settings: "tnum"`) on every count/stepper number so they
  don't shift width when changed.

Type sizes used on this screen (size / weight / letter-spacing):
- 24 / 700 / `-0.5` — hero number (stepper)
- 24 / 600 / `-0.5` — name field
- 22 / 700 / `-0.5` — scan card headline; stepper for "Days before empty"
- 18 / 700 / `-0.4` — faux box brand text on the viewfinder card
- 17 / 600 / `-0.2` — nav-bar title, status bar
- 17 / 600 — Save button (in current accent color)
- 17 / 400 — list-row primary text
- 17 / 500 — accent action rows ("+ Add another time", "+ Add dose time")
- 16 / 600 — primary CTA pill ("Open camera")
- 16 / 500 — "Enter manually" button
- 15 / 400 — list-row secondary text
- 15 / 600 — viewfinder title; scan thumbnail title
- 14 / 400 — reassurance list labels
- 13 / 400 — small captions
- 13 / 500 — "Quantity · detected on label" suffix
- 13 / 600 — "Auto-filled from photo" label; Retake pill
- 12 / 400 — OR divider, icon picker captions
- 11 / 600 — detected-chip caption
- 11 / 400 — "Tap any field to edit · please verify"

### Spacing & radius

- Screen padding: 16 (group horizontal margin) / 20 (large vertical sections)
- List row: padding `12px 16px`, min-height 44, hairline `0.5px` separator
- Group: margin `0 16px`, `border-radius: 12px`, `overflow: hidden`,
  `background: surface`
- Group header: padding `20px 20px 8px`, 13/500 uppercase
  `letter-spacing: 0.4`, color `text2`
- Sheet: top `border-radius: 20px`, padding-top 10, bottom safe-area
  padding ~28
- Hero badge: 96×96 round
- Pencil chip: 30×30 round, 2 pt `bg` border (halo)
- Color ball: 22×22 round, 8 pt gap, 2 pt outline on selected
- Stepper button: 28×28 round (small) or 32×32 (regular)
- Icon picker tile: 60×60 round
- Type picker tile: 36×36 round
- Scan card: `border-radius: 20px`, padding `32px 24px 28px`

### Shadows

- Hero badge: `0 10px 24px tint(color, 0.32), 0 2px 6px tint(color, 0.18)`
- Scan camera badge: `0 8px 20px rgba(0,0,0,0.16)`
- Sparkle dot on camera badge: `0 2px 6px rgba(0,0,0,0.12)`
- Pencil chip: `0 1px 3px rgba(0,0,0,0.14)`
- Scan card: `0 1px 3px rgba(0,0,0,0.04), 0 0 0 0.5px rgba(0,0,0,0.04)`
- Bottom sheet: `0 -8px 30px rgba(0,0,0,0.16)`
- Detected chip (in viewfinder): `0 4px 12px rgba(0,0,0,0.3)`

## Iconography

All icons are in `src/icons.jsx` as inline SVGs inside the `DLIcon`
component. **They are intentionally not SF Symbols** — they are custom,
geometric, abstract glyphs that read clearly inside an accent circle at
small sizes (widget, watch, app icon). When porting:

- If your target codebase uses SF Symbols, prefer using the matching
  symbol (`pills.fill`, `inhaler.fill`, `drop.fill`, etc.) but match the
  visual weight/proportion of the originals.
- If you need exact parity, copy the SVG paths from `DLIcon`.

Icons used on this screen:
- **Medication forms** (filled glyphs): `pills`, `inhaler`, `drop`,
  `bottle`, `tube`, `syringe`, `patch`, `vial`.
- **UI** (stroked glyphs): `plus`, `minus`, `pencil`, `chev-right`,
  `chev-down`, `chev-left`, `check`, `camera`, `flash`, `keyboard`,
  `close`, `sparkle`.

## Constants

In `screens-forms.jsx`:

```
DL_MED_TYPES = [
  { id: 'tablet',    label: 'Tablet',         icon: 'pills',   unit: 'tablet',      plural: 'tablets' },
  { id: 'capsule',   label: 'Capsule',        icon: 'pills',   unit: 'capsule',     plural: 'capsules' },
  { id: 'inhaler',   label: 'Inhaler',        icon: 'inhaler', unit: 'puff',        plural: 'puffs' },
  { id: 'drops',     label: 'Drops',          icon: 'drop',    unit: 'drop',        plural: 'drops' },
  { id: 'spray',     label: 'Spray',          icon: 'bottle',  unit: 'spray',       plural: 'sprays' },
  { id: 'cream',     label: 'Cream / gel',    icon: 'tube',    unit: 'application', plural: 'applications' },
  { id: 'patch',     label: 'Patch',          icon: 'patch',   unit: 'patch',       plural: 'patches' },
  { id: 'injection', label: 'Injection / pen',icon: 'syringe', unit: 'dose',        plural: 'doses' },
  { id: 'liquid',    label: 'Liquid',         icon: 'vial',    unit: 'ml',          plural: 'ml' },
];

DL_ICON_LIST = ['pills','inhaler','drop','bottle','tube','syringe','patch','vial'];

DL_PALETTE  = [lavender, sage, ochre, terracotta, dustyRose, plum, slate, moss]  // hex values from tokens
```

## Copy

All visible strings in one place for easy translation review:

| Where | Copy |
|---|---|
| Nav title | New medication |
| Nav leading | Cancel |
| Nav trailing | Save |
| Scan card headline | Scan the box |
| Scan card subhead | We'll fill in the name, form and how many doses are inside automatically. |
| CTA | Open camera |
| Reassurance 1 | Medication name |
| Reassurance 2 | Form (tablet, inhaler, drops…) |
| Reassurance 3 | Total doses in the container |
| Divider | OR |
| Fallback button | Enter manually |
| Camera top title | Scan medication |
| Camera status | Detecting label… |
| Cancel link | Cancel |
| Auto label (camera right) | Auto |
| Scan strip title | Auto-filled from photo |
| Scan strip caption | Tap any field to edit · please verify |
| Retake button | Retake |
| Form row label | Form |
| Color row label | Color |
| Quantity header (manual) | Quantity |
| Quantity header (scanned) | Quantity · detected on label |
| Quantity row | Total · {plural} |
| Schedule header | Schedule |
| Schedule add row | + Add another time |
| Remind header | Remind me |
| Remind row | Days before empty |
| Form picker title | Form |
| Icon picker title | Choose icon |
| Icon picker subtitle | Suggested for {typeLabel} |
| Default-icon caption | Default |

## Privacy notes

This is a medical app; **all medication data stays on device** is a stated
brand principle. The camera scan should run **on-device** (Vision +
RecognizeText on iOS, ML Kit on Android). If a cloud OCR call is the only
viable path for an MVP, it must be transparent in copy and audited.

## Assets

No external assets. All glyphs are inline SVG. The box illustration in the
camera viewfinder and the photo thumbnail in the auto-filled strip are
placeholders — replace with the real camera feed / captured image in
production.
