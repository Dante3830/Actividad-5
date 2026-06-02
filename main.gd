extends Control

@onready var frog = %FrogIdle
@onready var frog_position = %Position

@onready var save_01 = %Save01
@onready var load_01 = %Load01
@onready var save_03 = %Save03
@onready var load_03 = %Load03

var sfx_is_on = true
var bgm_is_on = true

var click_count = 0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		frog.global_position = get_global_mouse_position()
		$Game/FrogIdle/SFX.play()
		click_count += 1
	
	frog_position.text = "X: " + str(get_global_mouse_position().x) + "Y: " + str(get_global_mouse_position().y)
	
	%Score.text = "SCORE: " + str(click_count)

func _on_sfx_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.

func _on_clear_data_pressed() -> void:
	click_count = 0

func _on_save_01_pressed() -> void:
	pass # Replace with function body.

func _on_load_01_pressed() -> void:
	pass # Replace with function body.

func _on_save_03_pressed() -> void:
	pass # Replace with function body.

func _on_load_03_pressed() -> void:
	pass # Replace with function body.
