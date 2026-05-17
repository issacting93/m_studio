# M-STUDIO Product Scope

**Version:** 2.0
**Date:** 2026-05-17
**Author:** Zac Ting / NYC

---

## Vision

M-Studio is a techwear garment design tool that produces production-ready tech packs and photorealistic lookbook renders through a two-stage pipeline:

1. **M-Studio** (macOS app) — Design garments: silhouettes, measurements, graphics, colorways, fabrics, components
2. **M-Studio Bridge** (Blender 4.2+ addon) — Import designs, build 3D garments, render lookbook images

Design in M-Studio. Export a `.mstudio` package. Import in Blender. Get a rendered garment on an avatar. No manual 3D modeling.

**Product moat:** Graphic placement on garments with production-accurate specs. CLO3D, Browzwear, and Style3D all treat graphic placement as secondary to simulation. M-Studio makes it primary — and produces cleaner factory-readable graphic specs than any of them.

---

## Core Architecture Decision

**Graphics are placed on the 2D pattern, not on the 3D mesh.**

All three commercial tools (CLO3D, Browzwear, Style3D) use this paradigm. Pattern pieces map 1:1 to UV islands. The flat pattern coordinates ARE the UV coordinates. This means M-Studio's normalized `(x, y, w, h)` graphic zones map directly to UV sub-rectangles — no projection math needed.

```
Pattern Piece (2D, cm)           UV Space (0-1)                Rendered 3D
┌──────────────────┐            ┌──────────────────┐           ╭──────────╮
│                  │            │                  │          ╱            ╲
│   ┌──────────┐   │    ══►    │   ┌──────────┐   │   ══►  │  ┌────────┐  │
│   │ GRAPHIC  │   │  XY→UV    │   │ GRAPHIC  │   │  Sim   │  │GRAPHIC │  │
│   │ ZONE     │   │           │   │ ZONE     │   │        │  │ZONE    │  │
│   └──────────┘   │           │   └──────────┘   │        │  └────────┘  │
│     BACK PANEL   │           │                  │         ╲            ╱
└──────────────────┘            └──────────────────┘           ╰──────────╯
```

---

## System Architecture

```
M-STUDIO (SwiftUI)                    .mstudio (ZIP)                BLENDER BRIDGE (Python)
──────────────────                    ──────────────                ───────────────────────

Silhouette + Params  ────────►  manifest.json            ────►  Bezier curve generation
12 measurements      ────────►  (full design state)              Convert → mesh → triangulate
Construction details ────────►                                   UV from XY (no unwrap needed)
                                                                 
Sewing connections   ────────►  sewing_map.json          ────►  Loose-edge sewing springs
(auto from silhouette)          (piece_a/edge ↔                  Cloth modifier + drape sim
                                 piece_b/edge)                   
                                                                 
Colorway + Blocking  ────────►  colorways/               ────►  Per-panel Principled BSDF
Fabric               ────────►  colorway_stealth.json            Fabric physics preset
                                (per-panel colors,               Cloth mass/stiffness
                                 fabric physics)                 
                                                                 
Graphic Zones        ────────►  graphics/                ────►  cairosvg rasterize (4096px)
  SVG content        ────────►    zone-fullback.svg              Strip bg, apply tint/opacity
  Tint + opacity     ────────►    placements.json                Composite onto panel texture
  Position + scale   ────────►  (zone, panel, frame,            UV-map to zone coordinates
  Print method       ────────►   method, tint, blend)           Print-method material template
                                                                 
Components           ────────►  components.json          ────►  Hardware mesh placement
  Type + position    ────────►  (type, panel, pos)              (future: glTF trim library)
                                                                 
Graded Sizes         ────────►  grading.json             ────►  Size-specific pattern gen
  XS-XXL specs       ────────►  (all sizes + rules)             Batch render per size

                                                          ════►  OUTPUT
                                                                 ├ Lookbook renders (PNG 4K)
                                                                 ├ Turntable (MP4)
                                                                 ├ Contact sheet (colorways grid)
                                                                 └ Scene file (.blend)
```

---

## .mstudio Package Format

A `.mstudio` file is a ZIP archive:

```
design.mstudio/
├── manifest.json               # v1.0, style code, silhouette, measurements,
│                               # construction, fabric (with cloth physics),
│                               # designer, season, notes
│
├── sewing_map.json             # [(piece_a, edge_a_idx, piece_b, edge_b_idx, flip)]
│                               # per-silhouette, auto-generated
│
├── colorways/
│   ├── stealth.json            # { primary, secondary, accent, graphic } hex
│   ├── hazard.json             # + per-panel blocking assignments
│   └── ...                     # + per-graphic tint overrides per colorway
│
├── graphics/
│   ├── placements.json         # [{zone_id, piece_id, x, y, w, h,
│   │                           #   rotation_deg, anchor: "center",
│   │                           #   method: "screen"|"dtf"|"sub"|"embroidery"|"hd",
│   │                           #   tint: [r,g,b], opacity, blend: "normal"|"multiply",
│   │                           #   x_cm_from_collar, y_cm_from_cb}]
│   ├── zone-fullback.svg
│   └── zone-leftchest.svg
│
├── components.json             # [{type, panel, x, y, w, h, rotation, flipped}]
│
├── grading.json                # {base_size, graded: {XS: {...}, S: {...}, ...}}
│
├── bom.json                    # [{item, material, spec, quantity, source, cost}]
│
└── render_presets.json         # camera angles, HDRI choice, resolution
```

### Graphic Placement Schema (CLO3D-aligned)

Following CLO's `AddGraphicStyleToPattern` convention — the cleanest reference model:

- Coordinates are **normalized 0-1** relative to pattern piece bounding box
- Origin: **top-left** of piece, **Y-down**
- Anchor: **center of graphic**
- Real-world measurements (cm from collar, cm from center-back) computed at export time from pattern bounds

```json
{
  "zone_id": "uuid",
  "piece": "BACK",
  "x": 0.5, "y": 0.3,
  "w": 0.8, "h": 0.4,
  "rotation": 0,
  "method": "screen",
  "tint": [1.0, 1.0, 1.0],
  "opacity": 1.0,
  "blend": "normal",
  "file": "zone-fullback.svg",
  "absolute": {
    "x_cm_from_cb": 0.0,
    "y_cm_from_collar": 8.2,
    "width_cm": 32.0,
    "height_cm": 18.0
  }
}
```

---

## Print Method System

Print method is a **shader template enum** in the package. Each method maps to a distinct Cycles material node graph.

| Method | Roughness | Displacement | Normal Map | Notes |
|--------|-----------|-------------|------------|-------|
| **Screen** | 0.75 | 0.1-0.3mm | Subtle bump | Plastisol on fabric. MOQ 24+. |
| **DTF** | 0.45 | None | Low-amplitude from alpha | PET film transfer. <24 pcs. 100 wash cycles. |
| **Sublimation** | Same as fabric | None | Fabric normal only | Dye bonds into polyester fibers. ≥65% poly, light substrates. |
| **Embroidery** | Anisotropic | 0.5-1.5mm | Stitch-direction from alpha→Sobel | Real thread. Normal-map-only default; displacement for hero shots. |
| **HD/DTG** | 0.55 | None | None | Direct-to-garment. White underbase on darks. |

### Material Node Graph (Screen Print Example)

```
[Fabric Texture] ──► [Mix RGB (Factor: Graphic Alpha)] ──► [Principled BSDF] ──► [Output]
[Graphic Texture] ──►                                       Roughness: 0.75
                                                             [Normal Map] ──► Normal
                                                             [Bump from Alpha] ──► Normal (mix)
```

---

## M-Studio App — Feature Scope

### Graphic Engine

| Feature | Priority | Status |
|---------|----------|--------|
| SVG background stripping | P0 | Done |
| Tint system (white/accent/graphic/original) | P0 | Done |
| Per-zone opacity | P0 | Done |
| Position + scale sliders | P0 | Done |
| Graphic asset library | P0 | Done |
| Print method per zone | P0 | Todo |
| Rotation (0-360) | P1 | Todo |
| Mirror/flip | P1 | Todo |
| Multi-layer per zone | P1 | Todo |
| Blend mode (normal/multiply/overlay) | P1 | Todo |
| Aspect ratio lock | P2 | Todo |
| Mask to panel edge | P2 | Todo |
| Per-colorway graphic overrides | P2 | Todo |
| Cross-seam graphic placement | P3 | Todo |

### Tech Pack Authoring

| Feature | Priority | Status |
|---------|----------|--------|
| .mstudio package export | P0 | Todo |
| .mstudio package re-import | P1 | Todo |
| BOM editor (fabric, hardware, trims, thread) | P1 | Todo |
| Season/designer/notes metadata | P1 | Todo |
| Print placement spec (cm from collar/CB) | P1 | Todo |
| Seam allowance toggle (1cm/1.5cm) | P1 | Todo |
| Custom fabric entry (name, weight, stiffness) | P2 | Todo |
| Custom colorway editor | P2 | Todo |
| Data-driven PDF tech pack | P1 | Todo |

### Workflow

| Feature | Priority | Status |
|---------|----------|--------|
| Undo/redo | P1 | Todo |
| Design iterations/snapshots | P2 | Todo |
| Collection mode (multi-garment) | P3 | Todo |

---

## Blender Bridge — Feature Scope

### Pattern Generation

| Feature | Priority | Status |
|---------|----------|--------|
| 6 silhouette Bezier generators | P0 | Done (in bridge) |
| Curve → mesh → triangulate (5mm edge) | P0 | Partial |
| UV from XY (no unwrap) | P0 | Todo |
| Sewing map (loose-edge springs) | P0 | Done (in bridge) |
| Store pattern bounds as custom property | P0 | Todo |
| Curved seams (armhole, neckline) | P1 | Todo |
| Seam allowance from package | P1 | Todo |
| Dart support | P2 | Todo |

### Cloth Simulation

| Feature | Priority | Status |
|---------|----------|--------|
| Cloth modifier with sewing springs | P0 | Partial (via garment_tool) |
| Native Blender sewing (no garment_tool dep) | P0 | Todo |
| Fabric physics from .mstudio preset | P0 | Done (fabric_presets.py) |
| Sewing force keyframe (0→30 over 20 frames) | P0 | Todo |
| Collision mannequin | P0 | Done (basic cylinder+sphere) |
| Curated mannequin set (4-6 poses) | P1 | Todo |
| Pin groups (shoulder vertices) | P1 | Todo |
| Parametric avatar (MakeHuman/MPFB2) | P3 | Todo |

### SVG → Texture Pipeline (critical new work)

| Feature | Priority | Description |
|---------|----------|-------------|
| cairosvg rasterization | P0 | SVG → PNG at 4096px, transparent bg |
| Background rect stripping | P0 | XML pre-process, not pixel keying |
| Tint application | P0 | Multiply RGB by tint color, preserve alpha |
| Opacity | P0 | Scale alpha channel |
| Panel texture composite | P0 | Place graphic at (x,y,w,h) on panel atlas |
| Print-method material templates | P1 | 5 shader graphs (screen/DTF/sub/emb/HD) |
| Normal map from alpha (embroidery) | P1 | Sobel edge detection → normal map |
| Displacement (embroidery hero shots) | P2 | Cycles adaptive subdivision |
| Multi-colorway texture swap | P1 | Per-colorway tint overrides |
| Blend modes (normal/multiply/overlay) | P1 | Composite math in pixel buffer |
| Bake Atlas button (for export) | P2 | Cycles bake, diffuse pass, per-panel |

**Dependency:** cairosvg + cairocffi + Pillow vendored inside addon ZIP. Tested on macOS Apple Silicon.

### Render Pipeline

| Feature | Priority | Status |
|---------|----------|--------|
| Cycles render engine | P0 | Done (128 samples) |
| Upgrade to 256-512 samples + OIDN denoiser | P0 | Todo |
| AgX color management (not Filmic) | P0 | Todo |
| Studio HDRI (Poly Haven) | P0 | Todo |
| 4 camera presets (front/back/3-4/detail) | P0 | Todo |
| One-click render button in addon panel | P0 | Todo |
| Batch colorway renders | P1 | Todo |
| Turntable animation export | P2 | Todo |
| Contact sheet (colorway x angle grid) | P2 | Todo |
| Resolution/format settings in panel | P1 | Todo |
| EEVEE preview mode (design-time) | P2 | Todo |

### Render Defaults

- **Engine:** Cycles, 256-512 samples, adaptive sampling (noise threshold 0.01), OpenImageDenoise
- **Color:** AgX (handles whites and metallics better than Filmic)
- **Lighting:** Studio HDRI (80% of the look) + rim light + fill area light
- **Cameras:**
  - Front: 85-100mm, eye level, 0deg
  - Back: same, 180deg
  - 3/4: 45deg around Z, 5deg tilt
  - Detail: 200mm, DOF f/4, focused on graphic zone
- **Resolution:** 4K (3840x2160) for hero, 2K for batch
- **Output:** PNG (lookbook), EXR (compositing), MP4 (turntable)

---

## Implementation Roadmap

### Stage 1: Core Data Path (4-6 weeks)

**Goal:** Prove the pipeline end-to-end with one garment + one graphic.

M-Studio side:
- [ ] Implement `PackageExportService.swift` — builds .mstudio ZIP
- [ ] Add print method enum to `GraphicZoneConfig`
- [ ] Add rotation/flip to `GraphicZoneConfig`
- [ ] Export button in inspector
- [ ] Season/designer/notes fields in `DesignState`

Bridge side:
- [ ] `.mstudio` ZIP parser (replaces raw JSON import)
- [ ] Pattern piece → mesh → triangulate (5mm target edge)
- [ ] UV assignment from XY coordinates (no unwrap step)
- [ ] cairosvg SVG → PNG rasterization (vendored)
- [ ] Background strip + tint + opacity bake
- [ ] Composite graphic onto panel texture at zone coordinates
- [ ] Single Principled BSDF per panel (no print method differentiation yet)
- [ ] One camera angle, EEVEE preview

**Success threshold:** A black t-shirt with a chest logo renders correctly with the logo at the right size and position.

### Stage 2: Sewing Simulation + Full Silhouettes (4-6 weeks)

**Goal:** All 6 silhouettes drape onto an avatar via native Blender cloth sim.

- [ ] Native sewing springs (loose edges, no garment_tool dependency)
- [ ] Sewing force keyframe (0→30 over frames 1-20)
- [ ] All 6 silhouettes generate + drape correctly
- [ ] Collision avatar (curated mannequin, not parametric)
- [ ] Shoulder pin groups for stability
- [ ] Fabric physics from .mstudio preset (mass, tension, bending)
- [ ] Cycles render with studio HDRI + 3 lights

**Success threshold:** Hoodie generates, drapes onto avatar, sleeves attached, shoulders pinned. Cycles render at 4K in <5 minutes per camera.

### Stage 3: Print Method Differentiation (3-4 weeks)

**Goal:** Same graphic renders differently based on print method.

- [ ] 5 material templates (screen/DTF/sub/embroidery/HD)
- [ ] Normal map generation from graphic alpha (screen, embroidery)
- [ ] Displacement for embroidery hero shots (optional toggle)
- [ ] Per-colorway tint overrides in package
- [ ] Multi-colorway texture swap at render time
- [ ] Print method selector in M-Studio inspector

**Success threshold:** Same SVG on same shirt renders distinguishably as screen print vs embroidery vs DTF.

### Stage 4: Lookbook Polish (2-3 weeks)

**Goal:** One-click batch lookbook output.

- [ ] 4 camera presets (front/back/3-4/detail)
- [ ] HDRI library selector (3 options)
- [ ] 3 lighting setups (studio/golden hour/dramatic rim)
- [ ] Batch render across all colorways
- [ ] Tech pack JSON with cm-accurate placement measurements
- [ ] Data-driven PDF tech pack from .mstudio data
- [ ] Render settings panel in addon sidebar

**Success threshold:** Hit "Render Collection" once → get 4-angle x N-colorway lookbook set.

### Stage 5: Extension Surface (ongoing)

- [ ] Components as glTF trim imports (zippers, drawcords, buckles)
- [ ] Cross-seam graphic placement (anchor piece + bleed pieces)
- [ ] Embroidery hair-particle hero shots (optional)
- [ ] Export to glTF/USD for web viewer
- [ ] Collection mode (multiple garments, shared colorway)
- [ ] Parametric avatar (MakeHuman/MPFB2)
- [ ] Design iterations/snapshots in M-Studio
- [ ] Undo/redo

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| cairosvg install fragile on macOS Apple Silicon | Blocks Stage 1 | Vendor cairosvg + cairocffi + Pillow in addon ZIP. Test on AS specifically. |
| Cloth sewing instability (aggressive shrink) | Broken drape | Keyframe sewing force 0→30 over 20 frames. Document in addon. |
| UV ambiguity when joining pieces for sewing | Texture bleed | Keep UV islands at separate origins (piece_a u∈[0,0.5], piece_b u∈[0.5,1]) |
| Graphic-across-seam coordinate math | Complex | Defer to Stage 5. Store as anchor_piece + bleed_pieces in placements.json. |
| garment_tool is paid dependency ($40) | Licensing | Replace with native Blender cloth + sewing springs (Stage 2). Strategic win. |
| Render time >10min/camera | Batch unusable | 128 samples + OIDN. No displacement unless explicitly toggled. |
| Stage 1 exceeds 8 weeks | Pipeline structural problem | Pause, consult CLO API design as ground truth for data model. |

---

## Replanning Triggers

- **Stage 1 > 8 weeks:** cairosvg + UV pipeline has structural problem. Re-evaluate rasterization approach.
- **Cloth sim unstable past keyframe fix:** Switch to Geometry Nodes simulation zones (Blender 3.6+).
- **Render > 10 min/camera in Stage 3:** Drop to 128 samples + OIDN. Check for accidental global displacement.
- **Graphic placement drift across colorways:** Bug is active UV map not preserved on duplicate. Fix: explicit `uv_layers.active_index` assignment.

---

## Out of Scope

- Cloth physics simulation authoring (use Blender's built-in or garment_tool)
- Real-time 3D in M-Studio (keep as rough preview only — Blender is the real 3D output)
- CLO3D ZPRJ import (proprietary, no public spec)
- Browzwear BW import (no public artwork API)
- Style3D interop (no public API)
- Collaboration / multi-user
- Mobile / iPad version
- AI graphic generation (existing Claude API feature stays experimental)
- E-commerce / storefront integration
- Pattern grading beyond current linear grade rules
- Surface painting workflow (Substance Painter handles this externally)

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| M-Studio app | SwiftUI, macOS 14+, @Observable |
| 2D rendering | Canvas + GraphicsContext |
| 3D preview | SceneKit (rough preview only) |
| SVG parsing | Custom (SVGRenderer.swift) |
| Package format | ZIP (.mstudio extension) |
| Blender bridge | Python 3.11+, Blender 4.2+ addon |
| Pattern geometry | Procedural Bezier curves from measurements |
| SVG rasterization | cairosvg (vendored) + Pillow |
| Cloth simulation | Blender native cloth modifier + sewing springs |
| Render engine | Cycles (hero) / EEVEE Next (preview) |
| Color management | AgX |
| Denoiser | OpenImageDenoise |
| Avatar (v1) | Curated mannequin set (4-6 .blend assets) |
| Avatar (future) | MakeHuman / MPFB2 |

---

## Key References

- CLO3D Python API: `AddGraphicStyleToPattern` signature (center anchor, Y-down, mm units)
- garment_tool (Bartosz Styperek): Bezier-to-cloth-with-sewing precedent
- Blender cloth sewing: loose edges + `use_sewing_springs` + `sewing_force_max`
- BlenderProc `MaterialUtility.py`: Principled BSDF construction patterns
- Poly Haven studio HDRIs: `studio_small_03_4k`, `photo_studio_01_4k`
