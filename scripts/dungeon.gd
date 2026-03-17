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

const PLAYER_DOOR_LAYER := 2
const DASH_DOOR_LAYER := 6
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

# Player collides with world layer (1) — barriers use this to block doors.
const WORLD_LAYER := 1
const PLAYER_LAYER := 3
const ENEMY_LAYER := 4
const FURNITURE_LAYER := 5

# Spawn validation: avoid spawning inside walls, obstacles, other enemies, or player.
const SPAWN_CHECK_RADIUS := 24.0
const SPAWN_MAX_ATTEMPTS := 25

@export var grid_size := Vector2i(8, 8)
@export var target_rooms: int = 12

var _generator := DungeonGenerator.new()
var _layout: Dictionary = {}
var _current_cell: Vector2i
var _transitioning := false
var _player: CharacterBody2D
var _door_areas: Array[Area2D] = []
var _door_barriers: Array[StaticBody2D] = []  # Block doors until room is cleared
var _room_scenes: Dictionary = {}      # for each cell, store the selected room scene
var _room_open_dirs: Dictionary = {}   # for each cell, store the open directions
var _room_container: Node2D
var _active_room_root: Node2D
var _active_room_tilemap: TileMapLayer
var _room_enemies: Array[Node] = []
var _coin_label: Label
var _heart_hud: Control
var _ability_cooldown_hud: Control
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
const BOSS_SCENE := preload("res://scenes/boss.tscn")

var _pause_menu: Node
var _shop_menu: Node
var _game_over_menu: Node
var _game_win_menu: Node
var _shop_prompt_label: Label
var _spirit_menu: Node
var _boss_ref: Node = null
var _boss_health_bar: Control
var _boss_health_bar_fill: ColorRect
var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _shake_intensity: float = 10.0
var _boss_room_spawn_timer: float = 0.0
const BOSS_ROOM_SPAWN_INTERVAL := 5.0
var _treasure_claimed: Dictionary = {} # cell -> bool (coins spawned)
var _secret_completed: Dictionary = {} # cell -> bool (spirit interacted)

@onready var _camera: Camera2D = $Camera2D
@onready var _fade: ColorRect = $TransitionLayer/FadeOverlay
@onready var _tilemap: TileMapLayer = $TileMapLayer
@onready var _minimap := $MinimapLayer/Minimap


func _ready() -> void:
	# Seed the global RNG used by randf()/randi_range() so chances feel correct.
	randomize()
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
	_setup_heart_hud()
	_setup_ability_cooldown_hud()
	_setup_boss_health_bar()
	_generate_dungeon()


# --------------------------------------------------------------------------
# Dungeon generation
# --------------------------------------------------------------------------

func _generate_dungeon() -> void:
	_layout = _generator.generate(grid_size, target_rooms)
	_room_scenes.clear()
	_room_open_dirs.clear()
	_cleared_rooms.clear()
	_treasure_claimed.clear()
	_secret_completed.clear()

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
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)
	if _player.has_signal("health_changed") and _heart_hud:
		_player.health_changed.connect(_on_player_health_changed)
	if _heart_hud and _heart_hud.has_method("set_half_hearts"):
		_heart_hud.set_half_hearts(_player.current_health)
	if _ability_cooldown_hud and _ability_cooldown_hud.has_method("set_player"):
		_ability_cooldown_hud.set_player(_player)


func _on_player_died() -> void:
	if _game_over_menu and _game_over_menu.has_method("show_game_over"):
		_game_over_menu.show_game_over()


func _room_center() -> Vector2:
	return ROOM_PIXEL_SIZE / 2.0


func _room_boss_position() -> Vector2:
	return Vector2(ROOM_PIXEL_SIZE.x / 2.0, ROOM_PIXEL_SIZE.y / 3.0)


func _spawn_coin_pile(count: int, room_pos: Vector2) -> void:
	var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
	for i in count:
		var coin := coin_scene.instantiate()
		add_child(coin)
		coin.position = room_pos
		# Scatter a bit so it looks like a pile burst.
		var angle := randf() * TAU
		var dist := randf_range(0.0, 28.0)
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var tw := create_tween()
		tw.tween_property(coin, "position", room_pos + offset, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _get_boss_room_cell() -> Vector2i:
	for cell in _layout.keys():
		if _layout[cell] == DungeonGenerator.RoomType.BOSS:
			return cell
	return Vector2i(-999, -999)


# --------------------------------------------------------------------------
# Input — Space to regenerate, M to toggle minimap, T to teleport to boss
# --------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event.is_action_pressed("regenerate"):
		_regenerate()
	elif event.is_action_pressed("minimap_toggle"):
		$MinimapLayer.visible = not $MinimapLayer.visible
	elif event.is_action_pressed("teleport_boss"):
		_teleport_to_boss_room()
	elif event.is_action_pressed("interact"):
		_try_shop_interact()


func _process(delta: float) -> void:
	if _shake_timer > 0:
		_shake_timer -= delta
		var f := _shake_timer / _shake_duration if _shake_duration > 0 else 0.0
		_camera.offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity) * f,
			randf_range(-_shake_intensity, _shake_intensity) * f
		)
	else:
		_camera.offset = Vector2.ZERO

	# Keep prompts (shop/secret) responsive as player moves.
	if not _transitioning and not get_tree().paused:
		_update_shop_prompt()

	# Treasure room: when player gets near center, spawn a one-time coin pile.
	if _layout.get(_current_cell, DungeonGenerator.RoomType.NORMAL) == DungeonGenerator.RoomType.TREASURE and is_instance_valid(_player):
		if not _treasure_claimed.get(_current_cell, false):
			if _player.position.distance_to(_room_center()) <= 56.0:
				_treasure_claimed[_current_cell] = true
				_spawn_coin_pile(randi_range(10, 15), _room_center())

	# Boss room: spawn one random enemy every 5 seconds while boss is alive
	if _layout.get(_current_cell, DungeonGenerator.RoomType.NORMAL) == DungeonGenerator.RoomType.BOSS and _boss_ref and is_instance_valid(_boss_ref):
		_boss_room_spawn_timer += delta
		if _boss_room_spawn_timer >= BOSS_ROOM_SPAWN_INTERVAL:
			_boss_room_spawn_timer = 0.0
			_spawn_one_random_enemy_in_boss_room()


func _screen_shake(duration: float, intensity: float = 10.0) -> void:
	_shake_duration = duration
	_shake_timer = duration
	_shake_intensity = intensity


func _teleport_to_boss_room() -> void:
	var boss_cell := _get_boss_room_cell()
	if not _layout.has(boss_cell) or boss_cell == _current_cell:
		return
	_transitioning = true
	if _player:
		_player.frozen = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.15)
	await tween.finished
	_current_cell = boss_cell
	_show_current_room()
	_camera.position = _room_center()
	if _player:
		_player.position = _room_center()
	_update_minimap()
	_update_shop_prompt()
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.15)
	await tween.finished
	_transitioning = false
	if _player:
		_player.frozen = false


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
	# Block leaving the room until all enemies are dead.
	if _has_living_enemies_in_room():
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
	_spawn_boss_for_room(_current_cell)
	_update_door_barriers()
	_update_shop_prompt()
	if _layout.get(_current_cell, DungeonGenerator.RoomType.NORMAL) == DungeonGenerator.RoomType.BOSS and _boss_ref:
		_screen_shake(2.0)


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
	_clear_doors() # Remove existing doors and barriers from previous room

	for dir in open_dirs:
		if not DOOR_CENTERS.has(dir):
			continue

		var rect_size: Vector2
		if dir == Vector2i.UP or dir == Vector2i.DOWN:
			rect_size = Vector2(56, 24)
		else:
			rect_size = Vector2(24, 56)

		# Area2D that detects when a player body walks into the doorway.
		var area := Area2D.new()
		area.position = DOOR_CENTERS[dir]
		area.monitoring = true
		area.monitorable = false
		area.collision_mask = 0
		area.set_collision_mask_value(PLAYER_DOOR_LAYER, true)
		area.set_collision_mask_value(DASH_DOOR_LAYER, true)
		add_child(area)

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = rect_size
		shape.shape = rect
		area.add_child(shape)

		area.body_entered.connect(_on_door_body_entered.bind(dir))
		_door_areas.append(area)

		# StaticBody2D barrier — blocks player until room is cleared.
		var barrier := StaticBody2D.new()
		barrier.position = DOOR_CENTERS[dir]
		barrier.collision_layer = 0  # Start disabled; _update_door_barriers enables when room has enemies
		barrier.collision_mask = 0
		add_child(barrier)
		var barrier_shape := CollisionShape2D.new()
		var barrier_rect := RectangleShape2D.new()
		barrier_rect.size = rect_size
		barrier_shape.shape = barrier_rect
		barrier.add_child(barrier_shape)
		_door_barriers.append(barrier)


# Clear all existing door areas and barriers.
func _clear_doors() -> void:
	for area in _door_areas:
		if is_instance_valid(area):
			area.queue_free()
	_door_areas.clear()
	for barrier in _door_barriers:
		if is_instance_valid(barrier):
			barrier.queue_free()
	_door_barriers.clear()


func _update_door_barriers() -> void:
	var should_block := _has_living_enemies_in_room()
	for barrier in _door_barriers:
		if is_instance_valid(barrier):
			barrier.set_collision_layer_value(WORLD_LAYER, should_block)


func _has_living_enemies_in_room() -> bool:
	for e in _room_enemies:
		if is_instance_valid(e) and e.get_parent() == self:
			return true
	return false

# Enemy spawning
# --------------------------------------------------------------------------

## Returns true if a circle of SPAWN_CHECK_RADIUS at global_pos does not overlap world, player, or enemies.
func _is_spawn_position_valid(global_pos: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = SPAWN_CHECK_RADIUS
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_pos)
	params.collision_mask = WORLD_LAYER | PLAYER_LAYER | ENEMY_LAYER | FURNITURE_LAYER
	var results := space_state.intersect_shape(params, 1)
	return results.is_empty()


## Picks a random position in the room interior; retries until non-overlapping or max attempts. Margin in pixels from edges.
func _get_valid_spawn_position_in_room(margin: float) -> Vector2:
	var attempt := 0
	while attempt < SPAWN_MAX_ATTEMPTS:
		var pos := Vector2(
			randf_range(margin, ROOM_PIXEL_SIZE.x - margin),
			randf_range(margin, ROOM_PIXEL_SIZE.y - margin)
		)
		if _is_spawn_position_valid(pos):
			return pos
		attempt += 1
	# Fallback: center of room (caller can still use it)
	return ROOM_PIXEL_SIZE / 2.0


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
		enemy.position = _get_valid_spawn_position_in_room(48.0)
		add_child(enemy)

		# Track lifecycle so we can mark rooms as cleared.
		# Use an inline lambda so the handler receives exactly (cell, enemy).
		if enemy.has_signal("died"):
			enemy.died.connect(func(e): _on_enemy_died(cell, e))

		_room_enemies.append(enemy)


func _spawn_boss_for_room(cell: Vector2i) -> void:
	if _layout.get(cell, DungeonGenerator.RoomType.NORMAL) != DungeonGenerator.RoomType.BOSS:
		return
	if _cleared_rooms.get(cell, false):
		return
	var boss := BOSS_SCENE.instantiate()
	add_child(boss)
	boss.position = _room_boss_position()
	_boss_ref = boss
	if boss.has_signal("died"):
		boss.died.connect(func(): _on_boss_died(cell, boss))
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_boss_health_changed)
	_room_enemies.append(boss)
	_show_boss_health_bar(boss.max_health, boss.current_health)
	_boss_room_spawn_timer = 0.0


func _spawn_one_random_enemy_in_boss_room() -> void:
	var key: String = ENEMY_KEYS[randi() % ENEMY_KEYS.size()]
	var scene: PackedScene = ENEMY_SCENES[key]
	var enemy := scene.instantiate()
	enemy.position = _get_valid_spawn_position_in_room(48.0)
	# Boss room: force immediate aggro so they don't idle at long range.
	if enemy is EnemyBase:
		(enemy as EnemyBase).been_attacked = true
	add_child(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(func(e): _on_enemy_died(_current_cell, e))
	_room_enemies.append(enemy)


const HEART_PICKUP_SCENE := preload("res://scenes/heart_pickup.tscn")


func _on_boss_died(cell: Vector2i, _boss: Node) -> void:
	# Kill all enemies in the room (adds that spawned during fight)
	for e in _room_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_room_enemies.clear()
	_cleared_rooms[cell] = true
	_update_door_barriers()
	_boss_ref = null
	_hide_boss_health_bar()
	_screen_shake(2.0)
	get_tree().create_timer(1.0).timeout.connect(_show_boss_victory)


func _show_boss_victory() -> void:
	if _game_win_menu and _game_win_menu.has_method("show_victory"):
		_game_win_menu.show_victory()


func _on_boss_health_changed(current: int, maximum: int) -> void:
	_update_boss_health_bar(current, maximum)


func _on_enemy_died(cell: Vector2i, enemy: Node) -> void:
	if enemy == _boss_ref:
		return
	var death_pos: Vector2 = enemy.global_position if is_instance_valid(enemy) else Vector2.ZERO

	# Remove from current room enemy list.
	for i in range(_room_enemies.size()):
		if _room_enemies[i] == enemy:
			_room_enemies.remove_at(i)
			break

	# If no living enemies remain in this cell, mark as cleared and spawn 1 heart pickup.
	var any_alive := false
	for e in _room_enemies:
		if is_instance_valid(e) and e.get_parent() == self:
			any_alive = true
			break

	if not any_alive:
		_cleared_rooms[cell] = true
		_update_door_barriers()
		# Last enemy in room: drop 1 heart that heals 1 full heart.
		var heart := HEART_PICKUP_SCENE.instantiate()
		add_child(heart)
		heart.global_position = death_pos


func _clear_room_enemies() -> void:
	_boss_ref = null
	_hide_boss_health_bar()
	_boss_room_spawn_timer = 0.0
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
	for node in get_tree().get_nodes_in_group("heart_pickups"):
		if is_instance_valid(node):
			node.queue_free()


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


func _on_player_health_changed(old_half: int, new_half: int) -> void:
	if not _heart_hud:
		return
	if new_half >= old_half:
		_heart_hud.set_half_hearts(new_half)
	else:
		_heart_hud.on_damage_taken(old_half, new_half)


func _setup_heart_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	hud_layer.name = "HeartHUD"
	add_child(hud_layer)

	var heart_script := load("res://scripts/ui/heart_hud.gd") as GDScript
	_heart_hud = Control.new()
	_heart_hud.set_script(heart_script)
	_heart_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_heart_hud.position = Vector2.ZERO
	_heart_hud.custom_minimum_size = Vector2(220, 56)
	hud_layer.add_child(_heart_hud)


func _setup_ability_cooldown_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	hud_layer.name = "AbilityCooldownHUD"
	add_child(hud_layer)

	var script := load("res://scripts/ui/ability_cooldown_hud.gd") as GDScript
	_ability_cooldown_hud = Control.new()
	_ability_cooldown_hud.set_script(script)
	_ability_cooldown_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Left side of screen, slightly below hearts.
	_ability_cooldown_hud.position = Vector2(8, 72)
	hud_layer.add_child(_ability_cooldown_hud)


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

	var spirit_script := load("res://scripts/menus/mysterious_spirit_menu.gd") as GDScript
	_spirit_menu = CanvasLayer.new()
	_spirit_menu.set_script(spirit_script)
	add_child(_spirit_menu)
	if _spirit_menu.has_signal("accepted"):
		_spirit_menu.accepted.connect(_on_spirit_accepted)
	if _spirit_menu.has_signal("declined"):
		_spirit_menu.declined.connect(_on_spirit_declined)


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


func _setup_boss_health_bar() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	layer.name = "BossHealthBarLayer"
	add_child(layer)

	# Full-rect wrapper so we can center the bar
	var wrapper := Control.new()
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(wrapper)

	# CenterContainer at top half to put bar at top center (a little lower)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.anchor_top = 0.0
	center.anchor_bottom = 0.0
	center.offset_top = 28
	center.offset_bottom = 95
	center.offset_left = 0
	center.offset_right = 0
	wrapper.add_child(center)

	var bar_width := 600
	_boss_health_bar = Control.new()
	_boss_health_bar.custom_minimum_size = Vector2(bar_width, 65)
	_boss_health_bar.visible = false
	center.add_child(_boss_health_bar)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	_boss_health_bar.add_child(vbox)

	var label := Label.new()
	label.text = "THE DUNGEON BOSS"
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 24)
	bar_bg.color = Color(0.2, 0.1, 0.1, 0.9)
	vbox.add_child(bar_bg)

	_boss_health_bar_fill = ColorRect.new()
	_boss_health_bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_boss_health_bar_fill.anchor_left = 0.0
	_boss_health_bar_fill.anchor_right = 0.0
	_boss_health_bar_fill.anchor_top = 0.0
	_boss_health_bar_fill.anchor_bottom = 1.0
	_boss_health_bar_fill.offset_top = 2
	_boss_health_bar_fill.offset_bottom = -2
	_boss_health_bar_fill.offset_left = 2
	_boss_health_bar_fill.offset_right = -2
	_boss_health_bar_fill.color = Color(0.9, 0.15, 0.15)
	bar_bg.add_child(_boss_health_bar_fill)


func _show_boss_health_bar(max_hp: int, current_hp: int) -> void:
	if _boss_health_bar:
		_boss_health_bar.visible = true
		_update_boss_health_bar(current_hp, max_hp)


func _hide_boss_health_bar() -> void:
	if _boss_health_bar:
		_boss_health_bar.visible = false


func _update_boss_health_bar(current: int, maximum: int) -> void:
	if not _boss_health_bar_fill or maximum <= 0:
		return
	var parent_rect := _boss_health_bar_fill.get_parent_control()
	if parent_rect:
		var ratio := clampf(float(current) / float(maximum), 0.0, 1.0)
		_boss_health_bar_fill.anchor_right = ratio
		_boss_health_bar_fill.offset_right = 0


func _update_shop_prompt() -> void:
	if not _shop_prompt_label:
		return
	var room_type: int = _layout.get(_current_cell, -1)
	var key_name: String = SettingsManager.get_action_key_name("interact")

	if room_type == DungeonGenerator.RoomType.SHOP:
		_shop_prompt_label.visible = true
		_shop_prompt_label.text = "Press " + key_name + " to talk to the Shopkeeper"
		return

	if room_type == DungeonGenerator.RoomType.SECRET and not _secret_completed.get(_current_cell, false):
		_shop_prompt_label.visible = true
		_shop_prompt_label.text = "Press " + key_name + " to talk to the Mysterious Spirit"
		return

	_shop_prompt_label.visible = false


func _try_shop_interact() -> void:
	var room_type: int = _layout.get(_current_cell, -1)
	if room_type == DungeonGenerator.RoomType.SHOP:
		_shop_menu.open_shop()
		return

	if room_type == DungeonGenerator.RoomType.SECRET and not _secret_completed.get(_current_cell, false):
		if _spirit_menu and _spirit_menu.has_method("open_menu") and (not _spirit_menu.has_method("is_open") or not _spirit_menu.is_open()):
			_spirit_menu.open_menu()


func _on_spirit_declined() -> void:
	_secret_completed[_current_cell] = true
	_update_shop_prompt()


func _on_spirit_accepted() -> void:
	_secret_completed[_current_cell] = true
	_update_shop_prompt()
	var roll := randf()
	# 20% teleport to boss room
	if roll < 0.20:
		await _teleport_to_boss_room()
		if _spirit_menu and _spirit_menu.has_method("show_result"):
			_spirit_menu.show_result("The Spirit's laughter curls through the dark like smoke.\n\nIn the blink of an eye, the floor forgets you were ever standing here, and the dungeon hurls you toward a place meant for endings.")
		return
	# 30% spawn 8 random enemies
	if roll < 0.50:
		for i in range(8):
			_spawn_one_random_enemy_in_secret_room()
		_update_door_barriers()
		if _spirit_menu and _spirit_menu.has_method("show_result"):
			_spirit_menu.show_result("A cold hush falls over the room… then the air splits with hungry footsteps.\n\nYour wager has been answered with violence. Steel yourself. The Spirit has called in something that wants you gone.")
		return
	# 50% coin pile (no enemies)
	_spawn_coin_pile(randi_range(15, 20), _room_center())
	# Bonus: good outcome also spawns 2 heart pickups.
	for i in range(2):
		var heart := HEART_PICKUP_SCENE.instantiate()
		add_child(heart)
		heart.position = _room_center()
		var angle := randf() * TAU
		var dist := randf_range(0.0, 22.0)
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var tw := create_tween()
		tw.tween_property(heart, "position", _room_center() + offset, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if _spirit_menu and _spirit_menu.has_method("show_result"):
		_spirit_menu.show_result("A pleasant warmth blooms in your chest as the shadows loosen their grip.\n\nWith a soft chime, a shower of coin spills into the center of the room. The Spirit has paid out, and it feels almost generous.")


func _spawn_one_random_enemy_in_secret_room() -> void:
	var key: String = ENEMY_KEYS[randi() % ENEMY_KEYS.size()]
	var scene: PackedScene = ENEMY_SCENES[key]
	var enemy := scene.instantiate()
	enemy.position = _get_valid_spawn_position_in_room(48.0)
	if enemy is EnemyBase:
		(enemy as EnemyBase).been_attacked = true
	add_child(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(func(e): _on_enemy_died(_current_cell, e))
	_room_enemies.append(enemy)
