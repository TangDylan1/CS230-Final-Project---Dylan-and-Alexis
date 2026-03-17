extends Node2D
## Dungeon manager. Generates the room layout with the Drunkard's Walk
## algorithm, instantiates room scenes, spawns the player, and handles
## room transitions with a fade-to-black effect.
##
## CONTROLS:
##   WASD / Arrow keys — move the player
##   Space             — regenerate the entire dungeon
##   M                 — toggle developer minimap

# Room dimensions in pixels (22 tiles * 32px, 15 tiles * 32px).
const ROOM_PIXEL_SIZE := Vector2(704, 480)
const ROOM_WIDTH := 22
const ROOM_HEIGHT := 15
const ROOM_TEMPLATES := preload("res://scripts/room_templates.gd")

# When the player enters a door going direction D, they spawn at this
# room-local position in the TARGET room (near the opposite door, pushed
# one tile inward so they don't immediately re-trigger the door).
const SPAWN_OFFSETS := {
	Vector2i.UP:    Vector2(352, 432),
	Vector2i.DOWN:  Vector2(352, 48),
	Vector2i.LEFT:  Vector2(656, 224),
	Vector2i.RIGHT: Vector2(48, 224),
}

# Door cell positions inside a room (22x15).
const DOOR_TILE_CELLS := {
	Vector2i.UP: [
		Vector2i(10, 0), Vector2i(11, 0),
		Vector2i(10, 1), Vector2i(11, 1),
	],
	Vector2i.LEFT: [
		Vector2i(0, 6), Vector2i(0, 7),
	],
	Vector2i.RIGHT: [
		Vector2i(21, 6), Vector2i(21, 7),
	],
	Vector2i.DOWN: [
		Vector2i(10, 14), Vector2i(11, 14),
	],
}

# Atlas replacements for each door side.
const DOOR_TILE_ATLAS := {
	Vector2i.UP: [
		Vector2i(18, 8), Vector2i(19, 8),
		Vector2i(18, 9), Vector2i(19, 9),
	],
	Vector2i.LEFT: [
		Vector2i(17, 10), Vector2i(17, 11),
	],
	Vector2i.RIGHT: [
		Vector2i(20, 10), Vector2i(20, 11),
	],
	Vector2i.DOWN: [
		Vector2i(18, 12), Vector2i(19, 12),
	],
}

const BOSS_DOOR_TILE_ATLAS := {
	Vector2i.UP: [
		Vector2i(22, 14), Vector2i(23, 14),
		Vector2i(22, 15), Vector2i(23, 15),
	],
	Vector2i.LEFT: [
		Vector2i(27, 16), Vector2i(27, 17),
	],
	Vector2i.RIGHT: [
		Vector2i(26, 16), Vector2i(26, 17),
	],
	Vector2i.DOWN: [
		Vector2i(20, 18), Vector2i(21, 18),
	],
}

# Pixel center of each door opening (for placing the Area2D trigger).
const DOOR_CENTERS := {
	Vector2i.UP:    Vector2(352, 16),
	Vector2i.DOWN:  Vector2(352, 464),
	Vector2i.LEFT:  Vector2(16, 224),
	Vector2i.RIGHT: Vector2(688, 224),
}


@export var grid_size := Vector2i(8, 8)
@export var target_rooms: int = 12

var _generator := DungeonGenerator.new()
var _layout: Dictionary = {}
var _current_cell: Vector2i
var _transitioning := false
var _player: CharacterBody2D
var _door_areas: Array[Area2D] = []
var _room_scenes: Dictionary = {}      # for each cell, store the selected room scene
var _room_open_dirs: Dictionary = {}   # for each cell, store the open directions
var _room_container: Node2D
var _active_room_root: Node2D
var _active_room_tilemap: TileMapLayer
var _room_enemies: Array[Node] = []
var _coin_label: Label
var _cleared_rooms: Dictionary = {}    # cell -> bool, true if enemies cleared once

const ENEMY_SCENES := {
	"soldier": preload("res://scenes/enemies/soldier_melee.tscn"),
	"ranged": preload("res://scenes/enemies/ranged_static.tscn"),
	"flying": preload("res://scenes/enemies/flying_weak.tscn"),
	"tank": preload("res://scenes/enemies/tank_slow.tscn"),
}
const ENEMY_KEYS := ["soldier", "ranged", "flying", "tank"]
const MAX_PER_TYPE := 3
const MIN_ENEMIES := 3
const MAX_ENEMIES := 6

var _pause_menu: Node
var _shop_menu: Node
var _game_over_menu: Node
var _game_win_menu: Node
var _shop_prompt_label: Label

@onready var _camera: Camera2D = $Camera2D
@onready var _fade: ColorRect = $TransitionLayer/FadeOverlay
@onready var _tilemap: TileMapLayer = $TileMapLayer
@onready var _minimap := $MinimapLayer/Minimap


func _ready() -> void:
	if _tilemap:
		_tilemap.visible = false
		_tilemap.clear()

	_room_container = Node2D.new()
	_room_container.name = "RoomContainer"
	add_child(_room_container)
	move_child(_room_container, 0)

	_setup_menus()
	_setup_shop_prompt()
	_setup_coin_hud()
	_generate_dungeon()


# --------------------------------------------------------------------------
# Dungeon generation
# --------------------------------------------------------------------------

func _generate_dungeon() -> void:
	_layout = _generator.generate(grid_size, target_rooms)
	_room_scenes.clear()
	_room_open_dirs.clear()
	_cleared_rooms.clear()

	for cell_key in _layout.keys():
		var cell: Vector2i = cell_key
		var room_type: int = _layout[cell]

		var room_scene: PackedScene = ROOM_TEMPLATES.get_random_room_scene(room_type)

		var neighbors := _generator.get_room_neighbors(cell)
		var open_dirs: Array[Vector2i] = []
		for neighbor in neighbors:
			open_dirs.append(neighbor - cell)

		_room_scenes[cell] = room_scene
		_room_open_dirs[cell] = open_dirs

	_current_cell = _generator.start_room
	_camera.position = _room_center()
	_show_current_room()

	_spawn_player()
	_update_minimap()
	_update_shop_prompt()


func _spawn_player() -> void:
	if is_instance_valid(_player):
		if _player.get_parent() == self:
			remove_child(_player)
		_player.queue_free()
	var player_scene := preload("res://scenes/player.tscn")
	_player = player_scene.instantiate()
	add_child(_player)
	_player.position = _room_center()


func _room_center() -> Vector2:
	return ROOM_PIXEL_SIZE / 2.0


# --------------------------------------------------------------------------
# Input — Space to regenerate, M to toggle minimap
# --------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event.is_action_pressed("regenerate"):
		_regenerate()
	elif event.is_action_pressed("minimap_toggle"):
		$MinimapLayer.visible = not $MinimapLayer.visible
	elif event.is_action_pressed("interact"):
		_try_shop_interact()


func _regenerate() -> void:
	_clear_doors()
	_clear_room_enemies()
	_clear_active_room()
	if _tilemap:
		_tilemap.clear()
	_layout.clear()
	_room_scenes.clear()
	_room_open_dirs.clear()
	_generate_dungeon()


# --------------------------------------------------------------------------
# Door transitions
# --------------------------------------------------------------------------

func _on_door_body_entered(body: Node2D, direction: Vector2i) -> void:
	if body != _player:
		return
	_on_door_entered(direction)


func _on_door_entered(direction: Vector2i) -> void:
	if _transitioning:
		return
	var target := _current_cell + direction
	if _layout.has(target):
		_transition_to(target, direction)


func _transition_to(target_cell: Vector2i, entered_dir: Vector2i) -> void:
	_transitioning = true
	if _player:
		_player.frozen = true

	# Fade to black.
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	await tween.finished

	_current_cell = target_cell
	_show_current_room()
	_camera.position = _room_center()

	if _player and SPAWN_OFFSETS.has(entered_dir):
		_player.position = SPAWN_OFFSETS[entered_dir]

	_update_minimap()
	_update_shop_prompt()

	# Fade back in.
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.25)
	await tween.finished

	_transitioning = false
	if _player:
		_player.frozen = false

# --------------------------------------------------------------------------
# Minimap
# --------------------------------------------------------------------------

func _update_minimap() -> void:
	if _minimap:
		_minimap.update_data(_layout, _current_cell, _generator)

# --------------------------------------------------------------------------
# Room management
# --------------------------------------------------------------------------

# Update the room scene and open directions after swapping rooms.
func _show_current_room() -> void:
	var open_dirs := _get_open_dirs(_current_cell)

	_clear_room_enemies()
	_spawn_room_scene(_current_cell)
	_apply_door_tiles(open_dirs)
	_create_doors(open_dirs)
	_spawn_enemies_for_room(_current_cell)


func _get_open_dirs(cell: Vector2i) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = []
	if _room_open_dirs.has(cell):
		for dir in _room_open_dirs[cell]:
			dirs.append(dir as Vector2i)
	return dirs


func _spawn_room_scene(cell: Vector2i) -> void:
	_clear_active_room()
	if not _room_scenes.has(cell):
		return

	var room_scene: PackedScene = _room_scenes[cell] as PackedScene
	if room_scene == null:
		return

	_active_room_root = room_scene.instantiate() as Node2D
	if _active_room_root == null:
		return

	_room_container.add_child(_active_room_root)
	_active_room_tilemap = _find_tilemap_layer(_active_room_root)


func _apply_door_tiles(open_dirs: Array[Vector2i]) -> void:
	if _active_room_tilemap == null:
		return

	for dir in open_dirs:
		if not DOOR_TILE_CELLS.has(dir) or not DOOR_TILE_ATLAS.has(dir):
			continue

		var cells: Array
		var atlas_tiles: Array


		if _layout.get(_current_cell, DungeonGenerator.RoomType.NORMAL) == DungeonGenerator.RoomType.BOSS:
			cells = DOOR_TILE_CELLS[dir]
			atlas_tiles = BOSS_DOOR_TILE_ATLAS[dir]
		else:
			cells = DOOR_TILE_CELLS[dir]
			atlas_tiles = DOOR_TILE_ATLAS[dir]

		var tile_count := mini(cells.size(), atlas_tiles.size())

		for i in range(tile_count):
			var cell: Vector2i = cells[i] as Vector2i
			var atlas: Vector2i = atlas_tiles[i] as Vector2i
			_active_room_tilemap.set_cell(cell, 0, atlas)


func _find_tilemap_layer(root: Node) -> TileMapLayer:
	if root is TileMapLayer:
		return root as TileMapLayer

	for child in root.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		var found := _find_tilemap_layer(child_node)
		if found != null:
			return found

	return null


func _clear_active_room() -> void:
	_active_room_tilemap = null
	if is_instance_valid(_active_room_root):
		_active_room_root.queue_free()
	_active_room_root = null


func _create_doors(open_dirs: Array[Vector2i]) -> void:
	_clear_doors() # Remove existing doors from previous room

	for dir in open_dirs:
		if not DOOR_CENTERS.has(dir):
			continue

		# Area2D that detects when a player body walks into the doorway.
		var area := Area2D.new()
		area.position = DOOR_CENTERS[dir]
		area.monitoring = true
		area.monitorable = false
		add_child(area)

		# Collision shape sized to the 2-tile doorway.
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		if dir == Vector2i.UP or dir == Vector2i.DOWN:
			rect.size = Vector2(56, 24)
		else:
			rect.size = Vector2(24, 56)
		shape.shape = rect
		area.add_child(shape)

		area.body_entered.connect(_on_door_body_entered.bind(dir))
		_door_areas.append(area)


# Clear all existing door areas 
func _clear_doors() -> void:
	for area in _door_areas:
		if is_instance_valid(area):
			area.queue_free()
	_door_areas.clear()

# Enemy spawning
# --------------------------------------------------------------------------

func _spawn_enemies_for_room(cell: Vector2i) -> void:
	var room_type: int = _layout.get(cell, DungeonGenerator.RoomType.NORMAL)
	# Skip spawning in special rooms
	if room_type in [
		DungeonGenerator.RoomType.START,
		DungeonGenerator.RoomType.BOSS,
		DungeonGenerator.RoomType.SHOP,
		DungeonGenerator.RoomType.TREASURE,
		DungeonGenerator.RoomType.SECRET,
	]:
		return

	# If this room has been cleared before, never respawn enemies.
	if _cleared_rooms.get(cell, false):
		return

	var total := randi_range(MIN_ENEMIES, MAX_ENEMIES)
	var type_counts := {}
	for key in ENEMY_KEYS:
		type_counts[key] = 0

	for i in total:
		var available: Array[String] = []
		for key in ENEMY_KEYS:
			if type_counts[key] < MAX_PER_TYPE:
				available.append(key)
		if available.is_empty():
			break
		var key: String = available[randi() % available.size()]
		type_counts[key] += 1

		var scene: PackedScene = ENEMY_SCENES[key]
		var enemy := scene.instantiate()
		add_child(enemy)

		# Track lifecycle so we can mark rooms as cleared.
		# Use an inline lambda so the handler receives exactly (cell, enemy).
		if enemy.has_signal("died"):
			enemy.died.connect(func(e): _on_enemy_died(cell, e))

		# Random position in room interior (avoid walls near edges)
		var margin := 48.0
		var ex := randf_range(margin, ROOM_PIXEL_SIZE.x - margin)
		var ey := randf_range(margin, ROOM_PIXEL_SIZE.y - margin)
		enemy.position = Vector2(ex, ey)

		_room_enemies.append(enemy)


func _on_enemy_died(cell: Vector2i, enemy: Node) -> void:
	# Remove from current room enemy list.
	for i in range(_room_enemies.size()):
		if _room_enemies[i] == enemy:
			_room_enemies.remove_at(i)
			break

	# If no living enemies remain in this cell, mark as cleared.
	var any_alive := false
	for e in _room_enemies:
		if is_instance_valid(e) and e.get_parent() == self:
			any_alive = true
			break

	if not any_alive:
		_cleared_rooms[cell] = true


func _clear_room_enemies() -> void:
	for enemy in _room_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_room_enemies.clear()
	# Also clean up any scattered coins and enemy projectiles from the previous room
	for node in get_tree().get_nodes_in_group("coins"):
		if is_instance_valid(node):
			node.queue_free()
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(proj):
			proj.queue_free()


# --------------------------------------------------------------------------
# Coin HUD
# --------------------------------------------------------------------------

func _setup_coin_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	hud_layer.name = "CoinHUD"
	add_child(hud_layer)

	_coin_label = Label.new()
	_coin_label.text = "Coins: 0"
	_coin_label.add_theme_font_size_override("font_size", 16)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_coin_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_coin_label.add_theme_constant_override("outline_size", 3)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coin_label.anchor_left = 1.0
	_coin_label.anchor_right = 1.0
	_coin_label.anchor_top = 0.0
	_coin_label.offset_left = -140
	_coin_label.offset_right = -8
	_coin_label.offset_top = 88
	hud_layer.add_child(_coin_label)

	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("coins_changed"):
		gm.coins_changed.connect(_on_coins_changed)


func _on_coins_changed(new_amount: int) -> void:
	if _coin_label:
		_coin_label.text = "Coins: %d" % new_amount


# --------------------------------------------------------------------------
# Menu overlays
# --------------------------------------------------------------------------

func _setup_menus() -> void:
	_pause_menu = preload("res://scenes/menus/pause_menu.tscn").instantiate()
	add_child(_pause_menu)

	_shop_menu = preload("res://scenes/menus/shop_menu.tscn").instantiate()
	add_child(_shop_menu)

	_game_over_menu = preload("res://scenes/menus/game_over.tscn").instantiate()
	add_child(_game_over_menu)

	_game_win_menu = preload("res://scenes/menus/game_win.tscn").instantiate()
	add_child(_game_win_menu)


func _setup_shop_prompt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	layer.name = "ShopPromptLayer"
	add_child(layer)

	var wrapper := Control.new()
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(wrapper)

	_shop_prompt_label = Label.new()
	_shop_prompt_label.anchor_left = 0.5
	_shop_prompt_label.anchor_right = 0.5
	_shop_prompt_label.anchor_top = 1.0
	_shop_prompt_label.anchor_bottom = 1.0
	_shop_prompt_label.offset_left = -200
	_shop_prompt_label.offset_right = 200
	_shop_prompt_label.offset_top = -50
	_shop_prompt_label.offset_bottom = -30
	_shop_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_prompt_label.add_theme_font_size_override("font_size", 12)
	_shop_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_shop_prompt_label.visible = false
	wrapper.add_child(_shop_prompt_label)


func _update_shop_prompt() -> void:
	if not _shop_prompt_label:
		return
	var is_shop: bool = _layout.get(_current_cell, -1) == DungeonGenerator.RoomType.SHOP
	_shop_prompt_label.visible = is_shop
	if is_shop:
		var key_name: String = SettingsManager.get_action_key_name("interact")
		_shop_prompt_label.text = "Press " + key_name + " to talk to the Shopkeeper"


func _try_shop_interact() -> void:
	if _layout.get(_current_cell, -1) == DungeonGenerator.RoomType.SHOP:
		_shop_menu.open_shop()
