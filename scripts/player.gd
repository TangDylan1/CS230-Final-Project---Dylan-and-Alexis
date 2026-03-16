class_name Player
extends CharacterBody2D

const MAX_SPEED := 300.0
const DASH_SPEED := 700.0
const STAR_PROJECTILE_SCENE := preload("res://scenes/star.tscn")

var frozen := false
var dash_velocity := Vector2.ZERO
var direction := Vector2.ZERO
var dash_cooldown := 0.0
var active_attack := String("katana")
var star_timer := 0.0
var star_spawn := false

@export var FRICTION := 0.1
@export var ACCELERATION := 50.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var katana: Node2D = $Katana
@onready var sword_animation: AnimationPlayer = $Katana/KatNode2D/SwordAnimation
@onready var slash_animation: AnimatedSprite2D = $Katana/SlashEffect
@onready var throwing_star: Node2D = $ThrowingStar
@onready var throwing_star_animation: AnimationPlayer = $ThrowingStar/StarNode2D/StarAnimation


func _ready() -> void:
	add_to_group("player")


func update_active_attack():
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
	update_active_attack()

	# Flip player based on mouse dir
	var mouse_direction := (get_global_mouse_position() - global_position).normalized()
	if mouse_direction.x > 0:
		sprite.flip_h = false
	elif mouse_direction.x < 0:
		sprite.flip_h = true

	if dash_cooldown > 0.0:
		dash_cooldown -= _delta

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
			enemy.apply_damage(2)
