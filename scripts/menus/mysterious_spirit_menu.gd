extends CanvasLayer

signal accepted
signal declined

var _root: Control
var _is_open := false
var _dialogue_label: Label
var _choice_row: HBoxContainer
var _result_box: VBoxContainer
var _result_label: Label


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func open_menu() -> void:
	_is_open = true
	_root.visible = true
	_choice_row.visible = true
	_result_box.visible = false
	get_tree().paused = true


func close_menu() -> void:
	_is_open = false
	_root.visible = false
	get_tree().paused = false


func is_open() -> bool:
	return _is_open


func show_result(text: String) -> void:
	_is_open = true
	_root.visible = true
	_choice_row.visible = false
	_result_box.visible = true
	_result_label.text = text
	get_tree().paused = true


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 360)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.10, 1.0)
	panel_style.border_color = Color(0.25, 0.45, 0.65, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "MYSTERIOUS SPIRIT"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	vbox.add_child(title)

	_dialogue_label = Label.new()
	_dialogue_label.text = "\"Hush… mortal. The walls here remember every footstep, and the shadows bargain in whispers.\n\nI am the Mysterious Spirit, watcher of hidden doors and keeper of cruel luck. I offer you a single wager: a test of chance. It may grant you glittering fortune… or awaken hungry foes… or cast you somewhere you were never meant to return from.\n\nDo you dare accept my challenge?\""
	_dialogue_label.add_theme_font_size_override("font_size", 12)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(_dialogue_label)

	vbox.add_child(HSeparator.new())

	_choice_row = HBoxContainer.new()
	_choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_row.add_theme_constant_override("separation", 14)
	vbox.add_child(_choice_row)

	var accept := Button.new()
	accept.text = "Accept"
	_choice_row.add_child(accept)

	var decline := Button.new()
	decline.text = "Decline"
	_choice_row.add_child(decline)

	accept.pressed.connect(func():
		close_menu()
		accepted.emit()
	)
	decline.pressed.connect(func():
		close_menu()
		declined.emit()
	)

	_result_box = VBoxContainer.new()
	_result_box.visible = false
	_result_box.add_theme_constant_override("separation", 12)
	vbox.add_child(_result_box)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.add_theme_font_size_override("font_size", 12)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	_result_box.add_child(_result_label)

	var ok := Button.new()
	ok.text = "OK"
	ok.pressed.connect(func(): close_menu())
	_result_box.add_child(ok)

