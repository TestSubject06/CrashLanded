extends KinematicBody2D
class_name Enemy


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var health = 16;
var max_health = 16;
var armor = 1;
var dead = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func on_take_damage(_damage: float, _damage_point: Vector2, _source: Node2D, _piercing = false):
	print("An enemy has not handled damage yet")
	pass

func die():
	dead = true;
	#queue_free()
