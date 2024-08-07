extends Control

# Game state variables
var current_player_index: int = 0
var turn_number: int = 1
var players = []

# UI Elements
@onready var end_turn_button = $VBoxContainer/EndTurn
@onready var current_player_label = $VBoxContainer/CurrentPlayer
@onready var sync_timer = $SyncTimer
@onready var player_labels = [
	$VBoxContainer/HBoxContainer/Player1Label,
	$VBoxContainer/HBoxContainer/Player2Label,
	$VBoxContainer/HBoxContainer/Player3Label,
	$VBoxContainer/HBoxContainer/Player4Label
]

const SYNC_INTERVAL = 5.0  # Sync every 5 seconds

func _ready():
	setup_game()
	connect_signals()
	initialize_game_state()
	sync_timer.start()
	_update_player_labels()

# Set up initial game state
func setup_game():
	players = Global.players.keys()
	players.sort()  # Sort player IDs to ensure consistent order

# Connect signals to their respective functions
func connect_signals():
	Global.socket.received_match_state.connect(self._on_match_state)
	end_turn_button.connect("pressed", Callable(self, "_on_end_turn_pressed"))
	Global.players_updated.connect(self._update_player_labels)
	Global.username_updated.connect(self._on_username_updated)
	sync_timer.connect("timeout", Callable(self, "_on_sync_timer_timeout"))

# Initialize game state based on host/client status
func initialize_game_state():
	if Global.is_host:
		_init_game_state()
	else:
		_request_game_state()

# Initialize game state (host only)
func _init_game_state():
	current_player_index = 0  # Ensure first turn is for Player 1 (host)
	turn_number = 1
	_broadcast_game_state()

# Request game state (client only)
func _request_game_state():
	Global.send_match_state(3, {"type": "request_game_state"})

# Handle end turn button press
func _on_end_turn_pressed():
	if is_current_player():
		if Global.is_host:
			next_turn()
			_broadcast_game_state()
		else:
			Global.send_match_state(3, {"type": "end_turn"})

# Move to the next turn
func next_turn():
	current_player_index = (current_player_index + 1) % players.size()
	turn_number += 1
	update_turn_display()

# Update the turn display
func update_turn_display():
	
	
	if current_player_index < 0 or current_player_index >= players.size():
		print("Error: Invalid current_player_index: ", current_player_index)
		return
	
	var current_player_id = players[current_player_index]
	var current_player_name = Global.player_usernames.get(current_player_id, "Unknown Player")
	
	if is_current_player():
		current_player_label.text = "Your turn"
		end_turn_button.disabled = false
	else:
		current_player_label.text = current_player_name + "'s turn"
		end_turn_button.disabled = true
	
	print("Turn number: ", turn_number, " Current player index: ", current_player_index, " Current player ID: ", current_player_id, " Is current player: ", is_current_player())
	$TurnNumberLabel.text = str(turn_number)

# Update player labels
func _update_player_labels():
	print("Updating player labels")
	var sorted_players = players.duplicate()
	sorted_players.sort()
	
	# Move host to the beginning of the array
	var host_index = sorted_players.find(Global.player_id if Global.is_host else sorted_players[0])
	if host_index != -1:
		var host_id = sorted_players[host_index]
		sorted_players.remove_at(host_index)
		sorted_players.insert(0, host_id)
	
	for i in range(4):
		if i < sorted_players.size():
			var player_id = sorted_players[i]
			player_labels[i].text = Global.player_usernames.get(player_id, "Loading...") if player_id == Global.player_id else "---"
		else:
			player_labels[i].text = "---"

# Handle username updates
func _on_username_updated(id, username):
	print("Username updated for player ", id, ": ", username)
	if id == Global.player_id:
		_update_player_labels()

# Check if it's the current player's turn
func is_current_player():
	return Global.player_id == players[current_player_index]

# Handle received match states
func _on_match_state(state):
	var data = JSON.parse_string(state.data)
	if data == null:
		print("Error: Failed to parse match state data")
		return
	
	match data.type:
		"game_state":
			if data.has("current_player_index") and data.has("turn_number"):
				current_player_index = data.current_player_index
				turn_number = data.turn_number
				update_turn_display()
			else:
				print("Error: game_state message missing required fields")
		"request_game_state":
			if Global.is_host:
				_broadcast_game_state()
		"end_turn":
			if Global.is_host:
				next_turn()
				_broadcast_game_state()

# Broadcast current game state (host only)
func _broadcast_game_state():
	Global.send_match_state(3, {
		"type": "game_state", 
		"current_player_index": current_player_index,
		"turn_number": turn_number
	})

# Handle periodic sync timer
func _on_sync_timer_timeout():
	if Global.is_host:
		print("Periodic sync: Broadcasting game state")
		_broadcast_game_state()
	else:
		_request_game_state()
