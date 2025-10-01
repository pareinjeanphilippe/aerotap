extends Sprite2D

@export var scroll_speed: float = 0.1
var running = true
const SHADER_TIME_PARAM = "game_time"
const SHADER_SPEED_PARAM = "scroll_speed" 
var current_game_time: float = 0.0

func _process(delta: float) -> void:
	if not running : return	
	current_game_time += delta
	if material is ShaderMaterial:
		var shader_material: ShaderMaterial = material as ShaderMaterial
		shader_material.set_shader_parameter(SHADER_SPEED_PARAM, scroll_speed)
		shader_material.set_shader_parameter(SHADER_TIME_PARAM, current_game_time)

func stop_scroll():	
	running = false
