extends Node

signal coins_changed(new_amount: int)

var _coins: int = 0
var coins: int:
	get:
		return _coins
	set(value):
		_coins = value
		coins_changed.emit(_coins)

# Shop upgrade levels (persist for the run). Base level 1 = no purchases.
var upgrade_attack: int = 1
var upgrade_speed: int = 1
var upgrade_health: int = 1


func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func start_game() -> void:
	_coins = 0
	upgrade_attack = 1
	upgrade_speed = 1
	upgrade_health = 1
	coins_changed.emit(0)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/dungeon.tscn")


func restart_game() -> void:
	_coins = 0
	upgrade_attack = 1
	upgrade_speed = 1
	upgrade_health = 1
	coins_changed.emit(0)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/dungeon.tscn")


func add_coins(amount: int) -> void:
	_coins += amount
	coins_changed.emit(_coins)


func spend_coins(amount: int) -> bool:
	if _coins < amount:
		return false
	_coins -= amount
	coins_changed.emit(_coins)
	return true


func reset_coins() -> void:
	_coins = 0
	coins_changed.emit(0)


# Each attack upgrade adds +1 damage. Katana base 2, star base 1.
func get_katana_damage() -> int:
	return 2 + (upgrade_attack - 1)


func get_star_damage() -> int:
	return 1 + (upgrade_attack - 1)


# Speed: +15% per upgrade. Level 1 = 1.0, level 2 = 1.15, etc.
func get_speed_multiplier() -> float:
	return 1.0 + 0.15 * (upgrade_speed - 1)


# Health: base 4 hearts, +1 heart per health upgrade.
func get_max_hearts() -> int:
	return 4 + (upgrade_health - 1)


func quit_game() -> void:
	get_tree().quit()
