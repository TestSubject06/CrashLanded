extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	hide();


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func reset(position, minerals, silicates):
	$Tween.reset_all();
	visible = true;
	self.position = position
	modulate = Color(1, 1, 1, 1)
	$VBoxContainer/MineralsText.setText("( + %d" % minerals)
	if silicates > 0:
		$VBoxContainer/SilicatesText.setText(") + %d" % silicates)
	else:
		$VBoxContainer/SilicatesText.setText("")
	$Tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 
		1, Tween.TRANS_CUBIC, Tween.EASE_IN, 1)
	$Tween.interpolate_property(self, "position:y", null, position.y - 70, 
		2, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0)
	$Tween.start()

func hide():
	visible = false;
