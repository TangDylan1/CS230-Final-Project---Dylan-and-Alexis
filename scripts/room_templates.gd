class_name RoomTemplates
extends RefCounted

## Doors are NOT part of the template — they're carved at runtime based on
## which adjacent rooms exist in the dungeon layout.

const ROOM_WIDTH  := 22
const ROOM_HEIGHT := 15

# ==========================================================================
# SCENE POOLS
# ==========================================================================

const START_SCENE_POOL    := [preload("res://scenes/room scenes/start.tscn"),]

const NORMAL_SCENE_POOL   := [preload("res://scenes/room scenes/NORMAL/N_01.tscn"), 
							  preload("res://scenes/room scenes/NORMAL/N_02.tscn"), 
							  preload("res://scenes/room scenes/NORMAL/N_03.tscn")]

const BOSS_SCENE_POOL     := [preload("res://scenes/room scenes/BOSS/B_01.tscn")]
const SHOP_SCENE_POOL     := [preload("res://scenes/room scenes/SHOP/SHP_01.tscn")]
const TREASURE_SCENE_POOL := [preload("res://scenes/room scenes/TREASURE/T_01.tscn")]
const SECRET_SCENE_POOL   := [preload("res://scenes/room scenes/SECRET/ST_01.tscn")]

## Returns a random room scene for the given room type.
static func get_random_room_scene(room_type: int) -> PackedScene:
	var pool: Array
	match room_type:
		DungeonGenerator.RoomType.START:
			pool = START_SCENE_POOL
		DungeonGenerator.RoomType.BOSS:
			pool = BOSS_SCENE_POOL
		DungeonGenerator.RoomType.SHOP:
			pool = SHOP_SCENE_POOL
		DungeonGenerator.RoomType.TREASURE:
			pool = TREASURE_SCENE_POOL
		DungeonGenerator.RoomType.SECRET:
			pool = SECRET_SCENE_POOL
		_:
			pool = NORMAL_SCENE_POOL

	return pool[randi() % pool.size()] as PackedScene
