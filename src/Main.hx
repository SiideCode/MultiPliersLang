package;

import Lexer;
#if cpp
import cpp.link.StaticStd;
import cpp.link.StaticRegexp;
#end

class Main {
	// it's only a test script rn
	static function main() {
		var lex = new Lexer();
		lex.setScriptString("
			// oval
			/*
			boval
			*/
			package src_al.cac;

			import heya.iam.Bob;

			class Greeting
			{
				var aa = 0x32ba;
				var M:Int = 34;
				var H:Float = 34.5;
				var L:String = \" elo \";
				var regexpr = ~/[A-Z]/i;

				H += 2;

				H >>= 3;

				H *= 2;

				H = H / 2;

				H /= 2;

				print(L);
			}
		");
		try {
			lex.nextToken();
		} catch (e:LexerException) {
			Sys.println(e.message);
		}
		Sys.println("Any key to exit");
		Sys.stdin().readLine();
	}
}
