extends Node

class_name Ranking

const judgements:Dictionary = {
	"marvelous": {
		"time": 40.75,
		"score": 300,
		"noteSplash": true,
		"mod": 1
	},
	"sick": {
		"time": 43.5,
		"score": 300,
		"noteSplash": true,
		"mod": 0.95
	},
	"good": {
		"time": 73.5,
		"score": 200,
		"mod": 0.7
	},
	"bad": {
		"time": 125,
		"score": 100,
		"mod": 0.4
	},
	"shit": {
		"time": 150,
		"score": 50,
		"mod": 0,
		"health": -0.15
	}
}

const ranks:Dictionary = {
	100: "S+",
	90: "S",
	80: "A",
	70: "B",
	60: "C",
	50: "D",
	40: "E",
	30: "F",
	0: "boooo"
};

static func judgeNote(strumTime:float):
	var noteDiff:float = abs(Conductor.songPosition - strumTime) / PlayStateSettings.songMultiplier
	var lastJudge:String = "no"
	
	for key in judgements.keys():
		if noteDiff <= Preferences.getOption(key + "-timing") and lastJudge == "no":
			lastJudge = key
	
	if lastJudge == "no":
		lastJudge = judgements.keys()[len(judgements) - 1]
	
	return lastJudge
	
static func getRank(accuracy:float):
	if accuracy > 0:
		# biggest Haccuracy
		var bigHacc:int = 0;
		var leRank:String = ""
		
		for rank in ranks.keys():
			var minAccuracy = rank
			if minAccuracy <= accuracy and minAccuracy >= bigHacc:
				bigHacc = minAccuracy
				leRank = ranks[rank]
		
		return leRank
	
	return "?"
