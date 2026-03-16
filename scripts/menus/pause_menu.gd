extends CanvasLayer

var _root: Control
var _menu_container: CenterContainer
var _settings_wrapper: Control
var _is_open := false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	_menu_container = CenterContainer.new()
	_menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_menu_container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu_container.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	_add_button(vbox, "Resume", _on_resume)
	_add_button(vbox, "Settings", _on_settings)
	_add_button(vbox, "Main Menu", _on_main_menu)
	_add_button(vbox, "Exit Game", _on_exit)


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 32)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _settings_wrapper and _settings_wrapper.visible:
			_hide_settings()
		else:
			toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_is_open = not _is_open
	_root.visible = _is_open
	get_tree().paused = _is_open
	if not _is_open and _settings_wrapper:
		_settings_wrapper.visible = false
		_menu_container.visible = true


func _on_resume() -> void:
	toggle()


func _on_settings() -> void:
	_menu_container.visible = false
	if not _settings_wrapper:
		_settings_wrapper = Control.new()
		_settings_wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var settings_bg := ColorRect.new()
		settings_bg.color = Color(0.06, 0.06, 0.12, 0.95)
		settings_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		settings_bg.mouse_filter = Control.MOUSE_FILTER_STOP
		_settings_wrapper.add_child(settings_bg)

		var panel_scene: PackedScene = preload("res://scenes/menus/settings_panel.tscn")
		var panel: Control = panel_scene.instantiate() as Control
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.back_pressed.connect(_hide_settings)
		_settings_wrapper.add_child(panel)

		_root.add_child(_settings_wrapper)
	else:
		_settings_wrapper.visible = true


func _hide_settings() -> void:
	if _settings_wrapper:
		_settings_wrapper.visible = false
	_menu_container.visible = true


func _on_main_menu() -> void:
	get_tree().paused = false
	GameManager.go_to_main_menu()


func _on_exit() -> void:
	get_tree().quit()
