extends Area2D

var direction := Vector2.ZERO
var speed := 200.0
var _lifetime := 3.0


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(_lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body is CharacterBody2D:
			var kb := direction.normalized() * 150.0
			(body as CharacterBody2D).velocity += kb
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()
