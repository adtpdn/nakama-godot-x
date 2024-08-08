extends Control

# UI Elements
@onready var host_game_button = $VBoxContainer/HostGame
@onready var join_game_button = $VBoxContainer/JoinGame
@onready var match_id_input = $VBoxContainer/MatchIDInput
@onready var title_label = $VBoxContainer/TitleLabel
@onready var logout_button = $VBoxContainer/LogoutButton

func _ready():
	update_title()
	connect_signals()

func update_title():
	title_label.text = "Welcome, @" + Global.username

# Connect signals to their respective functions
func connect_signals():
	host_game_button.connect("pressed", Callable(self, "_on_host_game_pressed"))
	join_game_button.connect("pressed", Callable(self, "_on_join_game_pressed"))
	logout_button.connect("pressed", Callable(self, "_on_logout_pressed"))

# Handle host game button press
func _on_host_game_pressed():
	await Global.create_match()
	change_to_lobby_scene()

# Handle join game button press
func _on_join_game_pressed():
	var match_id = match_id_input.text.strip_edges()
	if match_id.is_empty():
		print("Please enter a valid match ID")
		return
	
	print("Attempting to join match: " + match_id)
	await Global.join_match(match_id)
	
	if Global.match_id.is_empty():
		print("Failed to join match. Please check the match ID and try again.")
	else:
		change_to_lobby_scene()

func _on_logout_pressed():
	Global.logout()
	get_tree().change_scene_to_file("res://scenes/auth_scene.tscn")

# Change scene to lobby
func change_to_lobby_scene():
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
