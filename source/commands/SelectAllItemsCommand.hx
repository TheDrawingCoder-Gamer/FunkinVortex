package commands;

import vortex.data.song.SongData.SongEventData;
import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongDataUtils;

@:access(PlayState)
class SelectAllItemsCommand implements EditorCommand {
	var previousNoteSelection: Array<SongNoteData> = [];
	var previousEventSelection: Array<SongEventData> = [];

	public function new()
	{
	}

	public function execute(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		this.previousNoteSelection = state.curSelectedNotes;
		this.previousEventSelection = state.curSelectedEvents;

		state.curSelectedNotes = state.currentSongChart.notes.clone();
		state.curSelectedEvents = state.songData.chart.events.clone();

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function undo(state: PlayState):Void {
		state.curSelectedNotes = previousNoteSelection.clone();
		state.curSelectedEvents = previousEventSelection.clone();

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return previousNoteSelection.length > 0 || previousEventSelection.length > 0;
	}

	public function toString():String {
		return 'Select All Items(s)';
	}
}
