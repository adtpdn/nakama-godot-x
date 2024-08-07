extends Control

# UI Elements
@onready var lobby_title = $VBoxContainer/LobbyTitle
@onready var host_client_label = $VBoxContainer/Label
@onready var start_game_button = $VBoxContainer/StartGame
@onready var waiting_label = $VBoxContainer/WaitingLabel
@onready var player_containers = [
	$VBoxContainer/HBoxContainer/Player1,
	$VBoxContainer/HBoxContainer/Player2,
	$VBoxContainer/HBoxContainer/Player3,
	$VBoxContainer/HBoxContainer/Player4
]

func _ready():
	setup_ui()
	connect_signals()
	Global.add_player(Global.player_id)

# Set up initial UI state
func setup_ui():
	lobby_title.text = Global.match_id
	if Global.is_host:
		host_client_label.text = "Host"
		start_game_button.show()
		waiting_label.hide()
	else:
		host_client_label.text = "Client"
		start_game_button.hide()
		waiting_label.show()

# Connect signals to their respective functions
func connect_signals():
	start_game_button.connect("pressed", Callable(self, "_on_start_game_pressed"))
	Global.players_updated.connect(self.update_player_list)
	Global.game_started.connect(self.start_game)

# Update the player list in the UI
func update_player_list():
	print("Updating player list in UI")
	for i in range(4):
		var player_container = player_containers[i]
		var label = player_container.get_node("Label")
		var color_rect = player_container.get_node("ColorRect")
		
		if i < Global.players.size():
			label.text = Global.players.values()[i]
			color_rect.color = Color.GREEN
		else:
			label.text = "Waiting..."
			color_rect.color = Color.RED

# Start game button pressed (host only)
func _on_start_game_pressed():
	if Global.is_host and Global.players.size() > 1:
		Global.start_game()

# Change scene to game when game starts
func start_game():
	print("Starting game...")
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")
