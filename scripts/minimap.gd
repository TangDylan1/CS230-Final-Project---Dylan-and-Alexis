class_name Minimap
extends Node2D
## Developer minimap overlay. Draws a small color-coded map of the dungeon
## layout in the top-right corner. Shows room types and highlights the
## current room. Toggle with 'M'.

const CELL := 14
const GAP := 2
const MARGIN := 6

var layout: Dictionary = {}
var current_cell: Vector2i
var generator: DungeonGenerator


func update_data(p_layout: Dictionary, p_current: Vector2i, p_generator: DungeonGenerator) -> void:
	layout = p_layout
	current_cell = p_current
	generator = p_generator
	queue_redraw()


func _draw() -> void:
	if layout.is_empty():
		return

	# Find the bounding box of all rooms in the layout.
	var min_c := Vector2i(9999, 9999)
	var max_c := Vector2i(-9999, -9999)
	for k in layout.keys():
		var c: Vector2i = k
		min_c.x = mini(min_c.x, c.x)
		min_c.y = mini(min_c.y, c.y)
		max_c.x = maxi(max_c.x, c.x)
		max_c.y = maxi(max_c.y, c.y)

	var grid := max_c - min_c + Vector2i.ONE
	var map_w := float(grid.x * CELL + MARGIN * 2)
	var map_h := float(grid.y * CELL + MARGIN * 2)

	# Position in the top-right corner of the screen.
	var vp := get_viewport_rect().size
	var origin := Vector2(vp.x - map_w - MARGIN, MARGIN)

	# Semi-transparent background.
	draw_rect(Rect2(origin, Vector2(map_w, map_h)), Color(0, 0, 0, 0.65))

	var font := ThemeDB.fallback_font

	# Draw each room as a small colored square.
	for k in layout.keys():
		var c: Vector2i = k
		var local := c - min_c
		var rect := Rect2(
			origin + Vector2(MARGIN + local.x * CELL + 1, MARGIN + local.y * CELL + 1),
			Vector2(CELL - GAP, CELL - GAP)
		)
		var rt: int = layout[c]
		draw_rect(rect, _color(rt))

		# White border around the room the player is currently in.
		if c == current_cell:
			draw_rect(rect, Color(1, 1, 1, 0.9), false, 2.0)

		# Letter label for special rooms.
		var letter := _letter(rt)
		if letter != "":
			var text_pos := rect.position + Vector2(1, CELL - GAP - 3)
			draw_string(font, text_pos, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.9))


func _color(rt: int) -> Color:
	if rt == DungeonGenerator.RoomType.START:
		return Color(0.25, 0.78, 0.42)
	if rt == DungeonGenerator.RoomType.BOSS:
		return Color(0.9, 0.25, 0.25)
	if rt == DungeonGenerator.RoomType.SHOP:
		return Color(0.92, 0.78, 0.2)
	if rt == DungeonGenerator.RoomType.TREASURE:
		return Color(0.7, 0.4, 0.85)
	if rt == DungeonGenerator.RoomType.SECRET:
		return Color(0.3, 0.75, 0.75)
	return Color(0.35, 0.55, 0.78)


func _letter(rt: int) -> String:
	if rt == DungeonGenerator.RoomType.START:
		return "S"
	if rt == DungeonGenerator.RoomType.BOSS:
		return "B"
	if rt == DungeonGenerator.RoomType.SHOP:
		return "$"
	if rt == DungeonGenerator.RoomType.TREASURE:
		return "T"
	if rt == DungeonGenerator.RoomType.SECRET:
		return "?"
	return ""
