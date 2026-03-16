extends Node

signal coins_changed(new_amount: int)

var coins: int = 0:
	set(value):
		coins = value
		coins_changed.emit(coins)


func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func start_game() -> void:
	coins = 0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/dungeon.tscn")


func restart_game() -> void:
	coins = 0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/dungeon.tscn")


func quit_game() -> void:
	get_tree().quit()
