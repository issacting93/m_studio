# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

M-STUDIO Pattern Lab (v0.3) is a single-file techwear garment design tool built as a self-contained HTML application. It enables designing technical garments with parametric controls, flat pattern generation, 3D preview, size grading, and production sourcing information.

## Running

Open `m-studio-pattern-lab-v0.3.html` directly in a browser. No build step, no server required. The file loads Three.js and Google Fonts from CDN.

## Architecture

Everything lives in one HTML file (~1715 lines) with three sections:

1. **CSS** (lines 11–313) — Custom design system using CSS variables (`--paper`, `--ink`, `--accent`, etc.). Grid-based layout with a sticky 320px control sidebar and flexible canvas area.

2. **HTML** (lines 315–500) — Two-column app layout: sidebar controls (silhouette selector, sliders, toggles, colorway/fabric pickers, workspace actions) and main canvas with tabbed views (Garment, 3D, Flat Pattern, Colorway, Sizes, Sourcing).

3. **JavaScript** (lines 502–1714) — Vanilla JS, no framework. Key sections:
   - **Config & State** (~502–560): `COLORWAYS`, `FABRICS`, `GRADE_RULES`, `SILHOUETTE_DEFAULTS`, and mutable `state` object
   - **UI Binding** (~566–675): Event listeners for controls, syncs UI ↔ state
   - **Size Grading** (~680–750): Industry-standard grade rules (±4cm body width per size step)
   - **Graphic Helpers** (~755–808): Generates SVG graphics (milspec, mecha, typo styles) or renders AI-generated content
   - **Garment Renderers** (~814–942): `garmentNoragi`, `garmentBomber`, `garmentHoodie`, `garmentParka` — each draws front/back SVG elevations
   - **Garment View + Drag** (~950–1048): Draggable/resizable graphic zone on back panel via pointer events
   - **Flat Pattern** (~1053–1122): Cut-layout view with grain lines, spec callouts, scale stamp
   - **Three.js 3D** (~1200–1458): WebGL garment preview with manual rotation, tapered body geometry, cylindrical sleeves, hood/collar, pockets, back graphic texture
   - **DXF Export** (~1464–1520): Generates simple DXF with POLYLINE entities for pattern pieces
   - **AI Graphic Generation** (~1525–1592): Calls Anthropic API directly (`/v1/messages`) to generate Machine56-style SVG graphics via Claude
   - **Save/Load** (~1597–1645): Persists designs via `window.storage` API (list/get/set/delete)
   - **Export** (~1665–1686): SVG (active panel), JSON (full tech pack with graded measurements)

## Key Design Decisions

- **No API key in code**: The AI graphic feature calls `api.anthropic.com` without an auth header in the source — expects the hosting environment (e.g., Claude artifacts) to handle auth.
- **`window.storage`**: Save/load uses a storage abstraction provided by the host environment, not localStorage directly.
- **Silhouettes share renderer logic**: Hoodie and Parka delegate to `garmentBomber()` with options (`hood: true`, `parka: true`).
- **State-driven rendering**: All views re-render from the single `state` object on any change. The `render()` function calls all view renderers unconditionally.
- **Graphic zone is relative**: `state.graphicZone` stores position/size as fractions (0–1) of the back panel bounds.

## Conventions

- Measurements are in centimeters
- Silhouette codes follow pattern: `M-{3-letter}-001` (e.g., M-NRG-001, M-BMB-001)
- Color scheme: paper (#f1ede3), ink (#141414), accent (#d63d2e), accent-2 (#2864db)
- Fonts: JetBrains Mono (UI/technical), Archivo (display/headlines)
- All UI text is uppercase with letter-spacing
