extends CanvasLayer

signal closed

const CARDS := [
	{"key": "attack", "name": "Attack", "price": 15, "desc": "Upgrades your\ndamage by 1"},
	{"key": "speed", "name": "Speed", "price": 12, "desc": "Increases movement\nspeed by 15%"},
	{"key": "health", "name": "Health", "price": 18, "desc": "Increases health\nby 1 heart"},
]

const CARD_TEXTURES := {
	"attack": "res://assets/cards/card_attack.png",
	"speed": "res://assets/cards/card_speed.png",
	"health": "res://assets/cards/card_health.png",
}

const CARD_SIZE := Vector2(160, 256)
const HOVER_SCALE := 1.12
const NORMAL_SCALE := 1.0

var _root: Control
var _coin_label: Label
var _is_open := false
var _hovered_card: Control = null
var _card_controls: Array[Control] = []
var _level_labels: Array[Label] = []
var _card_levels := {"attack": 1, "speed": 1, "health": 1}


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 430)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.18, 1.0)
	panel_style.border_color = Color(0.4, 0.4, 0.6, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var shop_title := Label.new()
	shop_title.text = "THE SHOPKEEPER"
	shop_title.add_theme_font_size_override("font_size", 18)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(shop_title)

	var dialogue := Label.new()
	dialogue.text = "\"Hello adventurer! I sell items that will help you on your journey... just don't ask where they came from.\""
	dialogue.add_theme_font_size_override("font_size", 9)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(dialogue)

	vbox.add_child(HSeparator.new())

	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 12)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(_coin_label)

	# --- Card row ---
	var cards_center := CenterContainer.new()
	vbox.add_child(cards_center)

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 24)
	cards_center.add_child(cards_row)

	for i in CARDS.size():
		var card := _create_card(i)
		cards_row.add_child(card)
		_card_controls.append(card)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	vbox.add_child(spacer)

	var leave_container := CenterContainer.new()
	var leave_btn := Button.new()
	leave_btn.text = "Leave Shop"
	leave_btn.custom_minimum_size = Vector2(130, 28)
	leave_btn.add_theme_font_size_override("font_size", 11)
	leave_btn.pressed.connect(_on_leave)
	leave_container.add_child(leave_btn)
	vbox.add_child(leave_container)


func _create_card(index: int) -> Control:
	var data: Dictionary = CARDS[index]

	var card := Control.new()
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.pivot_offset = CARD_SIZE / 2.0
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Card art texture
	var tex := TextureRect.new()
	tex.texture = load(CARD_TEXTURES[data["key"]])
	tex.position = Vector2.ZERO
	tex.size = CARD_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tex)

	# Card name — centered on the art area
	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(10, 55)
	name_lbl.size = Vector2(140, 30)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# Description — in the cream/white text area of the card
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.position = Vector2(12, 155)
	desc_lbl.size = Vector2(136, 60)
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	# Level indicator — positioned over the white circle in the top-right
	var level_lbl := Label.new()
	level_lbl.text = str(_card_levels[data["key"]])
	level_lbl.add_theme_font_size_override("font_size", 13)
	level_lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_lbl.position = Vector2(134, 4)
	level_lbl.size = Vector2(20, 20)
	level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(level_lbl)
	_level_labels.append(level_lbl)

	# Price — bottom of the cream area
	var price_lbl := Label.new()
	price_lbl.text = str(data["price"]) + " coins"
	price_lbl.add_theme_font_size_override("font_size", 12)
	price_lbl.add_theme_color_override("font_color", Color(0.4, 0.35, 0.15))
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.position = Vector2(10, 225)
	price_lbl.size = Vector2(140, 20)
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(price_lbl)

	card.mouse_entered.connect(_on_card_hover.bind(card))
	card.mouse_exited.connect(_on_card_unhover.bind(card))
	card.gui_input.connect(_on_card_input.bind(index))

	return card


# ---------------------------------------------------------------------------
# Hover animation — only one card pops out at a time
# ---------------------------------------------------------------------------

func _on_card_hover(card: Control) -> void:
	if _hovered_card == card:
		return
	if _hovered_card:
		_animate_card(_hovered_card, NORMAL_SCALE)
		_hovered_card.z_index = 0
	_hovered_card = card
	card.z_index = 1
	_animate_card(card, HOVER_SCALE)


func _on_card_unhover(card: Control) -> void:
	if _hovered_card == card:
		_animate_card(card, NORMAL_SCALE)
		card.z_index = 0
		_hovered_card = null


func _animate_card(card: Control, target: float) -> void:
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2(target, target), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# ---------------------------------------------------------------------------
# Purchase logic
# ---------------------------------------------------------------------------

func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_buy_card(index)


func _buy_card(index: int) -> void:
	var data: Dictionary = CARDS[index]
	var key: String = data["key"]
	if GameManager.coins >= data["price"]:
		GameManager.coins -= data["price"]
		_card_levels[key] += 1
		_update_level_labels()
		_update_coin_display()


func _update_level_labels() -> void:
	for i in CARDS.size():
		_level_labels[i].text = str(_card_levels[CARDS[i]["key"]])


# ---------------------------------------------------------------------------
# Open / close
# ---------------------------------------------------------------------------

func open_shop() -> void:
	_is_open = true
	_root.visible = true
	get_tree().paused = true
	_update_coin_display()


func _on_leave() -> void:
	_is_open = false
	_root.visible = false
	get_tree().paused = false
	if _hovered_card:
		_hovered_card.scale = Vector2(NORMAL_SCALE, NORMAL_SCALE)
		_hovered_card.z_index = 0
		_hovered_card = null
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("pause"):
		_on_leave()
		get_viewport().set_input_as_handled()


func _update_coin_display() -> void:
	_coin_label.text = "Coins: " + str(GameManager.coins)
