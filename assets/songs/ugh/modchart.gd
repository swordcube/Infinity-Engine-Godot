extends Modchart

onready var dad = PlayState.dad

func stepHit():
	match(Conductor.curStep):
		60, 444, 524, 540, 541, 829:
			if dad:
				if dad.animPlayer.has_animation("ugh"):
					dad.playAnim("ugh")
				else:
					dad.playAnim("singUP")
					
				dad.holdTimer = 0
				
				# because normally you would hit a note for every "ugh"
				# but i removed said note because your mom
				if Preferences.getOption("play-as-opponent"):
					PlayState.songScore += 350
