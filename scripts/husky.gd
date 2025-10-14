extends CharacterBody2D

# The @export annotation is used to expose (or "export") variables to the editor's inspector.
# These variables can then be edited from within the editor and are saved with the scene.
@export
var move_speed: float = 32.0

# The @onready annotation is used to indicate that the following line should be executed when the node is ready.
# These variables are references to the child nodes found under the node this script is attached to.
# In this case, the Sprite2D and AnimationPlayer nodes directly under the Husky node are referenced.
@onready
var _sprite: Sprite2D = $Sprite2D as Sprite2D
@onready
var _animation_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer

# This is the vector direction to move the character towards.
# This is set in _input() and read in _physics_process().
var _input_move: Vector2 = Vector2.ZERO

# In the _input method callback, input events are sent by the Engine whenever an input action is pressed.
# To process movement inputs, the Input singleton will be used to check if certain move actions are currently pressed
# during each input event.
# Normally, InputEvent.is_action_pressed()/is_action_released() is used to check for actions and pressed states.
# However, for the purposes of this workshop, the Input singleton is used to vastly simplify the logic.
# Both methods achieve the same result, but handling per event is more proper than querying the Input singleton.
func _input(event: InputEvent) -> void:
	# Reset the move vector to zero since input will be polled and added.
	# Use addition and subtraction to account for cases when both the positive and negative direction of an input axis
	# is pressed (e.g. pressing both A and D should not move the character neither left nor right).
	_input_move = Vector2.ZERO
	
	if Input.is_action_pressed(&"move_right"):
		_input_move.x += 1.0
	
	if Input.is_action_pressed(&"move_left"):
		_input_move.x -= 1.0
	
	if Input.is_action_pressed(&"move_down"):
		_input_move.y += 1.0
	
	if Input.is_action_pressed(&"move_up"):
		_input_move.y -= 1.0

func _physics_process(delta: float) -> void:
	# Moving a character is a lot more involved than just changing the character's position.
	# Physics must be taken into account—and setting the position directly will not work with physics!
	# Godot instead has multiple physics classes that can be used to properly move objects and characters.
	# These include StaticBody, RigidBody, and CharacterBody, in both 2D and 3D.
	# These physics objects have methods and internal logic to handle movement that reacts with physics.
	
	# Godot's CharacterBody2D handles all of the internal movement logic with the move_and_slide() method.
	# Just set the desired velocity, call move_and_slide(), and the character will move!
	# If the character collides with anything, it will slide along it. Hence, move_and_slide.
	# Do note that the input vector must be normalized first.
	# Otherwise, diagonal movement will be faster than cardinal movement (bad!)!
	velocity = move_speed * _input_move.normalized()
	
	# The collided variable will be used later to apply forces to the ball.
	var collided: bool = move_and_slide()
	
	if !_input_move.is_zero_approx():
		# Here we change the Y coordinate of the sprite frame to change the character sprite direction variation.
		# There are MANY different ways to handle sprites; It all depends on how you organize your sprite sheets.
		# I like to use a bit of math combined with the movement vector to calculate the correct sprite direction.
		# NOTE: You do not have to understand all of this.
		
		# This constant is used to mark the number of direction variations in the sprite sheet.
		# In the husky sprite sheet, there are 4 rows with 4 different directions for each animation.
		const SPRITE_DIRECTIONS: int = 4
		
		# Since the first sprite direction (the first row in the sprite sheet) is facing down, find the angle of the
		# movement vector with the down vector (Vector2.DOWN constant).
		var move_angle: float = Vector2.DOWN.angle_to(_input_move)
		
		# Then convert that angle as the approximate direction interval to use.
		# This is just mapping that angle (in radians) to a simple fraction (-1.0 to 1.0).
		var sprite_interval_angle: float = float(SPRITE_DIRECTIONS) * move_angle / TAU
		
		# Finally, round the interval fraction to the closest integer and wrap positively with the number of directions.
		var sprite_row: int = posmod(roundi(sprite_interval_angle), SPRITE_DIRECTIONS)
		_sprite.frame_coords.y = sprite_row
	
	# To properly set the idle and move animations, check the velocity vector if the character is moving.
	if velocity.is_zero_approx():
		# If the velocity is zero, the character is not moving and the idle animation should be played.
		_animation_player.play(&"idle")
	else:
		# If the velocity is not zero, the character is moving and the move animation should be played.
		_animation_player.play(&"move")
	
	# If the character has collided with any sort of physics object, then try to apply an impulse force to it.
	if collided:
		# This method returns information about the last collision, including what object the character collided with.
		var collision: KinematicCollision2D = get_last_slide_collision()
		
		# Cast the colliding object to a RigidBody2D and check if it's valid.
		# If it's not valid, then the object was not a RigidBody2D and there's nothing to do.
		var rigid_body: RigidBody2D = collision.get_collider() as RigidBody2D
		if is_instance_valid(rigid_body):
			# The impulse to the rigid body is the reverse of the collision normal multiplied by the character's speed.
			# It's not 100% physically accurate, but works well enough for this project.
			# Make sure to set damping on the rigid body in the inspector, or else it will move forever!
			var impulse: Vector2 = -collision.get_normal() * velocity.length()
			rigid_body.apply_central_impulse(impulse)
			
			# A torque is also applied to make the rigid body spin.
			# The randf_range is used to give some variation in torque.
			# The signf is used to rotate the rigid body in the direction of the impulse.
			var torque: float = randf_range(2.0, 4.0) * impulse.length() * signf(impulse.x)
			rigid_body.apply_torque_impulse(torque)
