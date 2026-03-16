extends State
class_name EnemyIdleState

func enter() -> void:
	pass

func physics_update(_delta: float) -> void:
	var enemy := fsm.get_parent() as EnemyBase
	if enemy == null or enemy.frozen:
		return

	if enemy.distance_to_player() <= enemy.aggro_range:
		if enemy.enemy_type == EnemyBase.EnemyType.RANGED:
			fsm.change_state("enemyattackstate")
		else:
			fsm.change_state("enemychasestate")
