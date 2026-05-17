"""
Read .mstudio packages (ZIP) and legacy .json tech packs.
Returns a unified data dict regardless of input format.
"""

import json
import os
import tempfile
import zipfile


def read_file(filepath):
    """
    Read a .mstudio package or legacy .json tech pack.
    Returns a unified dict with keys:
        manifest, colorway, grading, components, graphics
    """
    ext = os.path.splitext(filepath)[1].lower()

    if ext == ".mstudio":
        return _read_package(filepath)
    elif ext == ".json":
        return _read_legacy_json(filepath)
    else:
        raise ValueError(f"Unsupported file type: {ext}")


def _read_package(filepath):
    """Extract and parse a .mstudio ZIP package."""
    extract_dir = tempfile.mkdtemp(prefix="mstudio_")

    with zipfile.ZipFile(filepath, "r") as zf:
        zf.extractall(extract_dir)

    # Find the package root (may be nested in a subdirectory)
    manifest_path = _find_file(extract_dir, "manifest.json")
    if not manifest_path:
        raise ValueError("No manifest.json found in .mstudio package")

    package_root = os.path.dirname(manifest_path)

    result = {
        "manifest": _load_json(manifest_path),
        "colorway": _load_json_optional(package_root, "colorway.json"),
        "grading": _load_json_optional(package_root, "grading.json"),
        "components": _load_json_optional(package_root, "components.json"),
        "graphics": {
            "placements": [],
            "svg_dir": None,
        },
        "_extract_dir": extract_dir,
    }

    # Load graphics
    graphics_dir = os.path.join(package_root, "graphics")
    if os.path.isdir(graphics_dir):
        result["graphics"]["svg_dir"] = graphics_dir
        placements_path = os.path.join(graphics_dir, "placements.json")
        if os.path.exists(placements_path):
            with open(placements_path, "r", encoding="utf-8") as f:
                placements_data = json.load(f)
            result["graphics"]["placements"] = placements_data.get("zones", [])

    return result


def _read_legacy_json(filepath):
    """Wrap a legacy JSON tech pack in the unified format."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Build manifest from legacy format
    manifest = {
        "version": "0.3",
        "styleCode": data.get("document", "M-STUDIO"),
        "silhouette": data.get("silhouette", "bomber"),
        "measurements": data.get("measurements", {}),
        "construction": {},
        "fabric": data.get("fabric", {}),
        "designer": "",
        "season": "",
        "notes": "",
    }

    # Extract construction from measurements (legacy format stores them together)
    for key in ["sleeveType", "closure", "pocket", "collarType", "cuffType", "hemType"]:
        if key in manifest["measurements"]:
            manifest["construction"][key] = manifest["measurements"].pop(key)

    # Build colorway
    colorway = None
    cw_data = data.get("colorway", {})
    if cw_data:
        active_name = cw_data.get("id", "stealth")
        colorway = {
            "active": active_name,
            "colorways": {
                active_name: {
                    "primary": cw_data.get("primaryHex", "#1a1a1a"),
                    "secondary": cw_data.get("secondaryHex", "#2a2a2a"),
                    "accent": cw_data.get("accentHex", "#d63d2e"),
                    "graphic": cw_data.get("graphicHex", "#ffffff"),
                }
            },
            "blocking": {},
        }

    # Build grading
    grading = None
    sizes = data.get("sizes", {})
    if sizes:
        grading = {
            "baseSize": "M",
            "sizes": sizes,
        }

    return {
        "manifest": manifest,
        "colorway": colorway,
        "grading": grading,
        "components": None,
        "graphics": {
            "placements": [],
            "svg_dir": None,
        },
        "_extract_dir": None,
    }


def get_measurements(data, target_size="BASE"):
    """Get measurements from unified data, optionally applying size grading."""
    measurements = dict(data["manifest"].get("measurements", {}))

    if target_size != "BASE" and data.get("grading"):
        sizes = data["grading"].get("sizes", {})
        if target_size in sizes:
            measurements.update(sizes[target_size])

    return measurements


def get_colorway_colors(data):
    """Get the active colorway's color dict from unified data."""
    if not data.get("colorway"):
        return {"primary": "#1a1a1a", "secondary": "#2a2a2a", "accent": "#d63d2e", "graphic": "#ffffff"}

    active = data["colorway"].get("active", "stealth")
    colorways = data["colorway"].get("colorways", {})

    if active in colorways:
        return colorways[active]

    # Fallback to first colorway
    if colorways:
        return next(iter(colorways.values()))

    return {"primary": "#1a1a1a", "secondary": "#2a2a2a", "accent": "#d63d2e", "graphic": "#ffffff"}


def get_blocking(data):
    """Get color blocking assignments from unified data."""
    if not data.get("colorway"):
        return {}
    return data["colorway"].get("blocking", {})


def get_graphic_placements(data):
    """Get graphic zone placements from unified data."""
    return data.get("graphics", {}).get("placements", [])


def get_svg_path(data, filename):
    """Get full path to an SVG file in the package."""
    svg_dir = data.get("graphics", {}).get("svg_dir")
    if not svg_dir or not filename:
        return None
    path = os.path.join(svg_dir, filename)
    return path if os.path.exists(path) else None


def cleanup(data):
    """Remove temporary extraction directory."""
    extract_dir = data.get("_extract_dir")
    if extract_dir and os.path.isdir(extract_dir):
        import shutil
        shutil.rmtree(extract_dir, ignore_errors=True)


# -- helpers --

def _find_file(root, filename):
    """Recursively find a file in a directory tree."""
    for dirpath, _, filenames in os.walk(root):
        if filename in filenames:
            return os.path.join(dirpath, filename)
    return None


def _load_json(path):
    """Load a JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _load_json_optional(root, filename):
    """Load a JSON file if it exists, return None otherwise."""
    path = os.path.join(root, filename)
    if os.path.exists(path):
        return _load_json(path)
    return None
