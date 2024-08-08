extends TextureRect

@onready var name_label = $Name

func set_character(character_name: String, texture: Texture):
	name_label.text = character_name
	self.texture = texture
