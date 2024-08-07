extends Control

func _ready():
	$VBoxContainer/HostGame.connect("pressed", Callable(self, "_on_host_game_pressed"))
	$VBoxContainer/JoinGame.connect("pressed", Callable(self, "_on_join_game_pressed"))

func _on_host_game_pressed():
	await Global.create_match()
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

func _on_join_game_pressed():
	var match_id = $VBoxContainer/MatchIDInput.text.strip_edges()
	if match_id.is_empty():
		print("Please enter a valid match ID")
		return
	
	print("Attempting to join match: " + match_id)
	await Global.join_match(match_id)
	
	if Global.match_id.is_empty():
		print("Failed to join match. Please check the match ID and try again.")
	else:
		get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
