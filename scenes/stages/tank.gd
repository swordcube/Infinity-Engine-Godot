extends Stage

onready var boppinGuys:Array = [
	$ParallaxBackground/layer7/WatchTower,
	$FGGuys/layer1/tank,
	$FGGuys/layer2/tank,
	$FGGuys/layer3/tank,
	$FGGuys/layer3/tank2,
	$FGGuys/layer3/tank3,
	$FGGuys/ParallaxLayer/tank4,
]

onready var watchTower:AnimatedSprite = $ParallaxBackground/layer7/WatchTower

onready var tankRolling:AnimatedSprite = $ParallaxBackground/layer7/TankRolling

var tankAngle:float = rand_range(-90, 45)
var tankSpeed:float = rand_range(5, 7)
var tankX:float = 400

var tankFucks:Array = []

var isStress:bool = false

func createPost():
	randomize()
	
	if PlayState.SONG.song.to_lower() == "stress":
		isStress = true
		var tankmen = load("res://scenes/stages/tank/TankFucker.tscn").instance()
		tankmen.strumTime = 10
		tankmen.resetShit(20, 300, true)
		$TankmenRun.add_child(tankmen)
		
		tankFucks = PlayState.gf.animationNotes.duplicate()

func _process(delta):
	moveTank(delta)
	
	if isStress:
		for cum in tankFucks:
			if cum[0] < Conductor.songPosition + 2500:
				if rand_range(0, 85) < 16:
					var man = load("res://scenes/stages/tank/TankFucker.tscn").instance()
					man.strumTime = cum[0]
					man.resetShit(500, 200 + int(rand_range(50, 100)), cum[1] < 2)
					$TankmenRun.add_child(man)
				
				tankFucks.erase(cum)
				
var canBop:bool = true
	
func beatHit():
	if canBop:
		canBop = false
		for guy in boppinGuys:
			guy.frame = 0
			guy.play("bop")
			
			watchTower.frame = 0
			watchTower.play("bop")
	
func moveTank(delta):
	tankAngle += tankSpeed * delta
	tankRolling.rotation_degrees = (tankAngle - 90 + 15)
	tankRolling.position.x = 400 + 1500 * cos(PI / 180 * (1 * tankAngle + 180))
	tankRolling.position.y = 1300 + 1100 * sin(PI / 180 * (1 * tankAngle + 180))

func onTankDone():
	canBop = true
