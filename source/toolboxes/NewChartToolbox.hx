package toolboxes;

import vortex.data.song.Gamemode;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import vortex.data.song.SongData.SongChart;
import vortex.data.song.SongData.ChartKey;

@:access(PlayState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/toolboxes/newchart.xml"))
class NewChartToolbox extends BaseToolbox {
	var currentGamemode: Null<Gamemode> = null;

	public function new(parent2: PlayState) {
		super(parent2);

		initialize();


	}

	function initialize():Void {
		this.x = 150;
		this.y = 250;
		for (mode in Gamemode.gamemodes) {
			inputChart.dataSource.add(mode.displayName);
		}
		inputChart.onChange = function (event:UIEvent) {
			if (event.target.value == null) return;
			for (mode in Gamemode.gamemodes) {
				if (mode.displayName == event.target.value) {
					currentGamemode = mode;
					return;
				}
			}
		};

		buttonCreate.onClick = function(event:UIEvent) {
			if (currentGamemode == null) return; // : (
			
			// :)
			final diff = 
				if (inputDifficulty.text == 'Edit' && inputEditDifficulty.text != null && inputEditDifficulty.text != "")
					inputEditDifficulty.text
				else
					inputDifficulty.text.toLowerCase();

			final key = new ChartKey(diff, currentGamemode.id);
			final chart = new SongChart(key, 1.0, [], inputFNFRating.value, inputStepmaniaRating.value);
			playstate.songData.chart.charts[key] = chart;
			playstate.loadChart(key);
			hideDialog(DialogButton.SAVE);
		}
	}

}
