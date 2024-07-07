package;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import vortex.data.song.Gamemode;
import flixel.graphics.FlxGraphic;

class StrumLine extends FlxTypedSpriteGroup<StrumNote> {
	public var gamemode(default, null): Gamemode = Gamemode.DANCE_SINGLE;
	public var noteCount(default, null): Int = 4;
	public function new() {
		super();
		// hardcoded max
		for (i in 0...10) {
			final strumNote = new StrumNote();
			add(strumNote);
		}
	}
	public function setup(gamemode: Gamemode) {
		this.gamemode = gamemode;
		for (member in this.members) {
			member.kill();
		}
		this.noteCount = gamemode.noteCount;
		for (i in 0...noteCount) {
			final strumNote = members[i];
			strumNote.revive();
			strumNote.setup(i, gamemode);
			strumNote.x = this.x + 45 * i;
			strumNote.y = this.y;
		}

	}
	public function get(index: Int): Null<StrumNote> {
		var i = 0;
		for (item in this.members) {
			if (!item.alive) continue;
			if (i == index) return item;
			i++;
		}
		return null;
	}
}

// A strumline note : )
class StrumNote extends FlxSprite {
	public var colorSwap: ColorSwapShader.ColorSwap;
	var animVariant: String = "norm";
	public function new() {
		super();

		colorSwap = new ColorSwapShader.ColorSwap();

		this.frames = FlxTileFrames.fromGraphic(FlxGraphic.fromAssetKey("assets/images/arrow.png"), new FlxPoint(16, 16));

		this.shader = colorSwap.shader;

		animation.add('static-norm', [0]);
		animation.add('pressed-norm', [2, 4]);
		animation.add('confirm-norm', [5, 6]);

		animation.add('static-diag', [7]);
		animation.add('pressed-diag', [9, 11]);
		animation.add('confirm-diag', [12, 13]);

		animation.add('static-center', [14]);
		animation.add('pressed-center', [16, 18]);
		animation.add('confirm-center', [19, 20]);


		this.active = true;
		this.antialiasing = false;

		setGraphicSize(40);
		updateHitbox();

	}

	public function setup(index: Int, gamemode: Gamemode) {

		switch (gamemode) {
			case Gamemode.DANCE_SINGLE | Gamemode.DANCE_DOUBLE | Gamemode.DANCE_COUPLE | Gamemode.DANCE_ROUTINE:
				// : )
				this.angle = switch (index % 4) {
					case 0:
						90;
					case 1: 0;
					case 2: 180;
					case 3: -90;
					default: 0;
				};
				this.animVariant = "norm";
			case Gamemode.DANCE_SOLO:
				this.angle = switch (index) {
					case 0: 90;
					case 1: 180;
					case 2: 0;
					case 3: 180;
					case 4: -90;
					case 5: -90;
					default: 0;
				};
				this.animVariant = switch (index) {
					case 1 | 4: "diag";
					default: "norm";
				};
			case Gamemode.DANCE_THREEPANEL:
				this.angle = switch (index) {
					case 0: 90;
					case 1: 180;
					case 2: -90;
					default: 0;
				};
				this.animVariant = "norm";
			case Gamemode.PUMP_SINGLE | Gamemode.PUMP_DOUBLE | Gamemode.PUMP_COUPLE | Gamemode.PUMP_ROUTINE:
				this.angle = switch (index % 5) {
					case 0: 90;
					case 1: 180;
					case 2: 0;
					case 3: -90;
					case 4: 0;
					default: 0;
				};
				this.animVariant = switch (index % 5) {
					case 2: "center";
					default: "diag";
				};
			case Gamemode.PUMP_HALFDOUBLE:
				this.angle = switch (index) {
					case 0 | 5: 0;
					case 1: -90;
					case 2: 0;
					case 3: 90;
					case 4: 180;
					default: 0;
				};
				this.animVariant = switch (index) {
					case 0 | 5: "center";
					default: "diag";
				};
			default:

		}
		playStatic();
	}

	public function playStatic():Void {
		this.active = false;
		this.animation.play('static-$animVariant', true);
	}
	public function playPress(): Void {
		this.active = true;
		this.animation.play('pressed-$animVariant', true);
	}
	public function playConfirm(): Void {
		this.active = true;
		this.animation.play('confirm-$animVariant', true);
	}
	public override function update(elapsed:Float): Void {
		super.update(elapsed);
		// ?
	}
}
