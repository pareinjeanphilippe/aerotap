extends AudioStreamPlayer
@export var sfx_jump : AudioStream
@export var sfx_dead : AudioStream

func play_sfx_jump():
	stream = sfx_jump
	play()
	
func play_sfx_dead():
	stream = sfx_dead
	play()
