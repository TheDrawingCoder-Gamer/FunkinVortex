package commands;

import vortex.data.song.SongData.SongTimeChange;
import vortex.util.SortUtil;
import flixel.util.FlxSort;

@:access(PlayState)
class SetBPMCommand implements EditorCommand {
	var row: Int;
	var oldBPM: Float;
	var oldRow: Null<SongTimeChange> = null;
	var newBPM: Float;
	public function new(row: Int, newBPM: Float) {
		this.row = row;
		this.oldBPM = 0;
		this.newBPM = newBPM;
	}

	public function execute(state:PlayState):Void {
		if (state.songData == null) return;
		var lastBPM: SongTimeChange = null;
		// assumes sorted
		for (item in state.songData.timeChanges) {
			if (item.rowTime < row) {
				// : )
				lastBPM = item;
			} else break;
		}
		var rowBPM: SongTimeChange = null;
		for (item in state.songData.timeChanges) {
			if (item.rowTime == row) {
				rowBPM = item;
				break;
			}
		}

		if (rowBPM != null) {
			oldRow = rowBPM.clone();
			rowBPM.bpm = newBPM;
		}

		 
		// ???
		if (lastBPM != null && rowBPM != null && lastBPM.sameTimingAs(rowBPM)) {
			state.songData.timeChanges = state.songData.timeChanges.filter(x -> x.rowTime != row);
		} else {
			if (rowBPM != null) {
				rowBPM.bpm = newBPM;
			} else if (lastBPM != null) {
				final newOne = lastBPM.clone();
				newOne.rowTime = row;
				newOne.bpm = newBPM;
				state.songData.timeChanges.push(newOne);
				state.songData.timeChanges.insertionSort(SortUtil.timeChangeByTime.bind(FlxSort.ASCENDING, _, _));
			}
		}
		state.tempoToolbox.refresh();
		state.tooltipsDirty = true;
	}

	public function undo(state:PlayState): Void {
		if (state.songData == null) return;
		state.songData.timeChanges = state.songData.timeChanges.filter(x -> x.rowTime != row);
		if (oldRow != null) {
			// clone?
			state.songData.timeChanges.push(oldRow.clone());
			state.songData.timeChanges.insertionSort(SortUtil.timeChangeByTime.bind(FlxSort.ASCENDING, _, _));
		}
		state.tooltipsDirty = true;
	}

	public function shouldAddToHistory(state: PlayState): Bool {
		return oldBPM != newBPM;
	}
	public function toString(): String {
		return 'Set BPM to $newBPM';
	}
}
