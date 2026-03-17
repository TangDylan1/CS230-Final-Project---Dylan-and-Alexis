extends Control
## Heart HUD: 4 hearts (full / half / empty). Flashes red/white on damage for 0.5s.
## Health is in half-hearts (0-8). Player emits health_changed(old_half, new_half, heart_index_to_flash).

const HEART_SIZE := 16  # Source sprite size; display scaled 3x (48x48)
const HEART_DISPLAY_SCALE := 3
const NUM_HEARTS := 4
const FLASH_DURATION := 0.5
const FLASH_INTERVAL := 0.08  # Switch red/white every 0.08s

# Sprite indices in sheet (2 rows of 5, 16x16 each: 80x32 texture)
const IDX_FULL := 0
const IDX_HALF := 1
const IDX_EMPTY := 4
const IDX_FLASH_RED := 8   # Bottom row, 4th
const IDX_FLASH_WHITE := 9 # Bottom row, 5th

var _hearts: Array[TextureRect] = []
var _atlas: Texture2D
var _flash_heart_index: int = -1
var _flash_timer: float = 0.0
var _flash_show_red: bool = true
var _current_half_hearts: int = 8


func _ready() -> void:
	_atlas = load("res://assets/ui/heart_spritesheet.png") as Texture2D
	if _atlas == null:
		push_error("HeartHUD: heart_spritesheet.png not found at res://assets/ui/")
		return

	# 4 hearts in a row, top-left (16x16 source scaled 3x = 48x48 display)
	var display_size := HEART_SIZE * HEART_DISPLAY_SCALE
	for i in NUM_HEARTS:
		var rect := TextureRect.new()
		rect.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		rect.size = Vector2(HEART_SIZE, HEART_SIZE)
		rect.position = Vector2(8 + i * (display_size + 4), 8)
		rect.scale = Vector2(HEART_DISPLAY_SCALE, HEART_DISPLAY_SCALE)
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture = _make_atlas_texture(IDX_FULL)
		add_child(rect)
		_hearts.append(rect)

	_current_half_hearts = 8
	_refresh_hearts()


func _process(delta: float) -> void:
	if _flash_heart_index < 0:
		return
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_flash_heart_index = -1
		_refresh_hearts()
		return
	# Toggle red/white
	var interval_elapsed := FLASH_DURATION - _flash_timer
	var toggle_count := int(interval_elapsed / FLASH_INTERVAL)
	_flash_show_red = (toggle_count % 2) == 0
	if _flash_heart_index >= 0 and _flash_heart_index < _hearts.size():
		_hearts[_flash_heart_index].texture = _make_atlas_texture(IDX_FLASH_RED if _flash_show_red else IDX_FLASH_WHITE)


func set_half_hearts(half_hearts: int) -> void:
	half_hearts = clampi(half_hearts, 0, NUM_HEARTS * 2)
	if half_hearts == _current_half_hearts:
		return
	_current_half_hearts = half_hearts
	_refresh_hearts()


## Call when player took damage: old_half, new_half (after damage), heart_index to flash (0-based).
func on_damage_taken(old_half: int, new_half: int) -> void:
	_current_half_hearts = clampi(new_half, 0, NUM_HEARTS * 2)
	# Rightmost heart that lost a half-heart
	var heart_index := int((old_half - 1) / 2.0) if old_half > 0 else 0
	heart_index = clampi(heart_index, 0, NUM_HEARTS - 1)
	_flash_heart_index = heart_index
	_flash_timer = FLASH_DURATION
	_flash_show_red = true
	if _flash_heart_index >= 0 and _flash_heart_index < _hearts.size():
		_hearts[_flash_heart_index].texture = _make_atlas_texture(IDX_FLASH_RED)
	_refresh_hearts_except(_flash_heart_index)


func _refresh_hearts() -> void:
	for i in _hearts.size():
		_set_heart_texture(i)


func _refresh_hearts_except(skip_index: int) -> void:
	for i in _hearts.size():
		if i == skip_index:
			continue
		_set_heart_texture(i)


func _set_heart_texture(heart_index: int) -> void:
	if heart_index < 0 or heart_index >= _hearts.size() or _atlas == null:
		return
	var half_remaining := _current_half_hearts - heart_index * 2
	var idx: int
	if half_remaining >= 2:
		idx = IDX_FULL
	elif half_remaining >= 1:
		idx = IDX_HALF
	else:
		idx = IDX_EMPTY
	_hearts[heart_index].texture = _make_atlas_texture(idx)


func _make_atlas_texture(index: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = _atlas
	var col := index % 5
	var row := int(index / 5.0)
	at.region = Rect2(col * HEART_SIZE, row * HEART_SIZE, HEART_SIZE, HEART_SIZE)
	return at
