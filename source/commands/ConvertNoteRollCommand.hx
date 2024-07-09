package commands;

import vortex.data.song.SongData.SongNoteData;

@:access(PlayState)
class ConvertNoteRollCommand implements EditorCommand {
	var notes:Array<SongNoteData>;
	final oldRolls:Array<Bool>;
	var asRoll:Bool;
	public function new(notes:Array<SongNoteData>, asRoll:Bool) {
		this.notes = notes;
		this.oldRolls = notes.map(it -> it.isRoll);
		this.asRoll = asRoll;
	}
	public function execute(state:PlayState):Void {
		for (note in notes) {
			note.isRoll = asRoll;
		}

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
		state.saveDataDirty = true;
	}

	public function undo(state:PlayState):Void {
		for (i => note in notes) {
			note.isRoll = oldRolls[i];
		}

		state.noteDisplayDirty = true;
		state.notePreviewDirty = true;
		state.saveDataDirty = true;
	}

	public function shouldAddToHistory(state:PlayState):Bool {
		return notes.length > 0;
	}

	public function toString(): String {
		return 'Converted ${notes.length} Note(s) to ${asRoll ? "Roll" : "Sustain"}';
	}
}
