package toolboxes;

import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.components.Slider;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;

@:access(PlayState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/toolboxes/metadata.xml"))
class MetadataToolbox extends BaseToolbox {
	/*
	var inputSongName:TextField;
	var inputSongArtist:TextField;
	var inputSongCharter:TextField;
	var inputStage:TextField;
	var inputNoteStyle:TextField;
	var inputPlayer:TextField;
	var inputOpponent:TextField;
	var inputGirlfriend:TextField;
	var labelScrollSpeed:Label;
	var inputScrollSpeed:Slider;
	var labelDifficultyRating:Label;
	var inputDifficultyRating:NumberStepper;
	var labelStepmaniaRating:Label;
	var inputStepmaniaRating:Slider;
	var frameDifficulty:Frame;
	*/

	public function new(parent2:PlayState) {
		super(parent2);

		initialize();

		this.onDialogClosed = onClose;
	}

	function onClose(event:UIEvent) {
		playstate.toggleToolboxMetadata.selected = false;
	}

	function initialize():Void {
		this.x = 150;
		this.y = 250;

		inputSongName.onChange = function (event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputSongName.removeClass('invalid-value');
				playstate.songData.songName = event.target.text;
			} else {
				playstate.songData.songName = '';
			}
		};

		inputSongArtist.onChange = function(event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputSongArtist.removeClass('invalid-value');
				playstate.songData.artist = event.target.text;
			} else {
				playstate.songData.artist = '';
			}
		};

		inputSongCharter.onChange = function(event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputSongCharter.removeClass('invalid-value');
				playstate.songData.charter = event.target.text;
			} else {
				playstate.songData.charter = null;
			}
		};

		inputStage.onChange = function (event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputStage.removeClass('invalid-value');
				playstate.songData.playData.stage = event.target.text;
			} else {
				playstate.songData.playData.stage = '';
			}
		};
		inputNoteStyle.onChange = function(event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputNoteStyle.removeClass('invalid-value');
				playstate.songData.playData.noteStyle = event.target.text;
			} else {
				playstate.songData.playData.noteStyle = '';
			}
		};
		inputPlayer.onChange = function(event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputPlayer.removeClass('invalid-value');
				playstate.songData.playData.characters.player = event.target.text;
			} else {
				playstate.songData.playData.characters.player = '';
			}
		};
		inputOpponent.onChange = function(event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputOpponent.removeClass('invalid-value');
				playstate.songData.playData.characters.opponent = event.target.text;
		} else {
				playstate.songData.playData.characters.opponent = '';
			}
		};
		inputGirlfriend.onChange = function(event:UIEvent) {
			var valid = event.target.text != null && event.target.text != '';
			if (valid) {
				inputGirlfriend.removeClass('invalid-value');
				playstate.songData.playData.characters.girlfriend = event.target.text;
			} else {
				playstate.songData.playData.characters.girlfriend = '';
			}
		};

		inputScrollSpeed.onChange = function(event:UIEvent) {
			var valid = event.target.value != null && event.target.value > 0;

			if (valid) {
				inputScrollSpeed.removeClass('invalid-value');
				playstate.currentSongChart.scrollSpeed = event.target.value;
			} else {
				playstate.currentSongChart.scrollSpeed = 0;
			}
			labelScrollSpeed.text = 'Scroll Speed ${playstate.currentSongChart.scrollSpeed}x';
		};
		inputDifficultyRating.onChange = function(event:UIEvent) {
			playstate.currentSongChart.rating = event.target.value;
		};
		inputStepmaniaRating.onChange = function(event:UIEvent) {
			playstate.currentSongChart.stepmaniaRating = event.target.value;
		};
	
		refresh();
	}

	public override function refresh():Void {
		super.refresh();

		inputSongName.value = playstate.songData.songName;
		inputSongArtist.value = playstate.songData.artist;
		inputSongCharter.value = playstate.songData.charter;
		inputStage.value = playstate.songData.playData.stage;
		inputNoteStyle.value = playstate.songData.playData.noteStyle;
		inputDifficultyRating.value = playstate.currentSongChart.rating;
		inputStepmaniaRating.value = playstate.currentSongChart.stepmaniaRating;
		inputPlayer.value = playstate.songData.playData.characters.player;
		inputOpponent.value = playstate.songData.playData.characters.opponent;
		inputGirlfriend.value = playstate.songData.playData.characters.girlfriend;
		frameDifficulty.text = 'Chart: ${playstate.selectedChart}';

	}
}
