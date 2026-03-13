class_name Room
extends Node2D
## A single dungeon room. Built at runtime from a template string and a list
## of directions that should have open doors.

# Emitted when a physics body (player) enters one of this room's doors.
# `direction` is the Vector2i pointing toward the adjacent room
# (e.g. Vector2i.UP means the player walked through the top door).
signal door_entered(direction: Vector2i)

const ROOM_WIDTH  := 20
const ROOM_HEIGHT := 11
const TILE_SIZE   := 32

# Door openings are 2 tiles wide, centered on each wall.
# Each entry maps a direction to the tile coords that get carved open.
const DOOR_TILES := {
	Vector2i.UP:    [Vector2i(9, 0),  Vector2i(10, 0)],
	Vector2i.DOWN:  [Vector2i(9, 10), Vector2i(10, 10)],
	Vector2i.LEFT:  [Vector2i(0, 4),  Vector2i(0, 5)],
	Vector2i.RIGHT: [Vector2i(19, 4), Vector2i(19, 5)],
}

# Pixel center of each door opening (for placing the Area2D trigger).
const DOOR_CENTERS := {
	Vector2i.UP:    Vector2(320, 16),
	Vector2i.DOWN:  Vector2(320, 336),
	Vector2i.LEFT:  Vector2(16, 160),
	Vector2i.RIGHT: Vector2(624, 160),
}

var _tilemap: TileMapLayer
var _open_directions: Array[Vector2i] = []


## Call this right after instancing to populate the room.
## `template`        — a 20x11 character grid (from RoomTemplates)
## `open_directions` — which sides have an adjacent room (e.g. [UP, RIGHT])
## `tileset`         — the shared TileSet created by TileFactory
func setup(template: String, open_directions: Array, tileset: TileSet) -> void:
	for dir in open_directions:
		_open_directions.append(dir as Vector2i)

	_build_tilemap(template, tileset)
	_create_doors()


func _build_tilemap(template: String, tileset: TileSet) -> void:
	_tilemap = TileMapLayer.new()
	_tilemap.tile_set = tileset
	add_child(_tilemap)

	# Parse the template string row by row, character by character.
	var lines := template.strip_edges().split("\n")
	for y in range(mini(lines.size(), ROOM_HEIGHT)):
		var line := lines[y]
		for x in range(mini(line.length(), ROOM_WIDTH)):
			var atlas_coords: Vector2i
			match line[x]:
				"W":
					atlas_coords = TileFactory.WALL
				"S":
					atlas_coords = TileFactory.SPIKE
				_:
					atlas_coords = TileFactory.FLOOR
			_tilemap.set_cell(Vector2i(x, y), TileFactory.SOURCE_ID, atlas_coords)

	# Carve door openings. For each door tile, carve inward from the wall
	# edge until we reach the room interior (a floor tile). This handles
	# rooms with thick walls automatically — a 1-tile wall carves 1 tile,
	# a 2-tile wall carves 2 tiles, etc.
	for dir in _open_directions:
		if not DOOR_TILES.has(dir):
			continue
		var inward := _inward_direction(dir)
		var tiles: Array = DOOR_TILES[dir]
		for start_pos in tiles:
			var pos: Vector2i = start_pos
			while _in_room(pos):
				if _tilemap.get_cell_atlas_coords(pos) == TileFactory.FLOOR:
					break
				_tilemap.set_cell(pos, TileFactory.SOURCE_ID, TileFactory.FLOOR)
				pos += inward


func _create_doors() -> void:
	for dir in _open_directions:
		if not DOOR_CENTERS.has(dir):
			continue

		var pixel_pos: Vector2 = DOOR_CENTERS[dir]

		# Area2D that detects when a player body walks into the doorway.
		var area := Area2D.new()
		area.position = pixel_pos
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


func _on_door_body_entered(_body: Node2D, direction: Vector2i) -> void:
	door_entered.emit(direction)


# Returns the direction pointing inward from a wall edge.
static func _inward_direction(door_dir: Vector2i) -> Vector2i:
	if door_dir == Vector2i.UP:
		return Vector2i.DOWN
	if door_dir == Vector2i.DOWN:
		return Vector2i.UP
	if door_dir == Vector2i.LEFT:
		return Vector2i.RIGHT
	return Vector2i.LEFT


func _in_room(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < ROOM_WIDTH and pos.y >= 0 and pos.y < ROOM_HEIGHT
