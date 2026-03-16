extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "SPIRITBREAKERS"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	vbox.add_child(spacer)

	_add_button(vbox, "Start Game", _on_start)
	_add_button(vbox, "Settings", _on_settings)
	_add_button(vbox, "Credits", _on_credits)
	_add_button(vbox, "Exit", _on_exit)


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 36)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(callback)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.22, 1.0)
	style.border_color = Color(0.35, 0.35, 0.55, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.18, 0.32, 1.0)
	hover.border_color = Color(0.5, 0.5, 0.75, 1.0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.08, 0.08, 0.16, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)

	parent.add_child(btn)


func _on_start() -> void:
	GameManager.start_game()


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings.tscn")


func _on_credits() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/credits.tscn")


func _on_exit() -> void:
	get_tree().quit()
