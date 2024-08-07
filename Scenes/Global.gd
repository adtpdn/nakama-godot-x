extends Node

# Constants
const KEY = "defaultkey"
const SERVER_IP = "34.50.96.220"
const PORT = 7350
const SCHEME = "http"

# Nakama related variables
var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket

# Game state variables
var is_host = false
var player_id = ""
var player_usernames = {}
var match_id = ""
var players = {}

# Signals
signal players_updated
signal game_started
signal username_updated(id, username)

func _ready():
	client = Nakama.create_client(KEY, SERVER_IP, PORT, SCHEME)
	connect_to_server()

# Connect to Nakama server
func connect_to_server():
	var result = await client.authenticate_custom_async("user_id" + str(randi()))
	if result.is_exception():
		print("An error occurred: " + str(result.get_exception().message))
		return
	session = result
	player_id = session.user_id
	print("Connected as player: ", player_id)
	
	socket = Nakama.create_socket_from(client)
	var connected = await socket.connect_async(session)
	if connected.is_exception():
		print("An error occurred: " + str(connected.get_exception().message))
		return
	print("Socket connected.")
	
	socket.received_match_state.connect(self._on_match_state)

# Create a new match
func create_match():
	var result = await socket.create_match_async()
	if result.is_exception():
		print("An error occurred: " + str(result.get_exception().message))
		return
	match_id = result.match_id
	is_host = true
	print("Match created with ID: " + match_id)
	add_player(player_id)

# Join an existing match
func join_match(match_id):
	print("Attempting to join match with ID: " + match_id)
	
	if match_id.is_empty():
		print("Error: Match ID is empty")
		return
	
	var result = await socket.join_match_async(match_id)
	if result.is_exception():
		var error_message = str(result.get_exception().message)
		print("An error occurred while joining the match: " + error_message)
		return
	
	self.match_id = match_id
	is_host = false
	print("Successfully joined match with ID: " + match_id)
	send_match_state(1, {"type": "player_joined", "id": player_id})

# Send match state to other players
func send_match_state(op_code, data):
	if match_id == "":
		print("Not in a match.")
		return
	socket.send_match_state_async(match_id, op_code, JSON.stringify(data))

# Add a player to the game
func add_player(id):
	if not players.has(id):
		players[id] = "Player " + str(players.size() + 1)
		print("Added player: ", id)
		_fetch_username(id)
		players_updated.emit()
	if is_host:
		send_match_state(1, {"type": "player_list", "players": players})

# Fetch username for a player
func _fetch_username(id):
	print("Fetching username for player ", id)
	var result = await client.get_users_async(session, [id])
	if not result.is_exception():
		var users = result.users
		if users.size() > 0:
			var user = users[0]
			player_usernames[id] = user.username
			print("Fetched username for player ", id, ": ", user.username)
			username_updated.emit(id, user.username)
		else:
			print("No user found for player ", id)
	else:
		print("Failed to fetch username for player ", id, ": ", result.get_exception().message)

# Handle received match states
func _on_match_state(state):
	var data = JSON.parse_string(state.data)
	match data.type:
		"player_joined":
			print("Player joined: ", data.id)
			if is_host:
				add_player(data.id)
		"player_list":
			players = data.players
			print("Updated player list: ", players)
			for player_id in players.keys():
				if not player_usernames.has(player_id):
					_fetch_username(player_id)
			players_updated.emit()
		"game_start":
			print("Game start received")
			game_started.emit()
		"sync_players":
			players = data.players
			players_updated.emit()

# Start the game (host only)
func start_game():
	if is_host:
		send_match_state(2, {"type": "game_start"})
	game_started.emit()

# Synchronize players (host only)
func sync_players():
	if is_host:
		send_match_state(1, {"type": "sync_players", "players": players})
