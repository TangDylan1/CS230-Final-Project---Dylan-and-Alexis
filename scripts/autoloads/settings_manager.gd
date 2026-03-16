extends Node

const SAVE_PATH := "user://settings.cfg"

const BINDABLE_ACTIONS := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"interact": "Interact",
	"pause": "Pause",
}

var _defaults: Dictionary = {}

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0

signal volume_changed


func _ready() -> void:
	_cache_defaults()
	load_settings()


func _cache_defaults() -> void:
	for action in BINDABLE_ACTIONS:
		if InputMap.has_action(action):
			_defaults[action] = InputMap.action_get_events(action).duplicate()


func rebind_action(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	save_settings()


func reset_defaults() -> void:
	for action in _defaults:
		InputMap.action_erase_events(action)
		for ev in _defaults[action]:
			InputMap.action_add_event(action, ev)
	save_settings()


func get_action_key_name(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			var kc: Key = (ev as InputEventKey).physical_keycode
			if kc == KEY_NONE:
				kc = (ev as InputEventKey).keycode
			if kc != KEY_NONE:
				return OS.get_keycode_string(kc)
	return "Unbound"


func save_settings() -> void:
	var config := ConfigFile.new()
	for action in BINDABLE_ACTIONS:
		var events := InputMap.action_get_events(action)
		for ev in events:
			if ev is InputEventKey:
				var key_ev := ev as InputEventKey
				var kc: int = key_ev.physical_keycode if key_ev.physical_keycode != KEY_NONE else key_ev.keycode
				config.set_value("keybinds", action, kc)
				break
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for action in BINDABLE_ACTIONS:
		if config.has_section_key("keybinds", action):
			var keycode: int = config.get_value("keybinds", action)
			var event := InputEventKey.new()
			event.physical_keycode = keycode as Key
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
	master_volume = config.get_value("audio", "master", 1.0)
	music_volume = config.get_value("audio", "music", 1.0)
	sfx_volume = config.get_value("audio", "sfx", 1.0)
	_apply_audio()


func _apply_audio() -> void:
	volume_changed.emit()
