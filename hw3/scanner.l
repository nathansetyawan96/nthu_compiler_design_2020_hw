/* scanner.l */

%{
#include "y.tab.h"
#include "def.h"
#include "code.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>

int yyparse();
int id_or_keyword(char *text);
int check_id_exist(char *text);
int test_install_sym(char *text, unsigned int type);
int look_up_symbol_kw(char *s);

FILE *f_asm;

char *copys();

%}

digit		[0-9]
fraction	[.]{digit}*
sign		[+|-]
integer		{sign}?{digit}+
exp		[E|e]{sign}?{integer}
float_num       {integer}{fraction}
exp_num  	[{integer}|{float_num}]{exp}
id		[a-zA-Z][a-zA-Z0-9_]*
blank		[ \t]+

%%
{blank}			; /* do nothing */
"\n"			{ lineno++;			}
"%" { printf("A mod op: %s\n", yytext); return('%');}
"/" { printf("A div op: %s\n", yytext); return('/');}
"("			{ printf("An lp: %s\n", yytext);
                          return('(');                  }
")"			{ printf("An rp: %s\n", yytext);
                          return(')');                  }
"{"			{ printf("An lc: %s\n", yytext);
                          return('{');                  }
"}" 			{ printf("An rc: %s\n", yytext);
                          return('}');                  }
"["			{ printf("An lb: %s\n", yytext);
                          return('[');                  }
"]"			{ printf("An lb: %s\n", yytext);
                          return(']');                  }
"->"			{ printf("A strcut op: %s\n", yytext);
                          return(POINTSAT);                  }  
"."			{ printf("A strcut op: %s\n", yytext); 
                          return('+');                  }  
"++"			{ printf("An inc op: %s\n", yytext);     
                          return(PLUSPLUS);                  } 
"--"			{ printf("An inc op: %s\n", yytext);   
                          return(MINUSMINUS);                  } 
"*"			{ printf("A star: %s\n", yytext);
                          return('*');                  } 
"+"			{ printf("A plus: %s\n", yytext);       
                          return('+');                  }  
"-"			{ printf("A minus: %s\n", yytext);  
                          return('-');                  }
[<|>]=?			{ printf("A relation op: %s\n", yytext);
                          return(ARITHCOMPARE);         }
"="			{ printf("A equal: %s\n", yytext);	
                          return('=');                  }  
","			{ printf("A comma: %s\n", yytext);	
                          return(',');                  }  
";"			{ printf("A semi-colon: %s\n", yytext);	 
                          return(';');                  }  
{id} 			{
                         int value;
			 switch(id_or_keyword(yytext)) {
                         case IDENTIFIER:
			    if (!check_id_exist(yytext))
                               test_install_sym(yytext, IDENTIFIER);
			    printf("An id: %s\n", yytext);
                            value = IDENTIFIER;	
                            yylval.ident= copys(yytext);
			    break;
			 default:
                            /* test_install_sym(yytext, id_or_keyword(yytext)); */
			    printf("A keyword: %s\n", yytext);
                            value = id_or_keyword(yytext);
			    break;
                         }
                         return(value);
			}
"/*"			{
			 dummy: while (input()!='*');
			 if (input()=='/') 
			    break;
			 else 
			    goto dummy;
			}
{integer}               {
                          test_install_sym(yytext, INTEGER);
                          printf("An integer: %s\n", yytext);
                          yylval.token= atoi(yytext);
	                  return(CONSTANT);
                        }
{float_num}             {
                          test_install_sym(yytext, FLOAT);
                          printf("A float num: %s\n", yytext);
                          return(CONSTANT);
                        }
"#"			{ while (input()!='\n') ;}
\"			{ while (input()!='"');}
.			{ printf("Error...: %s, %d\n", yytext, lineno); }

%%

int id_or_keyword(char *text)
{
	int i;

	for (i=0; i<(sizeof(k_tab)/sizeof(KWORD)); i++) {
		if (!strcmp(text, k_tab[i].name))
			return k_tab[i].value;
	}
	return IDENTIFIER;
}

int check_id_exist(char *text)
{
	int i;

	for (i=0; i<sym_tbl_index && sym_tbl[i].lexptr!=NULL; i++) {
		if (!strcmp(text, sym_tbl[i].lexptr))
			return TRUE;
	}
	return FALSE;
}

int look_up_symbol_kw(char *s) {
  if (sym_tbl_index == 0)
    return -1;
  for (int i = sym_tbl_index - 1; i >= 0; i--) {
    if (!strcmp(s, sym_tbl[i].lexptr)) return i;
  }
}

int yywrap()
{
	int i;
	printf("Total Lines: %d\n\n", lineno);
	printf("YYTEXT\t\tVALUE\n");
	printf("---------------------\n");
	for(i=0; i<sym_tbl_index; i++) {
		printf("%s\t\t", sym_tbl[i].lexptr);
		switch(sym_tbl[i].token) {
			case IDENTIFIER:
				printf("%s \n", sym_tbl[i].attrib.sval);
				break;
			case INTEGER:
				printf("%d \n", sym_tbl[i].attrib.ival);
				break;
			case FLOAT:
				printf("%f \n", sym_tbl[i].attrib.fval);
				break;
			default:
				printf("%s \n", sym_tbl[i].attrib.sval);
				break;
		}
	}
	return TRUE;
}

int test_install_sym(char *text, unsigned int type)
{
	sym_tbl[sym_tbl_index].lexptr=(char*)malloc(sizeof(char*)); 
	strcpy(sym_tbl[sym_tbl_index].lexptr, text);
	sym_tbl[sym_tbl_index].token=type;
	switch(type) {
		case IDENTIFIER:
			sym_tbl[sym_tbl_index].attrib.sval=(char*)malloc(sizeof(char*));     
			strcpy(sym_tbl[sym_tbl_index].attrib.sval, text);
			break;
		case INTEGER:
			sym_tbl[sym_tbl_index].attrib.ival=atoi(text);
			break;
		case FLOAT:
			sym_tbl[sym_tbl_index].attrib.fval=atof(text);
			break;
		default:
			sym_tbl[sym_tbl_index].attrib.sval=(char*)malloc(sizeof(char*));  
			strcpy(sym_tbl[sym_tbl_index].attrib.sval, text);
			break;
	}
	sym_tbl_index++;
	return TRUE;
}

void code_gen_with_header(char *filename)
{
	fprintf(f_asm,"      .text\n");
	fprintf(f_asm,"      .file \"%s\"\n",filename);
}

void main(int argc, char **argv)
{
	int i;

	--argc; ++argv;
	lineno=0;
	if (argc>0) 
		yyin=fopen(argv[0], "r");
	else 
		yyin=stdin;

	if ((f_asm = fopen("test.s", "w")) == NULL) {
		fprintf(stderr, "Cant open the file %s for write\n", "test.s");
		exit(1);
	}

	init_symbol_table();
	code_gen_with_header(argv[0]);
	if (i = yyparse()) {
		fprintf(stderr,"Bad parse, return code %d\n", i);
	}
	else
		fprintf(stdout,"\nParsing Successfully\n");

	code_gen_global_vars();
}
