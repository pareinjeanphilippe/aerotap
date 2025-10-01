extends CharacterBody2D

@export var gravity_force: float = 1200.0
@export var flap_strength: float = -400.0
var vertical_velocity: float = 0.0
var use_gravity = false
@export var max_angle_up = deg_to_rad(-2)
@export var max_angle_down = deg_to_rad(2)
var spawn_started := false
var is_dead : bool = false
var best = 0
var config = ConfigFile.new()
const CONFIG_PATH = "user://game_data.cfg"
@export var medals: Array[Texture2D] = []

func _ready():	
	$Area2D.connect("area_entered", _on_area_entered)
	spawn_started = false
	use_gravity = false
	$Tap.visible = true
	#best
	var error = config.load(CONFIG_PATH)
	if error == ERR_FILE_NOT_FOUND:
		best = 0
	else:
		best = config.get_value("bestscore","best")
		$"../CanvasLayer/TextureRectGameOver/LabelBest".text = str(best)
	print(best)
	
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("obstacle"):
		is_dead = true
		$"../Background".stop_scroll()
		$"../GroundDirt".stop_scroll()
		$"../Spawner".stop_spawning()		
		get_tree().call_group("pairs", "freeze") 
		$"../Sfx_sound".play_sfx_dead() 
		$Area2D.queue_free()
		$CPUParticles2DExplosion.emitting = true
		show_game_over()
		await get_tree().create_timer(2).timeout
		use_gravity = false

func show_game_over():
	await get_tree().create_timer(0.5).timeout
	$"../CanvasLayer/TextureRectGameOver/AnimationPlayer".play("Show")
	var score = $"../Spawner".score
	$"../CanvasLayer/TextureRectGameOver/LabelScore".text = str(score)
		
	if score>best:
		$"../CanvasLayer/TextureRectGameOver/LabelBest".text = str(score)
		config.set_value("bestscore","best",score)
		config.save(CONFIG_PATH)
			
	if score >= 10:
		$"../CanvasLayer/TextureRectGameOver/TextureRectMedal".texture = medals[0]
	elif score >= 30:			
		$"../CanvasLayer/TextureRectGameOver/TextureRectMedal".texture = medals[1]
	elif score >= 60 :			
		$"../CanvasLayer/TextureRectGameOver/TextureRectMedal".texture = medals[2]
			
func _physics_process(delta: float) -> void:
	if !spawn_started and Input.is_action_just_pressed("click_or_touch"):
		spawn_started = true
		use_gravity = true
		$Tap.visible=false
		$"../Spawner".start_spawning()
		$"../Sfx_sound".play_sfx_jump()
	
	if not use_gravity: return
	
	const MAX_FALL: float = 800.0       
	const MAX_UP_RAD: float = -0.35    
	const MAX_DOWN_RAD: float = 0.25	   
	const ROTATION_SMOOTHNESS: float = 10.0 
	var normalized_velocity: float = clamp(velocity.y / MAX_FALL, -1.0, 1.0)
	var target_rotation: float = lerp(MAX_UP_RAD, MAX_DOWN_RAD, (normalized_velocity + 1.0) / 2.0)
	rotation = lerp_angle(rotation, target_rotation, delta * ROTATION_SMOOTHNESS)

	if Input.is_action_just_pressed("click_or_touch") and not is_dead:
		vertical_velocity = flap_strength
		$"../Sfx_sound".play_sfx_jump()
	
	vertical_velocity += gravity_force * delta
	velocity.x = 0 
	velocity.y = vertical_velocity	
	move_and_slide()

#UI
func _on_button_exit_pressed():
	get_tree().quit()

func _on_button_play_pressed():
	get_tree().reload_current_scene()
