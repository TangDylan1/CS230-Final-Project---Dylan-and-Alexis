extends Control

@export var bar_size := Vector2(16, 120)
@export var bar_color := Color("#30cbff")
@export var bar_bg_color := Color(0, 0, 0, 0.55)

var _player: Node = null
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_bar_bg = ColorRect.new()
	_bar_bg.color = bar_bg_color
	_bar_bg.custom_minimum_size = bar_size
	add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = bar_color
	_bar_fill.size = bar_size
	_bar_fill.position = Vector2.ZERO
	_bar_bg.add_child(_bar_fill)

	_label = Label.new()
	_label.text = "Ability\nCooldown"
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.position = Vector2(0, bar_size.y + 6)
	add_child(_label)

	custom_minimum_size = Vector2(maxf(bar_size.x, 90), bar_size.y + 40)


func set_player(player: Node) -> void:
	_player = player


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		visible = false
		return
	if not ("swap_timer" in _player) or not ("swap_cooldown" in _player):
		visible = false
		return

	var remaining: float = float(_player.swap_timer)
	var total: float = maxf(0.001, float(_player.swap_cooldown))

	if remaining <= 0.0:
		visible = false
		return

	visible = true
	var t := clampf(remaining / total, 0.0, 1.0)
	var h := bar_size.y * t
	_bar_fill.size = Vector2(bar_size.x, h)
	_bar_fill.position = Vector2(0, bar_size.y - h)

