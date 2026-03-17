extends StaticBody2D

## Boss: big red circle placeholder. Spawns only in boss room.
## Shoots waves of kunai in semicircle (bottom half), one shot every 0.2s.
## StaticBody2D so player projectiles (RigidBody2D) get body_entered when hitting.

signal died
signal health_changed(current: int, maximum: int)

const PROJECTILE_SPEED := 200.0
const PROJECTILE_DAMAGE := 1
const WAVE_COOLDOWN := 1.5
const SHOT_INTERVAL := 0.2
const INTRO_DELAY := 2.0  # Don't shoot for first 2 seconds
const BOSS_RADIUS := 50.0 

var max_health := 30
var current_health: int
var _wave_timer: float = 0.0
var _intro_timer: float = 0.0
var _pattern_index: int = 0
var _pending_dirs: Array[Vector2] = []
var _shot_timer: float = 0.0

# Arc covers bottom and top corners: -PI/4 (top-right) to 5*PI/4 (top-left)
const ANGLE_MIN := -PI / 4.0
const ANGLE_MAX := 5.0 * PI / 4.0
const SLOT_COUNT := 9


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _process(delta: float) -> void:
	if current_health <= 0:
		return

	# Intro: don't shoot for first 2 seconds
	if _intro_timer < INTRO_DELAY:
		_intro_timer += delta
		return

	# Fire pending wave one shot at a time
	if _pending_dirs.size() > 0:
		_shot_timer += delta
		if _shot_timer >= SHOT_INTERVAL:
			_shot_timer = 0.0
			var dir: Vector2 = _pending_dirs.pop_front()
			_spawn_kunai(Vector2.ZERO, dir)
		return

	_wave_timer += delta
	if _wave_timer >= WAVE_COOLDOWN:
		_wave_timer = 0.0
		_start_pattern()



func apply_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()


func _start_pattern() -> void:
	var dirs: Array[Vector2] = []
	match _pattern_index:
		0:
			# Left to right along full arc (top-right to top-left)
			var n := randi_range(7, 10)
			for i in n:
				var t := (i / float(n - 1)) if n > 1 else 0.5
				var angle := lerpf(ANGLE_MIN, ANGLE_MAX, t)
				dirs.append(Vector2(cos(angle), sin(angle)))
		1:
			# Right to left along full arc
			var n := randi_range(7, 10)
			for i in n:
				var t := (i / float(n - 1)) if n > 1 else 0.5
				var angle := lerpf(ANGLE_MAX, ANGLE_MIN, t)
				dirs.append(Vector2(cos(angle), sin(angle)))
		2:
			# Odd slots across full arc + 2 extra
			for i in [0, 2, 4, 6, 8]:
				var t: float = (i / float(SLOT_COUNT - 1))
				var angle: float = lerpf(ANGLE_MIN, ANGLE_MAX, t)
				dirs.append(Vector2(cos(angle), sin(angle)))
			dirs.append(Vector2(cos(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.25), sin(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.25)))
			dirs.append(Vector2(cos(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.75), sin(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.75)))
		3:
			# Even slots across full arc + 2 extra
			for i in [1, 3, 5, 7]:
				var t: float = (i / float(SLOT_COUNT - 1))
				var angle: float = lerpf(ANGLE_MIN, ANGLE_MAX, t)
				dirs.append(Vector2(cos(angle), sin(angle)))
			dirs.append(Vector2(cos(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.2), sin(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.2)))
			dirs.append(Vector2(cos(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.8), sin(ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * 0.8)))
	_pending_dirs.clear()
	for d in dirs:
		_pending_dirs.append(d)
	_pattern_index = (_pattern_index + 1) % 4


func _spawn_kunai(offset: Vector2, dir: Vector2) -> void:
	var proj := _create_projectile(dir)
	if proj:
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + offset + dir * (BOSS_RADIUS + 8.0)


func _create_projectile(dir: Vector2) -> Area2D:
	dir = dir.normalized()
	var proj := Area2D.new()
	proj.set_meta("is_enemy_projectile", true)
	proj.add_to_group("enemy_projectiles")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	proj.add_child(shape)

	var visual := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/player/weapons/kunai.png")
	sprite.scale *= 2.0
	sprite.rotation = dir.angle()
	visual.add_child(sprite)
	proj.add_child(visual)

	var script_res := load("res://scripts/enemies/enemy_projectile.gd")
	proj.set_script(script_res)
	proj.set("direction", dir)
	proj.set("speed", PROJECTILE_SPEED)
	proj.set("damage", PROJECTILE_DAMAGE)

	return proj
