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

	_generate_dungeon()


# --------------------------------------------------------------------------
# Dungeon generation
# --------------------------------------------------------------------------

func _generate_dungeon() -> void:
	_layout = _generator.generate(grid_size, target_rooms)
	_room_scenes.clear()
	_room_open_dirs.clear()

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


func _spawn_player() -> void:
	if _player:
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
	if event.is_action_pressed("ui_accept"):
		_regenerate()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		$MinimapLayer.visible = not $MinimapLayer.visible


func _regenerate() -> void:
	_clear_doors()
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

	_spawn_room_scene(_current_cell)
	_apply_door_tiles(open_dirs)
	_create_doors(open_dirs)


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

		var cells: Array = DOOR_TILE_CELLS[dir]
		var atlas_tiles: Array = DOOR_TILE_ATLAS[dir]
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
