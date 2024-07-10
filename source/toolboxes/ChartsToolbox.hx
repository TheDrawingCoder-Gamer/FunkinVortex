package toolboxes;

import vortex.data.song.SongData.ChartKey;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Button;


@:access(PlayState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/toolboxes/charts.xml"))
class ChartsToolbox extends BaseToolbox {
	public function new(parent2:PlayState) {
		super(parent2);
		initialize();

		this.onDialogClosed = onClose;
	}

	function onClose(event:UIEvent) {
		playstate.toggleToolboxCharts.selected = false;
	}

	function initialize():Void {
		this.x = 150;
		this.y = 250;

		refresh();
	}

	public override function refresh(): Void {
		super.refresh();

		if (playstate.songData == null) return;

		chartMembers.removeAllComponents();

		final components: Map<ChartKey, ChartDifficulty> = [];
		for (id => chart in playstate.songData.chart.charts) {
			if (components.exists(chart.chartKey)) {
				// : )
				components.get(chart.chartKey).chartIds.push(id);
			} else {
				components.set(chart.chartKey, new ChartDifficulty(playstate, '${chart.chartKey.gamemode} - ${chart.chartKey.difficulty}', chart.chartKey, [id]));
			}
		}
		for (_ => component in components) {
			chartMembers.addComponent(component);
		}
	}
}

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/toolboxes/charts/diff.xml"))
class ChartDifficulty extends haxe.ui.containers.VBox {
	public var diff: String;
	public var chartKey: ChartKey;
	public var chartIds: Array<Int>;
	public var playstate: PlayState;
	public function new(parent: PlayState, diff:String, chartKey: ChartKey, chartIds: Array<Int>) {
		super();
		this.playstate = parent;
		this.diff = diff;
		this.chartKey = chartKey;
		this.chartIds = chartIds;

		refresh();
	}
	public function refresh(): Void {
		diffName.text = diff;
		diffCharts.removeAllComponents();
		for (i => id in chartIds) {
			final coolChart = new Button();
			coolChart.text = '$diff $i';
			coolChart.onClick = function(e:MouseEvent) {
				playstate.loadChart(id);
			};
			addComponent(coolChart);
		}
	}

	
}
