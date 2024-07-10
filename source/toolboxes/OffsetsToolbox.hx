package toolboxes;

import haxe.ui.events.UIEvent;


@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/toolboxes/offsets.xml"))
class OffsetsToolbox extends BaseToolbox {
	public function new(parent2:PlayState) {
		super(parent2);

		initialize();
		this.onDialogClosed = onClose;
	}

	function onClose(e:UIEvent) {
		playstate.toggleToolboxOffsets.selected = false;
	}

	public function initialize(): Void {
		this.x = 150;
		this.y = 250;

		inputInstOffset.onChange = function(e:UIEvent) {
			// : )
			if (playstate.songData?.offsets == null) return;
			playstate.songData.offsets.instrumental = e.target.value;
		};
		inputPlayerOffset.onChange = function(e:UIEvent) {
			if (playstate.songData == null) return;
			final playerId = playstate.songData.playData.characters.player;
			playstate.songData.offsets.vocals.set(playerId, e.target.value);
		};
		inputOpponentOffset.onChange = function(e:UIEvent) {
			if (playstate.songData == null) return;
			final oppId = playstate.songData.playData.characters.opponent;
			playstate.songData.offsets.vocals.set(oppId, e.target.value);
		};

		refresh();
	}
	public override function refresh():Void {
		if (playstate.songData == null) return;
		inputInstOffset.value = playstate.songData.offsets.instrumental;
		final playerId = playstate.songData.playData.characters.player;
		inputPlayerOffset.value = playstate.songData.offsets.vocals[playerId] ?? 0;
		final oppId = playstate.songData.playData.characters.opponent;
		inputOpponentOffset.value = playstate.songData.offsets.vocals[oppId] ?? 0;

	}
}
