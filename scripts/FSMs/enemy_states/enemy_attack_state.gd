extends State
class_name EnemyAttackState

var _cooldown_timer: float = 0.0
var _windup_timer: float = 0.0
var _has_attacked: bool = false

const ENEMY_PROJECTILE_SPEED := 200.0

func enter() -> void:
	_cooldown_timer = 0.0
	_windup_timer = 0.0
	_has_attacked = false

func physics_update(delta: float) -> void:
	var enemy := fsm.get_parent() as EnemyBase
	if enemy == null or enemy.frozen:
		return

	_cooldown_timer += delta
	var dist := enemy.distance_to_player()

	# If player no longer exists, go back to idle.
	if dist == INF:
		fsm.change_state("enemyidlestate")
		return

	match enemy.enemy_type:
		EnemyBase.EnemyType.SOLDIER:
			_melee_attack(enemy, delta, dist)
		EnemyBase.EnemyType.RANGED:
			_ranged_attack(enemy, delta, dist)
		EnemyBase.EnemyType.FLYING:
			_melee_attack(enemy, delta, dist)
		EnemyBase.EnemyType.TANK:
			_tank_attack(enemy, delta, dist)


func _melee_attack(enemy: EnemyBase, _delta: float, dist: float) -> void:
	if _is_player_dashing(enemy):
		fsm.change_state("enemychasestate")
		return

	enemy.velocity = Vector2.ZERO

	if not _has_attacked and _cooldown_timer >= 0.2:
		_do_melee_hit(enemy)
		_has_attacked = true

	if _cooldown_timer >= enemy.attack_cooldown:
		if dist <= enemy.attack_range * 1.5:
			_cooldown_timer = 0.0
			_has_attacked = false
		elif dist > enemy.aggro_range:
			fsm.change_state("enemyidlestate")
		else:
			fsm.change_state("enemychasestate")


func _ranged_attack(enemy: EnemyBase, _delta: float, _dist: float) -> void:
	var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var dir := enemy.direction_to_player()

	if sprite:
		if dir.x > 0:
			sprite.flip_h = false
		elif dir.x < 0:
			sprite.flip_h = true

	# Ranged enemies now have infinite detection; just stand and shoot.
	if _cooldown_timer >= enemy.attack_cooldown:
		_fire_projectile(enemy)
		_cooldown_timer = 0.0


func _tank_attack(enemy: EnemyBase, _delta: float, dist: float) -> void:
	if _is_player_dashing(enemy):
		fsm.change_state("enemychasestate")
		return

	enemy.velocity = Vector2.ZERO

	# Windup phase
	if not _has_attacked:
		_windup_timer += _delta
		# Visual telegraph: slight scale pulse
		enemy.scale = Vector2.ONE * lerpf(1.0, 1.15, clampf(_windup_timer / 0.5, 0.0, 1.0))
		if _windup_timer >= 0.5:
			_do_melee_hit(enemy)
			_has_attacked = true
			enemy.scale = Vector2.ONE
		return

	if _cooldown_timer >= enemy.attack_cooldown:
		if dist <= enemy.attack_range * 1.5:
			_cooldown_timer = 0.0
			_has_attacked = false
			_windup_timer = 0.0
		elif dist > enemy.aggro_range:
			fsm.change_state("enemyidlestate")
		else:
			fsm.change_state("enemychasestate")


func _do_melee_hit(enemy: EnemyBase) -> void:
	var player := enemy.get_player()
	if player and enemy.global_position.distance_to(player.global_position) <= enemy.attack_range * 2.0:
		# Knockback player
		if player is CharacterBody2D:
			var kb_dir := (player.global_position - enemy.global_position).normalized()
			(player as CharacterBody2D).velocity += kb_dir * 200.0


func _fire_projectile(enemy: EnemyBase) -> void:
	var dir := enemy.direction_to_player()
	if dir == Vector2.ZERO:
		return
	var proj := _create_projectile(enemy)
	if proj:
		enemy.get_tree().current_scene.add_child(proj)
		proj.global_position = enemy.global_position + dir * 16.0


func _create_projectile(enemy: EnemyBase) -> Node2D:
	var proj := Area2D.new()
	proj.set_meta("is_enemy_projectile", true)
	proj.add_to_group("enemy_projectiles")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	proj.add_child(shape)

	# Visual
	var visual := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/player/weapons/kunai.png")
	sprite.scale *= 2.0
	visual.add_child(sprite)
	proj.add_child(visual)
	

	var dir := enemy.direction_to_player()
	var script := load("res://scripts/enemies/enemy_projectile.gd")
	proj.set_script(script)
	proj.set("direction", dir)
	proj.set("speed", ENEMY_PROJECTILE_SPEED)
	sprite.rotation = dir.angle()

	return proj


func _is_player_dashing(enemy: EnemyBase) -> bool:
	var player := enemy.get_player() as Player
	return player != null and player.dash_velocity.length_squared() > 0.0
