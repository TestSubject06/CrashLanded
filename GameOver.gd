extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var tips = [
	"Armor subtracts from enemy damage, making it essential to surviving hits.",
	"Enemies get more powerful each day, slowly at first, but faster over time.",
	"By day 40, enemies are nigh unkillable. Get out before then!",
	"Mining during the day is much easier since there are fewer enemies.",
	"Balancing damage and attack rate is crucial for surviving.",
	"Don't neglect your lander's stats.",
	"Do your best to avoid getting surrounded - grenades are not implemented.",
]

# Called when the node enters the scene tree for the first time.
func _ready():
	var rng = RandomNumberGenerator.new();
	rng.randomize()
	
	match(Global.death_reason):
		"player":
			$Label.text = "You died."
		"lander":
			$Label.text = "Your pod was destroyed."
		_:
			$Label.text = "You died."
	
	$Label3.text = tips[rng.randi_range(0, tips.size()-1)]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept") || Input.is_action_just_pressed("Fire"):
		get_tree().change_scene("res://Main.tscn");
	pass
