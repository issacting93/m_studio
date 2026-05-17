ns
# M-Studio Bridge: Architecture Research for a Blender-Native Garment & Graphic Placement Pipeline

## TL;DR
- **All three commercial tools (CLO3D, Browzwear VStitcher/Lotta, Style3D) place graphics on the 2D pattern, not on the 3D mesh, and rely on a 1:1 pattern-piece ↔ UV-island mapping where the UV layout is literally the flat pattern in real-world mm** — this is the single most important architectural decision M-Studio Bridge should inherit, because it lets the SVG normalized (x, y, w, h) coordinates from .mstudio packages map directly to UVs without projection math.
- **CLO3D is the only tool with a first-class scriptable graphic-placement API** — `AddGraphicStyleToPattern(patternIndex, graphicStyleIndex, x, y, width, height, face, zOffset, angle)` with top-left origin, Y-down, center-of-graphic anchor, mm units — and this signature is the cleanest reference model for the M-Studio data structure on disk.
- **For the Blender side, the right stack is: cairosvg for rasterization → Blender's native cloth simulation with sewing springs on loose edges → procedural pattern UV pinning so UVs match cm-scale pattern coordinates → per-print-method material node templates (screen / DTF / sublimation / embroidery / HD) → Cycles for hero renders with HDRI + 4-camera presets.** Bake graphics into a per-panel atlas only for export-to-engine; composite at render time during design iteration.

## Key Findings

1. **Pattern-piece-based placement is the universal paradigm.** CLO3D, Browzwear, and Style3D all treat the 2D pattern window as the authoring surface for graphics. The 3D view exists only as a fitting/preview window — the graphic moves on the 2D pattern, and the UV-bound 3D triangulation re-samples it automatically. There is no surface-painting workflow in any of the three; Substance Painter handles that case externally.
2. **UV islands are pattern pieces, one-to-one.** Every commercial tool generates UVs by laying the flat 2D pattern directly into UV space, optionally normalized to 0–1 (CLO's "Reposition all UVs to 0-1" / Browzwear's "Single UV Layout per Piece" / Style3D's UV Editor with auto-layout). For seam-crossing graphics, CLO supports "Graphic across seams" since v6.0 — internally this is still a 2D placement that crosses the boundary between two pattern UV islands.
3. **CLO is scriptable; Browzwear is scriptable but artwork-placement is not first-class; Style3D has no public API.** CLO's Python API exposes ~10 graphic-related functions including `AddGraphicStyleToPattern`, `GetGraphicStylePosition`, `SetGraphicBaseColorMapTexture`, `SetGraphicStyleColor`, and `ReplaceGraphicStyleFromImage` (with a 9-position anchor enum). Browzwear's `BwApi` (Python/C++/C#) covers garments, materials, colorways, and render output — but there is no public `ArtworkPlace(x, y)` function; artwork goes through the materials subsystem and the Adobe Illustrator integration.
4. **Print method differentiation is shader-based, not pipeline-based.** None of the three tools has a true "print method" abstraction. Instead, designers add normal maps (for embroidery height), displacement maps (for puff/foil), and Substance .sbsar parametric materials (for metallic, glitter, puff). CLO classifies graphics as "embroidery / logo / print" in the property editor, but this is a label, not a behaviour switch — the visual difference comes from manual normal/displacement map assignment.
5. **Texture resolution conventions are 1K, 2K, 4K with 4K as the working default; 8K for production bakes.** VNTANA's CLO export guide explicitly recommends "1K or 4K textures with a DPI of 300." The Pictofit/CLO production guide specifies 8192 for final OBJ texture bakes. Browzwear's Substance materials default to 2048×2048 at 72 DPI from version 2022.1+.
6. **Tech-pack graphic-placement export is weak across all three tools.** CLO has "Extract Graphic Placement" inside its UI for production specs, but the CLO-SET Excel tech pack export is described by users as "very basic" — measurement detail for graphics often does not survive the export. Browzwear's Excel tech pack supports artwork with measurements and position. This is a real opportunity for M-Studio: producing a clean, factory-readable graphic spec from normalized coordinates is genuinely better than the incumbents' default output.
7. **`garment_tool` (Bartosz Styperek) — your current dependency — is the closest open precedent.** It already generates simulation-ready meshes from 2D Bezier sewing patterns, triangulates them, sets up cloth modifiers, and supports sewing-pattern presets. The replacement strategy should be: keep its Bezier-curve-to-mesh-with-sewing-springs core idea, but rebuild it as a clean Python module under your control rather than a third-party addon dependency.
8. **Blender has native sewing-spring support built into the cloth modifier.** Loose edges (edges not part of any face) between mesh islands are treated as sewing springs when the "Sewing" checkbox is enabled in the cloth Shape panel, with a configurable Max Sewing Force. This is the canonical Blender mechanic and you do not need a custom solver.

## Details

### Tool-by-tool deep dive

#### CLO3D

1. **Graphic placement workflow.** Tool lives under `Main Menu ▶ Materials ▶ Graphics ▶ Graphic (2D Pattern) / Graphic (3D Pattern)` and in both the 2D and 3D toolbars. The 2D-Pattern variant is canonical: click on a pattern piece, an "Add Graphic" dialog appears with Width / Height / Position fields, and the graphic is placed with its centre at the chosen point. The 3D variant projects onto the live 3D mesh and is recommended only for "applying graphics that cross a seam" (per official help). Designers can also right-click an image in CLO Library and "Add as Graphic." AI/PDF imports prompt for artboard and layer selection.
2. **UV mapping and projection.** CLO generates UVs by placing each pattern piece's mesh in 2D UV space at its real-world flat-pattern coordinates. There is no separate unwrap step — the UV is the pattern. The UV Editor offers "Reset to 2D Arrangement" and "Reposition all UVs to 0-1" for atlas export. Side meshes (from pattern thickness) collapse to a UV line and don't get usable UV territory — a documented limitation acknowledged on CLO's support forum.
3. **Print method handling.** Graphics are classified in the Property Editor as **embroidery / logo / print** — but this is a metadata label, not a behaviour switch. The visible difference between these comes from the user attaching: (a) a **normal map** for surface bumpiness (CLO ships a default fabric normal-map library and auto-generates normal maps from textures when you adjust the Normal Map intensity slider); (b) a **displacement map** (greyscale, controls protrusion height in Render mode — values that are too high cast undesirable shadows); (c) **clipping/opacity** for cutout-style graphics; (d) a **specular/reflective material preset** for screen-print sheen. Embroidery rendering in CLO is fundamentally displacement-map-based, not geometry-based.
4. **Texture resolution and atlas.** Working textures of around 1K–4K at 300 DPI are the recommended default; production bakes go to 8K with 64-pixel "Fill Texture Seams" padding. The Texture Bake tool composites graphic layers onto the panel texture for export. Designers can choose per-export whether to bake or to keep graphics as separate textures.
5. **File format.** ZPRJ (project) is a proprietary container — sometimes ZIP-extractable with 7-Zip but often not, depending on save settings. Companion formats: ZPAC (garment), PACX (2D pattern), ZFAB (fabric), TRM (trim), AVT (avatar), ZACS (accessory). Graphic placement data is stored inside the ZPRJ. From the API surface we can infer the on-disk schema per graphic instance is approximately `(patternIndex, graphicStyleIndex, centerX_mm, centerY_mm, width_mm, height_mm, face_enum, zOffset_mm, angle_deg)` — pattern-local coordinates, top-left origin, Y-down, centre anchor. No public reverse-engineered binary spec exists.
6. **Tint, opacity, blending.** Graphics have a base colour, opacity, and texture-channel desaturation (for recoloring single-colour graphics). The Colorway feature stores per-colorway texture variants per graphic — you can have different graphic positions, angles, and colours per colorway by unchecking "Link All Colorways ▶ Angle or Position" in the Property Editor.
7. **Repeating vs placed.** CLO distinguishes them at the **material assignment level**: fabric textures are tile-mapped to pattern pieces (the fabric's tile width/repeat determines coverage), while graphics are discrete placed instances with explicit X/Y/W/H. Graphics can also be tiled via right-click Tile Options (X-axis tile, Y-axis tile) if you want a placed-graphic-with-repeat behaviour. The forum example for all-over-print production explicitly recommends "apply it to the fabric and not as a graphic" — i.e. for true repeats use the fabric channel.
8. **Tech pack export.** CLO's "Extract Graphic Placement" tool emits dimensional information for production. The downstream CLO-SET Web Tech Pack reports BOM, measurement (auto-generated from 2D POM), and material placement. User feedback in the support forum consistently flags graphic-placement detail in the Excel export as "very basic" — buttons, sliders, zippers often show in wrong colours and stitch info is missing.
9. **Performance.** Per CLO's official support article *CLO system requirements (March 2026)*: "RAM: 16GB or higher · GPU: NVIDIA GeForce GTX 1060 and above (Except Quadro series, graphic cards with G3D Mark above 8000), latest drivers and at least 4GB of graphics memory (GTX 1080 is recommended for better render efficiency.)" Topstitching can be set to "Texture" rather than "OBJ" to reduce poly count. CLO has both a real-time OpenGL viewport and a V-Ray-based offline render mode.

   **CLO Python API for graphics (verbatim from developer.clo3d.com / developer.marvelousdesigner.com):**
   ```python
   AddGraphicStyleToPattern(patternIndex, graphicStyleIndex,
                            x, y, width, height,    # pattern-space mm, center anchor, Y-down
                            face,                    # 0=Front, 1=Back, 2=Both
                            zOffset, angle) -> bool
   GetGraphicStylePosition(graphicIndex, is2D)
                            # -> dict[patternIndex, list[list[float]]]
   SetGraphicBaseColorMapTexture(imageFilePath, graphicStyleIndex)
   SetGraphicStyleColor(styleIndex, r, g, b, a)
   ReplaceGraphicStyleFromImage(graphicStyleIndex, imagePath, anchor)
                            # anchor: 0=center, 1=up, 2=right-up, 3=right,
                            # 4=right-down, 5=down, 6=left-down, 7=left, 8=left-up
   CloApiGraphicDimensions: struct { width: float; height: float }
   ```

   The docstring states: *"X-axis represent the horizontal position relative to this point, moving to the right … Y-axis represent the vertical position relative to this point, moving downward. For example, in a 100×100 pattern, the bottom-right corner is located at (100, 100). Place the graphic so that its center aligns with the specified (X, Y) coordinates."* Units (mm) are inferred from the rest of the API consistently using mm; they are not explicitly stated in this particular docstring.

#### Browzwear VStitcher / Lotta

1. **Graphic placement workflow.** Artwork is added by dragging from the Materials tab to a pattern piece in the 2D window, or via the Assign tool. The same drag onto a fabric converts artwork into an "allover print" — Browzwear's distinguishing concept. There is a direct **Adobe Illustrator integration** where AI prints are dragged onto the garment and any change in AI propagates back. The "Design in Sizes" feature lets you position artwork differently across the size range (S, M, L can have differently scaled or positioned art).
2. **UV mapping and projection.** Per-piece UV layouts are the default ("Single UV Layout per Piece"). The 2022.2+ "Pack UVs" feature optimises pattern pieces into a single 0–1 atlas (loses per-piece texel density, doesn't work with 3D trims). Two export UV modes exist — "Native UV" preserves layered Browzwear structure (seams, thickness, tiling); "Layout UV" creates a single packed texture for game engines.
3. **Print method.** Browzwear's material system is **PBR-based with parametric Substance (.sbsar) artwork effects**. Stock effects include "Stick Metallic print" and "Puff glitter print." Switching Material mode from PBR to Substance unlocks Substance-driven artwork. PBR layers in Browzwear: diffuse, specular, specular tint, roughness, normal, metalness, subsurface, displacement. Specular intensity in Browzwear ranges 0–10 (not the standard 0–1) for legacy Phong compatibility.
4. **Texture resolution.** Substance materials default to 2048×2048 at 72 DPI in VStitcher 2022.1+; older versions used 1024×1024.
5. **File format.** Native: `.bw` (single-file container, includes preview image, replaces legacy VSGX since 2019 August). Legacy: VSGX (working file with associated folder structure), VSP (zipped bundle for sharing). Artwork is stored as referenced texture assets within the BW container.
6. **Tint / opacity.** Diffuse layer can be recoloured per colorway; opacity is a separate channel; specular tint controls how much diffuse colour presents in the shiny areas (1.0 = full recolour of highlights).
7. **Repeating vs placed.** Explicit "Allover Print" command in the context menu converts artwork to a fabric-channel tile; placed artwork remains discrete. When you convert artwork to allover print, "the system automatically creates a vector fabric" (per Browzwear help).
8. **Tech pack export.** Excel tech pack with BOM, colorways, fabrics, trims, artwork (with measurements and position), 3D or schematic preview, exported as one Excel file or as folders (pattern pieces / BOM / artwork). DXF, rulers, and a new AI file with updated colours are all exported in print-to-file mode. This is meaningfully more production-friendly than CLO's tech pack output.
9. **Scripting.** `BwApi` module exposed in Python/C++/C#. API namespaces: Animation, AssetManagement (Material), CAD (Garment, Shape, Edge, Cluster, Colorway, Dart, etc.), General (Shoes, Avatar, Environment, Render, Snapshot). Public examples use `BwApi.CoordinatesXY(x, y)` for pattern-local geometry. **Notable gap: there is no documented `ArtworkPlace(x, y, w, h)` API** — artwork manipulation routes through `BwApi.MaterialGet` / `MaterialUpdate` / `MaterialUpdateFromFile`. Third-party reference plugins exist (BeProduct's Browzwear plugin on GitHub; VNTANA).

#### Style3D (Studio / Atelier)

1. **Graphic placement workflow.** Style3D Studio's graphic placement mirrors CLO conceptually — graphics are applied to pattern pieces in the 2D window with X/Y positioning. The newer (2025) feature set leans heavily on AI: text-to-pattern generation, AI seamless texture generation, AI auto-UV unwrapping. There is less public detail on the exact UI than CLO/Browzwear.
2. **UV mapping.** Style3D Atelier "doesn't quite work with textures and UV maps the same way as other 3D applications like Blender" (KatsBits) — patterns are scaled relative to real-world cm dimensions and the texture is applied based on physical scale rather than 0–1 UV normalization, with a UV Editor that supports auto-layout export for Blender/external tools and a customizable checkerboard (32, 64, 128, 256, 512, 1024 grid sizes) for inspection.
3. **Print method.** Realistic-fabric workflow uses base colour + normal + displacement + roughness + specular maps. AI-driven seamless tile generation aligns texture edges for infinite tiling. No specific embroidery / DTF / sublimation differentiation in the documented feature set — it's PBR-based like the other two.
4. **Texture resolution.** Style3D AI's seamless texture generator outputs production-ready PBR maps suitable for 4K workflows; specific defaults are not published.
5. **File format.** Native format is the Style3D project format (`.sproj` mentioned in KatsBits Atelier exercises; `.sbtn` for fabric texture assets). Less publicly documented than CLO's ZPRJ or Browzwear's BW.
6. **Other.** Style3D explicitly positions itself as integrating with CLO3D, Unreal Engine, and Blender. Notable forward-looking feature: "AI auto-UV unwrapping" using deep-learning-predicted seam lines — this is on the industry roadmap but you don't need it for M-Studio because pattern-piece-based UVs are already optimal.

   **There is no public Python/C++ API for Style3D**; integration is file-format-only.

### How fashion print methods actually differ (production reality the addon must represent)

This matters because M-Studio is a techwear tool — print method affects both visual rendering AND the tech pack output factories receive.

- **Screen print:** Plastisol ink sits on top of fabric, opaque, slightly thick hand-feel. It is dominant for runs of 24+ pieces — the standard industry MOQ — per Battle Born Clothing's 2026 screen-print pricing guide: *"Most professional screen printing shops … set a minimum around 24 pieces for screen printing. Below that, the setup costs make each shirt disproportionately expensive."* In a renderer: high-roughness, very slight displacement (~0.1–0.3 mm), subtle specular bump, hard edges.
- **DTF (Direct-to-Film):** Water-based or UV-cured inks on PET film, transferred via heat press, with durability of up to 100 wash cycles per DTFTransfers.com's care guide: *"A well-applied DTF transfer holds up through up to 100 wash cycles — and won't crack even in high-flex areas like sleeves and collars"*; independently confirmed by a documented DTF Dallas product test in which a transfer pressed for only three seconds *"was still vibrant and fully intact"* after 100 complete wash-and-tumble-dry cycles. Best for orders under 24 pieces, per NW Custom Apparel's screen-printing guide: *"Screen printing is the most cost-effective decoration method for orders of 24 pieces or more. For orders below that threshold, two alternatives make more sense … Direct to Film printing (DTF)."* In a renderer: slightly glossy, very thin layer, fine detail capable.
- **Sublimation:** Dye gases bond into polyester fibres — print is *in* the fabric, not on it. Requires ≥65% polyester, white/light substrates only. In a renderer: roughness identical to base fabric, zero displacement, follows fabric normal map exactly (no separate "print layer").
- **Embroidery:** Real stitched thread. Hand-feel and structural depth that no flat print can replicate. In a renderer: significant normal map (anisotropic stitch direction), 0.5–1.5 mm displacement, individual thread sheen approximated via anisotropic specular.
- **HD print / DTG:** High-resolution direct-to-garment, best on cotton, requires white underbase on dark garments. In a renderer: roughness slightly above fabric, no displacement, slight darkening on dark substrates from underbase modelling.
- **UV DTF "faux embroidery":** Multi-pass UV-cured ink builds genuine 3D texture mimicking stitches. In a renderer: treat as a hybrid — embroidery-level displacement + DTF gloss.

A clean architectural move: encode print method as a **shader template enum** in the .mstudio file, and instantiate the corresponding material node graph in Blender programmatically.

### Implementation recommendations for the Blender side (M-Studio Bridge)

#### 1. SVG-to-texture rasterization pipeline

The right answer is **cairosvg as the primary path**, with **Inkscape CLI as a fallback** for SVGs cairosvg chokes on. Reasoning:
- cairosvg is pure-Python (with a Cairo binding) — embeds cleanly inside Blender's bundled Python without a system Inkscape dependency.
- Use it as `cairosvg.svg2png(url=svg_path, output_width=W, output_height=H, background_color=None)`.
- For tint application, rasterize at 1.0 alpha first then post-process in `bpy.types.Image` pixel buffer (or in numpy with a `bgl`-free pure-Python loop). Multiply RGB by tint colour, keep alpha unchanged.
- Background stripping: SVGs from Illustrator sometimes ship with a white `<rect>` background — strip via XML pre-processing, *not* via pixel-colour-keying (which destroys legitimate near-white pixels). Parse with `xml.etree.ElementTree` and drop root-level full-bleed rects.
- Resolution: for techwear lookbooks rendered at 4K final, **4096×4096 per pattern panel is the right working size**. 2048 is acceptable for small accent pieces (cuffs, hems) but produces visible blur on chest-front prints. Atlas the whole garment to a 4K×4K (or 8K×8K for hero shots).
- For SVG containing only paths (no raster bitmaps), an alternative is **Blender's native `bpy.ops.import_curve.svg()`**, which imports paths as Bezier curves. For graphic-placement-as-texture, however, rasterization is the better workflow because texture placement is `O(1)` per panel, while curve-on-3D-surface requires shrink-wrapping.

#### 2. Procedural pattern piece generation (extending the 6-silhouette Bezier approach)

The existing pipeline uses procedural Bezier curves for noragi, bomber, hoodie, parka, pullover, t-shirt. The right extension:
- Keep Bezier curves as the authoring primitive (parametric measurements drive control points).
- For each pattern piece, generate a 2D Bezier curve in the XY plane (Z=0).
- Convert to mesh with `bpy.ops.object.convert(target='MESH')` then triangulate with a controlled edge length (~5–10 mm for sim, 2–3 mm for hero renders).
- Critical: **before triangulation, store the parametric measurement points and the curve in a custom property on the object** so the SVG placement zones (defined in normalised 0–1 coordinates relative to the bounding box) can be deterministically mapped to UV coordinates after triangulation.
- Pseudocode:
  ```python
  def build_pattern_piece(name, control_points, measurements_dict):
      curve = bpy.data.curves.new(name, type='CURVE')
      curve.dimensions = '2D'
      spline = curve.splines.new('BEZIER')
      spline.bezier_points.add(len(control_points) - 1)
      for i, (co, handle_left, handle_right) in enumerate(control_points):
          bp = spline.bezier_points[i]
          bp.co = co
          bp.handle_left = handle_left
          bp.handle_right = handle_right
      obj = bpy.data.objects.new(name, curve)
      obj['mstudio_measurements'] = measurements_dict
      obj['mstudio_bounds'] = compute_bounds(control_points)
      return obj
  ```

#### 3. UV unwrapping — the critical mapping

This is where M-Studio gains its leverage. Because pattern pieces are authored in 2D (XY at Z=0), you can skip projection entirely:
- After triangulating the pattern piece mesh, **the X,Y coordinates of each vertex ARE the UV coordinates** (modulo a normalization step).
- Build a UV map directly: `mesh.uv_layers.new(name="UVMap")` then for each loop, write `uv_layer.data[loop.index].uv = (vertex.co.x / bounds_width, vertex.co.y / bounds_height)`.
- Result: SVG placement zones expressed as `(x_norm, y_norm, w_norm, h_norm)` map directly to a sub-rectangle of the panel's texture — no projection math needed.
- For multi-piece graphics that cross seams: store the graphic with an anchor pattern piece + offset into adjacent pieces. Composite the graphic across the two piece textures at rasterization time using each piece's UV→world transform.
- When you later sew pieces together and run cloth simulation, the UV coordinates are preserved by Blender across the sim, so the graphic stays correctly placed on the deformed 3D mesh.

#### 4. Material node graph construction (print-method templates)

Build per-print-method shader templates as Python functions. Skeleton:
```python
def make_screen_print_material(name, base_color_img, panel_img, panel_normal_img):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    
    # Base fabric
    fabric_tex = nodes.new('ShaderNodeTexImage'); fabric_tex.image = panel_img
    fabric_normal = nodes.new('ShaderNodeTexImage'); fabric_normal.image = panel_normal_img
    fabric_normal.image.colorspace_settings.name = 'Non-Color'
    nm = nodes.new('ShaderNodeNormalMap')
    
    # Graphic overlay
    graphic_tex = nodes.new('ShaderNodeTexImage'); graphic_tex.image = base_color_img
    mix = nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'
    
    # Print-method-specific: screen print = high roughness, slight bump
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.75
    
    out = nodes.new('ShaderNodeOutputMaterial')
    
    links.new(graphic_tex.outputs['Alpha'], mix.inputs['Factor'])
    links.new(fabric_tex.outputs['Color'], mix.inputs['A'])
    links.new(graphic_tex.outputs['Color'], mix.inputs['B'])
    links.new(mix.outputs['Result'], bsdf.inputs['Base Color'])
    links.new(fabric_normal.outputs['Color'], nm.inputs['Color'])
    links.new(nm.outputs['Normal'], bsdf.inputs['Normal'])
    links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return mat
```
Variants per method:
- **DTF**: glossier (Roughness ~0.45), thin bump from a low-amplitude greyscale of graphic alpha.
- **Sublimation**: zero overlay — graphic Color goes straight into Base Color, fabric normal preserved, roughness identical to base fabric.
- **Embroidery**: high-detail normal map from graphic alpha (`Bump` node with Distance ~1.5 mm), anisotropic specular, displacement set via the Material's Displacement output.
- **HD print / DTG**: roughness ~0.55, no bump, multiply blend if substrate is dark.

#### 5. Cloth simulation alternative to garment_tool

Blender's native cloth modifier handles this without third-party code:
- Each pattern piece is a separate mesh; pieces share a single scene-level cloth object only if joined.
- Mark seam edges (between pieces) as **loose edges** (vertices connected by an edge that is not part of any face) using a vertex-pair-add step after triangulation.
- In Cloth ▶ Shape, enable **"Sewing"** and set Max Sewing Force (default 0 = unbounded; safer to keyframe from 0 to 30 over the first 20 frames to avoid instability).
- The loose edges contract during simulation, pulling pattern pieces together into the 3D garment shape — this IS how Marvelous Designer / garment_tool / Style3D fundamentally work.
- Pin groups: define a "shoulder" vertex group and pin those vertices to an Empty parented to the avatar's shoulder bones for stability during draping.
- Use the avatar mesh as a Collision object.

Architecture: a `SewingMap` data structure in your .mstudio file lists edge pairs `(piece_a, edge_a_idx, piece_b, edge_b_idx)`. The bridge resolves these to vertex-pair loose edges at import time.

#### 6. Avatar / mannequin

For a techwear-focused tool, parametric avatars matter less than fit accuracy. Two viable paths:
- **MakeHuman / MPFB2 (MakeHuman Plugin For Blender 2.x)**: parametric, free, OBJ-exportable, integrates into Blender natively. Best for diverse avatar generation.
- **Custom curated mannequin set**: ship 4–6 hand-modelled mannequins (M/F × XS/S/M/L) as `.blend` library assets. Faster, more predictable, no parametric blend-shape complexity. **Recommended for v1.**

Commercial tools all use a measurement-driven avatar (CLO Alvanon, Browzwear AlvaForm, Style3D's parametric). Eventually you'll want this; for v1, curated mannequins are sufficient and your customer base will not notice.

#### 7. Render pipeline for lookbooks

- **Cycles, not EEVEE, for hero renders.** Fabric subsurface scattering, anisotropic embroidery thread, and accurate displacement-mapped embroidery all need Cycles. Per SuperRenders Farm's *Blender Render Settings: Cycles & Eevee Guide (2026)*: *"A practical approach: set render samples to 256–512, enable adaptive sampling with a noise threshold of 0.01, and use OpenImageDenoise … The combination of 256–512 samples, adaptive sampling (noise threshold 0.01), and OpenImageDenoise produces results that are visually indistinguishable from brute-force 4096-sample renders."* This is the right preset to ship by default.
- **EEVEE Next for design-time previews.** Real-time, supports ray tracing in 4.x+, fast iteration. Use a single sun + HDRI for material preview.
- **Color management: AgX**, not Filmic, in Blender 4.x. AgX handles bright fabric whites and metallic foil prints noticeably better.
- **Lighting**: studio HDRI (free from Poly Haven, e.g. "studio_small_03_4k" or "photo_studio_01_4k") + one rim light + one fill area light. The HDRI carries 80% of the look.
- **Camera presets** for the addon to instantiate:
  - **Front**: orthographic-ish lens (85–100 mm) at eye level, 0° rotation.
  - **Back**: same, 180° around the Z axis.
  - **3/4**: 45° around Z, 5° tilt down.
  - **Detail**: 200 mm lens, focused on chest graphic or embroidery zone, DOF ~f/4 equivalent.
  Ship these as named cameras in a hidden collection per generated scene.

#### 8. Existing Blender addons to learn from

- **`garment_tool` (Bartosz Styperek)**: 2D-Bezier-curves-to-cloth-mesh with sewing; closest precedent to M-Studio. Price confirmed at $40 by 80.lv's product write-up: *"The tool is now compatible with Blender 3.6 and 4.0+ and can be purchased for $40"*; sold via bartoszstyperek.gumroad.com/l/GarmentTool. The current listing targets Blender 4.5+. Studied features: pin tool for buttons, pocket tool for source→target sewings, Bind Tool for projecting a 3D mesh onto a simulated cloth surface, garments library.
- **`Simply Cloth Studio`**: presets-driven cloth (silk, denim, cotton), cut & sew, asset library of 200+ patterns. Useful reference for fabric-physics-preset UX.
- **`seams-to-sewingpattern` (Thomas Kole, free)**: inverse direction — takes a 3D mesh and unfolds it into a sewing pattern. Cloth-sim setup helper is directly reusable.
- **MD2Blender / Marvelous Designer importers**: handle OBJ-with-pattern-metadata import.
- **MPFB2**: open-source MakeHuman successor for parametric avatars.
- **BlenderProc** (DLR): excellent reference codebase for procedural material construction (`MaterialUtility.py`), texture loading, and Principled BSDF Python manipulation — copy patterns from it, don't add as a dependency.

#### 9. Texture baking vs. composite-at-render

- **Bake when exporting** to glTF / Unity / Unreal — engines want a single PBR texture per material.
- **Composite at render time** during design iteration — graphics are mutable, designers swap them constantly, baking is wasted I/O.
- For Blender-internal renders (lookbook output), composite at render time using the node graph above. The Cycles overhead of evaluating mix nodes is negligible vs. fabric SSS / displacement.
- Provide a `Bake Atlas` button as a one-shot export step. Use Cycles bake with "Diffuse" pass, Direct/Indirect/Color flags configured for albedo-only output.

#### 10. Embroidery rendering — recommended approach

Three approaches in increasing order of cost:
- **Normal map only (cheapest, recommended default)**: Convert graphic alpha to a height map (Photoshop "Generate Normal Map" filter equivalent in Python: greyscale → Sobel edge detection → encode XY gradients into RGB normal map). Apply via Bump node. Looks good in 90% of lookbook contexts.
- **Normal + Displacement (Cycles only)**: True geometric protrusion. Drives the silhouette so embroidery shows on the edge profile. Adaptive subdivision must be enabled on the panel mesh.
- **Hair particles for thread (most accurate, very slow)**: hair-particle-as-thread approach is documented (Andreu Cabré's 2012 Blender embroidery tutorial). Each colour region becomes a particle system; the hair direction follows the stitch direction. Useful for hero macro shots of embroidered patches only. Skip for general lookbook rendering.

**Production recommendation**: default to normal-map-only with a per-material toggle "Use displacement (slow)" for hero shots.

### Proposed M-Studio Bridge architecture

```
.mstudio package (ZIP)
├── manifest.json                 — version, garment metadata
├── patterns/
│   ├── front.json                — Bezier control points + measurements
│   ├── back.json
│   ├── sleeve.json
│   └── …
├── sewing_map.json               — list of (piece_a, edge_a, piece_b, edge_b)
├── graphics/
│   ├── chest_logo.svg
│   ├── back_panel_print.svg
│   └── placements.json           — list of {graphic_id, piece_id, x_norm,
│                                            y_norm, w_norm, h_norm,
│                                            rotation_deg, anchor: "center"|...,
│                                            face: "front"|"back"|"both",
│                                            method: "screen"|"dtf"|"sub"|
│                                                    "embroidery"|"hd",
│                                            tint: [r,g,b], opacity: float,
│                                            blend: "normal"|"multiply"|"overlay"}
├── colorways/
│   ├── colorway_charcoal.json    — per-piece base colors + per-graphic tint overrides
│   └── colorway_olive.json
├── components/
│   ├── zipper_ykk_5.glb          — 3D trim, button, drawcord
│   └── …
└── render_presets.json           — camera + HDRI choices
```

**Blender addon load sequence:**
1. Parse manifest.json → spawn scene.
2. For each pattern: build Bezier curve → convert to mesh → triangulate (target edge length 5 mm) → assign UV from XY position normalised to bounds.
3. For each sewing edge pair: add loose edge between corresponding boundary vertices.
4. Spawn avatar from library, set Collision modifier.
5. For each pattern mesh: add Cloth modifier with Sewing enabled, Max Sewing Force keyframed 0 → 30.
6. For each graphic placement:
   a. `cairosvg.svg2png(svg, width=4096, height=4096, background=None)`
   b. Apply tint, opacity, blend mode.
   c. Composite into panel texture at (x_norm, y_norm) sub-rect.
   d. Generate normal map if method ∈ {embroidery, screen}.
7. Build per-method material node graphs, assign per pattern piece.
8. Bake simulation (T-pose frames 1–100, drape frame 100).
9. For each colorway: swap textures, render the 4 camera presets via Cycles 256–512 samples + OIDN denoiser, AgX color management.
10. Output: PNG lookbook set + optional tech pack JSON with absolute graphic measurements.

### Python code patterns the addon will lean on

```python
# UV from 2D pattern XY
def assign_pattern_uv(obj, bounds):
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv = mesh.uv_layers.active.data
    w = bounds.x_max - bounds.x_min
    h = bounds.y_max - bounds.y_min
    for poly in mesh.polygons:
        for loop_idx in poly.loop_indices:
            v = mesh.vertices[mesh.loops[loop_idx].vertex_index]
            uv[loop_idx].uv = ((v.co.x - bounds.x_min) / w,
                               (v.co.y - bounds.y_min) / h)

# Loose-edge sewing seam
def add_sewing_seam(piece_a, edge_a_indices, piece_b, edge_b_indices):
    # Join meshes first, then add as loose edges across a joined mesh
    joined = join_meshes([piece_a, piece_b])
    bm = bmesh.new(); bm.from_mesh(joined.data)
    for va, vb in zip(edge_a_indices, edge_b_indices):
        bm.edges.new([bm.verts[va], bm.verts[vb]])  # loose edge
    bm.to_mesh(joined.data); bm.free()

# Cloth modifier with sewing
def setup_cloth(obj):
    cloth = obj.modifiers.new('Cloth', 'CLOTH')
    cs = cloth.settings
    cs.use_sewing_springs = True
    cs.sewing_force_max = 30.0
    cs.mass = 0.3                # kg/m² for techwear-weight fabric
    cs.tension_stiffness = 15
    cs.compression_stiffness = 15
    cs.shear_stiffness = 5
    cs.bending_stiffness = 0.5

# Graphic composite onto panel texture
def composite_graphic_on_panel(panel_img, graphic_png, x_norm, y_norm,
                               w_norm, h_norm, tint, opacity, blend):
    panel_pixels = np.array(panel_img.pixels).reshape(panel_img.size[1],
                                                     panel_img.size[0], 4)
    pw, ph = panel_img.size
    gx = int(x_norm * pw); gy = int(y_norm * ph)
    gw = int(w_norm * pw); gh = int(h_norm * ph)
    graphic = scipy.ndimage.zoom(graphic_png,
                                 (gh / graphic_png.shape[0],
                                  gw / graphic_png.shape[1], 1))
    graphic[..., :3] *= tint[:3]            # multiplicative tint
    alpha = graphic[..., 3:4] * opacity
    region = panel_pixels[gy:gy+gh, gx:gx+gw]
    if blend == 'normal':
        region[..., :3] = region[..., :3] * (1 - alpha) + graphic[..., :3] * alpha
    elif blend == 'multiply':
        region[..., :3] = region[..., :3] * (region[..., :3] * (1 - alpha)
                                             + graphic[..., :3] * alpha)
    panel_img.pixels = panel_pixels.flatten()
```

### Risk areas and known limitations

1. **Cairo / cairosvg installation inside Blender's bundled Python is fragile** — the upstream CairoSVG GitHub issue thread documents installation pain on Windows and macOS. Mitigation: ship a vendored cairosvg + cairocffi + Pillow inside the addon ZIP and add to `sys.path` at register time. Test on macOS Apple Silicon specifically — that's the user's platform given the SwiftUI macOS app context.
2. **Blender cloth sewing instability when shrinking aggressively from frame 1.** Always keyframe sewing force from 0 to your target over the first 20–30 frames. The native docs warn explicitly about this.
3. **Multi-pattern joined mesh approach has UV ambiguity.** If you join two pattern pieces into one mesh for sewing-spring purposes, their UV islands must be separated in UV space or you'll get texture bleed across pieces. Keep islands at clearly different (u,v) origins (piece_a at u ∈ [0, 0.5], piece_b at u ∈ [0.5, 1.0]) or use separate UV maps and switch the active UV per material.
4. **CLO ZPRJ is proprietary and there is no public reverse-engineered spec.** Do NOT attempt to import ZPRJ directly. The bridge format must be `.mstudio` (your own).
5. **Graphic-across-seams placement is non-trivial.** When a single SVG bridges two pattern pieces, the bridge must split the SVG into per-piece regions at composite time, computing the seam boundary in normalised panel space. This is achievable but requires careful coordinate math; document it explicitly in placements.json as an `anchor_piece` plus `bleed_pieces: [...]`.
6. **Tech pack absolute measurements need a calibration step.** "Logo is 8 cm from collar" means a measurement in real-world cm, not normalised UV. The addon must store the pattern's real-world bounds (in cm) alongside the UV bounds, and emit `{x_cm_from_collar, y_cm_from_center_front}` in the tech pack JSON.
7. **EEVEE Next ≠ Cycles for fabric.** Don't promise photoreal output from the design-mode preview; flag clearly in UX that lookbook quality requires a Cycles render pass.
8. **The garment_tool addon is paid commercial software.** Replacing it eliminates a licensing dependency for your customers — a clear strategic win.

## Recommendations

**Stage 1 (4–6 weeks) — prove the core data path.** Implement .mstudio parser, pattern-piece-to-mesh-with-UV pipeline, single graphic SVG → rasterize → composite onto panel texture, single Principled BSDF material per piece, no print methods. Render one camera angle in EEVEE. **Success threshold: a black t-shirt with a chest logo renders correctly with the logo at the right size and position.**

**Stage 2 (4–6 weeks) — sewing simulation and full silhouette set.** Cloth modifier with sewing springs, all 6 silhouettes (noragi, bomber, hoodie, parka, pullover, t-shirt) generated procedurally, multi-piece sewing maps, basic avatar collision, drape simulation bake. **Success threshold: hoodie generates, drapes onto avatar, sleeves attached, shoulders pinned, render in Cycles takes <5 minutes per camera at 4K.**

**Stage 3 (3–4 weeks) — print method differentiation.** Five material templates (screen / DTF / sublimation / embroidery / HD), per-method normal/displacement maps generated from graphic alpha, tint and opacity controls, multi-colorway support via texture swap. **Success threshold: same shirt SVG renders distinguishably as screen print vs. embroidery vs. DTF.**

**Stage 4 (2–3 weeks) — lookbook polish.** Four camera presets, HDRI library selector, 3 lighting setups (studio / golden hour / dramatic rim), batch render across colorways, tech pack JSON export with cm-accurate placement measurements. **Success threshold: hit "Render Collection" once and get the 8-image lookbook set Slack-shareable.**

**Stage 5 (ongoing) — extension surface.** Components (zippers, drawcords) as glTF imports, multi-piece graphic-across-seam handling, embroidery hair-particle hero shots as optional, exports to glTF/USD for web viewer.

**Benchmarks to drive replanning:**
- If Stage 1 takes >8 weeks, your cairosvg + UV pipeline has a structural problem — pause and consult the CLO API design as ground truth.
- If cloth simulation is unstable in Stage 2 past the keyframed-sewing-force fix, switch from native Blender cloth to a custom solver via Geometry Nodes simulation zones (Blender 3.6+).
- If render times exceed 10 minutes per camera in Stage 3, dial Cycles to 128 samples + OIDN and verify you're not accidentally using displacement on all surfaces.
- If users report graphic placement drift across colorways in Stage 4, the bug is almost certainly the active UV map not being preserved on duplicate — explicit `uv_layers.active_index` assignment fixes it.

## Caveats

- **The CLO Python API docstrings for `AddGraphicStyleToPattern` do not explicitly state units for `x/y/width/height`** — they are inferred to be mm from the rest of the CLO API consistently using mm. Verify empirically before relying on this for any CLO interop.
- **Browzwear has no public artwork-placement API equivalent to CLO's `AddGraphicStyleToPattern`** — third-party plugin developers route through the material system and Adobe Illustrator integration. If M-Studio ever needs Browzwear interop, expect substantial scripting work.
- **Style3D has no public scripting API.** Integration with Style3D is file-format-only and not all formats are public.
- **No public reverse-engineering of ZPRJ exists.** Do not promise CLO project import in M-Studio Bridge.
- **AI-generated content in Style3D's recent marketing** ("70% prototyping cost reduction," "fashion tech investments hit record highs in 2026") is vendor-marketing language and should not be cited as fact in the addon's user-facing copy.
- **Some sources in this research are aggregators or auto-summarised (lilys.ai, learn3dfashion.com)** — they accurately convey the workflow but their commentary should be cross-checked against primary CLO/Browzwear documentation before being cited in customer-facing materials.
- **The `seams-to-sewingpattern` addon and `garment_tool` solve the inverse and forward problems respectively** — useful precedents, but neither addresses graphic placement, which is M-Studio's actual product moat.
