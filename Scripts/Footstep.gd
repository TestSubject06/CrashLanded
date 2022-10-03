extends AnimatedSprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var fade_time = 3
var fade_accumulator = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fade_accumulator += delta;
	if(fade_accumulator > fade_time):
		visible = false

func reset(left = true):
	visible = true
	fade_accumulator = 0;
	modulate = Color(1, 1, 1, 1)
	$Tween.reset_all()
	$Tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 
		fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.5)
	$Tween.start()
	if(left):
		play("left")
		position = position + Vector2(4, 0).rotated(rotation)
	else:
		play("right")
		position = position - Vector2(4, 0).rotated(rotation)

func hide():
	visible = false

