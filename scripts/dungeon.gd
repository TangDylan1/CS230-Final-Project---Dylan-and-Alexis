extends Node2D
## Dungeon manager. Generates the room layout with the Drunkard's Walk
## algorithm, instances Room scenes from templates, spawns the player,
## and handles room transitions with a fade-to-black effect.
##
## CONTROLS:
##   WASD / Arrow keys — move the player
##   Space             — regenerate the entire dungeon
##   M                 — toggle developer minimap

# Room dimensions in pixels (20 tiles * 32px, 11 tiles * 32px).
const ROOM_PIXEL_SIZE := Vector2(640, 352)

# When the player enters a door going direction D, they spawn at this
# room-local position in the TARGET room (near the opposite door, pushed
# one tile inward so they don't immediately re-trigger the door).
const SPAWN_OFFSETS := {
	Vector2i.UP:    Vector2(320, 304),
	Vector2i.DOWN:  Vector2(320, 48),
	Vector2i.LEFT:  Vector2(592, 160),
	Vector2i.RIGHT: Vector2(48, 160),
}

@export var grid_size := Vector2i(8, 8)
@export var target_rooms: int = 12

var _generator := DungeonGenerator.new()
var _layout: Dictionary = {}
var _rooms: Dictionary = {}       # Vector2i -> Room node
var _current_cell: Vector2i
var _transitioning := false
var _tileset: TileSet
var _player: CharacterBody2D

@onready var _camera: Camera2D = $Camera2D
@onready var _fade: ColorRect = $TransitionLayer/FadeOverlay
@onready var _rooms_node: Node2D = $Rooms
@onready var _minimap := $MinimapLayer/Minimap


func _ready() -> void:
	_tileset = TileFactory.create_tileset()
	_generate_dungeon()


# --------------------------------------------------------------------------
# Dungeon generation
# --------------------------------------------------------------------------

func _generate_dungeon() -> void:
	_layout = _generator.generate(grid_size, target_rooms)
	var room_scene := preload("res://scenes/room.tscn")

	for cell_key in _layout.keys():
		var cell: Vector2i = cell_key
		var room_type: int = _layout[cell]

		var template := RoomTemplates.get_random_template(room_type)

		var neighbors := _generator.get_room_neighbors(cell)
		var open_dirs: Array[Vector2i] = []
		for neighbor in neighbors:
			open_dirs.append(neighbor - cell)

		var room: Room = room_scene.instantiate()
		_rooms_node.add_child(room)
		room.position = Vector2(cell.x * ROOM_PIXEL_SIZE.x, cell.y * ROOM_PIXEL_SIZE.y)
		room.setup(template, open_dirs, _tileset)
		room.door_entered.connect(_on_door_entered.bind(cell))
		_rooms[cell] = room

	# Center camera on the start room.
	_current_cell = _generator.start_room
	_camera.position = _room_center(_current_cell)

	# Spawn the player at the center of the start room.
	_spawn_player()
	_update_minimap()


func _spawn_player() -> void:
	if _player:
		_player.queue_free()
	var player_scene := preload("res://scenes/player.tscn")
	_player = player_scene.instantiate()
	add_child(_player)
	_player.position = _room_center(_current_cell)


func _room_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * ROOM_PIXEL_SIZE + ROOM_PIXEL_SIZE / 2.0


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
	for child in _rooms_node.get_children():
		_rooms_node.remove_child(child)
		child.queue_free()
	_rooms.clear()
	_layout.clear()
	_generate_dungeon()


# --------------------------------------------------------------------------
# Door transitions
# --------------------------------------------------------------------------

func _on_door_entered(direction: Vector2i, from_cell: Vector2i) -> void:
	if _transitioning:
		return
	var target := from_cell + direction
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

	# Move camera to the new room.
	_current_cell = target_cell
	_camera.position = _room_center(_current_cell)

	# Reposition player at the opposite door in the new room.
	if _player and SPAWN_OFFSETS.has(entered_dir):
		var room_origin := Vector2(_current_cell) * ROOM_PIXEL_SIZE
		_player.position = room_origin + SPAWN_OFFSETS[entered_dir]

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
