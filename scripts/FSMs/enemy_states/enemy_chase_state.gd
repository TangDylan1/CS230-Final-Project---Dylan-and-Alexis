extends State
class_name EnemyChaseState

func enter() -> void:
	var enemy := fsm.get_parent() as EnemyBase
	var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if enemy.enemy_type != EnemyBase.EnemyType.FLYING and enemy.enemy_type != EnemyBase.EnemyType.RANGED:
		if enemy.enemy_weakness == "katana":
				sprite.play("chase_r")
		else:
				sprite.play("chase_b")
		sprite.play("chase")
		
	if enemy.enemy_type == EnemyBase.EnemyType.FLYING:
		enemy.set_collision_mask_value(EnemyBase.FURNITURE_LAYER, false)
	pass

func physics_update(delta: float) -> void:
	var enemy := fsm.get_parent() as EnemyBase
	var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if enemy == null or enemy.frozen:
		return

	var dist := enemy.distance_to_player()
	var player := enemy.get_player() as Player
	var player_is_dashing := player != null and player.dash_velocity != Vector2.ZERO
	var is_contact_damage_enemy := enemy.enemy_type == EnemyBase.EnemyType.SOLDIER \
		or enemy.enemy_type == EnemyBase.EnemyType.FLYING
	if is_contact_damage_enemy:
		enemy.attack_timer += delta
		if enemy.contact_hit_idle_timer > 0.0:
			enemy.contact_hit_idle_timer = maxf(enemy.contact_hit_idle_timer - delta, 0.0)
			enemy.velocity = Vector2.ZERO
			return

	# if dist > enemy.aggro_range * 1.3:
	# 	fsm.change_state("enemyidlestate")
	# 	return

	if not is_contact_damage_enemy and dist <= enemy.attack_range and not player_is_dashing:
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

	if is_contact_damage_enemy:
		_apply_contact_damage(enemy)


func _apply_contact_damage(enemy: EnemyBase) -> void:
	if enemy.attack_timer < enemy.attack_cooldown:
		return

	for i in range(enemy.get_slide_collision_count()):
		var collision := enemy.get_slide_collision(i)
		if collision == null:
			continue
			
		var collider := collision.get_collider() as Node2D
		if collider == null or not collider.is_in_group("player"):
			continue

		if collider.has_method("apply_damage"):
			collider.apply_damage(enemy.attack_damage)

		if collider is CharacterBody2D:
			var kb_dir := (collider.global_position - enemy.global_position).normalized()
			var kb_force := 300.0
			var kb := kb_dir * kb_force
			if collider.has_method("apply_knockback"):
				collider.apply_knockback(kb, 0.22)
			else:
				(collider as CharacterBody2D).velocity += kb

		enemy.attack_timer = 0.0
		enemy.contact_hit_idle_timer = enemy.contact_hit_idle_cooldown
		return
