extends Node

# ── Tier palette (opaque) ──────────────────────────────────────────────────
const TEAL   := Color(0.192, 0.718, 0.643)
const GREEN  := Color(0.300, 0.910, 0.480)
const BLUE   := Color(0.300, 0.560, 0.910)
const PURPLE        := Color(0.610, 0.300, 0.910)
const PURPLE_BRIGHT := Color(0.780, 0.420, 1.000)
const GOLD   := Color(1.000, 0.780, 0.200)

# ── Connection line colors ─────────────────────────────────────────────────
const LINK_DEFAULT := Color(0.192, 0.718, 0.643, 0.65)
const LINK_RING    := Color(0.300, 0.560, 0.910, 0.80)
const LINK_STAR    := Color(0.300, 0.560, 0.910, 0.80)
const LINK_MESH        := Color(0.610, 0.300, 0.910, 0.80)
const LINK_GOLD        := Color(1.000, 0.780, 0.200, 0.80)
const LINK_UNDERGROUND := Color(0.720, 0.720, 0.780, 0.60)
const LINK_PREVIEW     := Color(0.750, 0.750, 0.800, 0.50)

# ── Computer screen states ─────────────────────────────────────────────────
const SCREEN_OFF := Color(0.200, 0.200, 0.200)

# Returns the screen-on color for a given network pattern string.
static func screen_on_for(pattern: String) -> Color:
	match pattern:
		"mesh": return PURPLE_BRIGHT
		"star": return GOLD
		"ring": return BLUE
		_:      return TEAL

static func link_color_for(pattern: String) -> Color:
	match pattern:
		"mesh": return LINK_MESH
		"star": return LINK_GOLD
		"ring": return LINK_RING
		_:      return LINK_DEFAULT
