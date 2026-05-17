"""
Generate 2D pattern piece coordinates from M-STUDIO tech pack measurements.

Each piece is defined as a list of (x, y) control points in centimeters,
with associated handle types for Blender Bezier curves.

Vertex ordering is counter-clockwise starting from bottom-left:
  Point 0: bottom-left
  Point 1: bottom-right
  Point 2: top-right
  Point 3: top-left

This gives segment indices:
  Seg 0: bottom (hem)
  Seg 1: right side
  Seg 2: top (shoulder/neckline)
  Seg 3: left side
"""

import math


class PieceData:
    __slots__ = ("points", "handle_types", "offset")

    def __init__(self, points, handle_types=None, offset=(0.0, 0.0)):
        self.points = points
        self.handle_types = handle_types or ["VECTOR"] * len(points)
        self.offset = offset


def generate_pieces(measurements, silhouette):
    """Dispatch to silhouette-specific generator."""
    generators = {
        "noragi": _noragi,
        "bomber": _bomber,
        "hoodie": _hoodie,
        "parka": _parka,
        "pullover": _pullover,
        "tshirt": _tshirt,
    }
    gen = generators.get(silhouette, _bomber)
    return gen(measurements)


def _get(m, key, default=0.0):
    """Safely get a measurement value."""
    return m.get(key, default)


# ---------------------------------------------------------------------------
# NORAGI — T-shape wrap garment
# ---------------------------------------------------------------------------

def _noragi(m):
    bw = _get(m, "bodyWidth", 68)
    bl = _get(m, "bodyLength", 85)
    sl = _get(m, "sleeveLength", 42)
    sd = _get(m, "sleeveDepth", 32)
    so = _get(m, "sleeveOpen", 28)
    nw = _get(m, "neckOpeningWidth", 20)
    ch = _get(m, "collarHeight", 4)

    pieces = {}
    gap = 5  # cm between pieces in layout

    # BACK: full-width rectangle
    pieces["BACK"] = PieceData(
        points=[(0, 0), (bw, 0), (bw, bl), (0, bl)],
        offset=(0, 0),
    )

    # SLEEVE_L: tapered if sleeveOpen < sleeveDepth
    if so < sd:
        # 5-point tapered sleeve (shoulder wider than cuff)
        taper = (sd - so) / 2
        pieces["SLEEVE_L"] = PieceData(
            points=[
                (0, taper),       # cuff bottom-left
                (sl, 0),          # shoulder bottom
                (sl, sd),         # shoulder top
                (0, sd - taper),  # cuff top-left
            ],
            offset=(bw + gap, 0),
        )
    else:
        pieces["SLEEVE_L"] = PieceData(
            points=[(0, 0), (sl, 0), (sl, sd), (0, sd)],
            offset=(bw + gap, 0),
        )

    # SLEEVE_R: mirror
    if so < sd:
        taper = (sd - so) / 2
        pieces["SLEEVE_R"] = PieceData(
            points=[
                (0, 0),           # shoulder bottom
                (sl, taper),      # cuff bottom-right
                (sl, sd - taper), # cuff top-right
                (0, sd),          # shoulder top
            ],
            offset=(bw + gap + sl + gap, 0),
        )
    else:
        pieces["SLEEVE_R"] = PieceData(
            points=[(0, 0), (sl, 0), (sl, sd), (0, sd)],
            offset=(bw + gap + sl + gap, 0),
        )

    # COLLAR: strip (wraps around neckline)
    collar_w = nw * math.pi  # circumference of neck opening
    collar_h = ch * 2  # folded height
    pieces["COLLAR"] = PieceData(
        points=[(0, 0), (collar_w, 0), (collar_w, collar_h), (0, collar_h)],
        offset=(0, bl + gap),
    )

    return pieces


# ---------------------------------------------------------------------------
# BOMBER — split front, tapered body, stand collar
# ---------------------------------------------------------------------------

def _bomber(m):
    bw = _get(m, "bodyWidth", 58)
    bl = _get(m, "bodyLength", 62)
    sl = _get(m, "sleeveLength", 62)
    sd = _get(m, "sleeveDepth", 32)
    so = _get(m, "sleeveOpen", 22)
    hw = _get(m, "hemWidth", bw * 0.86)  # 8% taper default
    sw = _get(m, "shoulderWidth", 46)
    nw = _get(m, "neckOpeningWidth", 18)
    ch = _get(m, "collarHeight", 4)

    pieces = {}
    gap = 5

    # Taper inset from shoulder to hem
    taper = (bw - hw) / 2

    # BACK: tapered rectangle
    pieces["BACK"] = PieceData(
        points=[
            (taper, 0),        # hem-left (narrower)
            (bw - taper, 0),   # hem-right
            (bw, bl),          # shoulder-right (wider)
            (0, bl),           # shoulder-left
        ],
        offset=(0, 0),
    )

    # FRONT_L: half-width, same taper
    half_bw = bw / 2
    half_hw = hw / 2
    front_taper = (half_bw - half_hw) / 2
    pieces["FRONT_L"] = PieceData(
        points=[
            (front_taper, 0),
            (half_bw - front_taper, 0),
            (half_bw, bl),
            (0, bl),
        ],
        offset=(bw + gap, 0),
    )

    # FRONT_R: mirror of FRONT_L
    pieces["FRONT_R"] = PieceData(
        points=[
            (front_taper, 0),
            (half_bw - front_taper, 0),
            (half_bw, bl),
            (0, bl),
        ],
        offset=(bw + gap + half_bw + gap, 0),
    )

    # SLEEVE_L
    pieces["SLEEVE_L"] = _make_sleeve(sl, sd, so)
    pieces["SLEEVE_L"].offset = (0, bl + gap)

    # SLEEVE_R
    pieces["SLEEVE_R"] = _make_sleeve_mirror(sl, sd, so)
    pieces["SLEEVE_R"].offset = (sl + gap, bl + gap)

    # COLLAR: stand collar (flat strip)
    collar_w = nw * math.pi
    collar_h = ch * 2
    pieces["COLLAR"] = PieceData(
        points=[(0, 0), (collar_w, 0), (collar_w, collar_h), (0, collar_h)],
        offset=(0, bl + sd + gap * 2),
    )

    return pieces


# ---------------------------------------------------------------------------
# HOODIE — like bomber but with hood piece instead of collar
# ---------------------------------------------------------------------------

def _hoodie(m):
    pieces = _bomber(m)

    nw = _get(m, "neckOpeningWidth", 18)
    bl = _get(m, "bodyLength", 68)
    sd = _get(m, "sleeveDepth", 34)
    gap = 5

    # Replace collar with hood
    del pieces["COLLAR"]

    hood_w = nw * 1.5
    hood_h = 35  # cm head clearance
    # Half-oval shape: flat bottom, curved top
    pieces["HOOD"] = PieceData(
        points=[
            (0, 0),                       # bottom-left (neckline)
            (hood_w, 0),                  # bottom-right (neckline)
            (hood_w, hood_h * 0.6),       # right side curve
            (hood_w * 0.7, hood_h),       # top-right curve
            (hood_w * 0.3, hood_h),       # top-left curve
            (0, hood_h * 0.6),            # left side curve
        ],
        handle_types=["VECTOR", "VECTOR", "AUTO", "AUTO", "AUTO", "AUTO"],
        offset=(0, bl + sd + gap * 2),
    )

    return pieces


# ---------------------------------------------------------------------------
# PARKA — like hoodie but longer, wider
# ---------------------------------------------------------------------------

def _parka(m):
    # Parka uses same structure as hoodie, measurements drive the difference
    return _hoodie(m)


# ---------------------------------------------------------------------------
# PULLOVER — no front split, kangaroo pocket zone
# ---------------------------------------------------------------------------

def _pullover(m):
    bw = _get(m, "bodyWidth", 60)
    bl = _get(m, "bodyLength", 70)
    sl = _get(m, "sleeveLength", 64)
    sd = _get(m, "sleeveDepth", 34)
    so = _get(m, "sleeveOpen", 22)
    nw = _get(m, "neckOpeningWidth", 18)

    pieces = {}
    gap = 5

    # BACK: simple rectangle (no taper on pullover)
    pieces["BACK"] = PieceData(
        points=[(0, 0), (bw, 0), (bw, bl), (0, bl)],
        offset=(0, 0),
    )

    # FRONT: same as back (pullover is one continuous tube, cut flat)
    pieces["FRONT"] = PieceData(
        points=[(0, 0), (bw, 0), (bw, bl), (0, bl)],
        offset=(bw + gap, 0),
    )

    # SLEEVE_L / R
    pieces["SLEEVE_L"] = _make_sleeve(sl, sd, so)
    pieces["SLEEVE_L"].offset = (0, bl + gap)
    pieces["SLEEVE_R"] = _make_sleeve_mirror(sl, sd, so)
    pieces["SLEEVE_R"].offset = (sl + gap, bl + gap)

    # HOOD
    hood_w = nw * 1.5
    hood_h = 35
    pieces["HOOD"] = PieceData(
        points=[
            (0, 0), (hood_w, 0),
            (hood_w, hood_h * 0.6),
            (hood_w * 0.7, hood_h),
            (hood_w * 0.3, hood_h),
            (0, hood_h * 0.6),
        ],
        handle_types=["VECTOR", "VECTOR", "AUTO", "AUTO", "AUTO", "AUTO"],
        offset=(0, bl + sd + gap * 2),
    )

    return pieces


# ---------------------------------------------------------------------------
# T-SHIRT — simple, no hood, no front split
# ---------------------------------------------------------------------------

def _tshirt(m):
    bw = _get(m, "bodyWidth", 52)
    bl = _get(m, "bodyLength", 72)
    sl = _get(m, "sleeveLength", 22)
    sd = _get(m, "sleeveDepth", 22)
    so = _get(m, "sleeveOpen", 20)
    nw = _get(m, "neckOpeningWidth", 18)
    ch = _get(m, "collarHeight", 3)

    pieces = {}
    gap = 5

    # BACK
    pieces["BACK"] = PieceData(
        points=[(0, 0), (bw, 0), (bw, bl), (0, bl)],
        offset=(0, 0),
    )

    # FRONT
    pieces["FRONT"] = PieceData(
        points=[(0, 0), (bw, 0), (bw, bl), (0, bl)],
        offset=(bw + gap, 0),
    )

    # SLEEVE_L / R
    pieces["SLEEVE_L"] = _make_sleeve(sl, sd, so)
    pieces["SLEEVE_L"].offset = (0, bl + gap)
    pieces["SLEEVE_R"] = _make_sleeve_mirror(sl, sd, so)
    pieces["SLEEVE_R"].offset = (sl + gap, bl + gap)

    # COLLAR: crew neck band
    collar_w = nw * math.pi
    collar_h = ch * 2
    pieces["COLLAR"] = PieceData(
        points=[(0, 0), (collar_w, 0), (collar_w, collar_h), (0, collar_h)],
        offset=(0, bl + sd + gap * 2),
    )

    return pieces


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_sleeve(sl, sd, so):
    """Left sleeve: shoulder edge on the right."""
    if so < sd:
        taper = (sd - so) / 2
        return PieceData(
            points=[
                (0, taper),        # cuff BL
                (sl, 0),           # shoulder BR
                (sl, sd),          # shoulder TR
                (0, sd - taper),   # cuff TL
            ],
        )
    return PieceData(points=[(0, 0), (sl, 0), (sl, sd), (0, sd)])


def _make_sleeve_mirror(sl, sd, so):
    """Right sleeve: shoulder edge on the left."""
    if so < sd:
        taper = (sd - so) / 2
        return PieceData(
            points=[
                (0, 0),            # shoulder BL
                (sl, taper),       # cuff BR
                (sl, sd - taper),  # cuff TR
                (0, sd),           # shoulder TL
            ],
        )
    return PieceData(points=[(0, 0), (sl, 0), (sl, sd), (0, sd)])
