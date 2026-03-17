extends State
class_name WalkState

func enter() -> void:
	print("Entering player WalkState")
	var character := fsm.get_parent() as Player

	if character == null:
		return

	if character.get_input_direction() == Vector2.ZERO:
		fsm.change_state("idlestate")

	if character.active_attack == "katana" and (character.sprite == null or character.sprite.animation != "walk_r"):
		character.play_sprite_animation("walk_r")
	elif character.active_attack == "throwing_star" and (character.sprite == null or character.sprite.animation != "walk_b"):
		character.play_sprite_animation("walk_b")

func update(_delta: float) -> void:
	var character := fsm.get_parent() as Player
	if character == null:
		return
	update_walk_animation()


func physics_update(_delta: float):
	var character := fsm.get_parent() as Player
	if character == null:
		return

	# If the input dir is zero, switch to idle
	character.direction = character.get_input_direction()
	if character.direction == Vector2.ZERO:
		fsm.change_state("idlestate")
		return

	elif Input.is_action_just_pressed("ui_dash") and character.dash_cooldown <= 0.0:
		fsm.change_state("dashstate")


	character.velocity += character.direction * character.ACCELERATION # mmm slippery movement

	# max speed
	character.velocity = Vector2(
		clamp(character.velocity.x, -character.MAX_SPEED, character.MAX_SPEED),
		clamp(character.velocity.y, -character.MAX_SPEED, character.MAX_SPEED)
	)

func update_walk_animation() -> void:
	var character := fsm.get_parent() as Player
	if character == null:
		return

	if character.active_attack == "katana":
		if character.sprite != null and character.sprite.animation != "walk_r":
			character.play_sprite_animation("walk_r")
	elif character.active_attack == "throwing_star":
		if character.sprite != null and character.sprite.animation != "walk_b":
			character.play_sprite_animation("walk_b")