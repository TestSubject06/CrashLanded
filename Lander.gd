extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var target: Enemy = null;
var attack_range = 150;
var aiming = false;
var lerp_weight = 0;
var left = true;

var damage = 0;
var shots_per_second = 6;
var aim_delay = 0.7;
var armor_piercing = false;
var attack_timer = 0;

var max_health = 150;
var health = 150;
var armor = 2;

onready var turret_position = to_global($Turret.position)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !target:
		# Attempt to acquire a target
		var potentialTarget = get_node("/root/Game").get_enemy_within_range(turret_position, attack_range)
		if potentialTarget:
			target = potentialTarget
			$TargetingTimer.wait_time = clamp(aim_delay, 0.01, 999)
			$TargetingTimer.start()
			aiming = true;
	else:
		$Turret.rotation = lerp_angle($Turret.rotation, turret_position.angle_to_point(target.position) - PI/2, 0.3)
		
		if(turret_position.distance_to(target.position) > attack_range):
			target = null;
			aiming = false;
	
	if target && !aiming:
		attack_timer -= delta;
		if attack_timer <= 0:
			attack_timer += (1.0 / shots_per_second);
			target.on_take_damage(damage, target.position, self, armor_piercing)
			handle_gunshot()
			if target.dead:
				target = null
	
	if health < max_health:
		health += max_health * 0.02 * delta;

	if health > max_health:
		health = max_health;
	
	if health != max_health:
		$CanvasLayer.visible = true;
		$CanvasLayer/HealthBar/Bar.value = health / max_health;
		$CanvasLayer.offset = position;
		#$CanvasLayer/HealthBar.rotation = -rotation;
	else:
		$CanvasLayer.visible = false;
	pass

func handle_gunshot():
	if(left):
		$Turret/Gunshot.position.x = 8;
	else:
		$Turret/Gunshot.position.x = -8
	left = !left
	$Turret/Gunshot/Line2D.visible = true;
	$Tween.reset($Turret/Gunshot/Line2D, "modulate")
	$Tween.reset($Turret/Gunshot/Light2D, "color")
	$Tween.interpolate_property($Turret/Gunshot/Line2D, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.07,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.interpolate_property($Turret/Gunshot/Light2D, "color", Color(1, 0.921569, 0.066667, 0.9), Color(1, 0.921569, 0.066667, 0), 0.07,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Turret/Gunshot/ShotParticles.restart()
	$Turret/Gunshot/Line2D.points[1].y = -turret_position.distance_to(target.position)
	$Tween.start()
	
	$AudioStreamPlayer2D.pitch_scale = rand_range(0.9, 1.1);
	$AudioStreamPlayer2D.play(0.0);

func _on_TargetingTimer_timeout():
	aiming = false;

func on_take_damage(damage: float, source: Node2D):
	$DamageSparks.rotation = position.angle_to_point(source.position) + PI/2;
	$DamageSparks.restart();
	$Tween.interpolate_property($LanderSprite, "modulate", Color(0.835294, 0, 0.666667), Color(1, 1, 1, 1), 0.06)
	$Tween.start();
	
	health -= clamp(damage - armor, 1, 999);
	if(health <= 0):
		Global.death_reason = "lander"
		get_tree().change_scene("res://GameOver.tscn")
	pass
