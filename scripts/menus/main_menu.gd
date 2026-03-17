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

	# Transparent "frame" so the VBox always allocates space for the logo.
	var logo_frame := MarginContainer.new()
	logo_frame.add_theme_constant_override("margin_left", 20)
	logo_frame.add_theme_constant_override("margin_right", 20)
	logo_frame.add_theme_constant_override("margin_top", 10)
	logo_frame.add_theme_constant_override("margin_bottom", 10)
	logo_frame.custom_minimum_size = Vector2(720, 220)
	logo_frame.size_flags_horizontal = Control.SIZE_FILL
	logo_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(logo_frame)

	var logo := TextureRect.new()
	var logo_tex: Texture2D = load("res://assets/ui/spiritbreakers_logo.png")
	if logo_tex == null:
		# If the importer metadata is broken, fall back to loading the raw file.
		var img := Image.new()
		var err := img.load("res://assets/ui/spiritbreakers_logo.png")
		if err == OK:
			logo_tex = ImageTexture.create_from_image(img)
		else:
			push_error("MainMenu: failed to load logo (err=%s) at res://assets/ui/spiritbreakers_logo.png" % str(err))

	logo.texture = logo_tex
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = Control.SIZE_FILL
	logo.size_flags_vertical = Control.SIZE_FILL
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The logo asset includes a solid black background; key it out so the menu bg shows through.
	var logo_shader := Shader.new()
	logo_shader.code = """
shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float tolerance = 0.08;
uniform float softness = 0.06;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float d = distance(tex.rgb, key_color);
	float a = smoothstep(tolerance - softness, tolerance + softness, d);
	COLOR = vec4(tex.rgb, tex.a * a);
}
"""
	var logo_mat := ShaderMaterial.new()
	logo_mat.shader = logo_shader
	logo.material = logo_mat
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_frame.add_child(logo)

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
