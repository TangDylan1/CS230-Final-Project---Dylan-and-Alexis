extends Area2D
## Pickup that heals the player by 1 full heart (2 half-hearts) when collected.

const RADIUS := 10.0
const HEAL_AMOUNT := 2  # 2 half-hearts = 1 full heart
const MAGNET_RADIUS := 96.0
const MAGNET_SPEED := 520.0

@onready var _player: Node2D = null


func _ready() -> void:
	add_to_group("heart_pickups")
	monitoring = false
	set_deferred("monitorable", true)
	# Small delay before collectible so spawn tween can play.
	set_deferred("monitoring", true)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	call_deferred("add_child", shape)

	body_entered.connect(_on_body_entered)

	# Cache player reference if available
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node2D


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Node2D
		else:
			return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	if dist <= MAGNET_RADIUS and dist > 0.0:
		var dir := to_player / dist
		global_position += dir * MAGNET_SPEED * delta


func _draw() -> void:
	# Red heart shape: two circles + triangle
	draw_circle(Vector2(-4, 0), 5, Color(0.9, 0.2, 0.2))
	draw_circle(Vector2(4, 0), 5, Color(0.9, 0.2, 0.2))
	var pts := PackedVector2Array([Vector2(-9, 2), Vector2(0, 12), Vector2(9, 2)])
	draw_colored_polygon(pts, Color(0.9, 0.2, 0.2))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(HEAL_AMOUNT)
		queue_free()
