package;

// NO NOT WEEK 7 THAT CAN FUCK OFF
// A helper class to make supporting web easier
import flash.events.Event;
import flash.net.FileReference;
import flixel.FlxG;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.utils.Assets;
import openfl.utils.ByteArray;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class FNFAssets
{
	public static var _file:FileReference;
	static var fd:FileDialog;
	static var fdString:Null<String> = null;

	public static function getText(id:String):String
	{
		#if sys
		// if there a library strip it out..
		// future proofing ftw
		var path = Assets.exists(id) ? Assets.getPath(id) : null;
		if (path == null)
			path = id;
		return File.getContent(path);
		#else
		// no need to strip it out...
		// assets handles it
		return Assets.getText(id);
		#end
	}

	public static function getBytes(id:String):Bytes
	{
		#if sys
		// if there a library strip it out..
		// future proofing ftw
		var path = Assets.exists(id) ? Assets.getPath(id) : null;
		if (path == null)
			path = id;
		return File.getBytes(path);
		#else
		// no need to strip it out...
		// assets handles it
		return LimeAssets.getBytes(id);
		#end
	}

	public static function exists(id:String):Bool
	{
		#if sys
		var path = Assets.exists(id) ? Assets.getPath(id) : null;
		if (path == null)
			path = id;
		return FileSystem.exists(path);
		#else
		return Assets.exists(id);
		#end
	}

	public static function getBitmapData(id:String, ?useCache:Bool = true):BitmapData
	{
		#if sys
		// idk if this works lol
		var path = Assets.exists(id) ? Assets.getPath(id) : null;
		if (path == null)
			path = id;
		return BitmapData.fromFile(path);
		#else
		return Assets.getBitmapData(id, useCache);
		#end
	}

	public static function getSound(id:String, ?useCache:Bool = true)
	{
		#if sys
		var path = Assets.exists(id) ? Assets.getPath(id) : null;
		if (path == null)
			path = id;
		return Sound.fromFile(path);
		#else
		return Assets.getSound(id, useCache);
		#end
	}

	public static function askToBrowse(?filter:String, ?title:String = "Select a Chart"):Future<String>
	{
		fdString = null;
		fd = new FileDialog();
		fd.onSelect.add(onSelect);
		fd.browse(FileDialogType.OPEN, filter, null, title);
		var checkTimer = new Timer(50);
		var promise = new Promise<String>();
		checkTimer.run = function()
		{
			if (fdString != null)
			{
				promise.complete(FNFAssets.getText(fdString));
				checkTimer.stop();
			}
		}
		fd.onCancel.add(function()
		{
			promise.error("user cancelled");
			checkTimer.stop();
		});
		return promise.future;
	}

	public static function askToBrowseForPath(?filter:String, ?title:String = "Select a chart", why: FileDialogType = FileDialogType.OPEN):Future<String>
	{
		fdString = null;
		fd = new FileDialog();
		fd.onSelect.add(onSelect);
		fd.browse(FileDialogType.OPEN, filter, null, title);
		var checkTimer = new Timer(50);
		var promise = new Promise<String>();
		checkTimer.run = function()
		{
			if (fdString != null)
			{
				promise.complete(fdString);
				checkTimer.stop();
			}
		}
		fd.onCancel.add(function()
		{
			// sad promise hours
			promise.error("user cancelled");
			checkTimer.stop();
		});
		return promise.future;
	}

	static function onSelect(s:String):Void
	{
		trace(s);
		fdString = s;
	}

	public static function saveContent(id:String, data:String)
	{
		#if sys
		File.saveContent(id, data);
		#else
		askToSave(id, data);
		#end
	}

	public static function saveBytes(id:String, data:Bytes)
	{
		#if sys
		File.saveBytes(id, data);
		#else
		askToSave(id, data);
		#end
	}

	// you can save anything with this but you have to ask
	public static function askToSave(id:String, data:Dynamic)
	{
		_file = new FileReference();

		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		var idSus = Path.withoutDirectory(id);
		_file.save(data, idSus);
	}


	static function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	};

	static function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	};

	static function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}

// a proxy for HScript that gives some but not all of the features of
// regular FNFAssets
class HScriptAssets
{
	public static function getText(id:String):String
	{
		return FNFAssets.getText(id);
	}

	public static function getBytes(id:String):Bytes
	{
		return FNFAssets.getBytes(id);
	}

	public static function exists(id:String):Bool
	{
		return FNFAssets.exists(id);
	}

	public static function getBitmapData(id:String):BitmapData
	{
		return FNFAssets.getBitmapData(id);
	}

	public static function getSound(id:String):Sound
	{
		return FNFAssets.getSound(id);
	}
}
