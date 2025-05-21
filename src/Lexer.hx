package;

import haxe.ds.GenericStack;
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
	// sorry for the name mistake, never used it in my life :sob: (i'm embarrassed)
	// like, who the hell works with numbers big enough to use this? 99.99999999% of the time you don't
	ENGI_FLOAT(v:String);
	POINT_ENGI_FLOAT(v:String);

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
	// TODO: (this is a part of a type argument syntax, so i'll write it here). To replace the union types, there are type constraints and Either,
	// but union types are nicer, and they're a part of Luau's type system, so it might be better to put some thought into it i guess?
	// maybe they should even work without typechecking via monomorphization if there will ever even be a native (LLVM) target.
	LESS;
	LESS_OR_EQUAL;
	GREATER;
	GREATER_OR_EQUAL;
	// Condition (3 args)
	CONDITION;
	// Pipe will be either "=>" or "|>"?
	// "|>" or "|" is more natural for a lot of people (thanks, bash, C++ and JS), but "=>" just looks better, and it's pretty much math-like.
	// i'm not adding "<|" though, because it's confusing. it literally breaks the execution flow. it's confusing,
	// because everything ALWAYS goes left to right, top to bottom, but this one time it just doesn't, it SUDDENLY goes backwards - right to left,
	// and it adds complexity to the implementation.
	// Also, instead of haxe's "for (k => v in iterable)" for key-value iteration, we're gonna use something like "for (k, v in iterable)".
	// if i'm not lazy, might also include something like key value iterators, but you can have >2 values.
	// map literal syntax should also be either '"string" = 0' or '"string": 0' instead of '"string" => 0'.
	PIPE;

	// -> for arrow functions and function types
	ARROW;

	SEMICOLON;
	COLON;
	COMMA;
	// QUESTION_MARK plus DOT for safe traversal, basically a glorified null check. sweet sweet syntax sugar, yum.
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

	// TODO: add "!" at the end as macro function identifier, AND this, then see what sticks more with me and maybe other people i guess? macro is just more obvious.
	/*
		TODO: also think of some fancy names for the "insert something in this place" and "mess with this entire thing's AST output"
		types of macros (!/macro macros and @:build macros). Maybe something like "Insert Macro" and "Modification Macro"?
		Sounds decent enough to me, and explains the way they work quite well.
	 */
	// haxe DOES support something like the "Insert" macros, but whatever. should probably think about the implementation stuff AFTER the parser is done,
	// because macros do things on the AST level.
	// basically all macros should be like in haxe, but they might have less limitations and stuff.
	// also i need to write GOOD docs.
	KEYWORD_MACRO;

	// less keystrokes for constant variables than final
	KEYWORD_VAL;
	KEYWORD_VAR;
	KEYWORD_FUNCTION;

	// this can be applied to functions in classes (override prevention), or classes (extension prevention).
	// basically says that "this definition is set in stone, and you cannot change it or expand upon it"
	KEYWORD_FINAL;

	// maybe make it so that Null is guaranteed to be falsy and never truthy? kinda like null or nullptr (when converted to a bool) in C/C++. would be nice.
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

	// not needed i think, it's barely even useful (aside from code insertion), so instead make the native code insertion like in the JS haxe API (the syntax package)
	// KEYWORD_UNTYPED
	KEYWORD_NEW;

	KEYWORD_CAST;

	// short for "identifier". it's either a class, or a variable, or some sort of a namespace
	IDENT(v:String);
}

// TODO: put all these in a stack or something, because the old system with "current state" and "next state" is bad, just literally do a stack
enum LexerState {
	NORMAL;

	// search for token of a string start/end identifier
	STRING_ID;
	// string-only tokens (escapes and stuff)
	STRING;

	// formatted-string-only tokens
	FORMATTED_STRING;
	// expression inside of a formatted string
	FORMATTED_STRING_EXPRESSION;

	// token of a comment start/end identifier
	COMMENT_ID;
	// comment-only tokens
	COMMENT;

	// regular expression tokens
	REGULAR_EXPRESSION;

	// just forces a line break return
	LINE_BREAK;
}

// this lexer is sort of inspired by the Luau lexer
class Lexer {
	private var string:String = "";
	private var stringPos:Int = 0;
	private var filePos:Position = {pos: 1, line: 1};

	private var states:GenericStack<LexerState> = new GenericStack();

	public function new() {
		states.add(NORMAL);
	}

	public function setScriptString(s:String) {
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

		switch states.first() {
			case NORMAL:
				return normalToken(tokenPos);
			// case STRING_ID:
			// return stringId(tokenPos);
			default:
				throw new LexerException("No lexer state was set, or behaviour for the current state is unimplemented!! Current state: "
					+ states.first().getName(), UNKNOWN(""));
		}
	}

	private function normalToken(tokenPos:TokenPosition) {
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
			// TODO: make sure that it moves on when there's an exception
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
