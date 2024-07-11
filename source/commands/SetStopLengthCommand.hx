package commands;

import vortex.data.song.SongData.SongStop;
import vortex.util.SortUtil;
import flixel.util.FlxSort;
class SetStopLengthCommand implements EditorCommand {
	var row: Int;
	var oldLength: Float;
	var newLength: Float;
	public function new(row: Int, newLength: Float) {
		this.row = row;
		this.oldLength = 0;
		this.newLength = newLength;
	}

	public function execute(state:PlayState):Void {
		if (state.songData == null) return;
		if (newLength <= 0) {
			state.songData.stops = state.songData.stops.filter(x -> x.rowTime != row);
		} else {
			var stop: SongStop = null;
			for (item in state.songData.stops) {
				if (item.rowTime == row) {
					stop = item;
					break;
				}
			}
			if (stop != null) {
				this.oldLength = stop.length;
				stop.length = newLength;
			} else {
				state.songData.stops.push(new SongStop(row, newLength));
				state.songData.stops.insertionSort(SortUtil.stopByTime.bind(FlxSort.ASCENDING, _, _));
			}
		}
		state.tooltipsDirty = true;
	}

	public function undo(state:PlayState): Void {
		if (state.songData == null) return;
		if (oldLength <= 0) {
			state.songData.stops = state.songData.stops.filter(x -> x.rowTime != row);
		} else {
			for (item in state.songData.stops) {
				if (item.rowTime == row) {
					item.length = oldLength;
					return;
				}
			}
			state.songData.stops.push(new SongStop(row, oldLength));
			state.songData.stops.insertionSort(SortUtil.stopByTime.bind(FlxSort.ASCENDING, _, _));
		}
		state.tooltipsDirty = true;
	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return oldLength != newLength;
	}

	public function toString(): String {
		return 'Set Stop at $row to $newLength';
	}
}
