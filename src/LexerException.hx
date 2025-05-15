import ScanningLexer.TokenT;
import haxe.Exception;

class LexerException extends Exception {
	public var token:TokenT;

	public function new(message:String, token:ScanningLexer.TokenT, ?previous:Null<Exception>, ?native:Null<Any>) {
		super(message, previous, native);
		this.token = token;
	}
}
