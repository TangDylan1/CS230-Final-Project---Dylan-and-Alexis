extends State
class_name IdleState

func enter() -> void:
	print("Entering player IdleState")
	var character := fsm.get_parent() as Player
	if character:
		character.direction = Vector2.ZERO


func physics_update(_delta: float) -> void:
	var character := fsm.get_parent() as Player 
	if character == null:
		return

	if character.get_input_direction() != Vector2.ZERO:
		fsm.change_state("walkstate")