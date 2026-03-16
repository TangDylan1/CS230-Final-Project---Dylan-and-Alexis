extends Area2D

const RADIUS := 5.0
const MAGNET_RADIUS := 96.0
const MAGNET_SPEED := 520.0

@onready var _player: Node2D = null


func _ready() -> void:
	add_to_group("coins")

	monitoring = false
	monitorable = true
	# Small delay before collectible to let scatter animation play
	set_deferred("monitoring", true)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS + 2.0
	shape.shape = circle
	add_child(shape)

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
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2.ZERO, RADIUS - 1.5, Color(1.0, 0.95, 0.5))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.has_method("add_coins"):
			gm.add_coins(1)
		queue_free()
