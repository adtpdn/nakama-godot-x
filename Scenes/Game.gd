extends Control

# Game state variables
var current_player_index: int = 0
var turn_number: int = 1
var players = []
var turn_timer: Timer
var turn_duration: float = 60.0  # 30 seconds per turn

# Signals
signal turn_timer_updated(time_left: float)

# UI Elements
@onready var end_turn_button = $VBoxContainer/EndTurn
@onready var current_player_label = $VBoxContainer/CurrentPlayer
@onready var sync_timer = $SyncTimer
@onready var timer_label = $TimerLabel
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
	setup_turn_timer()
	_update_player_labels()

func _process(delta):
	if turn_timer.time_left > 0:
		emit_signal("turn_timer_updated", turn_timer.time_left)

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
	timer_label.connect("turn_timer_updated", Callable(self, "_on_turn_timer_updated"))

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

func setup_turn_timer():
	turn_timer = Timer.new()
	turn_timer.one_shot = true
	turn_timer.connect("timeout", Callable(self, "_on_turn_timer_timeout"))
	add_child(turn_timer)

func start_turn_timer():
	turn_timer.start(turn_duration)

func stop_turn_timer():
	turn_timer.stop()

func _on_turn_timer_timeout():
	print("Turn timer expired!")
	switch_turns()

func switch_turns():
	stop_turn_timer()
	current_turn = (current_turn + 1) % player_count
	emit_signal("turn_switched", current_turn)
	start_turn_timer()

func _on_cell_pressed(cell):
	if game_over:
		return
	
	if board[cell] == -1:
		board[cell] = current_turn
		emit_signal("cell_updated", cell, current_turn)
		
		if check_winner():
			stop_turn_timer()
			game_over = true
			emit_signal("game_over", current_turn)
		elif check_draw():
			stop_turn_timer()
			game_over = true
			emit_signal("game_over", -1)
		else:
			switch_turns()

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
