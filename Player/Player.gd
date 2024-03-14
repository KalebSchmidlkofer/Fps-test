extends CharacterBody3D

@onready var WallRunTimer = $Wall_run_timer
@export_category('Camera')
## Mouse sensitivity
@export var sensitivity = 0.01
## Invert camera on the y-axis
@export var invert_y : bool
## Invert camera on the x-axis
@export var invert_x : bool

@export_category('Run/Walk')
## Default Speed for the player
@export_range(-10, 1500, 0.2) var character_speed: float = 5.0
## What to multiply by when holding shift
@export_range(2, 60, 0.5) var multiply_run: float = 3.0
## How much stamina you have
@export_range(1, 15000, 5) var staminabase: float = 20

@export_category('Fly')
## Flight Speed
@export_range(1, 1500, .2) var flight_speed: float = 10
## How much to multiply flight speed when holding shift
@export_range(1, 60, .2) var multiply_flight_speed: float = 2
## How fast you move up and down
@export_range(1, 1500, .2) var flight_xy_speed: float = 10
## How much to multiply flight_xy speed when holding shift
@export_range(1, 60, .2) var multiply_xyflight_speed: float = 2



@export_category('Wall Running')
## How Many walljumps you have
@export_range(1, 60, 1) var wall_run_max_time: float = 1
## How far on the x-axis you jump off of walls
@export_range(2, 100, 0.2) var wall_run_speed: float = 10.4
## How Long Your allowed to wall run for
@export var wall_run_timer: Timer = WallRunTimer

@export_category('Jumps')
## How many double jumps the player has
@export var double_jumps:int=1
## How strong the double jump is
@export_range(0, 30, 0.2) var double_jump_power: float = 10

## How high default jump is for the player
@export_range(-10, 60, 0.2) var character_jump: float = 4.6

@export_category('Dash')
## How Many Dashes you have
@export_range(1, 100, 1) var air_dash: int = 1
## How fast you dash
@export_range(1, 100, 0.2) var dash_speed: float = 5.0

@export_category('Slide')
## Default slide resistance
@export_range(1, 100, 0.2) var slide_resistance: float = 5.0
## Default speed for sliding
@export var slide_speed: float = 10.0 # Speed of the slide
## Default Size of The Player
@export_range(1, 100, 0.2) var default_size: float = 1.0
## What size to divide by when crouch is held
@export_range(0, 100, 0.2) var slide_size: float = 0.5
## What size to divide by when crouch is held
@export var slide_deceleration: float = 5.0 # Rate at which the slide slows down
@export var slide_min_speed: float = 2.0 # Minimum speed to consider the slide finished

@export_category('Gravity')
## Default Gravity
@export_range(1, 100, 0.2) var gravity: float = 18



var stamina=staminabase
var current_double_jumps=double_jumps
var current_air_dash=air_dash
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var thirdneck := $"3rdPersonNeck"
@onready var thirdcamera := $"3rdPersonNeck/3rdPersonCamera"
@onready var uncrouchray := $avoidanceCeiling
@onready var player := $"."

var is_speed_flying:bool=false
var flightcheck:bool=false
var is_flying:bool = false
var is_running:bool = false
var wall_running:bool = false
var is_sliding:bool = false
var slide_velocity: Vector3 = Vector3.ZERO
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
	

func wall_run(delta):
	if Input.is_action_pressed('forward') and is_on_wall():
		player.gravity=0
		var wall_running=true
	
	else:
		var wall_running=true
		pass



func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_on_floor():
		current_double_jumps = double_jumps
	
	player.gravity=default_gravity
		
	#wall_run()
	# Handle jump.
	if Input.is_action_just_pressed('fly'):
		if is_flying:
			is_flying = false
		else:
			is_flying = true
	if is_flying:
		fly_mode(delta)
	else:
		flightcheck=false
		normal_mode(delta)
		

func fly_mode(delta):
	if not flightcheck:
		flightcheck=true
		gravity=0
		print('Flight Mode Engaged')
	
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if not Input.is_action_pressed("jump") and not Input.is_action_pressed("slide"):
		velocity.y = 0	

	if Input.is_action_pressed("jump"):
		velocity.y = flight_xy_speed
	if Input.is_action_pressed("slide"):
		velocity.y = flight_xy_speed * -1
	if Input.is_action_pressed("run") and not is_speed_flying:
		is_speed_flying=true
		flight_speed=flight_speed*multiply_flight_speed
		flight_xy_speed=flight_xy_speed*multiply_xyflight_speed
	elif is_speed_flying and not Input.is_action_pressed("run"):
		flight_speed=flight_speed/multiply_flight_speed
		flight_xy_speed=flight_xy_speed/multiply_xyflight_speed
		is_speed_flying=false
	
	
	
	if direction:
		velocity.x = direction.x * flight_speed * delta
		velocity.z = direction.z * flight_speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0, flight_speed)
		velocity.z = move_toward(velocity.z, 0, flight_speed)

	move_and_slide()
		
func normal_mode(delta):
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
		
	if Input.is_action_just_pressed("jump") and current_double_jumps > 0 and not is_on_floor() and wall_running==false:
		current_double_jumps-=1
		velocity.y = 0
		velocity.y += double_jump_power
		
	if Input.is_action_just_pressed("dash") and air_dash > 0:
		velocity.x = direction.x * dash_speed * delta
		velocity.z = direction.z * dash_speed * delta
	

	if is_sliding:
		slide_velocity = slide_velocity.lerp(Vector3.ZERO, slide_deceleration * delta)
		# If the slide velocity is below the minimum speed, end the slide
		if slide_velocity.length() < slide_min_speed:
			end_slide()
		else:
			# Move the character using the slide velocity
			velocity = slide_velocity
			move_and_slide()
	
	# Check if the slide action is triggered (e.g., by pressing a specific key)
	if Input.is_action_just_pressed("slide"):
		# Start the slide if not already sliding
		if !is_sliding:
			start_slide()

		
	if direction:
		velocity.x = direction.x * character_speed * delta
		velocity.z = direction.z * character_speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0, character_speed)
		velocity.z = move_toward(velocity.z, 0, character_speed)

	move_and_slide()


func start_slide() -> void:
	is_sliding = true
	player.scale.y = player.scale.y/slide_size
	uncrouchray.scale.y=uncrouchray.scale.y*slide_size
	var slide_direction = Vector3.FORWARD
	slide_velocity = slide_direction * slide_speed

func end_slide() -> void:
	is_sliding = false
	player.scale.y = player.scale.y*slide_size
	uncrouchray.scale.y=uncrouchray.scale.y/slide_size
	slide_velocity = Vector3.ZERO
