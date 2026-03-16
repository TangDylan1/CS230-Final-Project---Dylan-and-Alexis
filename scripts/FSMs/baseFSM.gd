extends Node
class_name FiniteStateMachine
# include "state.gd"

@export var initial_state: State
var states: Dictionary = {}
var curr_state: State
var prev_state: State

# Finite State Machine base class
# Updates the current state and handles transitions
# thank you 120B and this guy https://www.youtube.com/watch?v=yQLjbzhWkII&t=388s
func _ready() -> void:
	process_priority = -1

	# For every child node of this FSM, if it is a State, add it to the states dictionary
	for child in get_children(): 
		if child is State:
			states[child.name.to_lower()] = child
			child.fsm = self

	# Start at the initial state
	if initial_state: 
		change_state(initial_state.name.to_lower())

# For process through input, these functions update the current state 
func _process(delta: float) -> void:
	if curr_state:
		curr_state.update(delta)

func _physics_process(delta: float) -> void:
	if curr_state:
		curr_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if curr_state:
		curr_state.handle_input(event)

func change_state(new_state: String) -> void:
	if curr_state:
		curr_state.exit()
		prev_state = curr_state

	curr_state = states.get(new_state.to_lower())
	
	if curr_state:
		curr_state.enter()

	pass
	