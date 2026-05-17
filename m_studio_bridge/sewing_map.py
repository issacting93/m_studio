"""
Per-silhouette sewing definitions.

Each sewing connects a segment of one piece to a segment of another.
Segment N = the edge between bezier_point[N] and bezier_point[(N+1) % total_points].

For standard 4-point rectangular pieces (BL, BR, TR, TL):
  Seg 0: bottom (hem edge)
  Seg 1: right side
  Seg 2: top (shoulder/neckline edge)
  Seg 3: left side

For tapered sleeves (4-point):
  Left sleeve:  Seg 0 = cuff-to-shoulder bottom, Seg 1 = shoulder right, Seg 2 = shoulder-to-cuff top, Seg 3 = cuff left
  Right sleeve: Seg 0 = shoulder-to-cuff bottom, Seg 1 = cuff right, Seg 2 = cuff-to-shoulder top, Seg 3 = shoulder left
"""


def get_sewings(silhouette, pieces):
    """
    Return list of sewing definitions for a silhouette.

    Each sewing is a dict:
        source: piece name
        target: piece name
        from_seg: segment index on source
        to_seg: segment index on target
        flip: whether to reverse stitch direction
    """
    generators = {
        "noragi": _noragi_sewings,
        "bomber": _bomber_sewings,
        "hoodie": _hoodie_sewings,
        "parka": _hoodie_sewings,  # same topology as hoodie
        "pullover": _pullover_sewings,
        "tshirt": _tshirt_sewings,
    }
    gen = generators.get(silhouette, _bomber_sewings)
    return gen(pieces)


# ---------------------------------------------------------------------------
# NORAGI: T-shape, sleeves attach to back sides
# ---------------------------------------------------------------------------

def _noragi_sewings(pieces):
    sewings = []

    # Sleeve L: shoulder edge (seg 1 = right side) → Back left side (seg 3)
    if "SLEEVE_L" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_L",
            "target": "BACK",
            "from_seg": 1,  # sleeve shoulder edge (right side)
            "to_seg": 3,    # back left side
            "flip": False,
        })

    # Sleeve R: shoulder edge (seg 3 = left side) → Back right side (seg 1)
    if "SLEEVE_R" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_R",
            "target": "BACK",
            "from_seg": 3,  # sleeve shoulder edge (left side)
            "to_seg": 1,    # back right side
            "flip": False,
        })

    # Collar bottom → Back top (neckline)
    if "COLLAR" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "COLLAR",
            "target": "BACK",
            "from_seg": 0,  # collar bottom edge
            "to_seg": 2,    # back top edge
            "flip": False,
        })

    return sewings


# ---------------------------------------------------------------------------
# BOMBER: split front panels, side seams, sleeve attachment
# ---------------------------------------------------------------------------

def _bomber_sewings(pieces):
    sewings = []

    # Back right side → Front_R left side
    if "BACK" in pieces and "FRONT_R" in pieces:
        sewings.append({
            "source": "BACK",
            "target": "FRONT_R",
            "from_seg": 1,  # back right
            "to_seg": 3,    # front_R left
            "flip": False,
        })

    # Back left side → Front_L right side
    if "BACK" in pieces and "FRONT_L" in pieces:
        sewings.append({
            "source": "BACK",
            "target": "FRONT_L",
            "from_seg": 3,  # back left
            "to_seg": 1,    # front_L right
            "flip": False,
        })

    # Sleeve L shoulder → Back top (shoulder area)
    if "SLEEVE_L" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_L",
            "target": "BACK",
            "from_seg": 1,  # sleeve shoulder edge
            "to_seg": 2,    # back top
            "flip": False,
        })

    # Sleeve R shoulder → Back top
    if "SLEEVE_R" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_R",
            "target": "BACK",
            "from_seg": 3,  # sleeve shoulder edge
            "to_seg": 2,    # back top
            "flip": True,
        })

    # Collar → Back neckline
    if "COLLAR" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "COLLAR",
            "target": "BACK",
            "from_seg": 0,
            "to_seg": 2,
            "flip": False,
        })

    return sewings


# ---------------------------------------------------------------------------
# HOODIE / PARKA: like bomber but hood replaces collar
# ---------------------------------------------------------------------------

def _hoodie_sewings(pieces):
    sewings = _bomber_sewings(pieces)

    # Remove collar sewing if present (replaced by hood)
    sewings = [s for s in sewings if s["source"] != "COLLAR"]

    # Hood bottom edge → Back top (neckline)
    if "HOOD" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "HOOD",
            "target": "BACK",
            "from_seg": 0,  # hood bottom edge (between point 0 and point 1)
            "to_seg": 2,    # back top
            "flip": False,
        })

    return sewings


# ---------------------------------------------------------------------------
# PULLOVER: single front + back, hood, no center closure
# ---------------------------------------------------------------------------

def _pullover_sewings(pieces):
    sewings = []

    # Back right → Front right
    if "BACK" in pieces and "FRONT" in pieces:
        sewings.append({
            "source": "BACK",
            "target": "FRONT",
            "from_seg": 1,
            "to_seg": 3,
            "flip": False,
        })

    # Back left → Front left
    if "BACK" in pieces and "FRONT" in pieces:
        sewings.append({
            "source": "BACK",
            "target": "FRONT",
            "from_seg": 3,
            "to_seg": 1,
            "flip": False,
        })

    # Sleeve L → Back top
    if "SLEEVE_L" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_L",
            "target": "BACK",
            "from_seg": 1,
            "to_seg": 2,
            "flip": False,
        })

    # Sleeve R → Back top
    if "SLEEVE_R" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_R",
            "target": "BACK",
            "from_seg": 3,
            "to_seg": 2,
            "flip": True,
        })

    # Hood → Back neckline
    if "HOOD" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "HOOD",
            "target": "BACK",
            "from_seg": 0,
            "to_seg": 2,
            "flip": False,
        })

    return sewings


# ---------------------------------------------------------------------------
# T-SHIRT: same as pullover but with collar instead of hood
# ---------------------------------------------------------------------------

def _tshirt_sewings(pieces):
    sewings = []

    # Side seams
    if "BACK" in pieces and "FRONT" in pieces:
        sewings.append({
            "source": "BACK",
            "target": "FRONT",
            "from_seg": 1,
            "to_seg": 3,
            "flip": False,
        })
        sewings.append({
            "source": "BACK",
            "target": "FRONT",
            "from_seg": 3,
            "to_seg": 1,
            "flip": False,
        })

    # Sleeves
    if "SLEEVE_L" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_L",
            "target": "BACK",
            "from_seg": 1,
            "to_seg": 2,
            "flip": False,
        })
    if "SLEEVE_R" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "SLEEVE_R",
            "target": "BACK",
            "from_seg": 3,
            "to_seg": 2,
            "flip": True,
        })

    # Collar → Back neckline
    if "COLLAR" in pieces and "BACK" in pieces:
        sewings.append({
            "source": "COLLAR",
            "target": "BACK",
            "from_seg": 0,
            "to_seg": 2,
            "flip": False,
        })

    return sewings
