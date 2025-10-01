extends Node2D  

@export var my_timer: Timer  
@export var scene_to_spawn: PackedScene  
@export var offset_Y: float = 150.0 
var score: int = 0 
var rng := RandomNumberGenerator.new() 
@export var score_label: Label  
var stopped = true

func _ready() -> void:
	rng.randomize()  
	add_to_group("spawner") 	
	my_timer.timeout.connect(Callable(self, "_on_my_timer_timeout"))
	my_timer.start()  

func _on_my_timer_timeout():	
	if stopped : return
	var inst = scene_to_spawn.instantiate()
	get_tree().current_scene.add_child(inst)  
	inst.global_position.x = global_position.x  
	
	var rand_offset = rng.randf_range(-offset_Y, offset_Y)
	inst.global_position.y = global_position.y + rand_offset
	
func increment_score() -> void:
	score += 1
	if score_label:
		score_label.text = str(score)


func _on_area_2d_area_entered(area):
	if area.is_in_group("scoring"): 
		increment_score()

func stop_spawning() -> void:
	stopped = true
	if my_timer: my_timer.stop()

func start_spawning() -> void:
	stopped = false
	my_timer.start()
	my_timer.call_deferred("emit_signal", "timeout")
	
