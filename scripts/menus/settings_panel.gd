extends Control

signal back_pressed

var _listening_action: String = ""
var _listening_button: Button
var _keybind_buttons: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# -- Keybinds section --
	var keybinds_header := Label.new()
	keybinds_header.text = "Controls"
	keybinds_header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(keybinds_header)

	for action in SettingsManager.BINDABLE_ACTIONS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var label := Label.new()
		label.text = SettingsManager.BINDABLE_ACTIONS[action]
		label.custom_minimum_size.x = 130
		label.add_theme_font_size_override("font_size", 13)
		hbox.add_child(label)

		var btn := Button.new()
		btn.text = SettingsManager.get_action_key_name(action)
		btn.custom_minimum_size = Vector2(120, 26)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_rebind_pressed.bind(action, btn))
		hbox.add_child(btn)

		_keybind_buttons[action] = btn
		vbox.add_child(hbox)

	vbox.add_child(HSeparator.new())

	# -- Audio section --
	var audio_header := Label.new()
	audio_header.text = "Audio"
	audio_header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(audio_header)

	_add_volume_slider(vbox, "Master", SettingsManager.master_volume, _on_master_changed)
	_add_volume_slider(vbox, "Music", SettingsManager.music_volume, _on_music_changed)
	_add_volume_slider(vbox, "SFX", SettingsManager.sfx_volume, _on_sfx_changed)

	vbox.add_child(HSeparator.new())

	# -- Bottom buttons --
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var reset_btn := Button.new()
	reset_btn.text = "Reset Defaults"
	reset_btn.custom_minimum_size = Vector2(130, 30)
	reset_btn.add_theme_font_size_override("font_size", 12)
	reset_btn.pressed.connect(_on_reset)
	btn_row.add_child(reset_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(100, 30)
	back_btn.add_theme_font_size_override("font_size", 12)
	back_btn.pressed.connect(func(): back_pressed.emit())
	btn_row.add_child(back_btn)

	vbox.add_child(btn_row)


func _add_volume_slider(parent: VBoxContainer, label_text: String, value: float, callback: Callable) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(200, 20)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	hbox.add_child(slider)

	parent.add_child(hbox)


func _on_rebind_pressed(action: String, btn: Button) -> void:
	if _listening_action != "":
		_keybind_buttons[_listening_action].text = SettingsManager.get_action_key_name(_listening_action)
	_listening_action = action
	_listening_button = btn
	btn.text = "Press any key..."


func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == "" or not (event is InputEventKey) or not event.pressed:
		return

	var key_event := event as InputEventKey

	# Cancel rebind on Escape
	if key_event.keycode == KEY_ESCAPE:
		_listening_button.text = SettingsManager.get_action_key_name(_listening_action)
		_listening_action = ""
		get_viewport().set_input_as_handled()
		return

	SettingsManager.rebind_action(_listening_action, key_event)
	_listening_button.text = SettingsManager.get_action_key_name(_listening_action)
	_listening_action = ""
	get_viewport().set_input_as_handled()


func _on_reset() -> void:
	SettingsManager.reset_defaults()
	_refresh_keybind_labels()


func _refresh_keybind_labels() -> void:
	for action in _keybind_buttons:
		_keybind_buttons[action].text = SettingsManager.get_action_key_name(action)


func _on_master_changed(value: float) -> void:
	SettingsManager.master_volume = value
	SettingsManager.save_settings()


func _on_music_changed(value: float) -> void:
	SettingsManager.music_volume = value
	SettingsManager.save_settings()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	SettingsManager.save_settings()
