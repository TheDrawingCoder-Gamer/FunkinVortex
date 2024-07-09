package commands;

interface EditorCommand {
	public function execute(state:PlayState):Void;

	public function undo(state:PlayState):Void;

	public function shouldAddToHistory(state:PlayState):Bool;

	public function toString():String;
}
