package commands;

import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongDataUtils;

@:access(PlayState)
class RemoveNotesCommand implements EditorCommand {
	var notes:Array<SongNoteData>;

	public function new(notes:Array<SongNoteData>)
	{
		this.notes = notes;
	}

	public function undo(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		for (note in notes) {
			state.currentSongChart.notes.push(note);
		}
		state.curSelectedNotes = notes;
		state.curSelectedEvents = [];

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function execute(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		if (notes.length == 0) return;
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
		return 'Remove ${notes.length} Note(s)';
	}
}
