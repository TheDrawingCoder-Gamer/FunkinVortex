package commands;

import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongDataUtils;

@:access(PlayState)
class AddNotesCommand implements EditorCommand {
	var notes:Array<SongNoteData>;
	var appendToSelection:Bool;

	public function new(notes:Array<SongNoteData>, appendToSelection:Bool = false)
	{
		this.notes = notes;
		this.appendToSelection = appendToSelection;
	}

	public function execute(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		for (note in notes) {
			state.currentSongChart.notes.push(note);
		}

		if (appendToSelection) {
			state.curSelectedNotes = state.curSelectedNotes.concat(notes);
		} else {
			state.curSelectedNotes = notes;
			state.curSelectedEvents = [];
		}

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function undo(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		state.currentSongChart.notes = SongDataUtils.subtractNotes(state.currentSongChart.notes, notes);
		state.curSelectedNotes = [];
		state.curSelectedEvents = [];

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return notes.length > 0;
	}

	public function toString():String {
		return 'Add ${notes.length} Note(s)';
	}
}
