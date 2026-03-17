extends State
class_name EnemyIdleState


func enter() -> void:
	pass

func physics_update(_delta: float) -> void:
	var enemy := fsm.get_parent() as EnemyBase
	if enemy == null or enemy.frozen:
		return

	var dist := enemy.distance_to_player()

	# Ranged enemies: infinite detection as long as player exists.
	if enemy.enemy_type == EnemyBase.EnemyType.RANGED and dist < INF:
		fsm.change_state("enemyattackstate")
		return

	# Other enemies: use aggro_range (buffed globally in EnemyBase).
	if dist <= enemy.aggro_range or enemy.been_attacked:
		fsm.change_state("enemychasestate")
