extends KinematicBody2D
class_name Player


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (int) var speed = 200

var velocity = Vector2()
var delta_accumulator = 0
var mousePos = Vector2()
const QUARTER_STEP = PI/2
const FOOTSTEP_TIME = (0.0166 * 12)
var footstep_accumulator = 0

var footstep_pool = []
var footstep_pool_index = 0
var left = true;

onready var root = get_node("/root/Game")
var currentResources;
var mining = false;

var shot_timer = 0;
var shots_per_second = 8;
var damage = 5;
var armor = 0;
var max_health = 30;
var health = 30;
var mine_rate = 1.0;

func _ready():
	# Setup footstep pool
	var footstep_scene = preload("res://Instances/Footstep.tscn")
	for n in 15:
		var footstep = footstep_scene.instance()
		footstep.hide()
		get_node("/root/Game/GameWorld").call_deferred("add_child", footstep)
		footstep_pool.append(footstep)

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	velocity = velocity.normalized() * speed
	
func face_cursor():
	mousePos = get_global_mouse_position()
	rotation = atan2(mousePos.y - position.y, mousePos.x - position.x) + QUARTER_STEP
	$HealthBar.rotation = -rotation
	
func _process(delta):
	if health < max_health:
		health += max_health * 0.02 * delta;

	if health > max_health:
		health = max_health;
		
	if health != max_health:
		$HealthBar.visible = true;
		$HealthBar/Bar.value = health / max_health;
	else:
		$HealthBar.visible = false;
	pass

func _physics_process(delta):
	if(shot_timer > 0):
		shot_timer -= delta;
	# Mining
	var tileCords = root.get_tile_coords(position.x, position.y)
	currentResources = root.get_resources_at(tileCords.x, tileCords.y)
	
	if Input.is_action_pressed("Mine") && currentResources.mined_out == false:
		currentResources.progress += clamp((delta * mine_rate) / clamp((currentResources.difficulty / 1000), 0.0015, 0.08), 0, 100)
		mining = true
	else:
		# Movement
		mining = false;
		get_input()
		velocity = move_and_slide(velocity)
		handle_shot()
	
	# Aiming
	face_cursor()
	
	# Leave footsteps as we walk
	if(velocity.length() != 0):
		footstep_accumulator += delta
		if(footstep_accumulator > FOOTSTEP_TIME):
			footstep_accumulator -= FOOTSTEP_TIME
			var footstep = footstep_pool[footstep_pool_index]
			footstep_pool_index = wrapi(footstep_pool_index+1, 0, 14)
			footstep.position = position
			footstep.rotation = velocity.angle_to_point(Vector2(0, 0)) + QUARTER_STEP
			footstep.reset(left)
			left = !left

func handle_shot():
	if Input.is_action_pressed("Fire") && shot_timer <= 0:
		$Gunshot/Line2D.visible = true;
		$Tween.reset($Gunshot/Line2D, "modulate")
		$Tween.reset($Gunshot/Light2D, "color")
		$Tween.interpolate_property($Gunshot/Line2D, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.07,Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.interpolate_property($Gunshot/Light2D, "color", Color(1, 0.921569, 0.066667, 0.9), Color(1, 0.921569, 0.066667, 0), 0.07,Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Gunshot/ShotParticles.initial_velocity = 250 + (clamp(velocity.normalized().dot(Vector2(0,-1).rotated(rotation)), 0, 1)*speed)
		$Gunshot/ShotParticles.restart()
		var random_angle = rand_range(-4, 4);
		$Gunshot/Line2D.points[1].y = -450;
		$Gunshot/Line2D.rotation_degrees = random_angle;
		$Gunshot/RayCast2D.rotation_degrees = random_angle;
		$Gunshot/RayCast2D.force_raycast_update();
		$Tween.start()
		shot_timer += (1.0 / shots_per_second)
		
		handle_damage($Gunshot/RayCast2D.get_collider())
		$GunshotSound.pitch_scale = rand_range(0.7, 1.5);
		$GunshotSound.play(0.0);

func handle_damage(collider: CollisionObject2D):
	if(collider != null):
		var collision_point = $Gunshot/RayCast2D.get_collision_point();
		$Gunshot/Line2D.points[1].y = to_local(collision_point).y - $Gunshot.position.y
		if(collider is Enemy):
			(collider as Enemy).on_take_damage(damage, collision_point, self)
	
func on_take_damage(damage: float, source: Node2D):
	$HurtSound.play(0.0)
	health -= clamp(damage - armor, 1, 999);
	
	$Tween.reset($AnimatedSprite, "modulate")
	$Tween.interpolate_property($AnimatedSprite, "modulate", Color(1, 0, 0, 1), Color(1, 1, 1, 1), 0.07,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	
	$BloodHit.rotation = position.angle_to_point(source.position);
	$BloodHit.restart()
	
	if(health <= 0):
		Global.death_reason = "player"
		get_tree().change_scene("res://GameOver.tscn")
