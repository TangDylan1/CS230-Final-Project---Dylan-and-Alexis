extends State
class_name DashState

@export var dash_duration: float = 0.18
const DASH_DOOR_LAYER := 6

var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed: float = 0.0
var _saved_collision_layer: int = 0
var _saved_collision_mask: int = 0
var _collision_override_active := false

func enter() -> void:
	print("Entering player DashState")

	var character := fsm.get_parent() as Player

	if character == null:
		return

	dash_speed = character.DASH_SPEED
	character.dash_cooldown = 1.0

	# Save the dash direction
	dash_direction = character.get_input_direction().normalized()

	# If no input direction, just dash in the current mouse direction
	if dash_direction == Vector2.ZERO:
		dash_direction = (character.get_global_mouse_position() - character.global_position).normalized()
		dash_speed *= 0.7 # I think that without movement, friction isnt strong enough, so reduce dash speed to match dash with movement
	dash_timer = dash_duration
	character.dash_velocity = dash_direction * dash_speed
	_saved_collision_layer = character.collision_layer
	_saved_collision_mask = character.collision_mask
	_collision_override_active = true

	character.set_collision_mask_value(character.ENEMY_LAYER, false) # dash through enemies
	character.collision_layer = 0
	character.set_collision_layer_value(DASH_DOOR_LAYER, true)




func exit() -> void:
	print("Exiting player DashState")
	var character := fsm.get_parent() as Player

	if character == null:
		return

	character.dash_velocity = Vector2.ZERO
	if _collision_override_active:
		character.collision_layer = _saved_collision_layer
		character.collision_mask = _saved_collision_mask
		_collision_override_active = false


func physics_update(delta: float) -> void:
	var character := fsm.get_parent() as Player

	if character == null:
		return

	dash_timer -= delta

	# Keep moving in the locked dash direction
	character.dash_velocity = dash_direction * dash_speed

	if dash_timer <= 0.0:
		if character.get_input_direction() == Vector2.ZERO:
			fsm.change_state("idlestate")
		else:
			fsm.change_state("walkstate")
