extends Control
## Heart HUD: hearts (full / half / empty). Flashes red/white on damage for 0.5s.
## Supports variable max hearts (e.g. 4 base + 1 per health card). Health in half-hearts.

const HEART_SIZE := 16  # Source sprite size; display scaled 3x (48x48)
const HEART_DISPLAY_SCALE := 3
const FLASH_DURATION := 0.5
const FLASH_INTERVAL := 0.08  # Switch red/white every 0.08s
const MAX_HEARTS := 10  # Cap display (20 half-hearts)

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
	# Match max hearts to GameManager (4 base + 1 per health card)
	var initial_hearts := GameManager.get_max_hearts()
	_ensure_heart_count(initial_hearts)
	_current_half_hearts = initial_hearts * 2
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
	half_hearts = clampi(half_hearts, 0, MAX_HEARTS * 2)
	var need_hearts := int((half_hearts + 1) / 2.0)
	if need_hearts > _hearts.size():
		_ensure_heart_count(need_hearts)
	if half_hearts == _current_half_hearts:
		return
	_current_half_hearts = half_hearts
	_refresh_hearts()


## Ensure at least min_hearts heart slots exist (adds more if needed, e.g. after health card).
func _ensure_heart_count(min_hearts: int) -> void:
	min_hearts = clampi(min_hearts, 1, MAX_HEARTS)
	if _atlas == null:
		return
	var display_size := HEART_SIZE * HEART_DISPLAY_SCALE
	while _hearts.size() < min_hearts:
		var i := _hearts.size()
		var rect := TextureRect.new()
		rect.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		rect.size = Vector2(HEART_SIZE, HEART_SIZE)
		rect.position = Vector2(8 + i * (display_size + 4), 8)
		rect.scale = Vector2(HEART_DISPLAY_SCALE, HEART_DISPLAY_SCALE)
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture = _make_atlas_texture(IDX_FULL)
		add_child(rect)
		_hearts.append(rect)
	custom_minimum_size.x = 8 + _hearts.size() * (display_size + 4)


## Call when player took damage: old_half, new_half (after damage), heart_index to flash (0-based).
func on_damage_taken(old_half: int, new_half: int) -> void:
	var max_half := _hearts.size() * 2
	_current_half_hearts = clampi(new_half, 0, max_half)
	# Rightmost heart that lost a half-heart
	var heart_index := int((old_half - 1) / 2.0) if old_half > 0 else 0
	heart_index = clampi(heart_index, 0, _hearts.size() - 1)
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
