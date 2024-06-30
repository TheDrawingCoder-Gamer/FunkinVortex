package;

/**
 * An abstract to make working with raw note data easier
 */
@:build(ArrayAbstractMacro.buildAbstract())
abstract NoteData(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var strumTime:Float;
	public var noteDirection:Int;
	public var sustainLength:Null<Float>;
	public var altNote:Any;
}
