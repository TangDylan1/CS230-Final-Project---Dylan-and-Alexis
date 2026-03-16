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
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "CREDITS"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	vbox.add_child(spacer)

	var made_label := Label.new()
	made_label.text = "Made with love"
	made_label.add_theme_font_size_override("font_size", 18)
	made_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(made_label)

	var by_label := Label.new()
	by_label.text = "by Alexis Manalastas and Dylan Tang"
	by_label.add_theme_font_size_override("font_size", 16)
	by_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(by_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 40
	vbox.add_child(spacer2)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(160, 36)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
