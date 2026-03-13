class_name TileFactory
extends RefCounted
## Creates a placeholder TileSet programmatically with solid-color tiles.
## Swap the generated atlas texture for real pixel art later.

# Atlas coordinates for each tile type (column in the 3x1 atlas).
const WALL  := Vector2i(0, 0)
const FLOOR := Vector2i(1, 0)
const SPIKE := Vector2i(2, 0)

const SOURCE_ID := 0


static func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	# Physics layer 0: wall collision (blocks movement).
	ts.add_physics_layer()

	# Build a tiny 96x32 atlas image (3 tiles side by side).
	var img := Image.create(96, 32, false, Image.FORMAT_RGBA8)
	_paint_tile(img, 0,  Color(0.22, 0.22, 0.28), Color(0.16, 0.16, 0.20))
	_paint_tile(img, 32, Color(0.55, 0.45, 0.35), Color(0.45, 0.38, 0.28))
	_paint_tile(img, 64, Color(0.75, 0.25, 0.15), Color(0.60, 0.18, 0.10))

	var tex := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(32, 32)
	ts.add_source(source, SOURCE_ID)

	# Register the three tiles in the atlas.
	source.create_tile(WALL)
	source.create_tile(FLOOR)
	source.create_tile(SPIKE)

	# Give the wall tile a full-tile collision polygon.
	var wall_data := source.get_tile_data(WALL, 0)
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16),
		Vector2(16, 16), Vector2(-16, 16),
	]))

	return ts


static func _paint_tile(img: Image, x_offset: int, fill: Color, border: Color) -> void:
	img.fill_rect(Rect2i(x_offset, 0, 32, 32), border)
	img.fill_rect(Rect2i(x_offset + 1, 1, 30, 30), fill)
