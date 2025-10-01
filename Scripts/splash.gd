extends Control

@export var next_scene_path := "res://Scenes/Game.tscn"
@export var hold := 2.0

func _ready() -> void:
	$CanvasLayer/TextureRectLogo.modulate.a = 0.0	
	await create_tween().tween_property($CanvasLayer/TextureRectLogo, "modulate:a", 1.0, 0.35).finished
	await get_tree().create_timer(hold).timeout
	await create_tween().tween_property($CanvasLayer/TextureRectLogo, "modulate:a", 0.0, 0.35).finished

	get_tree().change_scene_to_file(next_scene_path)
