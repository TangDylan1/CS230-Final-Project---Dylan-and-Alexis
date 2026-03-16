extends State
class_name IdleState

func enter() -> void:
	print("Entering player IdleState")
	var character := fsm.get_parent() as Player
	if character == null:
		return
	
	character.direction = Vector2.ZERO
	character.play_sprite_animation("idle")


func physics_update(_delta: float) -> void:
	var character := fsm.get_parent() as Player 
	if character == null:
		return

	if character.get_input_direction() != Vector2.ZERO:
		fsm.change_state("walkstate")

	if Input.is_action_just_pressed("dash") and character.dash_cooldown <= 0.0:
		fsm.change_state("dashstate")