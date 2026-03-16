extends State
class_name EnemyDeadState

func enter() -> void:
	var enemy := fsm.get_parent() as EnemyBase
	if enemy == null:
		return
	enemy._die()
