extends Node2D

onready var notes:Node2D = $Notes
onready var sustains:ColorRect = $Sustains

onready var spr:AnimatedSprite = $spr

onready var PlayState = $"../../../../"

var isOpponent:bool = false

var oldDirection:String = "A"
export(String) var direction:String = "A"

var dontHit:bool = false

var animFinished:bool = false

func _ready():
	spr.frames = PlayStateSettings.currentUiSkin.strum_tex
	var ss = PlayStateSettings.currentUiSkin.strum_scale
	spr.scale = Vector2(ss, ss)
	playAnim("static")
	
func sortNotes(a, b):
	if a.strumTime < b.strumTime:
		return true
		
	return false
	
func _process(delta):
	if oldDirection != direction:
		oldDirection = direction
		playAnim("static")
		
	if PlayStateSettings.downScroll:
		sustains.rect_position.y = -sustains.rect_size.y
	else:
		sustains.rect_position.y = 0
		
	if not isOpponent:
		if not PlayStateSettings.botPlay and Input.is_action_just_pressed("gameplay_" + direction):
			PlayState.pressed[0] = true
			playAnim("press")
			
		if (not PlayStateSettings.botPlay and Input.is_action_just_released("gameplay_" + direction)) or (PlayStateSettings.botPlay and animFinished):
			PlayState.pressed[0] = false
			playAnim("static")
	else:
		if animFinished:
			playAnim("static")

	var scrollSpeed = PlayStateSettings.scrollSpeed
			
	if sustains:
		for note in sustains.get_children():
			note.position.x = (sustains.rect_size.x / 2)
			
			match Preferences.getOption("clip-style"):
				"StepMania":
					note.z_index = -1
			
			if note.downScroll:
				note.position.y = 0.45 * (Conductor.songPosition - note.strumTime) * scrollSpeed
			else:
				note.position.y = -0.45 * (Conductor.songPosition - note.strumTime) * scrollSpeed
				
			note.position.y -= sustains.rect_position.y
				
			var yourMom = 1 * ((note.timeBetweenSteps / 100 * 1.05) * scrollSpeed)
				
			if not note.isEndOfSustain:
				note.scale.y = yourMom * PlayStateSettings.currentUiSkin.sustain_scale
			else:
				var noteWidth = note.spr.frames.get_frame(note.spr.animation, note.spr.frame).get_width()
				var noteHeight = note.spr.frames.get_frame(note.spr.animation, note.spr.frame).get_height()
				
				if note.downScroll:
					note.spr.offset.y = ((scrollSpeed * (note.timeBetweenSteps / 1000.0)) * (230))
					note.spr.offset.y -= ((noteHeight*PlayStateSettings.currentUiSkin.note_scale)*0.5)
				else:
					note.spr.offset.y = -((scrollSpeed * (note.timeBetweenSteps / 1000.0)) * (230))
					note.spr.offset.y += ((noteHeight*PlayStateSettings.currentUiSkin.note_scale)*0.5)

			note.modulate.a = 0.6
				
			if note.mustPress:
				sustains.rect_clip_content = Input.is_action_pressed("gameplay_" + direction) or PlayStateSettings.botPlay
					
				if (Input.is_action_pressed("gameplay_" + direction) or PlayStateSettings.botPlay) and Conductor.songPosition >= note.strumTime + (Conductor.safeZoneOffset / 8):
					var characterSinging = PlayState.bf
					if Preferences.getOption("play-as-opponent"):
						characterSinging = PlayState.dad
						
					if characterSinging and not characterSinging.specialAnim:
						var altAnim = ""
						if note.altNote:
							altAnim = "-alt"
							
						characterSinging.holdTimer = 0
						characterSinging.playAnim(CoolUtil.singAnims[PlayState.SONG["keyCount"]][note.noteData] + altAnim)
						
					var gain:float = 0.023
					gain *= Preferences.getOption("hp-gain-multiplier")
					PlayState.health += gain
					AudioHandler.voices.volume_db = 0
					PlayState.updateHealth()
					playAnim("confirm")
					sustains.remove_child(note)
					note.queue_free()
					
				if not PlayStateSettings.botPlay and Conductor.songPosition >= note.strumTime + Conductor.safeZoneOffset:
					var characterSinging = PlayState.bf
					if Preferences.getOption("play-as-opponent"):
						characterSinging = PlayState.dad
						
					if characterSinging and not characterSinging.specialAnim:
						var altAnim = ""
						if note.altNote:
							altAnim = "-alt"
							
						characterSinging.holdTimer = 0
						characterSinging.playAnim(CoolUtil.singAnims[PlayState.SONG["keyCount"]][note.noteData] + "miss" + altAnim)
						
					var loss:float = -0.0475
					loss *= Preferences.getOption("hp-loss-multiplier")
					PlayState.health += loss
					if PlayState.combo >= 10:
						if PlayState.gf:
							PlayState.gf.playAnim('sad')
					PlayState.combo = 0
					PlayState.totalNotes += 1
					AudioHandler.voices.volume_db = -9999
					PlayState.updateHealth()
					PlayState.UI.healthBar.updateText()
					sustains.remove_child(note)
					note.queue_free()
			else:
				if Conductor.songPosition >= note.strumTime + (Conductor.safeZoneOffset / 4):
					var characterSinging = PlayState.dad
					if Preferences.getOption("play-as-opponent"):
						characterSinging = PlayState.bf
					
					var health:float = PlayState.health
					health -= 1 * Preferences.getOption("health-drain")
					if health < 0.023:
						health = 0.023
						
					PlayState.health = health
						
					if characterSinging and not characterSinging.specialAnim:
						var altAnim = ""
						var curSection = MathUtil.boundTo(int(Conductor.curStep / 16), 0, PlayState.SONG.notes.size() - 1)
						if note.altNote:
							altAnim = "-alt"
							
						characterSinging.holdTimer = 0
						characterSinging.playAnim(CoolUtil.singAnims[PlayState.SONG["keyCount"]][note.noteData] + altAnim)
					playAnim("confirm")
					AudioHandler.voices.volume_db = 0
					sustains.remove_child(note)
					note.queue_free()
		
	if notes:
		dontHit = false
		var possibleNotes:Array = []
		for note in notes.get_children():
			if Conductor.songPosition >= note.strumTime - Conductor.safeZoneOffset:
				possibleNotes.append(note)
				
		possibleNotes.sort_custom(self, "sortNotes")
				
		for note in notes.get_children():
			if note.downScroll:
				note.position.y = 0.45 * (Conductor.songPosition - note.strumTime) * scrollSpeed
			else:
				note.position.y = -0.45 * (Conductor.songPosition - note.strumTime) * scrollSpeed
				
		for note in possibleNotes:
			if note.mustPress:
				if not dontHit:
					if Input.is_action_just_pressed("gameplay_" + direction) or PlayStateSettings.botPlay:
						if (PlayStateSettings.botPlay and Conductor.songPosition >= note.strumTime) or not PlayStateSettings.botPlay:
							var characterSinging = PlayState.bf
							if Preferences.getOption("play-as-opponent"):
								characterSinging = PlayState.dad
								
							if characterSinging and not characterSinging.specialAnim:
								var altAnim = ""
								if note.altNote:
									altAnim = "-alt"
								characterSinging.holdTimer = 0
								characterSinging.playAnim(CoolUtil.singAnims[PlayState.SONG["keyCount"]][note.noteData] + altAnim)
					
							var gain:float = 0.023
							gain *= Preferences.getOption("hp-gain-multiplier")
							PlayState.health += gain
							PlayState.combo += 1
							PlayState.totalNotes += 1
							
							var rating:String = Ranking.judgeNote(note.strumTime)
							if PlayStateSettings.botPlay:
								rating = "marvelous"
							
							var newRating:Node2D = PlayState.UI.ratingTemplate.duplicate()
							newRating.position = Vector2(685, 230)
							newRating.combo = CoolUtil.numToComboStr(PlayState.combo)
							PlayState.UI.add_child(newRating)
								
							var texture:StreamTexture
							match rating:
								"marvelous":
									PlayState.marv += 1
									texture = PlayStateSettings.currentUiSkin.marvelous_tex
								"sick":
									PlayState.sicks += 1
									texture = PlayStateSettings.currentUiSkin.sick_tex
								"good":
									PlayState.goods += 1
									texture = PlayStateSettings.currentUiSkin.good_tex
								"bad":
									PlayState.bads += 1
									texture = PlayStateSettings.currentUiSkin.bad_tex
								"shit":
									PlayState.shits += 1
									texture = PlayStateSettings.currentUiSkin.shit_tex
									
							var rankingShit = Ranking.judgements[rating]
							if not PlayStateSettings.botPlay:
								PlayState.songScore += rankingShit["score"]
							PlayState.totalHit += rankingShit["mod"]
							if rankingShit.has("health"):
								PlayState.health += rankingShit["health"]
								
							newRating.rating.texture = texture
								
							if Preferences.getOption("note-splashes") and rankingShit.has("noteSplash"):
								var strum = PlayState.UI.playerStrums.get_child(note.noteData)
								if Preferences.getOption("play-as-opponent"):
									strum = PlayState.UI.opponentStrums.get_child(note.noteData)
									
								var noteSplash:Node2D = load("res://scenes/ui/playState/NoteSplash.tscn").instance()
								noteSplash.direction = strum.direction
								noteSplash.position = strum.global_position
								PlayState.UI.add_child(noteSplash)
							
							if Preferences.getOption("hitsound") != "None":
								var newHitsound = PlayState.hitsound.duplicate()
								newHitsound.isClone = true
								newHitsound.play()
								PlayState.add_child(newHitsound)
							
							AudioHandler.voices.volume_db = 0
							PlayState.updateHealth()
							PlayState.UI.healthBar.updateText()
							playAnim("confirm")
							notes.remove_child(note)
							note.queue_free()
							
							for coolNote in notes.get_children():
								if ((coolNote.strumTime - note.strumTime) < 2) and coolNote.noteData == note.noteData:
									print('found a stacked/really close note ' + str(coolNote.strumTime - note.strumTime))
									# just fuckin remove it since it's a stacked note and shouldn't be there
									notes.remove_child(coolNote)
									note.queue_free()
						
						dontHit = true
						
				if not PlayStateSettings.botPlay and Conductor.songPosition >= note.strumTime + Conductor.safeZoneOffset:
					var characterSinging = PlayState.bf
					if Preferences.getOption("play-as-opponent"):
						characterSinging = PlayState.dad
						
					if characterSinging and not characterSinging.specialAnim:
						var altAnim = ""
						if note.altNote:
							altAnim = "-alt"
							
						characterSinging.holdTimer = 0
						characterSinging.playAnim(CoolUtil.singAnims[PlayState.SONG["keyCount"]][note.noteData] + "miss" + altAnim)
					
					var loss:float = -0.0475
					loss *= Preferences.getOption("hp-loss-multiplier")
					PlayState.health += loss
					PlayState.songMisses += 1
					if PlayState.combo >= 10:
						if PlayState.gf:
							PlayState.gf.playAnim('sad')
					PlayState.combo = 0
					PlayState.totalNotes += 1
					AudioHandler.voices.volume_db = -9999
					PlayState.updateHealth()
					PlayState.UI.healthBar.updateText()
					notes.remove_child(note)
					note.queue_free()
			else:						
				if Conductor.songPosition >= note.strumTime:
					var characterSinging = PlayState.dad
					if Preferences.getOption("play-as-opponent"):
						characterSinging = PlayState.bf
						
					var health:float = PlayState.health
					health -= 1 * Preferences.getOption("health-drain")
					if health < 0.023:
						health = 0.023
						
					PlayState.health = health
						
					if characterSinging and not characterSinging.specialAnim:
						var altAnim = ""
						if note.altNote:
							altAnim = "-alt"
							
						characterSinging.holdTimer = 0
						characterSinging.playAnim(CoolUtil.singAnims[PlayState.SONG["keyCount"]][note.noteData] + altAnim)
					
					playAnim("confirm")
					AudioHandler.voices.volume_db = 0
					notes.remove_child(note)
					note.queue_free()

func playAnim(anim:String = "static"):
	match anim:
		"press", "pressed":
			spr.stop()
			spr.frame = 0
			spr.play(direction + " press")
			animFinished = false
		"confirm":
			spr.stop()
			spr.frame = 0
			spr.play(direction + " confirm")
			animFinished = false
		_:
			spr.stop()
			spr.frame = 0
			spr.play(direction + " static")
			animFinished = false

func _on_spr_animation_finished():
	animFinished = true
