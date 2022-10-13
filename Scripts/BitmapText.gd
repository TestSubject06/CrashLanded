extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (String) var text

var font_texture = preload("res://images/Font.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	var font = BitmapFont.new()
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ/ 0123456789:%@#+>-."
	font.add_texture(font_texture)
	for i in range (0, chars.length()):
		# warning-ignore:integer_division
		font.add_char(chars.ord_at(i), 0, Rect2(7 * (i % 7), 7 * floor(i/7), 7, 7), Vector2(0, 0), 6)
	font.add_char("(".ord_at(0), 0, Rect2(32, 48, 16, 16), Vector2(0,-8), 16)
	font.add_char(")".ord_at(0), 0, Rect2(48, 48, 16, 16), Vector2(0,-8), 16)
	font.update_changes()
	$Label.text = text
	$Label.add_font_override("font", font) # "font" here is a magic value.

func setText(newText = ""):
	self.text = newText
	$Label.text = newText;
