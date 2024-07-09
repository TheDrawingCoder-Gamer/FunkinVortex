package commands;

import vortex.data.song.SongData.SongEventData;
import vortex.data.song.SongData.SongNoteData;

@:access(PlayState)
class DeselectAllItemsCommand implements EditorCommand {
	var previousNoteSelection: Array<SongNoteData> = [];
	var previousEventSelection: Array<SongEventData> = [];

	public function new() {}

	public function execute(state:PlayState): Void {
		this.previousNoteSelection = state.curSelectedNotes;
		this.previousEventSelection = state.curSelectedEvents;

		state.curSelectedNotes = [];
		state.curSelectedEvents = [];

		state.noteDisplayDirty = true;
	}

	public function undo(state:PlayState):Void {
		state.curSelectedNotes = this.previousNoteSelection;
		state.curSelectedEvents = this.previousEventSelection;

		state.noteDisplayDirty = true;
	}

	public function shouldAddToHistory(state:PlayState): Bool {
		return previousNoteSelection.length > 0 || previousEventSelection.length > 0;
	}
	public function toString(): String {
		return 'Deselect All Items';
	}
}
