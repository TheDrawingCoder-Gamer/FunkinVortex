package toolboxes;

import haxe.ui.events.UIEvent;


@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/toolboxes/tempotoolbox.xml"))
@:access(PlayState)
class TempoToolbox extends BaseToolbox {
	public function new(parent2:PlayState) {
		super(parent2);

		initialize();
		this.onDialogClosed = onClose;
	}

	function onClose(e:UIEvent) {
		playstate.toggleToolboxTempo.selected = false;
	}

	public function initialize(): Void {
		this.x = 150;
		this.y = 250;

		inputBPM.onChange = function(e:UIEvent) {
			// : )
			playstate.setBPMAt(playstate.getRow(playstate.strumLine.y), e.target.value);
		};
		inputStop.onChange = function(e:UIEvent) {
			playstate.setStopAt(playstate.getRow(playstate.strumLine.y), e.target.value);
		};
		refresh();
	}
	public override function refresh():Void {
		if (playstate.songData == null) return;
		inputBPM.value = playstate.timeChangeAt(playstate.getRow(playstate.strumLine.y))?.bpm ?? 100;
		inputStop.value = playstate.stopAt(playstate.getRow(playstate.strumLine.y))?.length ?? 0;

	}
}
