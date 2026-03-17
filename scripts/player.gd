class_name Player
extends CharacterBody2D

signal died
signal health_changed(old_half_hearts: int, new_half_hearts: int)

const BASE_MAX_SPEED := 300.0
const DASH_SPEED := 700.0

# Used by FSM (e.g. walk_state); matches movement in _physics_process.
var MAX_SPEED: float:
	get:
		return BASE_MAX_SPEED * GameManager.get_speed_multiplier()
const STAR_PROJECTILE_SCENE := preload("res://scenes/star.tscn")
const PLAYER_LAYER := 2
const WORLD_LAYER := 1
const ENEMY_LAYER := 3
const FURNITURE_LAYER := 4

var frozen := false
var dash_velocity := Vector2.ZERO
var direction := Vector2.ZERO
var dash_cooldown := 0.0
var active_attack := String("katana")
var star_timer := 0.0
var star_spawn := false
# Health in half-hearts (4 hearts = 8 half-hearts). Game starts with 4 full hearts.
var max_health: int = 8
var current_health: int = 8
var _dead := false
var _damage_cooldown: float = 0.0  # 1s iframe after taking damage
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0
var swap_timer := 0.0
var swap_cooldown := 5.0

@export var FRICTION := 0.1
@export var ACCELERATION := 50.0
@export var KNOCKBACK_DECAY := 1000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var katana: Node2D = $Katana
@onready var sword_animation: AnimationPlayer = $Katana/KatNode2D/SwordAnimation
@onready var slash_animation: AnimatedSprite2D = $Katana/SlashEffect
@onready var throwing_star: Node2D = $ThrowingStar
@onready var throwing_star_animation: AnimationPlayer = $ThrowingStar/StarNode2D/StarAnimation
@onready var katana_sprite: Sprite2D = $Katana/KatNode2D/Sprite2D
@onready var throwing_star_sprite: Sprite2D = $ThrowingStar/StarNode2D/Sprite2D


func _ready() -> void:
	add_to_group("player")
	set_collision_layer_value(PLAYER_LAYER, true)
	set_collision_mask_value(WORLD_LAYER, true)
	set_collision_mask_value(ENEMY_LAYER, true)
	# 4 hearts = 8 half-hearts (shop health upgrade could add more later)
	max_health = GameManager.get_max_hearts() * 2
	current_health = max_health
	set_collision_mask_value(FURNITURE_LAYER, true)
	katana.visible = false
	throwing_star.visible = false


func update_active_attack_sprites():
	if active_attack == "katana":
		katana.visible = true
		throwing_star.visible = false
	elif active_attack == "throwing_star":
		katana.visible = false
		throwing_star.visible = true


func throw_star(mouse_direction: Vector2) -> void:
	var star = STAR_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(star)
	star.global_position = global_position + mouse_direction.normalized() * 24.0
	star.launch(mouse_direction)


func _process(_delta: float) -> void:

	# Attack swapping
	swap_timer -= _delta
	if swap_timer < 0.0:
		swap_timer = 0.0

	update_active_attack_sprites()
	
	if (Input.is_action_just_pressed("ui_swap")):
		print(swap_timer)
		if swap_timer > 0.0:
			return

		swap_timer = swap_cooldown
		if active_attack == "katana":
			active_attack = "throwing_star"
			swap_shader_flash(Color("#30cbff"), 0.7, sprite)
			swap_shader_flash(Color("#30cbff"), 0.7, throwing_star_sprite)
		else:
			active_attack = "katana"
			swap_shader_flash(Color("#ff5260"), 0.7, sprite)
			swap_shader_flash(Color("#ff5260"), 0.7, katana_sprite)

	# Flip player based on mouse dir
	var mouse_direction := (get_global_mouse_position() - global_position).normalized()
	if mouse_direction.x > 0:
		sprite.flip_h = false
	elif mouse_direction.x < 0:
		sprite.flip_h = true

	if dash_cooldown > 0.0:
		dash_cooldown -= _delta
	if _damage_cooldown > 0.0:
		_damage_cooldown -= _delta


	if active_attack == "katana":
		# Rotate and flip katana based on mouse dir
		if not sword_animation.is_playing(): # Dont let the player swing in a circle lol
			katana.rotation = mouse_direction.angle()
			if katana.scale.y == 1  and mouse_direction.x < 0:
				katana.scale.y = -1
			elif katana.scale.y == -1 and mouse_direction.x > 0:
				katana.scale.y = 1

		if Input.is_action_just_pressed("ui_attack") and not sword_animation.is_playing():
			sword_animation.play("attack")
			slash_animation.visible = true
			slash_animation.play("default")
			_katana_hit(mouse_direction)
		
		# Hide katana slash after animation finishes
		if slash_animation.visible and not slash_animation.is_playing():
			slash_animation.visible = false
	
	elif active_attack == "throwing_star":
		# Rotate and flip throwing star based on mouse dir
		if not throwing_star_animation.is_playing(): # Dont let the player swing in a circle lol
			throwing_star.rotation = mouse_direction.angle()
			if throwing_star.scale.y == 1  and mouse_direction.x < 0:
				throwing_star.scale.y = -1
			elif throwing_star.scale.y == -1 and mouse_direction.x > 0:
				throwing_star.scale.y = 1

		if Input.is_action_just_pressed("ui_attack") and not throwing_star_animation.is_playing():
			star_spawn = true
			star_timer = 0.15
			throwing_star_animation.play("attack")

		if star_spawn:
			star_timer -= _delta
			if star_timer <= 0.0:
				throw_star(mouse_direction)
				star_spawn = false
		
func _physics_process(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return

	if knockback_timer > 0.0:
		knockback_timer -= _delta
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * _delta)
		return

	var input_dir := get_input_direction()
	var move_speed := BASE_MAX_SPEED * GameManager.get_speed_multiplier()
	var target_velocity := input_dir * move_speed
	velocity = velocity.lerp(target_velocity, ACCELERATION * _delta)

	# If player is dashing, override velocity
	if dash_velocity != Vector2.ZERO:
		velocity = dash_velocity

	move_and_slide()

	# Apply friction when not dashing for that slippery movement
	if dash_velocity == Vector2.ZERO:
		velocity = lerp(velocity, Vector2.ZERO, FRICTION)


# Return normalized player input direction
func get_input_direction() -> Vector2:
	var input_direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input_direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input_direction.y += 1

	return input_direction.normalized()

func play_sprite_animation(anim: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


func apply_damage(amount: int) -> void:
	if _dead:
		return
	if _damage_cooldown > 0.0:
		return
	var old_half := current_health
	current_health = clampi(current_health - amount, 0, max_health)
	_damage_cooldown = 0.5  # 0.5s invulnerability when hit
	_flash_damage()
	health_changed.emit(old_half, current_health)
	if current_health <= 0:
		_dead = true
		died.emit()


func heal(amount: int) -> void:
	if _dead:
		return
	var old_half := current_health
	current_health = mini(current_health + amount, max_health)
	if current_health != old_half:
		health_changed.emit(old_half, current_health)


func _katana_hit(attack_dir: Vector2) -> void:
	var hit_range := 80.0
	var hit_angle := PI / 2.5
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > hit_range:
			continue
		if to_enemy.normalized().dot(attack_dir.normalized()) < cos(hit_angle):
			continue
		if enemy.has_method("apply_damage"):
			enemy.apply_damage(GameManager.get_katana_damage())


func _flash_damage() -> void:
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

# Force is knockback force, duration is how long the knockback lasts (used by enemy melee)
func apply_knockback(force: Vector2, duration: float = 0.18) -> void:
	if force == Vector2.ZERO:
		return
	knockback_velocity = force
	knockback_timer = maxf(knockback_timer, duration)


func swap_shader_flash(color: Color, duration: float, flash_sprite: CanvasItem) -> void:
	var shader_material := flash_sprite.material as ShaderMaterial
	
	if shader_material:
		shader_material.set_shader_parameter("outline_color", color)
		var tween := create_tween()
		tween.tween_property(shader_material, "shader_parameter/outline_color", Color(0, 0, 0, 0), duration)
