extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel_scene: PackedScene = preload("res://scenes/menus/settings_panel.tscn")
	var panel: Control = panel_scene.instantiate() as Control
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.back_pressed.connect(_on_back)
	add_child(panel)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
