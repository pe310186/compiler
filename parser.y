%{
#include "symbol.h"
#include "lex.yy.c"
#define Trace(t) if(Opt_p) cout << "TRACE =>" << t << endl;

int Opt_p = 1;

void yyerror(string s);

//symboltable
SymbolTableList symbols;
vector<vector<idInfo>> functions;
vector<string> ids_list;

%}

//yylval
%union {
  int int_val;
  double double_val;
  bool bool_val;
  string *str_val;
  idInfo *info;
  int type;
}


//tokens
%token LE GE NEQ AND OR
%token ARRAY BOOLEAN BEG BREAK CHAR CASE CONST CONTINUE DO ELSE END EXIT FOR FN IF IN INTEGER LOOP MODULE PRINT PRINTLN PROCEDURE REPEAT RETURN REAL STRING RECORD THEN TYPE USE UTIL VAR WHILE OF READ ASSIGN

%token <int_val> INT_CONST
%token <double_val> REAL_CONST
%token <bool_val> BOOLEAN_CONST
%token <str_val> STR_CONST
%token <str_val> ID

//non-terminal
%type <info> const_value expression func_invocation
%type <type> type opt_ret_type

//precedence
%left '*' '/'
%left '+' '-'
%left '<' LE '=' GE '>' NEQ
%left '~'
%left AND
%left OR
%left ASSIGN
%nonassoc UMINUS // '-' unary

%%

//program
program			: MODULE ID opt_var_dec opt_func_dec BEG opt_statement END ID '.'
			{
			  Trace("program")
			  if(*$2 != *$8) yyerror("module identifier not match");
			  symbols.dump();
			  symbols.pop();
			}
			;

const_decs		: const_decs const_dec
			| CONST const_dec
			;

const_dec  		: ID '=' const_value ';'
			{
			   Trace("constant declaration");

                          if (!isConst(*$3)) yyerror("expression not constant value"); // constant check 

                          $3->flag = constVariableFlag;
                          $3->init = true;
                          if (symbols.insert(*$1, *$3) == -1) yyerror("constant redefinition"); // symbol check
			}
			
			;

//multi-variable declaration
var_decs		: var_decs var_dec
			| VAR var_dec
			;


// variable declaration
var_dec                 : ids ':' type ';'
			{
			  Trace("variable declaration with type");
			  idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $3;
                          info->init = false;
			  for(int i=0;i<ids_list.size();i++)
			  {
			    if (symbols.insert(ids_list[i], *info) == -1) yyerror("variable redefinition"); // symbol check
			  }
			  ids_list.clear();
			}
			;



//one or more id
ids			: ID
			{
			  Trace("id");
			  ids_list.push_back(*$1);
			}
			| ids ',' ID 
			{
			  Trace("ids");
			  ids_list.push_back(*$3);
			}
			;




// array declaration
array_dec		: ids ':' ARRAY '[' expression ',' expression ']' OF type ';'
			{
			  Trace("array declaration");
			  if(!isConst(*$5) || !isConst(*$7)) yyerror("array index not const value");
			  if($5->type != intType || $7->type != intType) yyerror("array index not integer");
			  if($5->value.int_val < 0 || $7->value.int_val < 0) yyerror("array index less than zero");
			  if($5->value.int_val >= $7->value.int_val) yyerror("array left-index bigger than right-index");
			  for(int i=0;i<ids_list.size();i++){
			    if(symbols.insert(ids_list[i],$10,$5->value.int_val,$7->value.int_val) == -1) yyerror("variable redefinition");
			  }
			  ids_list.clear();
			}
			;





//procedure (function declaration)
func_dec		: PROCEDURE ID 
			{
			  Trace("function declaration");
			  idInfo *info = new idInfo();
			  info->flag = functionFlag;
			  info -> init = false;
			  if(symbols.insert(*$2, *info) == -1) yyerror("function redefinition");
			  symbols.push();
			}
			opt_ret_type BEG opt_statement END ID ';'
			{
			  symbols.dump();
			  symbols.pop();
			}
			| PROCEDURE ID 
			{
			  Trace("function declaration");
			  idInfo *info = new idInfo();
			  info->flag = functionFlag;
			  info -> init = false;
			  if(symbols.insert(*$2, *info) == -1) yyerror("function reefinition");
			  symbols.push();
			}
			'(' opt_arg ')' opt_ret_type BEG opt_statement END ID ';'
			{
			  symbols.dump();
			  symbols.pop();
			}
			;

//optional function declaration
opt_func_dec		: opt_func_dec func_dec 
			| //null
			;
	


//optional formal arguments
opt_arg			: args
			;

//formal argument
arg			: ID ':' type 
			{
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $3;
			  info->init = false;
			  if(symbols.insert(*$1,*info) == -1) yyerror("variable redefinition");
			  symbols.addFuncArg(*$1,*info);
			}
			;


//formal arguments
args			: arg ',' args
			| arg
			;

//optioanl return type
opt_ret_type 		: ':' type
			{
			  symbols.setFuncType($2);
			}
			| //void (no return)
			{
			  symbols.setFuncType(voidType);
			}
			;

// type define
type			: INTEGER
			{
			  $$ = intType;
			}
			| BOOLEAN
			{
			  $$ = boolType;
			}
			| CHAR
			{
			  $$ = charType;
			}
			| STRING
			{
			  $$ = strType;
			}
			| REAL
			{
			  $$ = realType;
			}
			;

//constant value
const_value             : INT_CONST
                        {
                          $$ = intConst($1);
                        }
                        | REAL_CONST
                        {
                          $$ = realConst($1);
                        }
                        | BOOLEAN_CONST
                        {
                          $$ = boolConst($1);
                        }
                        | STR_CONST
                        {
                          $$ = strConst($1);
                        }
			;

//optional variable and const declaration
opt_var_dec		: array_dec opt_var_dec   
			| const_decs opt_var_dec  
			| var_decs opt_var_dec 
			| //null
			;

	


//optional statement
opt_statement		: statement  opt_statement 
			| //null
			;
//statement
statement		: simple
			| expression
			| conditional
			| loop
			;
//simple
simple			: ID ASSIGN expression ';'
			{
                          Trace("statement: variable assignment");

                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared indentifier"); // declaration check 
                          if (info->flag == constVariableFlag) yyerror("can't assign to constant"); // constant check
                          if (info->flag == functionFlag) yyerror("can't assign to function"); // function check
                          if (info->type != $3->type) yyerror("type not match"); // type check
			}
			| ID '[' expression ']' ASSIGN expression ';'
			{
                          Trace("statement: array assignment");

                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared indentifier"); // declaration check 
                          if (info->flag != variableFlag) yyerror("not a variable"); // variable check 
                          if (info->type != arrayType) yyerror("not a array"); // type check 
                          if ($3->type != intType) yyerror("index not integer"); // index type check
                          if($3->value.int_val < info->value.arr_start_index || $3->value.int_val > info->value.arr_end_index) yyerror("index out of range");
                          if (info->value.array_val[0].type != $6->type) yyerror("type not match"); // type check
			}
			| PRINT expression ';'
			{
			  cout << "test";
			  Trace("statement print expression");
			}
			| PRINTLN expression ';'
			{
			  Trace("statement println expression");
			}
			| READ ID ';'
			{
			  Trace("statement: read ");
			}
			| RETURN ';'
			{
			  Trace("statement return");
			}
			| RETURN expression ';'
			{
			  Trace("statement return expression");
			}
			| expression ';'
			;

//expression
expression		: ID
			{
			  idInfo *info = symbols.lookup(*$1);
			  if (info == NULL) yyerror("undeclared identifier");
			  $$ = info;
			}
			| const_value
			{
			  cout << "const_value" <<endl;
			}
			| ID '[' expression ']'
			{
			  idInfo *info = symbols.lookup(*$1);
			  if (info == NULL) yyerror("undeclared identifier");
			  if (info->type != arrayType) yyerror("not array type ");
			  if($3->type != intType) yyerror("invaild index");
			  if($3->value.int_val < info->value.arr_start_index || $3->value.int_val > info->value.arr_end_index) yyerror("index out of range");
			  $$ = new idInfo(info->value.array_val[$3->value.int_val]);
			}
			| func_invocation
			| '-' expression %prec UMINUS
			{
			  Trace("- expression");

			  if($2->type != intType && $2->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $2->type;
			  $$ = info;
			}
			| expression '*' expression
			{
			 Trace("expression * expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $1->type;
			  $$ = info;
			}
			| expression '/' expression
			{
			  Trace("expression / expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $1->type;
			  $$ = info;
			}
			| expression '+' expression
			{
			  Trace("expression + expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType && $1->type != strType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $1->type;
			  $$ = info;
			}
			| expression '-' expression
			{
			  Trace("expression - expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $1->type;
			  $$ = info;
			}
			| expression '<' expression
			{
			  Trace("expression < expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| expression LE expression
			{
			  Trace("expression <= expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			|expression '=' expression
			{
			  Trace("expression = expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = $1->type;
			  $$ = info;
			}
			| expression GE expression
			{
			  Trace("expression => expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| expression '>' expression
			{
			  Trace("expression <= expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| expression NEQ expression
			{
			  Trace("expression <> expression");
			  if($1->type != $3->type) yyerror("type not the same");
			  if($1->type != intType && $1->type != realType && $1->type != boolType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| '~' expression
			{
			  Trace("~ expression");
			  if($2->type != boolType) yyerror("type not match");
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| expression AND expression
			{
			  Trace("expression && expression");
			  if($1->type!= $3-> type) ("type not the same");
			  if($1->type != boolType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| expression OR expression
			{
			  Trace("expression || expression");
			  if($1->type!= $3-> type) ("type not the same");
			  if($1->type != boolType) yyerror("operator error");
			  
			  idInfo *info = new idInfo();
			  info->flag = variableFlag;
			  info->type = boolType;
			  $$ = info;
			}
			| '(' expression ')'
			{
			  Trace("expression");
			  $$ = $2;
			}
			;

//procedure invocation(function invocation)
/*func_invocation		: ID 
			{
			  functions.push_back(vector<idInfo>());
			}
			'(' opt_comma_seperated ')'
			{
			  Trace("statement: function invocation");
			  idInfo *info = symbols.lookup(*$1);
			  if(info == NULL) yyerror("undeclared identifier");
			  if(info->flag != functionFlag) yyerror("not a function");
			  
			  vector<idInfo> para = info->value.array_val;
			  
			  if(para.size() != functions[functions.size()-1].size()) yyerror("parameter size not macth");
			  for(int i=0;i<para.size();i++){
			    if(para[i].type != functions[functions.size() -1 ].at(i).type) yyerror("parameter type not match");
			  }
			  
			}
			;
*/

func_invocation		: ID '(' 
			{
			  functions.push_back(vector<idInfo>());
			}
			opt_comma_seperated ')'
			{
			  Trace("statement: function invocation");
			  idInfo *info = symbols.lookup(*$1);
			  cout << "type:"<<  info->type << endl;
			  if(info == NULL) yyerror("undeclared identifier");
			  if(info->flag != functionFlag) yyerror("not a function");
			  
			  vector<idInfo> para = info->value.array_val;	  

			  if(para.size() != functions[functions.size()-1].size()) yyerror("parameter size not macth");
			  for(int i=0;i<para.size();i++){
			    if(para[i].type != functions[functions.size() -1 ].at(i).type) yyerror("parameter type not match");
			  }
			  $$ = info;
			}
			;


/*

//optional comma-seperated expression
opt_comma_seperated	: comma_seperated 
			| //null
			;
*/
opt_comma_seperated	: expres
			|
			;

expres			: expres ',' expression
			{
			  functions[functions.size()-1].push_back(*$3);
			}
			| expression
			{
			  functions[functions.size()-1].push_back(*$1);
			}
			;
/*


//comma-seperated expression
comma_seperated		: func_expression ',' comma_seperated
			| func_expression
			;



//function expression
func_expression		: expression
			{
			  functions[functions.size()-1].push_back(*$1);
			}
			;
*/


//conditional
conditional		: IF expression THEN opt_statement ELSE opt_statement END ';'
			{
			  Trace("statement: if else");
			  if($2->type != boolType) yyerror("conditional type error");
			}
			| IF expression THEN opt_statement END ';'
			{
			  Trace("statement: if");
			  if($2->type != boolType) yyerror("conditinal type error");
			}
			;

//loop
loop			: WHILE '(' expression ')' DO opt_statement END ';'
			{
			  Trace("statement: while loop");
			  if($3->type != boolType) yyerror("conditional type error");
			}
			;

%%


void yyerror(string msg)
{
    cerr << "line  " << linenum << ": " << msg << endl;
    exit(0);
}

int main(void)
{
  yyparse();
  return 0;

}
