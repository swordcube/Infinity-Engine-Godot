extends Node2D

onready var bar:ProgressBar = $ProgressBar

onready var iconP2:Sprite = $iconP2
onready var iconP1:Sprite = $iconP1

onready var scoreTxt:Label = $scoreTxt

onready var PlayState = $"../../../"

var health:float = 1.0
var minHealth:float = 0.0
var maxHealth:float = 2.0

var percent:int = 0

func _ready():
	Conductor.connect("beatHit", self, "beatHit")
	
	match Preferences.getOption("icon-bounce-style"):
		"Psych":
			iconP2.offset.y = 0
			iconP1.offset.y = 0
			
			iconP2.position.y += 75
			iconP1.position.y += 75
			
	updateText()
	
func calculateAccuracy():
	if PlayState.totalNotes > 0 and PlayState.totalHit > 0.0:
		PlayState.songAccuracy = (PlayState.totalHit / PlayState.totalNotes)
	else:
		PlayState.songAccuracy = 0
			
func updateText():
	calculateAccuracy()
	scoreTxt.text = (
		"Score: " + str(PlayState.songScore) + " // " +
		"Misses: " + str(PlayState.songMisses) + " // " +
		"Accuracy: " + str(MathUtil.roundDecimal(PlayState.songAccuracy * 100, 2)) + "% // " +
		"Rank: " + Ranking.getRank(MathUtil.roundDecimal(PlayState.songAccuracy * 100, 2))
	)
	
func beatHit():
	iconP2.scale = Vector2(1.2, 1.2)
	iconP1.scale = Vector2(1.2, 1.2)

func _process(delta):
	bar.min_value = minHealth
	bar.max_value = maxHealth
	bar.value = health
	percent = (bar.value / 2) * 100.0

	if percent <= 20:
		iconP2.switchTo("winning")
		iconP1.switchTo("losing")
	else:
		iconP2.switchTo("normal")
		iconP1.switchTo("normal")
		
	if percent >= 80:
		iconP2.switchTo("losing")
		iconP1.switchTo("winning")
	
	iconP2.scale = lerp(iconP2.scale, Vector2.ONE, MathUtil.getLerpValue(0.35, delta))
	iconP1.scale = iconP2.scale
	
	var iconOffset:int = 26
	iconP1.position.x = -(bar.rect_size.x / 2.7) + (bar.rect_size.x * (MathUtil.remapToRange(percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset
	iconP2.position.x = -(bar.rect_size.x / 2.7) + (bar.rect_size.x * (MathUtil.remapToRange(percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2
