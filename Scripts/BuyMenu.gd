extends VBoxContainer
signal on_menu_closed
signal on_item_chosen

var first_frame = true
onready var highlight_theme = preload("res://Theme.tres");

var menu_list = [
	{
		"text": "SOLDIER:",
		"children": [
			{
				"text": "ATTACK RATE + 2 SHOT/S",
				"mineral_cost": [30, 40, 50, 60, 70, 80, 90, 100],
				"silicate_cost": [2, 2, 2, 3, 3, 4, 5, 7],
				"upgrade_type": "SOLDIER_FIRE_RATE",
				"level": 0,
				"max_text": "ATTACK RATE - MAXED"
			},{
				"text": "DAMAGE + 2",
				"mineral_cost": [20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60],
				"silicate_cost": [0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 5],
				"upgrade_type": "SOLDIER_DAMAGE",
				"level": 0,
				"max_text": "DAMAGE - MAXED"
			},{
				"text": "ARMOR + 1",
				"mineral_cost": [30, 60, 90, 120, 150, 180, 210, 250],
				"silicate_cost": [2, 2, 3, 3, 5, 5, 7, 7],
				"upgrade_type": "SOLDIER_ARMOR",
				"level": 0,
				"max_text": "ARMOR - MAXED"
			},{
				"text": "MAX HEALTH + 5",
				"mineral_cost": [30, 40, 50, 60, 70, 80, 90, 100],
				"silicate_cost": [1, 1, 2, 2, 3, 3, 4, 5],
				"upgrade_type": "SOLDIER_MAX_HEALTH",
				"level": 0,
				"max_text": "MAX HEALTH - MAXED"
			},{
				"text": "MOVEMENT SPEED + 20 UNITS/S",
				"mineral_cost": [100, 150, 200, 250, 300],
				"silicate_cost": [8, 9, 10, 11, 12],
				"upgrade_type": "SOLDIER_MOVE_SPEED",
				"level": 0,
				"max_text": "MOVEMENT SPEED - MAXED"
			},{
				"text": "MINING RATE + 20%",
				"mineral_cost": [50, 100, 150, 200, 250, 300],
				"silicate_cost": [0, 0, 1, 2, 3, 5],
				"upgrade_type": "SOLDIER_MINE_SPEED",
				"level": 0,
				"max_text": "MINING RATE - MAXED"
			}
		]
	},{
		"text": "TURRET:",
		"children": [
			{
				"text": "ATTACK RATE + 2 SHOT/S",
				"mineral_cost": [40, 80, 120, 160, 200, 250],
				"silicate_cost": [2, 4, 8, 10, 12, 15],
				"upgrade_type": "TURRET_FIRE_RATE",
				"level": 0,
				"max_text": "ATTACK RATE - MAXED"
			},{
				"text": "DAMAGE + 4",
				"mineral_cost": [20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 250],
				"silicate_cost":[2, 2, 2, 4, 4, 4, 6, 6, 9, 12, 15],
				"upgrade_type": "TURRET_DAMAGE",
				"level": 0,
				"max_text": "DAMAGE - MAXED"
			},{
				"text": "TARGETING SPEED - 0.1S",
				"mineral_cost": [80, 120, 160, 200, 240, 280],
				"silicate_cost": [2, 2, 4, 4, 8, 8],
				"upgrade_type": "TURRET_AIM_SPEED",
				"level": 0,
				"max_text": "TARGETING SPEED - MAXED"
			},{
				"text": "TARGETING RANGE + 25 UNITS",
				"mineral_cost": [60, 90, 120, 150, 180, 210],
				"silicate_cost": [5, 5, 5, 5, 5, 10],
				"upgrade_type": "TURRET_RANGE",
				"level": 0,
				"max_text": "TARGETING RANGE - MAXED"
			},{
				"text": "ARMOR PIERCING ROUNDS",
				"mineral_cost": [500],
				"silicate_cost": [50],
				"upgrade_type": "TURRET_AP",
				"level": 0,
				"max_text": "ARMOR PIERCING ROUNDS - MAXED"
			}
		]
	},{
		"text": "SHUTTLE:",
		"children": [
			{
				"text": "ARMOR + 5",
				"mineral_cost": [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 600],
				"silicate_cost": [0, 1, 2, 4, 6, 9, 12, 16, 20, 30, 50],
				"upgrade_type": "SHUTTLE_ARMOR",
				"level": 0,
				"max_text": "ARMOR - MAXED"
			},{
				"text": "MAX HEALTH + 15",
				"mineral_cost": [100, 120, 140, 160, 180, 200, 220, 240, 260, 280, 300],
				"silicate_cost": [0, 0, 0, 1, 1, 2, 2, 4, 4, 6, 8],
				"upgrade_type": "SHUTTLE_MAX_HEALTH",
				"level": 0,
				"max_text": "MAX HEALTH - MAXED"
			},{
				"text": "THRUSTER REPAIR",
				"mineral_cost": [2500],
				"silicate_cost": [250],
				"upgrade_type": "SHUTTLE_REPAIR",
				"level": 0,
				"max_text": "THRUSTER REPAIR - MAXED"
			}
		]
	},
]

var selected_item = 0;
var selectable_elements = []
onready var root = get_node("/root/Game")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if(visible == false):
		return;

	if Input.is_action_just_pressed("open_menu") && !first_frame:
		emit_signal("on_menu_closed")
	
	if selectable_elements.size() > 0:
		if Input.is_action_just_pressed("ui_up"):
			var old_item = selectable_elements[selected_item];
			selected_item = wrapi(selected_item - 1, 0, selectable_elements.size())
			var new_item = selectable_elements[selected_item];
			
			old_item.element.setText(get_text_for_element(old_item.data, false))
			old_item.element.theme = null
			new_item.element.setText(get_text_for_element(new_item.data, true))
			new_item.element.theme = highlight_theme
			$AudioStreamPlayer2.play(0.0);
			
		if Input.is_action_just_pressed("ui_down"):
			var old_item = selectable_elements[selected_item];
			selected_item = wrapi(selected_item + 1, 0, selectable_elements.size())
			var new_item = selectable_elements[selected_item];
			
			old_item.element.setText(get_text_for_element(old_item.data, false))
			old_item.element.theme = null
			new_item.element.setText(get_text_for_element(new_item.data, true))
			new_item.element.theme = highlight_theme
			
			$AudioStreamPlayer2.play(0.0);
		
		if Input.is_action_just_pressed("ui_accept"):
			emit_signal("on_item_chosen", selectable_elements[selected_item].data)
			selectable_elements[selected_item].data.level += 1
			selectable_elements[selected_item].element.setText(get_text_for_element(selectable_elements[selected_item].data, true))
			$Tween.reset_all()
			$Tween.interpolate_property(selectable_elements[selected_item].element, "modulate", Color(0, 1, 0, 1), Color(1, 1, 1, 1), 0.2)
			$Tween.start()
			update_elements()
			
			$AudioStreamPlayer.pitch_scale = rand_range(0.9, 1.1);
			$AudioStreamPlayer.play(0.0);
		
	first_frame = false
	pass

func show():
	.show()
	first_frame = true;
	var item_list = $MarginContainer/VBoxContainer/BuyContainer/NinePatchRect2/MarginContainer/ItemList
	for child in item_list.get_children():
		child.queue_free()
	selectable_elements.clear()
	selected_item = 0
		
	var text_scene = preload("res://Instances/BitmapText.tscn")
	for group in menu_list:
		var text = text_scene.instance()
		text.setText(group.text)
		item_list.call_deferred("add_child", text)
		
		for child in group.children:
			text = text_scene.instance()
			text.setText(get_text_for_element(child, false))
			if child.level == child.mineral_cost.size() || root.minerals < child.mineral_cost[child.level] || root.silicates < child.silicate_cost[child.level]:
				text.modulate = Color(1,1,1,0.5)
			else:
				selectable_elements.push_back({"data": child, "element": text})
			item_list.call_deferred("add_child", text)
	
	if selectable_elements.size() > 0:
		selectable_elements[selected_item].element.setText(get_text_for_element(selectable_elements[selected_item].data, true))
		selectable_elements[selected_item].element.theme = highlight_theme

func update_elements():
	var elements_to_remove = []
	
	for n in range(selectable_elements.size()):
		var element = selectable_elements[n]
		if element.data.level == element.data.mineral_cost.size() || root.minerals < element.data.mineral_cost[element.data.level] || root.silicates < element.data.silicate_cost[element.data.level]:
			$Tween.interpolate_property(element.element, "modulate", null, Color(1,1,1,0.5), 0.25)
			$Tween.start()
			element.element.setText(get_text_for_element(element.data, false))
			element.element.theme = null
			elements_to_remove.push_front(n)
	
	if(elements_to_remove.size() == selectable_elements.size()):
		selectable_elements.clear();
		selected_item = 0;
	elif(elements_to_remove.size() > 0):
		for n in elements_to_remove:
			if(n < selected_item):
				selected_item = selected_item - 1
			elif( n == selected_item):
				selected_item = 0
			selectable_elements.remove(n)
		
		var new_item = selectable_elements[selected_item];
		new_item.element.setText(get_text_for_element(new_item.data, true))
		new_item.element.theme = highlight_theme

func get_text_for_element(element, selected):
	if(element.level == element.mineral_cost.size()):
		return "  " + element.max_text
	
	var mineral_cost = ""
	if(element.mineral_cost[element.level] > 0):
		mineral_cost = String(element.mineral_cost[element.level]) + " @"
	var silicate_cost = ""
	if(element.silicate_cost[element.level] > 0):
		silicate_cost = String(element.silicate_cost[element.level]) + " #"
	var spacer = ""
	if element.silicate_cost[element.level] > 0 && element.mineral_cost[element.level] > 0:
		spacer = "  "
	var padder = "  "
	if selected:
		padder = " >"
	var cost = mineral_cost + spacer + silicate_cost
	var line_item = padder + element.text + ":"
	return "%-40s%s" % [line_item, cost]
