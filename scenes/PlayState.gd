# warning-ignore:narrowing_conversion

extends Node2D

var countdownActive:bool = true
var endingSong:bool = false

var stage:Node2D

onready var camera = $Camera2D

onready var HUD = $HUD
onready var OTHER = $Other
onready var UI = $HUD/UI

onready var SONG = PlayStateSettings.SONG.song

var health:float = 1.0

var songScore:int = 0
var songMisses:int = 0
var songAccuracy:float = 0.0

var totalNotes:int = 0
var totalHit:float = 0.0

var combo:int = 0

var noteDataArray:Array = []

func sortAscending(a, b):
	if a[0] < b[0]:
		return true
	return false

func _init():
	PlayStateSettings.getSkin()

func _ready():
	get_tree().paused = false
	
	Conductor.changeBPM(SONG["bpm"])
	Conductor.songPosition = Conductor.timeBetweenBeats * -5
	Conductor.connect("beatHit", self, "beatHit")
	Conductor.connect("stepHit", self, "stepHit")
	
	if not "keyCount" in SONG:
		SONG["keyCount"] = 4
		
	stage = load("res://scenes/stages/stage.tscn").instance()
	add_child(stage)
	
	for section in SONG["notes"]:
		for note in section["sectionNotes"]:
			if note[1] != -1:
				if len(note) == 3:
					note.push_back(0)
				
				var type:String = "Default"
				
				if note[3] is Array:
					note[3] = note[3][0]
				elif note[3] is String:
					type = note[3]
					
					note[3] = 0
					note.push_back(type)
				
				if len(note) == 4:
					note.push_back("Default")
				
				if note[4]:
					if note[4] is String:
						type = note[4]
				
				if not "altAnim" in section:
					section["altAnim"] = false
					
				var offset:float = Preferences.getOption("note-offset") + (AudioServer.get_output_latency() * 1000)
				var strumTime:float = float(note[0]) + (offset * PlayStateSettings.songMultiplier)
				
				noteDataArray.push_back([strumTime + PlayStateSettings.songMultiplier, note[1], note[2], bool(section["mustHitSection"]), int(note[3]), type, bool(section["altAnim"])])
				
	noteDataArray.sort_custom(self, "sortAscending")
	
	PlayStateSettings.scrollSpeed = float(SONG["speed"])
	if Preferences.getOption("custom-scroll-speed"):
		PlayStateSettings.scrollSpeed = float(Preferences.getOption("scroll-speed"))
	
	UI.healthBar._process(0)
	UI.healthBar.updateText()
				
	var countdownTween:Tween = Tween.new()
	countdownTween.pause_mode = Node.PAUSE_MODE_PROCESS
	HUD.add_child(countdownTween)
	
	var countdownGraphic:Sprite = $HUD/CountdownGraphic
	var cs = PlayStateSettings.currentUiSkin.countdown_scale
	countdownGraphic.scale = Vector2(cs, cs)
	
	var countdownTime = (Conductor.timeBetweenBeats / 1000.0) / PlayStateSettings.songMultiplier
	for i in 5:
		yield(get_tree().create_timer(countdownTime, false), "timeout")
		match countdownTick:
			4:
				Conductor.songPosition = Conductor.timeBetweenBeats * -4
				countdownAudios["3"].stream = PlayStateSettings.currentUiSkin.countdown_3
				countdownAudios["3"].play()
			3:
				Conductor.songPosition = Conductor.timeBetweenBeats * -3
				countdownAudios["2"].stream = PlayStateSettings.currentUiSkin.countdown_2
				countdownAudios["2"].play()
				
				countdownGraphic.texture = PlayStateSettings.currentUiSkin.ready_tex
				
				countdownTween.stop_all()
				countdownTween.interpolate_property(countdownGraphic, "modulate:a", 1, 0, countdownTime, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				countdownTween.start()
			2:
				Conductor.songPosition = Conductor.timeBetweenBeats * -2
				countdownAudios["1"].stream = PlayStateSettings.currentUiSkin.countdown_1
				countdownAudios["1"].play()
				
				countdownGraphic.texture = PlayStateSettings.currentUiSkin.set_tex
				
				countdownTween.stop_all()
				countdownTween.interpolate_property(countdownGraphic, "modulate:a", 1, 0, countdownTime, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				countdownTween.start()
			1:
				Conductor.songPosition = Conductor.timeBetweenBeats * -1
				
				countdownGraphic.texture = PlayStateSettings.currentUiSkin.go_tex
				
				countdownAudios["go"].stream = PlayStateSettings.currentUiSkin.countdown_go
				countdownAudios["go"].play()
				
				countdownTween.stop_all()
				countdownTween.interpolate_property(countdownGraphic, "modulate:a", 1, 0, countdownTime, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
				countdownTween.start()
			0:
				AudioHandler.playInst(SONG.song)
				AudioHandler.playVoices(SONG.song)
				
				AudioHandler.inst.seek(0)
				AudioHandler.voices.seek(0)
				
				AudioHandler.inst.pitch_scale = PlayStateSettings.songMultiplier
				AudioHandler.voices.pitch_scale = PlayStateSettings.songMultiplier
				
				Conductor.songPosition = 0
				
				countdownActive = false
				
		countdownTick -= 1
				
var countdownTick:int = 4

onready var countdownAudios:Dictionary = {
	"3": $"HUD/3",
	"2": $"HUD/2",
	"1": $"HUD/1",
	"go": $HUD/Go
}

func updateHealth():
	if health < UI.healthBar.minHealth:
		health = UI.healthBar.minHealth
	if health > UI.healthBar.maxHealth:
		health = UI.healthBar.maxHealth
	
func _process(delta):		
	if Input.is_action_just_pressed("ui_back"):
		Scenes.switchScene("FreeplayMenu")
		AudioHandler.playMusic("freakyMenu")
		
	if not Scenes.transitioning and Input.is_action_just_pressed("ui_accept"):
		get_tree().paused = true
		var pauseMenu = load("res://scenes/ui/playState/PauseMenu.tscn").instance()
		OTHER.add_child(pauseMenu)
	
	Conductor.songPosition += (delta * 1000) * PlayStateSettings.songMultiplier
	
	updateHealth()
	
	camera.zoom = lerp(camera.zoom, Vector2.ONE, MathUtil.getLerpValue(0.05, delta))
	HUD.scale = lerp(HUD.scale, Vector2.ONE, MathUtil.getLerpValue(0.05, delta))
	HUD.offset.x = (HUD.scale.x - 1) * -640
	HUD.offset.y = (HUD.scale.y - 1) * -360
	
	for note in noteDataArray:
		if float(note[0]) - Conductor.songPosition < 2500:
			var mustPress = true
			
			if note[3] and int(note[1]) % (SONG["keyCount"] * 2) >= SONG["keyCount"]:
				mustPress = false
			elif !note[3] and int(note[1]) % (SONG["keyCount"] * 2) <= SONG["keyCount"] - 1:
				mustPress = false
				
			var strum:Node2D = UI.opponentStrums.get_child(int(note[1]) % SONG["keyCount"])
			if mustPress:
				strum = UI.playerStrums.get_child(int(note[1]) % SONG["keyCount"])
				
			var newNote:Node2D = load("res://scenes/ui/notes/Default.tscn").instance()
			newNote.noteData = int(note[1]) % SONG["keyCount"]
			newNote.strumTime = float(note[0])
			newNote.direction = strum.direction
			newNote.downScroll = PlayStateSettings.downScroll
			strum.notes.add_child(newNote)
		
			newNote.mustPress = mustPress
			
			var susLength:int = floor(note[2] / Conductor.timeBetweenSteps)
			for susNote in susLength:
				var sustainNote:Node2D = load("res://scenes/ui/notes/Default.tscn").instance()
				sustainNote.noteData = newNote.noteData
				sustainNote.strumTime = float(note[0]) + (Conductor.timeBetweenSteps * susNote) + (Conductor.timeBetweenSteps / MathUtil.roundDecimal(PlayStateSettings.scrollSpeed, 2))
				sustainNote.direction = strum.direction
				sustainNote.downScroll = PlayStateSettings.downScroll
				sustainNote.isSustainNote = true
				sustainNote.mustPress = mustPress
				
				sustainNote.isEndOfSustain = susNote == susLength - 1
				
				strum.sustains.add_child(sustainNote)
			
			noteDataArray.erase(note)
		else:
			break
			
	if not countdownActive:
		if Conductor.songPosition / 1000.0 >= AudioHandler.inst.stream.get_length():
			endSong()
			
func endSong():
	endingSong = true
	if PlayStateSettings.storyMode:
		Scenes.switchScene("StoryMenu")
	else:
		Scenes.switchScene("FreeplayMenu")
		
	AudioHandler.playMusic("freakyMenu")
	AudioHandler.inst.stop()
	AudioHandler.voices.stop()
			
func beatHit():
	if Conductor.curBeat % 4 == 0:
		camera.zoom -= Vector2(0.015, 0.015)
		HUD.scale += Vector2(0.05, 0.05)
		HUD.offset.x = (HUD.scale.x - 1) * -640
		HUD.offset.y = (HUD.scale.y - 1) * -360
			
func stepHit():
	if not countdownActive:
		var gaming = 30
		
		if PlayStateSettings.songMultiplier > 1:
			gaming *= PlayStateSettings.songMultiplier
			
		var inst_pos = (AudioHandler.inst.get_playback_position() * 1000) + (AudioServer.get_time_since_last_mix() * 1000)
		inst_pos -= AudioServer.get_output_latency() * 1000
		
		if not Conductor.songPosition / 1000.0 >= AudioHandler.inst.stream.get_length():
			if not endingSong and inst_pos > Conductor.songPosition - (AudioServer.get_output_latency() * 1000) + gaming or inst_pos < Conductor.songPosition - (AudioServer.get_output_latency() * 1000) - gaming:
				resyncVocals()
			
func resyncVocals():
	if not countdownActive:
		Conductor.songPosition = (AudioHandler.inst.get_playback_position() * 1000)
		AudioHandler.voices.seek(Conductor.songPosition / 1000)
