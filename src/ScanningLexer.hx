package;

import haxe.Exception;
import haxe.Int64;

using StringTools;

// This is a position type for the lexer to realise where it is in the file
typedef Position = {
	var pos:Int64;
	var line:Int64;
}

// Token position
typedef TokenPosition = {
	var startPos:Int64;
	var endPos:Int64;
	var startLine:Int64;
	var endLine:Int64;
}

typedef Token = {
	var tokT:TokenT;
	var pos:TokenPosition;
}

// Now I can put ANY DATA I want into each enum item, cause HAXE POWAH
enum TokenT {
	UNKNOWN(v:String);
	EOF;

	TAB_INDENTATION(size:Int);
	SPACE_INDENTATION(size:Int);
	LINE_BREAK_LF;
	LINE_BREAK_CRLF;

	HEXADECIMAL(v:String);
	INTEGER(v:String);

	FLOAT(v:String);
	POINT_FLOAT(v:String);
	EULER_FLOAT(v:String);
	POINT_EULER_FLOAT(v:String);

	INTEGER_INTERVAL;

	COMMENT;
	COMMENT_MULTILINE;
	COMMENT_CONTENT(v:String);

	// Unary
	INCREMENT;
	DECREMENT;
	NEGATE;
	BITWISE_NOT;
	LOGICAL_NOT;
	// Binary
	MODULO;
	MULTIPLY;
	DIVIDE;
	ADD;
	SUBSTRACT;
	ASSIGN;
	// Binary with assignment
	MODULO_ASSIGN;
	MULTIPLY_ASSIGN;
	DIVIDE_ASSIGN;
	ADD_ASSIGN;
	SUBSTRACT_ASSIGN;
	// Bitwise
	SHIFT_LEFT;
	SHIFT_RIGHT;
	UNSIGNED_SHIFT_RIGHT;
	BITWISE_AND;
	BITWISE_OR;
	BITWISE_XOR;
	// Bitwise with assignment
	SHIFT_LEFT_ASSIGN;
	SHIFT_RIGHT_ASSIGN;
	UNSIGNED_SHIFT_RIGHT_ASSIGN;
	BITWISE_AND_ASSIGN;
	BITWISE_OR_ASSIGN;
	BITWISE_XOR_ASSIGN;
	// Logical
	LOGICAL_AND;
	LOGICAL_OR;
	// Comparison
	EQUAL;
	NOT_EQUAL;
	LESS;
	LESS_OR_EQUAL;
	GREATER;
	GREATER_OR_EQUAL;
	// Condition (3 args)
	CONDITION;
	// Pipe is either "=>" or
	PIPE;

	// -> for arrow functions and function types
	ARROW;

	SEMICOLON;
	COLON;
	COMMA;
	// QUESTION_MARK plus DOT for safe traversal, basically a glorified null check
	DOT;
	QUESTION_MARK;

	// "@" for metadata, everything else is handled with ident and other tokens
	METADATA_AT;

	// Bracket type
	ROUND_BRACKET_OPEN;
	ROUND_BRACKET_CLOSE;
	SQUARE_BRACKET_OPEN;
	SQUARE_BRACKET_CLOSE;
	CURLY_BRACKET_OPEN;
	CURLY_BRACKET_CLOSE;

	// TODO: think about regular expressions (should they have special syntax and stuff)
	//
	// keywords, all must be prefixed with KEYWORD_, cause lexer will match them ALL automatically
	KEYWORD_PACKAGE;
	KEYWORD_IMPORT;
	KEYWORD_USING;

	// redefine some type on import/using
	KEYWORD_AS;

	KEYWORD_CLASS;
	KEYWORD_INTERFACE;
	KEYWORD_ENUM;
	KEYWORD_ABSTRACT;
	KEYWORD_TYPE;
	KEYWORD_STRUCT;
	KEYWORD_EXTENDS;
	KEYWORD_IMPLEMENTS;
	KEYWORD_EXTERN;

	KEYWORD_PRIVATE;
	KEYWORD_PUBLIC;
	KEYWORD_STATIC;

	KEYWORD_INLINE;
	KEYWORD_OVERRIDE;
	KEYWORD_OPERATOR;
	KEYWORD_OVERLOAD;

	// TODO: add "!" at the end as macro function identifier, AND this, then see what sticks more with me and maybe other people i guess? macro is just more obvious
	/*
		TODO: also think of some fancy names for the "insert something in this place" and "mess with this entire thing's AST output"
		types of macros (!/macro macros and @:build macros). Maybe something like "Insert Macro" and "Modification Macro"?
		Sounds decent enough to me, and explains the way they work quite well.
	 */
	KEYWORD_MACRO;

	// less keystrokes for constant variables than final
	KEYWORD_VAL;
	KEYWORD_VAR;
	KEYWORD_FUNCTION;

	// this is a modifier, and it also works with var, it's more common in other languages than final, so it's kinda easier to remember it
	KEYWORD_CONST;

	KEYWORD_NULL;

	KEYWORD_TRUE;
	KEYWORD_FALSE;

	KEYWORD_THIS;

	KEYWORD_IF;
	KEYWORD_ELSE;

	KEYWORD_WHILE;
	KEYWORD_DO;
	KEYWORD_FOR;

	KEYWORD_IN;

	KEYWORD_BREAK;
	KEYWORD_CONTINUE;

	KEYWORD_RETURN;

	KEYWORD_SWITCH;
	KEYWORD_CASE;

	KEYWORD_DYNAMIC;
	KEYWORD_DEFAULT;
	KEYWORD_NEVER;

	KEYWORD_THROW;
	KEYWORD_TRY;
	KEYWORD_CATCH;

	KEYWORD_UNTYPED;

	KEYWORD_NEW;

	KEYWORD_CAST;

	// short for "identifier". it's either a class, or a variable, or some sort of a namespace
	IDENT(v:String);
}

enum LexerState {
	DEFAULT;

	STRING_ID;
	STRING;

	FORMATTED_STRING;
	FORMATTED_STRING_EXPRESSION;

	COMMENT_ID;
	COMMENT;

	REGULAR_EXPRESSION;

	LINE_BREAK;
}

class ScanningLexer {
	private var string:String = "";
	private var stringPos:Int = 0;
	private var filePos:Position = {pos: 1, line: 1};

	public function new() {}

	public function setScript(s:String) {
		string = s;
		stringPos = 0;
		filePos = {pos: 1, line: 1};
	}

	public function nextToken() {
		var tokenPos:TokenPosition = {
			startPos: filePos.pos,
			endPos: filePos.pos,
			startLine: filePos.line,
			endLine: filePos.line
		}

		if ((string == "") || (string == null) || (filePos.pos > string.length))
			return EOF;
		else if (checkNewline(false) != null) {
			var nline = checkNewline(true);
			tokenPos.endPos = filePos.pos--;
			return nline;
		} else if (~/[_a-z]/i.match(char())) {
			while (~/[-_a-z0-9]/i.match(char())) {}
			return IDENT("");
		} else {
			final char = char();
			throw new LexerException('Encountered unknown token "${char}" .', UNKNOWN(char));
		}
	}

	private function checkNewline(advance:Bool = false) {
		final current = charCode();

		if (current == "\n".code) {
			if (advance) {
				proceed();
				filePos.line++;
			}
			return TokenT.LINE_BREAK_LF;
		} else if (current == "\r".code && charCode(1) == "\n".code) {
			if (advance) {
				proceed(2);
				filePos.line++;
			}
			return TokenT.LINE_BREAK_CRLF;
		}

		return null;
	}

	private function checkIndentation(advance:Bool = true) {
		var token:TokenT;
		var len = 0;
		var charToCheck = 0;

		final tab = "\t".code;
		final space = " ".code;

		if (charCode() == space)
			charToCheck = space;
		else if (charCode() == tab)
			charToCheck = tab;

		if (charToCheck != 0) {
			while (charCode() == charToCheck) {
				len++;
				proceed();
			}

			if (charToCheck == tab)
				return TokenT.TAB_INDENTATION(len);
			else
				return TokenT.SPACE_INDENTATION(len);
		}

		return null;
	}

	private function proceed(amount:Int = 1) {
		stringPos += amount;
		filePos.pos += amount;
	}

	private function charCode(add:Int = 0) {
		return string.charCodeAt(stringPos + add);
	}

	private function char(add:Int = 0) {
		return string.charAt(stringPos + add);
	}
}
