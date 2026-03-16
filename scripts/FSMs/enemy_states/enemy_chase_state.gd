extends State
class_name EnemyChaseState

func enter() -> void:
	pass

func physics_update(delta: float) -> void:
	var enemy := fsm.get_parent() as EnemyBase
	if enemy == null or enemy.frozen:
		return

	var dist := enemy.distance_to_player()

	if dist > enemy.aggro_range * 1.3:
		fsm.change_state("enemyidlestate")
		return

	if dist <= enemy.attack_range:
		fsm.change_state("enemyattackstate")
		return

	var dir := enemy.direction_to_player()

	# Flying enemies get erratic wobble
	if enemy.enemy_type == EnemyBase.EnemyType.FLYING:
		enemy._wobble_time += delta * enemy.wobble_speed
		var perp := Vector2(-dir.y, dir.x)
		dir = (dir + perp * sin(enemy._wobble_time) * 0.6).normalized()

	enemy.velocity = dir * enemy.move_speed
	enemy.move_and_slide()
