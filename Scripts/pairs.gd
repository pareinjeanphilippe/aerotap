extends Node2D  # Ce script est attaché à un nœud 2D qui gère les tuyaux du jeu (ex : Flappy Bird)
@export var speed: float = 400.0  # Vitesse de déplacement des tuyaux vers la gauche
@export var mountain_top: Array[Texture2D] = [] 
@export var mountain_bottom: Array[Texture2D] = []
var frozen := false

func _ready() -> void:		
	$Top.texture = mountain_top.pick_random()
	$Bottom.texture = mountain_bottom.pick_random()

func _process(delta: float) -> void:
	if frozen: return
	position.x -= speed * delta
	
	if position.x <= -400:
		queue_free()  

func freeze() -> void:
	frozen = true
	set_process(false)
	set_physics_process(false)
	var ap := get_node_or_null("AnimationPlayer"); if ap: ap.pause()
	var tw := get_node_or_null("Tween"); if tw: tw.pause()
