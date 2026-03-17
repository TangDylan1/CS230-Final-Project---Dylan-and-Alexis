extends State
class_name IdleState

func enter() -> void:
	print("Entering player IdleState")
	var character := fsm.get_parent() as Player
	if character == null:
		return
	
	character.direction = Vector2.ZERO
	if character.active_attack == "katana" and (character.sprite == null or character.sprite.animation != "idle_r"):
		character.play_sprite_animation("idle_r")
	elif character.active_attack == "throwing_star" and (character.sprite == null or character.sprite.animation != "idle_b"):
		character.play_sprite_animation("idle_b")

func update(_delta: float) -> void:
	var character := fsm.get_parent() as Player
	if character == null:
		return
	update_idle_animation()


func physics_update(_delta: float) -> void:
	var character := fsm.get_parent() as Player 
	if character == null:
		return

	if character.get_input_direction() != Vector2.ZERO:
		fsm.change_state("walkstate")

	if Input.is_action_just_pressed("ui_dash") and character.dash_cooldown <= 0.0:
		fsm.change_state("dashstate")

func update_idle_animation() -> void:
	var character := fsm.get_parent() as Player
	if character == null:
		return

	if character.active_attack == "katana":
		if character.sprite != null and character.sprite.animation != "idle_r":
			character.play_sprite_animation("idle_r")
	elif character.active_attack == "throwing_star":
		if character.sprite != null and character.sprite.animation != "idle_b":
			character.play_sprite_animation("idle_b")
