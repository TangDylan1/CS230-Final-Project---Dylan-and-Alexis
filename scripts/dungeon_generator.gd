class_name DungeonGenerator
extends RefCounted
## Procedural dungeon layout generator for Spiritbreakers.
##
## ALGORITHM OVERVIEW — DRUNKARD'S WALK:
## Imagine a grid of empty cells. A "drunk" walker starts in the center and
## takes random steps — up, down, left, or right — one cell at a time. Every
## new cell the walker steps on gets carved into a room. The walker keeps
## stumbling until we have enough rooms. Because the direction is random each
## step, every run produces a different layout.
##
## On top of the basic walk, we layer several techniques inspired by Binding of
## Isaac's dungeon generator (boristhebrave.com/2020/09/12/dungeon-generation-
## in-binding-of-isaac):
##
##   1. ANTI-LOOP CONSTRAINT — Before carving a new room, we check how many
##      existing rooms are adjacent to it. If there are 2 or more, we skip it.
##      This prevents the layout from looping back on itself, keeping it
##      tree-shaped with distinct corridors (just like Isaac).
##
##   2. DEAD-END TRACKING — After the walk, any room with exactly 1 neighbor
##      is a "dead end." These are corridor tips the player has to seek out,
##      making them natural spots for special rooms.
##
##   3. BOSS PLACEMENT (BFS) — We run a Breadth-First Search from the start
##      room, counting hops to every dead end. The one with the most hops
##      becomes the boss room, so the player must explore to reach it.
##
##   4. SPECIAL ROOMS — Shop and treasure rooms are placed at random dead ends.
##      The secret room is placed in an empty cell adjacent to 3+ rooms (near
##      an intersection), away from dead ends, so it feels hidden.
##
##   5. VALIDATION + RETRY — If a walk produces too few rooms, too few dead
##      ends, or puts the boss next to the start, we throw it away and re-walk
##      (up to 20 attempts).


# Each room on the grid has a type that determines its purpose.
enum RoomType { NORMAL, START, BOSS, SHOP, TREASURE, SECRET }

# The four cardinal directions the walker can move.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.DOWN,
]

# The generated room layout. Keys are grid positions (Vector2i), values are
# RoomType enums. This is the main output of generate().
var rooms: Dictionary = {}

# The grid cell where the player spawns.
var start_room: Vector2i

# Random number generator — kept as an instance variable so every method
# uses the same RNG stream for consistency.
var _rng := RandomNumberGenerator.new()

# The grid dimensions, stored so helper functions can do bounds checks.
var _grid_size: Vector2i


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Main entry point. Call this to produce a new dungeon layout.
## Returns a Dictionary of { Vector2i -> RoomType }.
##
## Parameters:
##   grid_size    — width and height of the grid in cells (e.g. 8×8)
##   target_rooms — how many rooms the walk should try to carve
##   max_steps    — safety cap to prevent infinite loops if the walker gets stuck
func generate(grid_size: Vector2i, target_rooms: int, max_steps: int = 300) -> Dictionary:
	_grid_size = grid_size
	_rng.randomize()

	# Step 1: Run the drunkard's walk. If the result doesn't pass validation
	# (too few rooms, boss next to start, etc.), retry up to 20 times.
	for attempt in range(20):
		_walk(target_rooms, max_steps)
		if _validate(target_rooms):
			break

	# Step 2: Label dead-end rooms as boss, shop, treasure, and place the
	# secret room near an intersection.
	_assign_special_rooms()

	return rooms


## Returns all rooms adjacent to `pos` that exist in the layout.
## Used by the visualization and later by room scenes to decide which
## doors to open (e.g. if there's a neighbor to the right, open the right door).
func get_room_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var neighbor := pos + dir
		if rooms.has(neighbor):
			neighbors.append(neighbor)
	return neighbors


# ==============================================================================
# STEP 1: THE DRUNKARD'S WALK
# ==============================================================================

## The core algorithm, where a walker starts at the grid center and takes random
## steps in cardinal directions. Each new cell it visits becomes a room.
## The walk ends when we have enough rooms or hit the step limit.
func _walk(target_rooms: int, max_steps: int) -> void:
	rooms.clear()

	# Start the walker in the center of the grid.
	var center := _grid_size / 2
	var current := center
	rooms[center] = RoomType.START
	start_room = center

	var steps := 0
	while rooms.size() < target_rooms and steps < max_steps:
		steps += 1

		# Pick a random direction: up, down, left, or right.
		var dir := DIRECTIONS[_rng.randi_range(0, 3)]
		var next := current + dir

		# If the step would go outside the grid, skip it (walker stays put).
		if not _in_bounds(next):
			continue

		if rooms.has(next):
			# The next cell is already a room — the walker moves there without
			# carving anything. This lets it wander through existing rooms to
			# reach new areas of the grid.
			current = next
		elif _neighbor_count(next) <= 1:
			# The next cell is empty and has at most 1 existing room next to
			# it. Carve it as a new room and move there.
			#
			# WHY THE NEIGHBOR CHECK: if the cell already touches 2+ rooms,
			# carving it would create a loop (multiple paths between rooms).
			# Skipping it keeps the layout tree-shaped — distinct corridors
			# that branch but never reconnect. This is the key technique from
			# Binding of Isaac.
			rooms[next] = RoomType.NORMAL
			current = next
		# If neither condition is met (empty cell with 2+ neighbors), the
		# walker stays put. This avoids creating loops AND prevents the walker
		# from standing on an uncarved cell (which would cause disconnected
		# rooms on later steps).


# ==============================================================================
# STEP 2: SPECIAL ROOM PLACEMENT
# ==============================================================================

## After the walk, we label certain rooms as special. Dead ends (rooms with
## exactly 1 neighbor) are ideal because the player must go out of their way
## to reach them.
func _assign_special_rooms() -> void:
	var ends := _find_dead_ends()

	# BOSS — placed at the dead end furthest from start (by BFS hop count).
	# This guarantees the player must explore the most rooms to reach it.
	if ends.size() > 0:
		var boss := _furthest_dead_end(ends)
		rooms[boss] = RoomType.BOSS
		ends.erase(boss)

	# SHOP — placed at a random remaining dead end.
	if ends.size() > 0:
		var idx := _rng.randi_range(0, ends.size() - 1)
		rooms[ends[idx]] = RoomType.SHOP
		ends.remove_at(idx)

	# TREASURE — placed at another random remaining dead end.
	if ends.size() > 0:
		var idx := _rng.randi_range(0, ends.size() - 1)
		rooms[ends[idx]] = RoomType.TREASURE
		ends.remove_at(idx)

	# SECRET — placed in an empty cell near an intersection, not a dead end.
	_place_secret_room(ends)


## Finds an empty cell (not an existing room) that borders 3 or more rooms.
## These are naturally near intersections, so the secret room feels "hidden"
## between corridors. Falls back to 2-neighbor cells if no 3+ candidates exist.
func _place_secret_room(remaining_ends: Array[Vector2i]) -> void:
	var best: Array[Vector2i] = []    # candidates adjacent to 3+ rooms
	var okay: Array[Vector2i] = []    # fallback: adjacent to 2 rooms
	var checked: Dictionary = {}

	# Look at every empty cell that borders an existing room.
	for cell_key in rooms.keys():
		var cell: Vector2i = cell_key
		for dir in DIRECTIONS:
			var candidate: Vector2i = cell + dir

			# Skip if already a room, already checked, or out of bounds.
			if rooms.has(candidate) or checked.has(candidate) or not _in_bounds(candidate):
				continue
			checked[candidate] = true

			# Isaac rule: secret rooms should NOT be next to dead ends.
			# Dead ends are where the player naturally explores, so putting
			# the secret room there would make it too easy to find.
			var touches_end := false
			for end_cell in remaining_ends:
				if _are_adjacent(candidate, end_cell):
					touches_end = true
					break
			if touches_end:
				continue

			# Count how many existing rooms border this empty cell.
			var adj := _neighbor_count(candidate)
			if adj >= 3:
				best.append(candidate)
			elif adj >= 2:
				okay.append(candidate)

	# Pick a random candidate from the best available pool.
	var pool := best if best.size() > 0 else okay
	if pool.size() > 0:
		rooms[pool[_rng.randi_range(0, pool.size() - 1)]] = RoomType.SECRET


# ==============================================================================
# STEP 3: VALIDATION
# ==============================================================================

## Checks whether the walk produced a usable layout. If not, generate() will
## re-run the walk.
func _validate(target_rooms: int) -> bool:
	# Must have carved at least 75% of the target room count.
	if rooms.size() < ceili(target_rooms * 0.75):
		return false

	# Must have at least 2 dead ends (need them for boss + other specials).
	var ends := _find_dead_ends()
	if ends.size() < 2:
		return false

	# The boss room (furthest dead end) must NOT be right next to start.
	# If it is, the dungeon would feel too short.
	var furthest := _furthest_dead_end(ends)
	if _are_adjacent(furthest, start_room):
		return false

	return true


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Returns all dead-end rooms — rooms with exactly 1 neighbor (excluding start).
## Dead ends are corridor tips where the player must deliberately backtrack.
func _find_dead_ends() -> Array[Vector2i]:
	var ends: Array[Vector2i] = []
	for cell in rooms.keys():
		if cell != start_room and _neighbor_count(cell) == 1:
			ends.append(cell)
	return ends


## BFS (Breadth-First Search) from start_room to find the dead end with the
## most hops. BFS explores rooms layer by layer — first all rooms 1 step away,
## then 2 steps, then 3, etc. — so when it reaches a dead end, the hop count
## is the shortest path distance from start.
func _furthest_dead_end(ends: Array[Vector2i]) -> Vector2i:
	var visited: Dictionary = {}       # cell -> hop count from start
	var queue: Array[Vector2i] = [start_room]
	visited[start_room] = 0
	var best: Vector2i = ends[0] if ends.size() > 0 else start_room
	var best_dist := -1

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		for dir in DIRECTIONS:
			var neighbor := current + dir
			if rooms.has(neighbor) and not visited.has(neighbor):
				# This neighbor is 1 hop further than the current cell.
				visited[neighbor] = visited[current] + 1
				queue.append(neighbor)
				# If this neighbor is a dead end and further than our best,
				# it becomes the new boss room candidate.
				if ends.has(neighbor) and visited[neighbor] > best_dist:
					best_dist = visited[neighbor]
					best = neighbor

	return best


## Counts how many existing rooms are directly adjacent to a given cell.
## Used by the anti-loop check during the walk and by secret room placement.
func _neighbor_count(pos: Vector2i) -> int:
	var count := 0
	for dir in DIRECTIONS:
		if rooms.has(pos + dir):
			count += 1
	return count


## Returns true if the cell is within the grid boundaries.
func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _grid_size.x and pos.y >= 0 and pos.y < _grid_size.y


## Returns true if two cells are exactly 1 step apart (directly neighboring).
func _are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := (a - b).abs()
	return (diff.x + diff.y) == 1
