class_name TileFactory
extends RefCounted

# Atlas coordinates for each tile type
const WALL  := Vector2i(18, 14)
const FLOOR := Vector2i(12, 28)
const SPIKE := Vector2i(10, 28)

const SOURCE_ID := 0
const ATLAS_TEXTURE_PATH := "res://assets/tileset/GuttyKreum_ForestGraveyard/Tilemaps/Fulltilemap.png"

static func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	
	# Physics layer 0: wall collision (blocks movement).
	ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load(ATLAS_TEXTURE_PATH) as Texture2D
	source.texture_region_size = Vector2i(16, 16)
	ts.add_source(source, SOURCE_ID)

	source.create_tile(WALL)
	source.create_tile(FLOOR)
	source.create_tile(SPIKE)

	# Give the wall tile a full-tile collision polygon.
	var wall_data := source.get_tile_data(WALL, 0)
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 8), Vector2(-8, 8),
	]))

	return ts
