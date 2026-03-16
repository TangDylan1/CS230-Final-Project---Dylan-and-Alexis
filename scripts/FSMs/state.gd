extends Node
class_name State

var fsm: FiniteStateMachine

# Basic state class for the FSM, have children inherit and override as needed
func enter() -> void: # Called on state enter
	pass

func exit() -> void: # Called on state exit
	pass

func update(delta: float): # Called every frame 
	pass

func physics_update(delta: float): # Called every physics frame 
	pass

func handle_input(event: InputEvent): # Called when an input event is received
	pass
