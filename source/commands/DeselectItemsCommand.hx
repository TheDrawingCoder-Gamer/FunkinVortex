package commands;

import vortex.data.song.SongData.SongEventData;
import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongDataUtils;

@:access(PlayState)
class DeselectItemsCommand implements EditorCommand {
	var notes:Array<SongNoteData>;
	var events:Array<SongEventData>;

	public function new(notes: Array<SongNoteData>, events:Array<SongEventData>)
	{
		this.notes = notes;
		this.events = events;
	}

	public function undo(state: PlayState):Void {
		for (note in notes) {
			state.curSelectedNotes.push(note);
		}
		for (event in events) {
			state.curSelectedEvents.push(event);
		}

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

	}

	public function execute(state: PlayState):Void {
		state.curSelectedNotes = SongDataUtils.subtractNotes(state.curSelectedNotes, notes);
		state.curSelectedEvents = SongDataUtils.subtractEvents(state.curSelectedEvents, events);

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;

	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return notes.length > 0 || events.length > 0;
	}

	public function toString():String {
		if (notes.length == 0) {
			return 'Deselect ${events.length} Event(s)';
		} else if (events.length == 0) {
			return 'Deselect ${notes.length} Note(s)';
		}
		return 'Deselect ${notes.length + events.length} Items(s)';
	}
}
