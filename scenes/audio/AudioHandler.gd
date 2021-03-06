extends Node

onready var inst:AudioStreamPlayer = $Song/Inst
onready var voices:AudioStreamPlayer = $Song/Voices

func playSFX(a:String, pos:float = 0.0):
	var node = get_node("SFX/" + a)
	if node:
		var clone = node.duplicate()
		clone.isClone = true
		clone.play()
		get_tree().current_scene.add_child(clone)
		
func setMusicPitch(pitch:float = 1.0):
	for node in $Music.get_children():
		node.pitch_scale = pitch
		
	inst.pitch_scale = pitch
	voices.pitch_scale = pitch
		
func playMusic(music:String, force:bool = false):
	inst.stop()
	voices.stop()
	
	var node = get_node("Music/" + music)
	for coolNode in $Music.get_children():
		if coolNode != node:
			coolNode.stop()
	
	if node:
		if not node.playing or force:
			node.play()
			
func stopMusic():
	inst.stop()
	voices.stop()
	
	for coolNode in $Music.get_children():
		coolNode.stop()
		
func playInst(song:String):
	for node in $Music.get_children():
		node.stop()
		
	inst.stop()
	inst.stream = load(Paths.inst(song))
	inst.play()
	
	inst.volume_db = 0
	
func playVoices(song:String):
	voices.stop()
	voices.stream = load(Paths.voices(song))
	voices.play()
	
	voices.volume_db = 0
