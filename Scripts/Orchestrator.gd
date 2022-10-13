extends Node2D
class_name Orchestrator
signal on_tile_mined

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (Curve) var difficulty;
export (Curve) var scout_armor_curve;
export (Curve) var scout_damage_curve;
export (Curve) var scout_health_curve;

#var time = 19
var resourceTable = {}
var playerTilePosition = Vector2(0,0)
var rng = RandomNumberGenerator.new()
var minerals = 0
var silicates = 0
var spawn_rate = 99;
var day = 0;
onready var scout_enemy = preload("res://Instances/Scout.tscn")

var scout_armor = 1;
var scout_max_health = 10;
var scout_damage = 3;

# Day ranges from 0-20
# Night ranges from 20-40
# Wrap back to 0
var time_of_day = 0;

func _init():
	rng.seed = hash(Time.get_unix_time_from_system());
	print("seed: ", rng.seed);

# Called when the node enters the scene tree for the first time.
func _ready():
	$UI.set_resources(minerals, silicates)
	$SpawnTimer.wait_time = spawn_rate;
	$SpawnTimer.start()
	scale_enemies(day)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta):
	process_time_of_day(delta);
	
	playerTilePosition = get_tile_coords($Player.position.x, $Player.position.y)
	$GroundSelector.position = playerTilePosition * 96
	var resources = get_resources_at(playerTilePosition.x, playerTilePosition.y)
	$GroundSelector.set_resources(resources)
	
	if resources.progress >= 100 && resources.mined_out == false:
		resources.mined_out = true
		minerals += resources.minerals
		silicates += resources.silicates
		$MiningSuccessText.reset(
			Vector2($Player.position.x - 20, $Player.position.y - 30), 
			resources.minerals, 
			resources.silicates
		)
		$UI.set_resources(minerals, silicates)
		$MineSound.play(0.0)
		emit_signal("on_tile_mined", playerTilePosition)
	
func get_tile_coords(x, y):
	return Vector2(floor(x/96), floor(y/96))

func get_resources_at(tileX, tileY):
	var key = "{x},{y}".format({"x": tileX, "y": tileY})
	if !resourceTable.has(key):
		# Create resource
		var distanceToHome = Vector2(tileX, tileY).length_squared()
		var silicatesDist = get_silicate_distribution(distanceToHome)
		var mineralsDist = get_mineral_distribution(distanceToHome)
		
		resourceTable[key] = {
			"scatter_seed": rng.randi(),
			"minerals": clamp(floor(rng.randfn(mineralsDist.mean, mineralsDist.dev)), 1, 50),
			"silicates": clamp(floor(rng.randfn(silicatesDist.mean, silicatesDist.dev)), 0, 10),
			"mined_out": false,
			"progress": 0,
			"difficulty": distanceToHome
		}
		# print(resourceTable[key])
	return resourceTable[key]

func get_silicate_distribution(distanceSquared):
	if distanceSquared < 10:
		return {"mean": 0.0, "dev": 0.5}
	if(distanceSquared < 25):
		return {"mean": 2.0, "dev": 0.6}
	return {"mean": 5.0, "dev": 0.8}
	
func get_mineral_distribution(distanceSquared):
	if distanceSquared < 10:
		return {"mean": 7, "dev": 2}
	if(distanceSquared < 25):
		return {"mean": 20.0, "dev": 6}
	return {"mean": 50, "dev": 10}

func get_enemy_within_range(position: Vector2, attack_range: float) -> Enemy:
	for node in $GameWorld/Enemies.get_children():
		if position.distance_to(node.position) < attack_range && !node.dead:
			return (node as Enemy)
	return null

func _on_Timer_timeout():
	var scout = scout_enemy.instance()
	scout.set_targets($Player, $GameWorld/Lander)
	var offset = (400 * Vector2(1, 0).rotated(rand_range(0, 2*PI)));
	if rng.randi() % 2 == 1:
		scout.position = $Player.position + offset;
	else:
		scout.position = $GameWorld/Lander.position + offset;
		
		# If the enemy would spawn on-screen - retry the spawn.
		var viewport_world = get_viewport_rect()
		viewport_world.position -= get_viewport_transform().origin
		while(viewport_world.has_point(scout.position)):
			offset = (400 * Vector2(1, 0).rotated(rand_range(0, 2*PI)));
			scout.position = $GameWorld/Lander.position + offset;
		
	# Scout stats are scaled with # days
	scout.max_health = scout_max_health;
	scout.health = scout_max_health;
	scout.armor = scout_armor;
	scout.damage = scout_damage;
	
	get_node("/root/Game/GameWorld/Enemies").call_deferred("add_child", scout)
	pass # Replace with function body.

func _on_BuyMenu_on_menu_closed():
	get_tree().paused = false;
	$UI/BuyMenu.hide()
	pass # Replace with function body.


func _on_BuyMenu_on_item_chosen(data):
	minerals -= data.mineral_cost[data.level];
	silicates -= data.silicate_cost[data.level];
	$UI.set_resources(minerals, silicates)
	
	match(data.upgrade_type):
		"SOLDIER_DAMAGE":
			$Player.damage += 2;
		"SOLDIER_FIRE_RATE":
			$Player.shots_per_second += 2;
		"SOLDIER_ARMOR":
			$Player.armor += 1;
		"SOLDIER_MOVE_SPEED":
			$Player.speed += 20;
		"SOLDIER_MAX_HEALTH":
			$Player.max_health += 5;
			$Player.health += 5;
		"SOLDIER_MINE_SPEED":
			$Player.mine_rate += 0.2;
		"TURRET_DAMAGE":
			$GameWorld/Lander.damage += 4;
		"TURRET_FIRE_RATE":
			$GameWorld/Lander.shots_per_second += 2;
		"TURRET_AIM_SPEED":
			$GameWorld/Lander.aim_delay -= .1;
		"TURRET_RANGE":
			$GameWorld/Lander.attack_range += 25;
		"TURRET_AP":
			$GameWorld/Lander.armor_piercing = true;
		"SHUTTLE_MAX_HEALTH":
			$GameWorld/Lander.max_health += 15;
			$GameWorld/Lander.health += 15;
		"SHUTTLE_ARMOR":
			$GameWorld/Lander.armor += 5;
		"SHUTTLE_REPAIR":
			if get_tree().change_scene("res://Scenes/Victory.tscn") != OK:
				print("Failed to transition to Victory scene from main scene.")
			pass
	pass # Replace with function body.

func process_time_of_day(delta):
	var old_time = time_of_day;
	time_of_day += delta;
	$UI/GUI/HBoxContainer/ClockContainer/Clock.rotation = (-(time_of_day/40) * (PI*2)) + (PI/2)
	var time_changed = false;
	
	# Mid-day
	if old_time < 10 && time_of_day > 10:
		time_changed = true
		$TimeOfDayTweener.interpolate_property($GameWorld, "modulate", null, Color(1, 1, 1, 1), 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "texture_scale", null, 2, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "texture_scale", null, 2, 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "energy", null, 1, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "energy", null, 1, 1)
		$TimeOfDayTweener.start()
		
		spawn_rate = (1-difficulty.interpolate(clamp(day/25, 0, 1))) * 6.0;
		
	# Early Night
	if old_time < 20 && time_of_day > 20:
		time_changed = true
		$TimeOfDayTweener.interpolate_property($GameWorld, "modulate", null, Color(0.407843, 0.658824, 0.839216), 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "texture_scale", null, 2.5, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "texture_scale", null, 2.5, 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "energy", null, 1.5, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "energy", null, 1.5, 1)
		$TimeOfDayTweener.start()

		spawn_rate = clamp((1-difficulty.interpolate(clamp(day/25, 0, 1))) * 1.1, 0.2, 1.1);
		$MenuOpenTimer.start()
		
	# Late Night
	if old_time < 30 && time_of_day > 30:
		time_changed = true
		$TimeOfDayTweener.interpolate_property($GameWorld, "modulate", null, Color(0.129501, 0.283358, 0.808594), 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "texture_scale", null, 3, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "texture_scale", null, 3, 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "energy", null, 2.5, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "energy", null, 2.5, 1)
		$TimeOfDayTweener.start()
		
		spawn_rate = clamp((1-difficulty.interpolate(clamp(day/25, 0, 1))) * 0.5, 0.2, 0.6);
		
	# Early Morning
	if old_time < 40 && time_of_day > 40:
		time_changed = true
		time_of_day -= 40;
		day += 1;
		scale_enemies(day);
		
		$TimeOfDayTweener.interpolate_property($GameWorld, "modulate", null, Color(0.870588, 0.678431, 0.956863), 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "texture_scale", null, 2.5, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "texture_scale", null, 2.5, 1)
		$TimeOfDayTweener.interpolate_property($Player/Gunshot/Light2D, "energy", null, 1, 1)
		$TimeOfDayTweener.interpolate_property($GameWorld/Lander/Turret/Gunshot/Light2D, "energy", null, 1, 1)
		$TimeOfDayTweener.start()
		spawn_rate = 99.0;
	
	if time_changed:
		$SpawnTimer.wait_time = spawn_rate;
		$SpawnTimer.stop()
		$SpawnTimer.start()

# warning-ignore:shadowed_variable
func scale_enemies(day):
	scout_armor = scout_armor_curve.interpolate(clamp(day/40.0, 0, 1))
	scout_max_health = scout_health_curve.interpolate(clamp(day/40.0, 0, 1))
	scout_damage = scout_damage_curve.interpolate(clamp(day/40.0, 0, 1))

func _on_MenuOpenTimer_timeout():
	get_tree().paused = true;
	$UI/BuyMenu.show()
