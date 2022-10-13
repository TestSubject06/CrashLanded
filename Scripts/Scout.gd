extends Enemy


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var state = "roaming"
var targetPos = null
var _player: Player
var _lander: Lander
var chase_target: Node2D
var rng = RandomNumberGenerator.new()
var turning = false
var lerp_weight = 0

var attack_timer = 0.7;
var attack_accumulator = 0;
var damage = 3;

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	$CanvasLayer.offset = position;
	$CanvasLayer.visible = false;

func set_targets(player: Player, lander: Lander):
	_player = player
	_lander = lander

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dead:
		return
		
	lerp_weight += delta
	do_state(delta)
	
	if health != max_health:
		$CanvasLayer.visible = true;
		$CanvasLayer/HealthBar/Bar.value = health / max_health;
		$CanvasLayer.offset = position;
		#$CanvasLayer/HealthBar.rotation = -rotation;
	else:
		$CanvasLayer.visible = false;
	

func do_state(delta):
	if !_player:
		return
		
	match(state):
		"roaming":
			#Pick a random point somewhere near either the player or the lander and move to it
			#When you arrive, pick a new point
			var velocity = Vector2(0, 0)
			if(!targetPos):
				var offset = Vector2(rng.randi_range(-200, 200), rng.randi_range(-200, 200))
				if randi() % 2 == 1:
					targetPos = _player.position + offset
				else:
					targetPos = _lander.position + offset
				turning = true
				lerp_weight = 0
				
			if(!turning):
				velocity = position.direction_to(targetPos) * 75
			else:
				rotation = lerp_angle(rotation, position.angle_to_point(targetPos) - PI/2, lerp_weight)
				if(abs(rotation - (position.angle_to_point(targetPos) - PI/2)) < 0.01 || lerp_weight > 0.4):
					rotation = position.angle_to_point(targetPos) - PI/2
					turning = false;
			
			# warning-ignore:return_value_discarded
			move_and_slide(velocity)
			
			if position.distance_squared_to(targetPos) < 10:
				targetPos = null
				velocity = null
		
		"chase":
			var velocity = position.direction_to(chase_target.position) * 125
			rotation = lerp_angle(rotation, position.angle_to_point(chase_target.position) - PI/2, 0.5)
			# warning-ignore:return_value_discarded
			move_and_slide(velocity)
			
			if position.distance_squared_to(chase_target.position) < 2500:
				attack_accumulator += delta;
				if(attack_accumulator > attack_timer):
					attack_accumulator -= attack_timer;
					chase_target.on_take_damage(damage, self);
			else:
				attack_accumulator = 0;
	

func change_state(new_state):
	exit_state(state)
	state = new_state
	enter_state(state)
	
# warning-ignore:shadowed_variable
func enter_state(state):
	match (state):
		"roaming":
			pass
		"chase":
			$VisionCone.set_deferred("monitoring", false);
			$AudioStreamPlayer.play(0.0);

# warning-ignore:shadowed_variable
func exit_state(state):
	match (state):
		"roaming":
			targetPos = null
		"chase":
			pass


func _on_Area2D_body_entered(body):
	#The player is the only thing that can enter here.
	if state != "chase":
		chase_target = body;
		change_state("chase")

# warning-ignore:shadowed_variable
func on_take_damage(damage: float, damage_point: Vector2, source: Node2D, piercing = false):
	
	if(state != "chase"):
		chase_target = source;
		change_state("chase")
		
	$BloodHit.position = to_local(damage_point);
	$BloodHit.rotation = $BloodHit.position.angle_to_point(source.position)
	$BloodHit.restart()
	if(piercing):
		#Armor piercing ignores 90% of armor
		health -= clamp((damage - (armor*.1)), 1, 999);
	else:
		health -= clamp((damage - armor), 1, 999);
	if health <= 0:
		.die();
		$Body.disabled = true
		$BloodDeath.restart()
		$Timer.start()
		$CanvasLayer.visible = false;
		$AudioStreamPlayer2.play(0.0);
		get_node("/root/Game").minerals += floor(rand_range(1, 3));
		get_node("/root/Game/UI").set_resources(get_node("/root/Game").minerals, get_node("/root/Game").silicates)


func _on_Timer_timeout():
	visible = false;
