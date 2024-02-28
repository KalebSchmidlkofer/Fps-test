extends CharacterBody3D

## Mouse sensitivity
@export var sensitivity = 0.01
## Invert camera on the y-axis
@export var invert_y : bool
## Invert camera on the x-axis
@export var invert_x : bool
## How many double jumps the player has
@export var double_jumps:int=1
## How strong the double jump is
@export_range(0, 30, 0.2) var double_jump_power: float = 10
## Default Speed for the player
@export_range(-10, 1500, 0.2) var character_speed: float = 5.0
## How high default jump is for the player
@export_range(-10, 60, 0.2) var character_jump: float = 4.6
## How Many walljumps you have
@export_range(1, 60, 1) var wall_jumps: int = 1
## How far on the x-axis you jump off of walls
@export_range(2, 100, 0.2) var wall_jump_speed: float = 10.4
## How Many Dashes you have
@export_range(1, 100, 1) var air_dash: int = 1
## How fast you dash
@export_range(1, 100, 0.2) var dash_speed: float = 5.0
## What to multiply by when holding shift
@export_range(2, 60, 0.5) var multiply_run: float = 3.0
## How much stamina you have
@export_range(1, 15000, 5) var staminabase: float = 20
## Default slide resistance
@export_range(1, 100, 0.2) var slide_resistance: float = 5.0
## Default Size of The Player
@export_range(1, 100, 0.2) var default_size: float = 1.0
## What size to divide by when crouch is held
@export_range(0, 100, 0.2) var slide_size: float = 0.5
## Default Gravity
@export_range(1, 100, 0.2) var gravity: float = 9.8


var stamina=staminabase
var current_double_jumps=double_jumps
var current_wall_jumps=wall_jumps
var current_air_dash=air_dash
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var thirdneck := $"3rdPersonNeck"
@onready var thirdcamera := $"3rdPersonNeck/Camera3D"
@onready var uncrouchray := $avoidanceCeiling
@onready var player := $"."
@onready var grappleray := $Neck/Camera3D/ghookray

var is_running:bool = false
var sliding:bool = false
var default_gravity = 0
func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if invert_x:
				neck.rotate_y(event.relative.x * sensitivity)
			else:
				neck.rotate_y(-event.relative.x * sensitivity)
			if invert_y:
				camera.rotate_x(event.relative.y * sensitivity)
			else:
				camera.rotate_x(-event.relative.y * sensitivity)
				
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
func _ready():
	stamina+=staminabase-stamina
	default_gravity=gravity
	
		
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_on_floor():
		current_double_jumps = double_jumps
		current_wall_jumps = wall_jumps
	
	if is_on_wall():
		player.gravity=0
	else:
		player.gravity=default_gravity
		pass
		
		
	# Handle jump.
	if Input.is_action_pressed('run') and not is_running and not stamina <= 0:
		is_running=true
		character_speed = character_speed*multiply_run
		
	elif is_running and not Input.is_action_pressed('run'):
		character_speed = character_speed / multiply_run
		is_running=false
		
	if is_running:
		stamina-=1
		if stamina <=0:
			is_running=false
			character_speed = character_speed / multiply_run
	else:
		if stamina < staminabase:
			stamina+=1
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()		

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += character_jump
		
	if Input.is_action_just_pressed("jump") and is_on_wall() and current_wall_jumps > 0:
		current_wall_jumps-=1
		velocity.y = character_jump/1.2
		velocity.x = character_jump*wall_jump_speed
		
	if Input.is_action_just_pressed("jump") and current_double_jumps > 0 and not is_on_floor() and not is_on_wall():
		current_double_jumps-=1
		velocity.y = 0
		velocity.y += double_jump_power
	if Input.is_action_just_pressed("dash") and air_dash > 0:
		velocity.x = direction.x * dash_speed * delta
		velocity.z = direction.z * dash_speed * delta
	
	if Input.is_action_pressed("slide") and not sliding:
		sliding=true
		player.scale.y = player.scale.y/slide_size
		uncrouchray.scale.y=uncrouchray.scale.y*slide_size
		move_and_slide()

	if not Input.is_action_pressed('slide') and sliding and not uncrouchray.is_colliding():
		sliding=false
		player.scale.y = player.scale.y*slide_size
		uncrouchray.scale.y=uncrouchray.scale.y/slide_size
	
	if Input.is_action_just_pressed("grapple"):
		if grappleray.is_colliding():
			var collision_point = grappleray.get_collision_point()
			global_transform.origin = collision_point
	
	if direction:
		velocity.x = direction.x * character_speed * delta
		velocity.z = direction.z * character_speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0, character_speed)
		velocity.z = move_toward(velocity.z, 0, character_speed)

	move_and_slide()
