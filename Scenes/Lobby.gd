extends Control

# Characters
var current_character_index = 0
@onready var character_portraits = [
	$VBoxContainer/CharacterSelector/HBoxContainer/Character1,
	$VBoxContainer/CharacterSelector/HBoxContainer/Character2,
	$VBoxContainer/CharacterSelector/HBoxContainer/Character3,
	$VBoxContainer/CharacterSelector/HBoxContainer/Character4
]
@onready var character_selector = $VBoxContainer/CharacterSelector
@onready var character_name_label = $VBoxContainer/CharacterSelector/CharacterName
@onready var prev_character_button = $VBoxContainer/CharacterSelector/HBoxContainer2/PrevCharacter
@onready var next_character_button = $VBoxContainer/CharacterSelector/HBoxContainer2/NextCharacter


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
	update_character_selection()


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

# Set Characters Portraits
func setup_character_portraits():
	for i in range(Global.characters.size()):
		var texture = load("res://assets/characters/" + Global.characters[i].to_lower() + ".png")
		character_portraits[i].set_character(Global.characters[i], texture)

# Connect signals to their respective functions
func connect_signals():
	start_game_button.connect("pressed", Callable(self, "_on_start_game_pressed"))
	Global.players_updated.connect(self.update_player_list)
	Global.game_started.connect(self.start_game)
	prev_character_button.connect("pressed", Callable(self, "_on_prev_character_pressed"))
	next_character_button.connect("pressed", Callable(self, "_on_next_character_pressed"))

# Match State
func _on_match_state(state):
	var data = JSON.parse_string(state.data)
	match data.type:
		"player_joined":
			print("Player joined: ", data.id)
			if Global.is_host:
				Global.add_player(data.id)
		"player_list":
			Global.players = data.players
			update_player_list()
		"game_start":
			start_game()
		"character_selected":
			Global.player_characters[data.id] = data.character
			update_player_list()

func _on_character_selected(index):
	current_character_index = index
	Global.update_selected_character(Global.characters[index])
	update_character_selection()

# Update the Character Selection
func update_character_selection():
	character_name_label.text = Global.characters[current_character_index]
	Global.selected_character = Global.characters[current_character_index]
	
	Global.send_match_state(1, {"type": "character_selected", "character": Global.selected_character})
	update_player_list()

func _on_prev_character_pressed():
	current_character_index = (current_character_index - 1 + Global.characters.size()) % Global.characters.size()
	update_character_selection()

func _on_next_character_pressed():
	current_character_index = (current_character_index + 1) % Global.characters.size()
	update_character_selection()
	

# Update the player list in the UI
func update_player_list():
	print("Updating player list in UI")
	for i in range(4):
		var player_container = player_containers[i]
		var name_label = player_container.get_node("Name")
		var character_label = player_container.get_node("Character")
		var color_rect = player_container.get_node("ColorRect")
		
		if i < Global.players.size():
			var player_id = Global.players.keys()[i]
			var player_name = Global.player_usernames.get(player_id, "Player " + str(i + 1))
			var character = Global.player_characters.get(player_id, "Not selected")
			
			name_label.text = player_name
			character_label.text = character
			color_rect.color = Color.GREEN
			player_container.show()
		else:
			name_label.text = "Waiting..."
			character_label.text = ""
			color_rect.color = Color.RED
			player_container.show()  # Changed from hide() to show() to maintain visibility of empty slots

# Start game button pressed (host only)
func _on_start_game_pressed():
	if Global.is_host and Global.players.size() > 1:
		Global.start_game()

# Change scene to game when game starts
func start_game():
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
