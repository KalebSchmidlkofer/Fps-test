extends Node3D

var character
var cam_pos = {"y":0.1,"z":0.3}
var sliding = false
var direction = Vector3()
var direction2 = Vector3()
var velocity = Vector3()
var gravity = -27
var jump_height = 10
var speed = 8
var slide_timeout = 0
var tpv_camera_speed = 0.001

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_window().set_position(Vector2(0,0))
	character = $character

func rotating(dir):
	var a  = atan2(dir.x* -1, dir.z* -1)
	var rot = character.get_rotation()
	if abs(rot.y-a) > PI:
		var m = PI * 2
		var d = fmod(a-rot.y,m)
		a = rot.y + (fmod(2 * d,m)-d)*0.2
	else:
		a = lerp(rot.y,a,0.1)
	character.rotation.y = a

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventMouseMotion:
			$head.rotate_y(-event.relative.x * tpv_camera_speed)
			var x = 0.5 -abs($head/cam.rotation.x)
			var rel = (-event.relative.y*x)*5
			var change = $head/cam.rotation.x+(rel*tpv_camera_speed)
			if -event.relative.y < 0 and change > -0.47 or -event.relative.y > 0 and change < 0.47:
				$head/cam.rotate_x(rel * tpv_camera_speed)

func _physics_process(delta):
	direction = Vector3()
	var aim = $head/cam.get_global_transform().basis
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	if Input.is_key_pressed(KEY_W):
		direction -= aim.z
	if Input.is_key_pressed(KEY_S):
		direction += aim.z
	if Input.is_key_pressed(KEY_A):
		direction -= aim.x
	if Input.is_key_pressed(KEY_D):
		direction += aim.x
	direction = direction.normalized()
		
#gravity stop, if the velocity keeps going down on surfaces, you gets glitches
#slowly killing the velocity so it doesn't messing up the sliding
	if character.is_on_floor():
		velocity.y *= 0.8
	else:
		velocity.y += gravity * delta
		
#direction is set by your input, but no imput = no direction, basically no walking
#oo we saves the last direction to direction2
#Or the player wll point at an empty vector3 / default direction
	if direction != Vector3():
		direction2 = direction
		
#Jump
	if character.is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_height



#slide down
	if (character.is_on_floor() or sliding == true and $character/ground.is_colliding()) and rad_to_deg(character.get_floor_angle()) > 20:
#timeout, so you have 0.5s before sliding
		slide_timeout += delta
		if slide_timeout > 0.5:
			direction *= 0.5#allows you to control the playing while sliding
			direction += $character/ground.get_collision_normal() # you can add "* n " for faster slide, but you will bump off on steeper slopes
			direction2 = direction
			velocity.y = 0
			velocity += Vector3(direction.x,0,direction.z)
			rotating(direction)
			sliding = true
	elif sliding:
		sliding = false
		if character.is_on_floor() and character.get_floor_angle() < 0.35:
			slide_timeout = 0



#velocity > movement
	var tv = velocity
	tv = velocity.lerp(direction * speed,5 * delta)
	velocity.x = tv.x
	velocity.z = tv.z
#movement
	character.set_velocity(velocity)
	character.set_up_direction(Vector3(0,1,0))
	character.move_and_slide()
	
	rotating(direction2)
	
#align to floor, on floor

	var ground
	if $character/ground.is_colliding():
		ground = $character/ground.get_collision_normal()
	else:
		ground = Vector3(0,1,0)
	var newt = align_to_floor(character.global_transform,ground)
	character.global_transform = character.global_transform.interpolate_with(newt,12 * delta)

#camera movement
	$head.transform.origin += (character.transform.origin-$head.transform.origin)/2
	$head/cam.transform.origin = Vector3(0,cam_pos.y*10,cam_pos.z*10)
		
#falling out of map

	if character.transform.origin.y < -20:
		character.transform.origin = Vector3(0,0,0)

func align_to_floor(trans,new):
	trans.basis.y = new
	trans.basis.x = -trans.basis.z.cross(new)
	trans.basis = trans.basis.orthonormalized()
	return trans
