package toolboxes;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.core.Component;

@:access(PlayState)
class BaseToolbox extends CollapsibleDialog {
	var playstate: PlayState;
	private function new(parent:PlayState) {
		super();
		this.playstate = parent;
		this.destroyOnClose = false;
	}
	public function refresh() {}
}
