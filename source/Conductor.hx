package;

import Song.SwagSong;
import flixel.FlxG;
import flixel.math.FlxMath;

/**
 * ...
 * @author
 */
typedef BPMChangeEvent =
{
	var beatTime:Float;
	var songTime:Float;
	var bpm:Float;
	var timeSignatureNum:Int;
	var timeSignatureDen:Int;
	var beatTuplets:Array<Int>;
}



class Conductor
{
	public static var instance(get, never):Conductor;
	static var _instance: Null<Conductor> = null;
	public var songPosition(default, null):Float;
	public var lastSongPos:Float;
	public var offset:Float = 0;
	public var bpmChangeMap:Array<BPMChangeEvent> = [];
	public var currentBpmChange(default, null): Null<BPMChangeEvent>;
	public  var instrumentalOffset:Float = 0;
	public static final DEFAULT_BPM: Float = 100.0;
	public static final DEFAULT_TIME_SIGNATURE_NUM = 4;
	public static final DEFAULT_TIME_SIGNATURE_DEN = 4;
	public static final STEPS_PER_BEAT: Int = 4;
	public static final MS_PER_SEC: Int = 1000;
	public static final SECS_PER_MIN: Int = 60;

	public var timeSignatureNum(get, never): Int;
	function get_timeSignatureNum(): Int {
		if (currentBpmChange == null) return DEFAULT_TIME_SIGNATURE_NUM;

		return currentBpmChange.timeSignatureNum;
	}
	public var timeSignatureDen(get, never): Int;
	function get_timeSignatureDen(): Int {
		if (currentBpmChange == null) return DEFAULT_TIME_SIGNATURE_DEN;

		return currentBpmChange.timeSignatureDen;
	}
	public var bpm(get, never): Float;
	function get_bpm(): Float {
		if (bpmOverride != null) return bpmOverride;
		if (currentBpmChange == null) return DEFAULT_BPM;

		return currentBpmChange.bpm;
	}
	public var startingBPM(get, never): Float;
	function get_startingBPM(): Float {
		if (bpmOverride != null) return bpmOverride;
		var timeChange = bpmChangeMap[0];
		if (timeChange == null) return DEFAULT_BPM;

		return timeChange.bpm;
	}
	// questionably integral
	public var stepsPerMeasure(get, never): Int;
	function get_stepsPerMeasure(): Int {
		return Std.int(timeSignatureNum / timeSignatureDen * STEPS_PER_BEAT * STEPS_PER_BEAT);
	}


	public var measureLengthMs(get, never): Float;

	function get_measureLengthMs(): Float {
		return beatLengthMs * timeSignatureNum;
	}

	public var beatLengthMs(get, never): Float;

	function get_beatLengthMs(): Float {
		return ((SECS_PER_MIN / bpm) * MS_PER_SEC);
	}
	public var stepLengthMs(get, never): Float;

	// ?
	function get_stepLengthMs(): Float {
		return beatLengthMs / timeSignatureNum;
	}
	
	var bpmOverride: Null<Float> = null;

	public var currentMeasure(default, null): Int = 0;

	public var currentBeat(default, null): Int = 0;

	public var currentStep(default, null): Int = 0;

	public var currentMeasureTime(default, null): Float = 0;

	public var currentBeatTime(default, null): Float = 0;

	public var currentStepTime(default, null): Float = 0;

	public function new() {}

	public function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [{beatTime: 0, songTime: 0, bpm: song.bpm, timeSignatureNum: 4, timeSignatureDen: 4, beatTuplets: [4, 4, 4, 4]}];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					// this will make more sense once we fully support new version
					beatTime: totalSteps / 4,
					songTime: totalPos,
					bpm: curBPM,
					timeSignatureNum: 4,
					timeSignatureDen: 4,
					beatTuplets: [4, 4, 4, 4]
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}


	public function getTimeInSteps(ms:Float):Float
	{
		if (bpmChangeMap.length == 0) {
			return Math.floor(ms / stepLengthMs);
		} else {
			var resultStep: Float = 0;

			var lastTimeChange:BPMChangeEvent = bpmChangeMap[0];
			for (bpmChange in bpmChangeMap) {
				if (ms >= bpmChange.songTime) {
					lastTimeChange = bpmChange;
					resultStep = lastTimeChange.beatTime * STEPS_PER_BEAT;
				} else {
					break;
				}
			}

			var lastStepLengthMs: Float = ((SECS_PER_MIN / lastTimeChange.bpm) * MS_PER_SEC) / timeSignatureNum;
			var resultFractionalStep: Float = (ms - lastTimeChange.songTime) / lastStepLengthMs;
			resultStep += resultFractionalStep;

			return resultStep;
		}
	}

	public function getStepTimeInMs(stepTime: Float): Float {
		if (bpmChangeMap.length == 0) {
			return stepTime * stepLengthMs;
		} else {
			var resultMs: Float = 0;

			var lastTimeChange: BPMChangeEvent = bpmChangeMap[0];
			for (timeChange in bpmChangeMap) {
				if (stepTime >= timeChange.beatTime * STEPS_PER_BEAT) {
					lastTimeChange = timeChange;
					resultMs = lastTimeChange.songTime;
				} else {
					break;
				}
			}

			var lastStepLengthMs = ((SECS_PER_MIN / lastTimeChange.bpm) * MS_PER_SEC) / timeSignatureNum;
			resultMs += (stepTime - lastTimeChange.beatTime * STEPS_PER_BEAT) * lastStepLengthMs;

			return resultMs;
		}
	}
	public function forceBPM(?bpm: Float): Void {
		bpmOverride = bpm;
	}
	public function getBeatTimeInMs(beatTime: Float): Float {
		if (bpmChangeMap.length == 0) {
			return beatTime * stepLengthMs * STEPS_PER_BEAT;
		} else {
			var resultMs: Float = 0;

			var lastTimeChange: BPMChangeEvent = bpmChangeMap[0];
			for (timeChange in bpmChangeMap) {
				if (beatTime >= timeChange.beatTime) {
					lastTimeChange = timeChange;
					resultMs = lastTimeChange.songTime;
				} else {
					break;
				}
			}

			var lastStepLengthMs = ((SECS_PER_MIN / lastTimeChange.bpm) * MS_PER_SEC) / timeSignatureNum;
			resultMs += (beatTime - lastTimeChange.beatTime) * lastStepLengthMs * STEPS_PER_BEAT;

			return resultMs;
		}
	}
	static function get_instance(): Conductor {
		if (Conductor._instance == null) _instance = new Conductor();
		if (Conductor._instance == null) throw "Could not initialize singleton Conductor";
		return Conductor._instance;
	}

	
	public function update(?songPos:Float, applyOffsets:Bool = true) {
		if (songPos == null) {
			songPos = (FlxG.sound.music != null) ? FlxG.sound.music.time : 0.0;
		}
		songPos += applyOffsets ? (instrumentalOffset) : 0;

		var oldMeasure:Float = this.currentMeasure;
		var oldBeat: Float = this.currentBeat;
		var oldStep: Float = this.currentStep;

		this.songPosition = songPos;


		currentBpmChange = bpmChangeMap[0];
		if (this.songPosition > 0.0) {
			for (i in 0...bpmChangeMap.length) {
				if (this.songPosition >= bpmChangeMap[i].songTime) currentBpmChange = bpmChangeMap[i];

				if (this.songPosition < bpmChangeMap[i].songTime) break;
			}
		}
		if (currentBpmChange == null && bpmOverride == null && FlxG.sound.music != null) {
			trace("WARNING: Conductor is broken, timeChanges is empty");
		} else if (currentBpmChange != null && this.songPosition > 0.0) {
			this.currentStepTime = FlxMath.roundDecimal((currentBpmChange.beatTime * STEPS_PER_BEAT) + (this.songPosition - currentBpmChange.songTime) / stepLengthMs, 6);
			this.currentBeatTime = currentStepTime / STEPS_PER_BEAT;
			this.currentMeasureTime = currentStepTime / stepsPerMeasure;
			this.currentStep = Math.floor(this.currentStepTime);
			this.currentBeat = Math.floor(this.currentBeatTime);
			this.currentMeasure = Math.floor(this.currentMeasureTime);
		} else {
			this.currentStepTime = FlxMath.roundDecimal((songPosition / stepLengthMs), 4);
			this.currentBeatTime = currentStepTime / STEPS_PER_BEAT;
			this.currentMeasureTime = currentStepTime / stepsPerMeasure;
			this.currentStep = Math.floor(currentStepTime);
			this.currentBeat = Math.floor(currentBeatTime);
			this.currentMeasure = Math.floor(currentMeasureTime);
		}

		// prevTime = this.songPosition;
	}

}
