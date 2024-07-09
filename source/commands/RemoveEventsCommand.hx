package commands;

import vortex.song.data.SongData.SongEventData;
import vortex.song.data.SongDataUtils;

@:access(PlayState)
class RemoveEventsCommand implements EditorCommand {
	var events:Array<SongEventData>;

	public function new(events:Array<SongEventData>)
	{
		this.events = events;
	}

	public function undo(state: PlayState):Void {
		for (event in events) {
			state.songData.chart.events.push(event);
		}
		state.curSelectedNotes = [];
		state.curSelectedEvents = events;

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function execute(state: PlayState):Void {
		if (state.songData == null) return;
		if (events.length == 0) return;
		state.songData.chart.events = SongDataUtils.subtractEvents(state.songData.chart.events, events);
		state.curSelectedNotes = [];
		state.curSelectedEvents = [];

		state.saveDataDirty = true;
		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

		state.sortChartData();
	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return events.length > 0;
	}

	public function toString():String {
		return 'Remove ${events.length} Events(s)';
	}
}
