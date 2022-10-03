extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var flicker = true;
var skip = true;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if skip:
		flicker = !flicker
		skip = false
	else:
		skip = !skip
	
	if flicker:
		modulate = Color(1,1,1,0.92)
	else:
		modulate = Color(1,1,1,0.53)
	
	if position.x == 0 && position.y == 0:
		visible = false
	else:
		visible = true

func set_resources(resources):
	if resources.mined_out:
		$MainText.setText("MINED OUT")
		$Minerals.setText("")
		$Silicates.setText("")
		$ProgressBar.visible = false
	else:
		$MainText.setText("HOLD E TO MINE")
		$Minerals.setText("MINERALS: %s" % get_mineral_text(resources.minerals))
		$Silicates.setText("SILICATES: %s" % get_silicate_text(resources.silicates))
		$ProgressBar.visible = true
		$ProgressBar.rect_size.x = 14 + ((resources.progress/100.0) * (88-14))

func get_mineral_text(minerals):
	if minerals < 5:
		return "LOW"
	
	if minerals < 15:
		return "MED"
		
	return "HI"
	
func get_silicate_text(silicates):
	if silicates == 0:
		return "N/A"
		
	if silicates < 3:
		return "LOW"
	
	if silicates < 6:
		return "MED"
		
	return "HI"
