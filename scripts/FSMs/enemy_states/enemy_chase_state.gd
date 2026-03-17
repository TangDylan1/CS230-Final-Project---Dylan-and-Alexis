extends State
class_name EnemyChaseState

func enter() -> void:
	pass

func physics_update(delta: float) -> void:
	var enemy := fsm.get_parent() as EnemyBase
	var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if enemy == null or enemy.frozen:
		return

	var dist := enemy.distance_to_player()
	var player := enemy.get_player() as Player
	var player_is_dashing := player != null and player.dash_velocity != Vector2.ZERO

	# if dist > enemy.aggro_range * 1.3:
	# 	fsm.change_state("enemyidlestate")
	# 	return

	if dist <= enemy.attack_range and not player_is_dashing:
		fsm.change_state("enemyattackstate")
		return

	var dir := enemy.direction_to_player()
	
	# Flip enemy based on player dir
	if sprite:
		if dir.x > 0:
			sprite.flip_h = false
		elif dir.x < 0:
			sprite.flip_h = true

	# Flying enemies get erratic wobble
	if enemy.enemy_type == EnemyBase.EnemyType.FLYING:
		enemy._wobble_time += delta * enemy.wobble_speed
		var perp := Vector2(-dir.y, dir.x)
		dir = (dir + perp * sin(enemy._wobble_time) * 0.6).normalized()

	enemy.velocity = dir * enemy.move_speed
	enemy.move_and_slide()
