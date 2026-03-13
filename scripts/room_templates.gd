class_name RoomTemplates
extends RefCounted
## Each template is 20 chars wide x 11 lines tall (matching a 20x11 tile room).
##
## Legend:  W = wall, . = floor, S = spike
##
## Doors are NOT part of the template — they're carved at runtime based on
## which adjacent rooms exist in the dungeon layout.

const ROOM_WIDTH  := 20
const ROOM_HEIGHT := 11

# ==========================================================================
# START — safe room, no obstacles
# ==========================================================================

const START_1 := """WWWWWWWWWWWWWWWWWWWW
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

const NORMAL_1 := """WWWWWWWWWWWWWWWWWWWW
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

const NORMAL_2 := """WWWWWWWWWWWWWWWWWWWW
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

const NORMAL_3 := """WWWWWWWWWWWWWWWWWWWW
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

const NORMAL_4 := """WWWWWWWWWWWWWWWWWWWW
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

const NORMAL_5 := """WWWWWWWWWWWWWWWWWWWW
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

const NORMAL_6 := """WWWWWWWWWWWWWWWWWWWW
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

const BOSS_1 := """WWWWWWWWWWWWWWWWWWWW
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

const BOSS_2 := """WWWWWWWWWWWWWWWWWWWW
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

const SHOP_1 := """WWWWWWWWWWWWWWWWWWWW
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

const TREASURE_1 := """WWWWWWWWWWWWWWWWWWWW
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

const SECRET_1 := """WWWWWWWWWWWWWWWWWWWW
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
const NORMAL_7 := """WWWWWWWWWWWWWWWWWWWW
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
const NORMAL_8 := """WWWWWWWWWWWWWWWWWWWW
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
	return pool[randi() % pool.size()]
