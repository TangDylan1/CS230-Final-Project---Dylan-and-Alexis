extends State
class_name WalkState

func enter() -> void:
	print("Entering player WalkState")
	var character := fsm.get_parent() as Player
	if character == null:
		return

	if character.get_input_direction() == Vector2.ZERO:
		fsm.change_state("idlestate")


func physics_update(_delta: float):
	var character := fsm.get_parent() as Player
	if character == null:
		return

	# If the input dir is zero, switch to idle
	character.direction = character.get_input_direction()
	if character.direction == Vector2.ZERO:
		fsm.change_state("idlestate")
		return

	character.velocity += character.direction * character.ACCELERATION # mmm slippery movement

	# max speed
	character.velocity = Vector2(
		clamp(character.velocity.x, -character.MAX_SPEED, character.MAX_SPEED),
		clamp(character.velocity.y, -character.MAX_SPEED, character.MAX_SPEED)
	)
