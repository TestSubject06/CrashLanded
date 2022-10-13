extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = false;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") || Input.is_action_just_pressed("Fire"):
		if get_tree().change_scene("res://Scenes/Main.tscn") != OK
			print("Failed to transition to the main scene from Victory.")
	pass
