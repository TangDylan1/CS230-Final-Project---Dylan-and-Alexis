extends Node

signal coins_changed(new_amount: int)

var coins: int = 0


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func reset_coins() -> void:
	coins = 0
	coins_changed.emit(coins)
