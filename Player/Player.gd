extends CharacterBody3D

@export var sensitivity = 0.01

@export var invert_y : bool
@export var invert_x : bool
@export var double_jumps:int=1
@export_range(0, 30, 0.2) var double_jump_power: float = 10
@export_range(-10, 60, 0.2) var character_speed: float = 5.0
@export_range(-10, 60, 0.2) var character_jump: float = 4.6
@export_range(2, 100, 0.2) var wall_jump_speed: float = 10.4
@export_range(2, 60, 0.5) var multiply_run: float = 3.0
@export_range(1, 15000, 5) var staminabase: float = 20
@export_range(1, 100, 0.2) var gravity: float = 9.8


# Get the gravity from the project settings to be synced with RigidBody nodes.

var stamina=staminabase
var current_double_jumps=double_jumps
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

var is_running:bool = false

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
				
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-50), deg_to_rad(60))
		
func _ready():
	stamina+=staminabase-stamina
		
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_on_floor():
		current_double_jumps = double_jumps
		

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
		velocity.y = character_jump
		
	if Input.is_action_just_pressed("jump") and is_on_wall():
		velocity.y = character_jump/1.2
		velocity.x = character_jump*wall_jump_speed
		
	if Input.is_action_just_pressed("jump") and current_double_jumps > 0 and not is_on_floor():
		current_double_jumps-=1
		velocity.y += double_jump_power


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if direction:
		velocity.x = direction.x * character_speed
		velocity.z = direction.z * character_speed
	else:
		velocity.x = move_toward(velocity.x, 0, character_speed)
		velocity.z = move_toward(velocity.z, 0, character_speed)

	move_and_slide()
