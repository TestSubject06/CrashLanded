extends Node2D

var speeds = [30, 70];
var time = 0;
var time_scale = 0;
var bright = false;
var free_entities = [];
var previous_origin_in_tiles = Vector2(0,0)
var tile_clusters = {};

onready var rng = RandomNumberGenerator.new();
onready var game: Orchestrator = get_node("/root/Game");
onready var root_camera: Camera2D = get_node("/root/Game/Player/Camera2D");
onready var pip_scene = preload("res://Instances/ScannerPip.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Prepare the pip pool
	for n in 150:
		var pip = pip_scene.instance();
		pip.use_parent_material = true;
		
		free_entities.push_back(pip);
	
	# Initialize the pip tile map
	initialize_resource_map();

func initialize_resource_map():
	for tile_x in 8:
		for tile_y in 5:
			set_tile_cluster_at(tile_x, tile_y);
	pass;
	
func clear_tile_cluster_at(tile_x, tile_y):
	if tile_x == 0 && tile_y == 0:
		return;
	
	if(tile_clusters.has("%d, %d" % [tile_x, tile_y])):
		var cluster = tile_clusters["%d, %d" % [tile_x, tile_y]];
		
		for entity in cluster.entities:
			free_node(entity);
		
		tile_clusters.erase("%d, %d" % [tile_x, tile_y]);
	pass
	
func set_tile_cluster_at(tile_x, tile_y):
	if tile_x == 0 && tile_y == 0:
		return;
	
	if(tile_clusters.has("%d, %d" % [tile_x, tile_y])):
		return;
		
	var resources = game.get_resources_at(tile_x, tile_y);
	
	if(resources.mined_out):
		return;

	rng.seed = resources.scatter_seed;
	
	var tile_cluster = {
		"tile_x": tile_x,
		"tile_y": tile_y,
		"entities": []
	}
	
	for n in (1 + floor((resources.minerals + (resources.silicates * 2)) / 15)):
		var pip = get_free_pip(); # Removes the pip from the pool.
		pip.centered = true;
		var pip_scale = rng.randf_range(0.5, 2);
		pip.scale.x = pip_scale
		pip.scale.y = pip_scale
		pip.position.x = rng.randi_range((tile_x + 0.2) * 96, (tile_x + 0.8) * 96);
		pip.position.y = rng.randi_range((tile_y + 0.2) * 96, (tile_y + 0.8) * 96);
		tile_cluster.entities.push_back(pip); # Keep track of the pip
	
	tile_clusters["%d, %d" % [tile_x, tile_y]] = tile_cluster;
	
func move_tile_clusters(new_tile_origin: Vector2, previous_tile_origin: Vector2):
	if new_tile_origin.is_equal_approx(previous_origin_in_tiles):
		return;
	
	# Process X direction first, then Y
	
	# "window" has moved left
	if(new_tile_origin.x > previous_tile_origin.x):
		var difference = new_tile_origin.x - previous_tile_origin.x;
		for n in difference:
			# Free all elements with a tile_x of previous.x + n, keep track of tile_y
			for y in range(previous_tile_origin.y, previous_tile_origin.y + 5):
				clear_tile_cluster_at(previous_tile_origin.x + n, y);
				set_tile_cluster_at(previous_tile_origin.x + n + 8, y);
			# Establish new elements with a tile_x of previous.x + n + 8, with tracked tile_y
	elif(new_tile_origin.x < previous_tile_origin.x):
		var difference = previous_tile_origin.x - new_tile_origin.x;
		for n in difference:
			# Free all elements with a tile_x of previous.x + n, keep track of tile_y
			for y in range(previous_tile_origin.y, previous_tile_origin.y + 5):
				clear_tile_cluster_at((previous_tile_origin.x - n) + 7, y);
				set_tile_cluster_at((previous_tile_origin.x - n) - 1, y);
				
	# Process Y direction after having "moved" the window along the X axis
	if(new_tile_origin.y > previous_tile_origin.y):
		var difference = new_tile_origin.y - previous_tile_origin.y;
		for n in difference:
			for x in range(new_tile_origin.x, new_tile_origin.x + 8):
				clear_tile_cluster_at(x, previous_tile_origin.y + n);
				set_tile_cluster_at(x, previous_tile_origin.y + n + 5);
	elif(new_tile_origin.y < previous_tile_origin.y):
		var difference = previous_tile_origin.y - new_tile_origin.y;
		for n in difference:
			for x in range(new_tile_origin.x, new_tile_origin.x + 8):
				clear_tile_cluster_at(x, (previous_tile_origin.y - n) + 4);
				set_tile_cluster_at(x, (previous_tile_origin.y - n) -1);
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_pressed("Scanner")):
		visible = true;
	else:
		visible = false;
		
	# Flicker control
	bright = !bright;
	if bright:
		modulate.a = 0.95;
	else:
		modulate.a = 0.25;
		
	# Shader control
	time += delta;
	time_scale = sin(time*5)/2.0 + 0.5;
	$Clusters.material.set_shader_param("time_scale", time_scale)
	$BackBufferCopy2/Sweeper1.position.y += speeds[0]*delta;
	$BackBufferCopy/Sweeper2.position.y += speeds[1]*delta;
	
	if $BackBufferCopy2/Sweeper1.position.y > get_viewport_rect().size.y:
		$BackBufferCopy2/Sweeper1.position.y = - 60
		speeds[0] = rand_range(25, 45);
	
	if $BackBufferCopy/Sweeper2.position.y > get_viewport_rect().size.y:
		$BackBufferCopy/Sweeper2.position.y = - 20
		speeds[1] = rand_range(50, 80);
	
	# Cluster Control
	#print("Clusters: ", (root_camera.get_viewport_transform().affine_inverse().origin / 96).floor())
	var new_origin_in_tiles = (root_camera.get_viewport_transform().affine_inverse().origin / 96).floor();
	$Clusters.position = root_camera.get_viewport_transform().origin
	move_tile_clusters(new_origin_in_tiles, previous_origin_in_tiles);
	previous_origin_in_tiles = (root_camera.get_viewport_transform().affine_inverse().origin / 96).floor();
	

func get_free_pip() -> Node2D:
	var node;
	if free_entities.size() > 0:
		node = free_entities.pop_back();
	else:
		node = pip_scene.instance();
	
	$Clusters.add_child(node);
	return node;
	
func free_node(node: Node2D):
	$Clusters.remove_child(node);
	free_entities.push_back(node);


func _on_Game_on_tile_mined(tile_coords):
	clear_tile_cluster_at(tile_coords.x, tile_coords.y)
	pass # Replace with function body.
