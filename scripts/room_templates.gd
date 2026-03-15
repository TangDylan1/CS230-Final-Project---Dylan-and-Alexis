class_name RoomTemplates
extends RefCounted
## Templates are authored as 20x11 and scaled to ROOM_WIDTH x ROOM_HEIGHT at runtime.
##
## Legend:  W = wall, . = floor, S = spike
##
## Doors are NOT part of the template — they're carved at runtime based on
## which adjacent rooms exist in the dungeon layout.

const ROOM_WIDTH  := 22
const ROOM_HEIGHT := 15

# ==========================================================================
# START — safe room, no obstacles
# ==========================================================================

const START_1 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

# ==========================================================================
# NORMAL — varied obstacle layouts for standard dungeon rooms
# ==========================================================================

const NORMAL_1 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..WW..........WW..W
W..WW..........WW..W
W..................W
W..................W
W..................W
W..WW..........WW..W
W..WW..........WW..W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

const NORMAL_2 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W......WWWW........W
W......W..W........W
W......W..W........W
W......W..W........W
W......WWWW........W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

const NORMAL_3 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W....W.........W...W
W..................W
W..........W.......W
W..................W
W.......W..........W
W..................W
W...W.........W....W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

const NORMAL_4 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W.WWWWWW...........W
W..................W
W...........WWWWWW.W
W..................W
W.WWWWWW...........W
W..................W
W...........WWWWWW.W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

const NORMAL_5 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..SSSS......SSSS..W
W..S..S......S..S..W
W..SSSS......SSSS..W
W..................W
W..SSSS......SSSS..W
W..S..S......S..S..W
W..SSSS......SSSS..W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

const NORMAL_6 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..WW..........WW..W
W..................W
W......SS..........W
W..................W
W..........SS......W
W..................W
W..WW..........WW..W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

# ==========================================================================
# BOSS — open arenas for boss fights
# ==========================================================================

const BOSS_1 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

const BOSS_2 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W....W........W....W
W..................W
W..................W
W..................W
W....W........W....W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

# ==========================================================================
# SHOP — empty room, items placed via spawn markers later
# ==========================================================================

const SHOP_1 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

# ==========================================================================
# TREASURE — guarded chest room
# ==========================================================================

const TREASURE_1 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..WW..........WW..W
W..WW..........WW..W
W..................W
W..................W
W..................W
W..WW..........WW..W
W..WW..........WW..W
W..................W
WWWWWWWWWWWWWWWWWWWW"""

# ==========================================================================
# SECRET — hidden reward room
# ==========================================================================

const SECRET_1 := """
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW"""


# ==========================================================================
# VARIED SIZE — rooms with thicker walls creating smaller/different interiors
# ==========================================================================

# Compact room: 2-tile-thick walls on all sides → 16x7 interior.
const NORMAL_7 := """
WWWWWWWWWWWWWWWWWWWW
WWWWWWWWWWWWWWWWWWWW
WW................WW
WW................WW
WW................WW
WW................WW
WW................WW
WW................WW
WW................WW
WWWWWWWWWWWWWWWWWWWW
WWWWWWWWWWWWWWWWWWWW"""

# Wide corridor: 3-tile-thick walls top/bottom → 18x5 interior.
const NORMAL_8 := """
WWWWWWWWWWWWWWWWWWWW
WWWWWWWWWWWWWWWWWWWW
WWWWWWWWWWWWWWWWWWWW
W..................W
W..................W
W..................W
W..................W
W..................W
WWWWWWWWWWWWWWWWWWWW
WWWWWWWWWWWWWWWWWWWW
WWWWWWWWWWWWWWWWWWWW"""

# ==========================================================================
# TEMPLATE POOLS
# ==========================================================================

const START_POOL     := [START_1]
const NORMAL_POOL    := [NORMAL_1, NORMAL_2, NORMAL_3, NORMAL_4, NORMAL_5, NORMAL_6, NORMAL_7, NORMAL_8]
const BOSS_POOL      := [BOSS_1, BOSS_2]
const SHOP_POOL      := [SHOP_1]
const TREASURE_POOL  := [TREASURE_1]
const SECRET_POOL    := [SECRET_1]


## Returns a random template string for the given room type.
static func get_random_template(room_type: int) -> String:
	var pool: Array
	match room_type:
		DungeonGenerator.RoomType.START:
			pool = START_POOL
		DungeonGenerator.RoomType.BOSS:
			pool = BOSS_POOL
		DungeonGenerator.RoomType.SHOP:
			pool = SHOP_POOL
		DungeonGenerator.RoomType.TREASURE:
			pool = TREASURE_POOL
		DungeonGenerator.RoomType.SECRET:
			pool = SECRET_POOL
		_:
			pool = NORMAL_POOL
	var template: String = pool[randi() % pool.size()]
	return _resize_template(template)


static func _resize_template(template: String) -> String:
	var source_lines: Array = template.strip_edges().split("\n")
	if source_lines.is_empty():
		return template.strip_edges()

	var src_height: int = source_lines.size()
	var src_width := 0
	for line in source_lines:
		src_width = maxi(src_width, (line as String).length())

	if src_width <= 0 or src_height <= 0:
		return template.strip_edges()
	if src_width == ROOM_WIDTH and src_height == ROOM_HEIGHT:
		return template.strip_edges()

	var out_lines: Array[String] = []
	for y in range(ROOM_HEIGHT):
		var sy := _map_index(y, ROOM_HEIGHT, src_height)
		var row := ""
		for x in range(ROOM_WIDTH):
			var sx := _map_index(x, ROOM_WIDTH, src_width)
			row += _char_or_fallback(source_lines, sy, sx)
		out_lines.append(row)

	return "\n".join(out_lines)


static func _map_index(target_idx: int, target_size: int, source_size: int) -> int:
	if target_size <= 1 or source_size <= 1:
		return 0
	var ratio := float(target_idx) / float(target_size - 1)
	return clampi(int(round(ratio * float(source_size - 1))), 0, source_size - 1)


static func _char_or_fallback(lines: Array, y: int, x: int) -> String:
	if y < 0 or y >= lines.size():
		return "W"
	var line := lines[y] as String
	if x < 0 or x >= line.length():
		return "W"
	return line[x]
