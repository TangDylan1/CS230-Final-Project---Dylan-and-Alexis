extends Area2D
## Pickup that heals the player by 1 full heart (2 half-hearts) when collected.

const RADIUS := 10.0
const HEAL_AMOUNT := 2  # 2 half-hearts = 1 full heart


func _ready() -> void:
	add_to_group("heart_pickups")
	monitoring = true
	monitorable = false

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)


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
