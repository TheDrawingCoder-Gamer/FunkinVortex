package;

import vortex.data.song.SongData.SongTimeChange;
import vortex.data.song.SongDataUtils;
import flixel.FlxG;
import flixel.math.FlxMath;





class Conductor
{
	public static var instance(get, never): Conductor;
	static var _instance:Null<Conductor> = null;

	static function get_instance(): Conductor {
		if (Conductor._instance == null) set_instance(new Conductor());
		if (Conductor._instance == null) throw 'Could not init singleton Conductor!';
		return Conductor._instance;
	}
	static function set_instance(conductor: Conductor): Conductor {
		Conductor._instance = conductor;

		return Conductor._instance;
	}
	public var currentRowTime(default, null):Float;
	public var songPosition(default, null):Float;
	public var lastSongPos:Float;
	public var offset:Float = 0;
	public var timeChanges: Array<SongTimeChange> = [];
	public var currentTimeChange(default, null): Null<SongTimeChange>;
	public  var instrumentalOffset:Float = 0;

	public var timeSignatureNum(get, never): Int;
	function get_timeSignatureNum(): Int {
		if (currentTimeChange == null) return Constants.DEFAULT_TIME_SIGNATURE_NUM;

		return currentTimeChange.timeSignatureNum;
	}
	public var timeSignatureDen(get, never): Int;
	function get_timeSignatureDen(): Int {
		if (currentTimeChange == null) return Constants.DEFAULT_TIME_SIGNATURE_DEN;

		return currentTimeChange.timeSignatureDen;
	}
	public var bpm(get, never): Float;
	function get_bpm(): Float {
		if (bpmOverride != null) return bpmOverride;
		if (currentTimeChange == null) return Constants.DEFAULT_BPM;

		return currentTimeChange.bpm;
	}
	public var startingBPM(get, never): Float;
	function get_startingBPM(): Float {
		if (bpmOverride != null) return bpmOverride;
		var timeChange = timeChanges[0];
		if (timeChange == null) return Constants.DEFAULT_BPM;

		return timeChange.bpm;
	}
	// questionably integral
	public var stepsPerMeasure(get, never): Int;
	function get_stepsPerMeasure(): Int {
		if (currentTimeChange == null) return 16;
		return currentTimeChange.stepsPerMeasure();
	}


	public var measureLengthMs(get, never): Float;

	function get_measureLengthMs(): Float {
		return beatLengthMs * timeSignatureNum;
	}

	public var beatLengthMs(get, never): Float;

	function get_beatLengthMs(): Float {
		return ((Constants.SECS_PER_MINUTE / bpm) * Constants.MS_PER_SEC);
	}
	public var stepLengthMs(get, never): Float;

	// ?
	function get_stepLengthMs(): Float {
		return beatLengthMs / Constants.STEPS_PER_BEAT;
	}

	public var rowLengthMs(get, never): Float;
	function get_rowLengthMs(): Float {
		return beatLengthMs / Constants.ROWS_PER_BEAT;
	}
	var bpmOverride: Null<Float> = null;

	public var currentMeasure(default, null): Int = 0;

	public var currentBeat(default, null): Int = 0;

	public var currentStep(default, null): Int = 0;

	public var currentMeasureTime(default, null): Float = 0;

	public var currentBeatTime(default, null): Float = 0;

	public var currentStepTime(default, null): Float = 0;

	public function new() {}


	public function mapTimeChanges(songTimeChanges: Array<SongTimeChange>): Void {
		timeChanges = [];

		SongDataUtils.sortTimeChanges(songTimeChanges);
		
		for (timeChange in songTimeChanges) {
			if (timeChange.rowTime < 0) timeChange.rowTime = 0;
			if (timeChange.rowTime <= 0) {
				timeChange.time = 0.0;
			} else {
				timeChange.time = 0.0;

				if (timeChange.rowTime > 0 && timeChanges.length > 0) {
					var prevTimeChange = timeChanges[timeChanges.length - 1];
					timeChange.time = prevTimeChange.time + ((timeChange.rowTime - prevTimeChange.rowTime) / Constants.ROWS_PER_BEAT) / prevTimeChange.bpm;
				}
			}

			timeChanges.push(timeChange);

		}
		if (timeChanges.length > 0) {
			trace('Done mapping time changes: ${timeChanges}');
		}

		this.update(this.songPosition, false);
	}

	public function timeChangeAt(ms:Float):SongTimeChange {
		var lastTimeChange = timeChanges[0];
		for (timeChange in timeChanges) {
			if (ms >= timeChange.time) {
				lastTimeChange = timeChange;
			} else {
				break;
			}
		}
		return lastTimeChange;
	}
	public function getTimeInSteps(ms:Float):Float
	{
		if (timeChanges.length == 0) {
			return Math.floor(ms / stepLengthMs);
		} else {
			var resultStep: Float = 0;

			var lastTimeChange = timeChanges[0];
			for (bpmChange in timeChanges) {
				if (ms >= bpmChange.time) {
					lastTimeChange = bpmChange;
					resultStep = lastTimeChange.rowTime / Constants.ROWS_PER_STEP;
				} else {
					break;
				}
			}

			var lastStepLengthMs: Float = ((Constants.SECS_PER_MINUTE / lastTimeChange.bpm) * Constants.MS_PER_SEC) / timeSignatureNum;
			var resultFractionalStep: Float = (ms - lastTimeChange.time) / lastStepLengthMs;
			resultStep += resultFractionalStep;

			return resultStep;
		}
	}
	public function getTimeInRows(ms:Float):Int 
	{
		final stepTime = getTimeInSteps(ms);
		return Math.round(stepTime / Constants.ROWS_PER_STEP);
	}

	public function getStepTimeInMs(stepTime: Float): Float {
		return getRowTimeInMs(stepTime * Constants.ROWS_PER_STEP);
	}
	public function getRowTimeInMs(rowTime: Float): Float {
		if (timeChanges.length == 0) {
			return rowTime * rowLengthMs;
		} else {
			var resultMs: Float = 0;

			var lastTimeChange = timeChanges[0];
			for (timeChange in timeChanges) {
				if (rowTime >= timeChange.rowTime) {
					lastTimeChange = timeChange;
					resultMs = lastTimeChange.time;
				} else {
					break;
				}
			}
			var lastRowLengthMs = ((Constants.SECS_PER_MINUTE / lastTimeChange.bpm) * Constants.MS_PER_SEC) / Constants.ROWS_PER_BEAT;
			resultMs += (rowTime - lastTimeChange.rowTime) * lastRowLengthMs;

			return resultMs;

		}
	}


	public function forceBPM(?bpm: Float): Void {
		bpmOverride = bpm;
	}
	public function getBeatTimeInMs(beatTime: Float): Float {
		if (timeChanges.length == 0) {
			return beatTime * stepLengthMs * Constants.STEPS_PER_BEAT;
		} else {
			var resultMs: Float = 0;

			var lastTimeChange = timeChanges[0];
			for (timeChange in timeChanges) {
				if (beatTime >= timeChange.rowTime / Constants.ROWS_PER_BEAT) {
					lastTimeChange = timeChange;
					resultMs = lastTimeChange.time;
				} else {
					break;
				}
			}

			var lastStepLengthMs = ((Constants.SECS_PER_MINUTE / lastTimeChange.bpm) * Constants.MS_PER_SEC) / timeSignatureNum;
			resultMs += (beatTime - lastTimeChange.rowTime / Constants.ROWS_PER_BEAT) * lastStepLengthMs * Constants.STEPS_PER_BEAT;

			return resultMs;
		}
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


		currentTimeChange = timeChanges[0];
		if (this.songPosition > 0.0) {
			for (i in 0...timeChanges.length) {
				if (this.songPosition >= timeChanges[i].time) currentTimeChange = timeChanges[i];

				if (this.songPosition < timeChanges[i].time) break;
			}
		}
		if (currentTimeChange == null && bpmOverride == null && FlxG.sound.music != null) {
			trace("WARNING: Conductor is broken, timeChanges is empty");
		} else if (currentTimeChange != null && this.songPosition > 0.0) {
			this.currentRowTime = FlxMath.roundDecimal(currentTimeChange.rowTime + (this.songPosition - currentTimeChange.time) / rowLengthMs, 6);
			this.currentStepTime = FlxMath.roundDecimal((currentTimeChange.rowTime * Constants.ROWS_PER_STEP) + (this.songPosition - currentTimeChange.time) / stepLengthMs, 6);
			this.currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
			// ?
			this.currentMeasureTime = currentStepTime / stepsPerMeasure;
			this.currentStep = Math.floor(this.currentStepTime);
			this.currentBeat = Math.floor(this.currentBeatTime);
			this.currentMeasure = Math.floor(this.currentMeasureTime);
		} else {
			this.currentRowTime = FlxMath.roundDecimal((songPosition / rowLengthMs), 4);
			this.currentStepTime = FlxMath.roundDecimal((songPosition / stepLengthMs), 4);
			this.currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
			this.currentMeasureTime = currentStepTime / stepsPerMeasure;
			this.currentStep = Math.floor(currentStepTime);
			this.currentBeat = Math.floor(currentBeatTime);
			this.currentMeasure = Math.floor(currentMeasureTime);
		}

		// prevTime = this.songPosition;
	}

}
