# M-STUDIO / Pattern Lab v0.3

A native macOS/iOS/visionOS garment design tool for techwear — from concept to factory-ready tech pack.

Designed by Zac Ting (NYC, 2026). Targets independent techwear designers taking garments from concept to small-batch production (30-100 unit MOQs).

## Current State

**Working features:**
- 4 silhouettes: Noragi, Bomber, Hoodie, Parka
- 6 parametric controls: body length/width, overlap, sleeve length/bicep/cuff
- 2D garment elevation (front + back) with draggable graphic zone
- 3D SceneKit preview with rotation/zoom
- Flat pattern cut layout with dimensions
- 4-colorway comparison sheet
- Size grading table (XS-XXL) with industry grade rules
- Sourcing supplier reference sheet
- 8 colorways, 6 fabrics
- 3 graphic styles (mil-spec, mecha, typo) + AI placeholder
- DXF and JSON tech pack export
- Save/load designs to file system

## What's Missing vs. Real Production Needs

### 1. Measurement Points (POMs)

Real tech packs have 15-25+ points of measure. Current tool has 6. Factory-required measurements still needed:

| Missing POM | What It Is | Why It Matters |
|---|---|---|
| Shoulder Width | Seam-to-seam across back | Defines fit silhouette — oversized = wider |
| Neck Opening | Width and depth of neckline | Affects collar/hood attachment |
| Armhole Depth | Shoulder seam to underarm | Controls sleeve mobility |
| Hem Width | Bottom opening, laid flat | Tapered vs boxy fit |
| Hood Height/Width/Depth | 3 dimensions of hood | Hood proportions affect entire garment look |
| Pocket Placement (x,y) | Distance from hem and center front | Factories need exact coordinates |
| Belt/Strap Position | Height from hem where belt sits | Noragi/kimono closure placement |
| Yoke Depth | Shoulder area panel height | Common construction detail |
| Collar Height | Stand collar or funnel neck height | Key design variable (3-15cm range) |

### 2. Multiple Graphic Zones

Current tool: single back graphic zone. Real techwear designs (see inspiration images) place graphics across:

- **Left/Right Chest** — 7.5-10cm square, logo/patch area
- **Center Chest** — 20-25cm wide, main front graphic
- **Full Back** — 30-40cm wide, primary large graphic
- **Upper Back** — Between shoulders, secondary detail
- **Left/Right Sleeve** — 7.5cm wide x 30-35cm long, full sleeve graphics
- **Hood** — Back panel of hood, 15-20cm square
- **Hem Band** — Full circumference, small repeat text
- **Pocket Flap** — Per-pocket branding

Each zone needs: position (x,y relative to seam references), dimensions, print method (screen/DTF/sublimation/embroidery), and independent SVG content.

### 3. Color Blocking

Current: single primary color per garment. Needed: per-panel color assignment.

Techwear frequently uses 2-3 tone color blocking (e.g., black upper + orange lower, contrasting sleeve panels, different hood color). Each major panel should have independent color:
- Upper body / yoke
- Lower body
- Left sleeve / right sleeve
- Hood
- Pockets
- Collar/cuffs/hem trim

### 4. Missing Construction Features

From the inspiration images and production reality:

| Feature | Type | Notes |
|---|---|---|
| Buckle/webbing belt | Closure | Side-release buckle on nylon webbing (noragi) |
| MOLLE webbing | Pocket detail | Mil-spec 25mm webbing grid on cargo pockets |
| Zippered welt pockets | Pocket | Most common techwear pocket type |
| Funnel/high neck collar | Collar | 8-15cm stand collar, covers lower face |
| Thumb-hole cuffs | Cuff | Extended cuff with thumb opening |
| Drawcord hem | Hem | Adjustable hem cinch |
| Baffle/quilting | Construction | Horizontal/chevron quilt lines for puffers |
| Storm flap | Closure | Wind flap over main zipper |
| Asymmetric zip | Closure | Off-center zipper placement |
| Taped seams | Construction | Waterproof seam sealing |

### 5. Missing Garment Types

- **Pullover hoodie** — No front zip, kangaroo pocket, currently only zip hoodie exists
- **T-shirt** — Simplest garment, most common for graphic placement
- **Puffer jacket** — Insulated construction with baffles, very different from shell jackets
- **Vest** — Sleeveless variant of bomber/puffer
- **Pants/joggers** — Natural extension for full-outfit design

### 6. Fabric System Improvements

Current fabric picker doesn't distinguish by garment type. Hoodies use 320-500+ GSM fleece/french terry. Shells use 40-80 GSM nylon. Puffers need shell + lining + insulation specs.

Needed:
- GSM slider per fabric category
- Fabric categories: fleece, french terry, jersey, ripstop, taffeta, cordura, mesh
- Composition (80/20 cotton/poly, 100% nylon, etc.)
- Treatments: DWR, waterproof membrane, anti-pilling, brushed interior
- Multi-layer support: shell + insulation + lining (puffer construction)

---

## Design Process & Workflow

### What This Tool Should Handle (Digital/Parametric)

1. **Silhouette definition** — Select garment type, set all POMs via sliders
2. **Flat pattern generation** — Auto-generate cut pieces from measurements
3. **Size grading** — Apply industry grade rules across size range
4. **Colorway exploration** — Set per-panel colors, compare variants side-by-side
5. **Graphic zone definition** — Place and size print zones on the garment
6. **Spec table generation** — Auto-populate tech pack measurement tables
7. **Material costing** — Calculate yardage and per-unit material cost
8. **Sourcing reference** — Supplier database for fabrics, hardware, factories
9. **Export** — DXF for cutting, JSON spec for factories, PDF tech pack sheets

### What Requires External Software (Import Into This Tool)

1. **Graphic/artwork design** — Create SVGs in Illustrator/Figma/Affinity, import as graphic zone content
2. **Photorealistic rendering** — CLO3D/Marvelous Designer for fabric drape simulation
3. **Detailed construction drawings** — CAD software for seam details and stitch specs
4. **Mood boards / reference collages** — Collected externally, referenced in design briefs

### What Requires a Human Designer

1. **Proportion decisions** — How oversized? How cropped? Where does the silhouette break?
2. **Fabric hand/drape judgment** — How the material moves, falls, and feels — can't be parametrized
3. **Graphic/brand identity** — The actual artwork, typography, and visual language
4. **Construction method selection** — Which seam types, which finishing techniques
5. **Fit validation** — Muslin/toile samples on body, adjusting from physical feedback
6. **Color approval** — Lab dips, Pantone matching — screen colors ≠ fabric colors
7. **Factory communication** — Reviewing samples, negotiating specs, quality control
8. **Costing negotiation** — MOQ discussions, bulk pricing, shipping logistics

### What AI Can Assist With

1. **Graphic generation** — Generate Machine56-style SVG graphics from text prompts (already partially implemented via Anthropic API)
2. **Measurement suggestions** — Given a silhouette and fit intent ("oversized streetwear"), suggest POM values
3. **Grade rule optimization** — Suggest grade rules based on garment type and target market
4. **Material recommendations** — Given design requirements (waterproof, breathable, <$15/yd), suggest fabrics
5. **Spec validation** — Flag impossible or unusual measurement combinations
6. **Colorway generation** — Suggest complementary colorways from a primary color
7. **Tech pack translation** — Auto-generate factory-ready Chinese/Vietnamese spec sheets
8. **Cost estimation** — Estimate CMT costs given garment complexity and production volume

---

## Architecture

### File Structure

```
m_studio/
├── m_studioApp.swift              # App entry, window config
├── ContentView.swift              # Main layout — split view + tabs + spec bar
├── Models/
│   ├── DesignState.swift          # @Observable state, enums, grade rules
│   ├── Colorway.swift             # 8 colorways with Color values
│   ├── Fabric.swift               # 6 fabrics with specs/costs
│   ├── DesignStorage.swift        # Save/load designs to file system
│   └── ExportService.swift        # DXF, JSON tech pack export
├── Views/
│   ├── SidebarView.swift          # Controls sidebar — all parametric inputs
│   ├── GarmentCanvasView.swift    # 2D front/back elevation with drag zones
│   ├── ThreeDView.swift           # SceneKit 3D preview
│   ├── FlatPatternView.swift      # Cut layout with dimensions
│   ├── ColorwaySheetView.swift    # 4-colorway comparison
│   ├── SizeGradeView.swift        # Graded measurement table
│   └── SourcingView.swift         # Supplier reference sheet
└── Renderers/
    └── GarmentRenderer.swift      # 2D garment drawing via SwiftUI Canvas
```

### Key Design Decisions

- **SwiftUI + Canvas** for all 2D rendering — hardware-accelerated, resolution-independent
- **SceneKit** for 3D preview — simpler than Metal, good enough for spatial reference
- **@Observable** state — single source of truth, all views re-render on any change
- **File system storage** — designs saved as JSON in Documents directory
- **Multiplatform** — iOS, macOS, visionOS from single codebase

### Design Language (v0.4+)

Warm, modern-retro aesthetic inspired by Nothing OS / PlayerZero. Clean, breathable, rounded.

**Palette:**
- Background: `#f5f3ef` (warm white)
- Surface: `#ffffff` (cards/panels)
- Ink: `#1a1a1a` (primary text only)
- Soft: `#999691` (secondary/labels)
- Accent: `#d63d2e` (actions)
- Border: `rgba(0,0,0,0.06)` (subtle separators)

**Typography:**
- Inter / SF Pro for UI text
- JetBrains Mono for spec values and measurement data only
- Archivo for brand/display headings
- Mixed case, not all-caps — Title Case for sections, sentence case for labels

**Components:**
- Pill-shaped buttons with 6-8px radius
- Card-style sections with subtle background tint and rounded corners
- Smooth 0.2s animations on state changes
- SF Symbols for all icons
- Generous padding and whitespace throughout

### Conventions

- Measurements in centimeters
- Silhouette codes: `M-{3-letter}-001`

## Running

Open `m_studio.xcodeproj` in Xcode 26+ and run for macOS, iOS, or visionOS.

The original browser-based prototype is also available: open `m-studio-pattern-lab-v0.3.html` in any browser.
# m_studio
