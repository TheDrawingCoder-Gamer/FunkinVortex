package commands;

import vortex.song.data.SongData.SongEventData;
import vortex.song.data.SongData.SongNoteData;
import vortex.song.data.SongDataUtils;

@:access(PlayState)
class RemoveItemsCommand implements EditorCommand {
	var notes:Array<SongNoteData>;
	var events:Array<SongEventData>;

	public function new(notes: Array<SongNoteData>, events:Array<SongEventData>)
	{
		this.notes = notes;
		this.events = events;
	}

	public function undo(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		if ((notes.length + events.length) == 0) return;
		for (note in notes) {
			state.currentSongChart.notes.push(note);
		}
		for (event in events) {
			state.songData.chart.events.push(event);
		}
		state.curSelectedNotes = notes;
		state.curSelectedEvents = events;

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function execute(state: PlayState):Void {
		if (state.currentSongChart == null) return;
		if ((notes.length + events.length) == 0) return;

		state.currentSongChart.notes = SongDataUtil.subtractNotes(state.currentSongCharts.notes, notes);
		state.songData.chart.events = SongDataUtils.subtractEvents(state.songData.chart.events, events);
		state.curSelectedNotes.clear();
		state.curSelectedEvents.clear();

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return notes.length > 0 || events.length > 0;
	}

	public function toString():String {
		return 'Remove ${notes.length + events.length} Items(s)';
	}
}
