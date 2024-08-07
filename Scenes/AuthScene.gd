extends Control

# UI Elements
@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var login_button = $VBoxContainer/LoginButton
@onready var signup_button = $VBoxContainer/SignupButton
@onready var quick_play_button = $VBoxContainer/QuickPlayButton
@onready var status_label = $VBoxContainer/StatusLabel

func _ready():
	Global.logout()  # Clear any existing session
	connect_signals()
	status_label.text = ""

# Connect signals to their respective functions
func connect_signals():
	login_button.connect("pressed", Callable(self, "_on_login_pressed"))
	signup_button.connect("pressed", Callable(self, "_on_signup_pressed"))
	quick_play_button.connect("pressed", Callable(self, "_on_quick_play_pressed"))

# Handle login button press
func _on_login_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username.is_empty() or password.is_empty():
		status_label.text = "Please enter both username and password."
		return
	
	status_label.text = "Logging in..."
	var result = await Global.login(username, password)
	
	if result:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else:
		status_label.text = "Login failed. Please check your credentials."

# Handle signup button press
func _on_signup_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username.is_empty() or password.is_empty():
		status_label.text = "Please enter both username and password."
		return
	
	status_label.text = "Signing up..."
	var result = await Global.signup(username, password)
	
	if result:
		status_label.text = "Signup successful! You can now log in."
	else:
		status_label.text = "Signup failed. Username may already exist."

# Handle quick play button press
func _on_quick_play_pressed():
	status_label.text = "Connecting as guest..."
	var result = await Global.connect_to_server()
	
	if result:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else:
		status_label.text = "Failed to connect as guest. Please try again."
