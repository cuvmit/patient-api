grammar QueryDSL;

// The main entry point for defining our custom DSL grammar.
query
  : expression WHITESPACE* EOF
  ;

// A separate entry point to handle an incomplete query that the user is still
// in the process of typing. A complete query is also a valid case for this.
partialQuery
  : partialExpression WHITESPACE* EOF
  ;

// These are not just comments over on the right. They're labels which ANTLR
// generates rule contexts for. See "Alternative Labels" at:
// https://github.com/antlr/antlr4/blob/master/doc/parser-rules.md
expression
  : groupBegin expression groupEnd                         # groupExpr
  | not WHITESPACE+ expression                             # notExpr
  | expression WHITESPACE+ and WHITESPACE+ expression      # andExpr
  | expression WHITESPACE+ or WHITESPACE+ expression       # orExpr
  | nestedObjectFieldQuery                                 # nestedObject
  | fieldQuery                                             # atomExpr
  ;

partialExpression
  : groupBegin expression groupEnd                           # groupExprFullPart
  | groupBegin partialExpression                             # groupExprPart
  | groupBegin                                               # groupBeginPart
  | not WHITESPACE+ partialExpression                        # notExprPart
  | expression WHITESPACE+ and WHITESPACE+ partialExpression # andExprFullPart
  | expression WHITESPACE+ and WHITESPACE*                   # andExprFullPart
  | expression WHITESPACE+ or WHITESPACE partialExpression   # orExprFullPart
  | expression WHITESPACE+ or WHITESPACE*                    # orExprFullPart
  | fieldName nestedObjectBegin expression nestedObjectEnd   # nestedObjectFieldQueryFullPart
  | fieldName nestedObjectBegin partialExpression            # nestedObjectFieldQueryPart
  | fieldName nestedObjectBegin                              # nestedObjectExpectingFieldName
  | fieldQuery                                               # bareFieldQuery
  | fieldName COLON                                          # fieldNameExpectingTerm
  | fieldName                                                # bareFieldName
  ;

// eg. species:canine
fieldQuery
  : fieldName COLON termExpression
  ;

// Fields with the "nested" mapping type. Allow for searching with these
// so all matching subfields must belong to the same object.
// procedures{name:adrenalectomy and time:>=2018} vs. "procedures.name:adrenalectomy
// and procedures.time:>=2018", which would match different procedures that meet
// either of those criteria.
nestedObjectFieldQuery
  : fieldName nestedObjectBegin expression nestedObjectEnd
  ;

// eg. species
fieldName
	: fieldNameChar+
	;

fieldNameChar
  : LETTERORDIGIT
  | UNDERSCORE
  | andOrNotChar
  ;


// eg. canine, "cat stevens", >=2018
termExpression
  : comparisonOperator? termText
  | DOUBLEQUOTE phraseChar+ DOUBLEQUOTE
  ;

phraseChar
  : termChar
  | WHITESPACE
  | LPAREN
  | RPAREN
  | AMPERSAND
  | PLUS
  | FORWARD_SLASH
  | LT
  | GT
  ;

termText
  : termChar+
  ;

termChar
  : LETTERORDIGIT
  | UNDERSCORE
  | HYPHEN
  | COMMA
  | andOrNotChar
  ;

// ANTLR will only pick one lexer rule to match a given character or literal
// string. If we have a lexer rule for OR, then it will treat the "or" in
// "lagomorpha" as an OR token, and that will cause problems in the parsing step.
// Hence, we treat these characters seperately so we can define and/or/not as
// parse rules instead and use these characters in multiple parse rules.
andOrNotChar
  : (A | D | N | O | R | T) ;

and
  : A N D ;

or
  : O R ;

not
  : N O T ;

comparisonOperator
  : GT EQUAL  # greaterThanEqual
  | GT        # greaterThan
  | LT EQUAL  # lessThanEqual
  | LT        # lessThan
  ;

groupBegin
  : LPAREN WHITESPACE*
  ;

groupEnd
  : WHITESPACE* RPAREN
  ;

nestedObjectBegin
  : LBRACE WHITESPACE*
  ;

nestedObjectEnd
  : WHITESPACE* RBRACE
  ;

LPAREN : '(';
RPAREN : ')';

LBRACE : '{';
RBRACE : '}';

// It may be tempting to expand these and pull them straight up into the fieldName
// and termExpression rules. However, there is a distinction in ANTLR between
// lexer rules, which start with uppercase letters, and parser rules. The
// lexer rules should not assign the same char in multiple rules, or the one
// that should take precedence should be defined first. Then lexing can proceed
// as the first step without any understanding of parse rule context.
A: [aA];
D: [dD];
N: [nN];
O: [oO];
R: [rR];
T: [tT];
LETTERORDIGIT: [a-zA-Z0-9];
COLON: ':';
COMMA: ',';
DOUBLEQUOTE: '"';
EQUAL: '=';
GT: '>';
LT: '<';
HYPHEN: '-';
UNDERSCORE: '_';
AMPERSAND: '&';
PLUS: '+';
FORWARD_SLASH: '/';
WHITESPACE: [ \t\n];
ERR_CHAR : . ;
