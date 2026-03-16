class_name Player
extends CharacterBody2D

const MAX_SPEED := 300.0
const DASH_SPEED := 700.0
var tween: Tween
var dash_velocity := Vector2.ZERO
var direction := Vector2.ZERO
var dash_cooldown := 0.0

@export var FRICTION := 0.1
@export var ACCELERATION := 50.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Set to true during room transitions to prevent movement.
var frozen := false

func _process(_delta: float) -> void:
	var mouse_direction := (get_global_mouse_position() - global_position).normalized()

	if mouse_direction.x > 0:
		sprite.flip_h = false
	elif mouse_direction.x < 0:
		sprite.flip_h = true

	if dash_cooldown > 0.0:
		dash_cooldown -= _delta


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
