extends Node

@export
var _goal_area: Area2D = null

@export
var _label_victory: Label = null

@export
var _button_restart: Button = null

func _ready() -> void:
	# Signals are used to immediately call connected functions when the signal is emitted.
	# The Area2D class has a body_entered signal that is emitted immediately when a physics body enters it.
	# The connect method is used to provide the function we want called when the signal is emitted.
	_goal_area.body_entered.connect(_on_goal_area_body_entered)
	
	_button_restart.pressed.connect(_on_button_restart_pressed)
	
	# Hide the victory label until the time is right.
	_label_victory.visible = false

func _on_goal_area_body_entered(body: Node2D) -> void:
	# Check the body name if it's the ball.
	# Keep in mind, any physics body can trigger the area, including the Husky character (try it!).
	if body.name == &"Ball":
		# Display the victory label. Hurray you won!
		_label_victory.visible = true

func _on_button_restart_pressed() -> void:
	# When the restart button is pressed, restart the scene!
	# This will completely reset the scene, reloading all objects, their variables and states.
	# It would be as if the entire application was reopened.
	# In a proper game, this should never be used. Instead, individual scenes should be loaded and unloaded from the
	# scene tree, ideally by a main scene that is never removed or reloaded.
	# In Unity, that main scene would be your DontDestroyOnLoad GameObjects.
	# However, for this workshop project, reload_current_scene() is perfectly fine to use.
	get_tree().reload_current_scene()
