''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2005 Andre Victor T. Vicentini (av1ctor@yahoo.com.br)
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' symbol table module
''
'' chng: sep/2004 written [v1ctor]
''		 jan/2005 updated to use real linked-lists [v1ctor]

option explicit
option escape

defint a-z
'$include: 'inc\fb.bi'
'$include: 'inc\fbint.bi'
'$include: 'inc\hash.bi'
'$include: 'inc\list.bi'
'$include: 'inc\rtl.bi'
'$include: 'inc\ast.bi'
'$include: 'inc\ir.bi'
'$include: 'inc\emit.bi'

type SYMBCTX
	inited			as integer

	symlist			as TLIST					'' symbols (VAR, CONST, FUNCTION, UDT, ENUM, LABEL, etc)
	symhash			as THASH

	loclist			as TLIST					'' local symbols (/)
	lochash			as THASH

	senlist			as TLIST					'' sentinels
	senhash			as THASH

	locsenlist		as TLIST					'' local sentinels
	locsenhash		as THASH

	liblist 		as TLIST					'' libraries
	libhash			as THASH

	arglist			as TLIST					'' proc arguments
	dimlist			as TLIST					'' array dimensions

	lastlbl			as FBSYMBOL ptr
end type


declare function 	hCalcDiff		( byval dimensions as integer, dTB() as FBARRAYDIM, byval lgt as integer ) as integer

declare function 	hCalcElements2	( byval dimensions as integer, dTB() as FBARRAYDIM ) as integer

declare function 	hCheckTypeField	( symbol as string, byval preservecase as integer, _
					      			  byval clearname as integer, fields as string ) as FBSYMBOL ptr


declare sub 		hDelSentinel	( byval s as FBSENTINEL ptr, byval isglobal as integer )


''globals
	dim shared ctx as SYMBCTX


'' predefined #defines: name, value, is_string
definesdata:
data "FB__VERSION",			FB.VERSION,		TRUE
data "FB__SIGNATURE",		FB.SIGN,		TRUE
#ifdef TARGET_WIN32
data "FB__WIN32",			"",				FALSE
#elseif defined(TARGET_LINUX)
data "FB__LINUX",			"",				FALSE
#elseif defined(TARGET_DOS)
data "FB__DOS",			    "",				FALSE
#endif
data ""


'' keywords: name, id (token), class
keyworddata:
data "AND"		, FB.TK.AND			, FB.TKCLASS.OPERATOR
data "OR"		, FB.TK.OR			, FB.TKCLASS.OPERATOR
data "XOR"		, FB.TK.XOR			, FB.TKCLASS.OPERATOR
data "EQV"		, FB.TK.EQV			, FB.TKCLASS.OPERATOR
data "IMP"		, FB.TK.IMP			, FB.TKCLASS.OPERATOR
data "NOT"		, FB.TK.NOT			, FB.TKCLASS.OPERATOR
data "MOD"		, FB.TK.MOD			, FB.TKCLASS.OPERATOR
data "SHL"		, FB.TK.SHL			, FB.TKCLASS.OPERATOR
data "SHR"		, FB.TK.SHR			, FB.TKCLASS.OPERATOR
data "REM"		, FB.TK.REM			, FB.TKCLASS.KEYWORD
data "DIM"		, FB.TK.DIM			, FB.TKCLASS.KEYWORD
data "STATIC"	, FB.TK.STATIC		, FB.TKCLASS.KEYWORD
data "SHARED"	, FB.TK.SHARED		, FB.TKCLASS.KEYWORD
data "INTEGER"	, FB.TK.INTEGER		, FB.TKCLASS.KEYWORD
data "LONG"		, FB.TK.LONG		, FB.TKCLASS.KEYWORD
data "SINGLE"	, FB.TK.SINGLE		, FB.TKCLASS.KEYWORD
data "DOUBLE"	, FB.TK.DOUBLE		, FB.TKCLASS.KEYWORD
data "STRING"	, FB.TK.STRING		, FB.TKCLASS.KEYWORD
data "CALL"		, FB.TK.CALL		, FB.TKCLASS.KEYWORD
data "BYVAL"	, FB.TK.BYVAL		, FB.TKCLASS.KEYWORD
data "INCLUDE"	, FB.TK.INCLUDE		, FB.TKCLASS.KEYWORD
data "DYNAMIC"	, FB.TK.DYNAMIC		, FB.TKCLASS.KEYWORD
data "AS"		, FB.TK.AS			, FB.TKCLASS.KEYWORD
data "DECLARE"	, FB.TK.DECLARE		, FB.TKCLASS.KEYWORD
data "GOTO"		, FB.TK.GOTO		, FB.TKCLASS.KEYWORD
data "GOSUB"	, FB.TK.GOSUB		, FB.TKCLASS.KEYWORD
data "DEFINT"	, FB.TK.DEFINT		, FB.TKCLASS.KEYWORD
data "DEFLNG"	, FB.TK.DEFLNG		, FB.TKCLASS.KEYWORD
data "DEFSNG"	, FB.TK.DEFSNG		, FB.TKCLASS.KEYWORD
data "DEFDBL"	, FB.TK.DEFDBL		, FB.TKCLASS.KEYWORD
data "DEFSTR"	, FB.TK.DEFSTR		, FB.TKCLASS.KEYWORD
data "DEFBYTE"	, FB.TK.DEFBYTE		, FB.TKCLASS.KEYWORD
data "DEFUBYTE"	, FB.TK.DEFUBYTE	, FB.TKCLASS.KEYWORD
data "DEFSHORT"	, FB.TK.DEFSHORT	, FB.TKCLASS.KEYWORD
data "DEFUSHORT", FB.TK.DEFUSHORT	, FB.TKCLASS.KEYWORD
data "DEFUINT"	, FB.TK.DEFUINT		, FB.TKCLASS.KEYWORD
data "CONST"	, FB.TK.CONST		, FB.TKCLASS.KEYWORD
data "FOR"		, FB.TK.FOR			, FB.TKCLASS.KEYWORD
data "STEP"		, FB.TK.STEP		, FB.TKCLASS.KEYWORD
data "NEXT"		, FB.TK.NEXT		, FB.TKCLASS.KEYWORD
data "TO"		, FB.TK.TO			, FB.TKCLASS.KEYWORD
data "TYPE"		, FB.TK.TYPE		, FB.TKCLASS.KEYWORD
data "END"		, FB.TK.END			, FB.TKCLASS.KEYWORD
data "SUB"		, FB.TK.SUB			, FB.TKCLASS.KEYWORD
data "FUNCTION"	, FB.TK.FUNCTION	, FB.TKCLASS.KEYWORD
data "CDECL"	, FB.TK.CDECL		, FB.TKCLASS.KEYWORD
data "STDCALL"	, FB.TK.STDCALL		, FB.TKCLASS.KEYWORD
data "ALIAS"	, FB.TK.ALIAS		, FB.TKCLASS.KEYWORD
data "LIB"		, FB.TK.LIB			, FB.TKCLASS.KEYWORD
data "LET"		, FB.TK.LET			, FB.TKCLASS.KEYWORD
data "BYTE"		, FB.TK.BYTE		, FB.TKCLASS.KEYWORD
data "UBYTE"	, FB.TK.UBYTE		, FB.TKCLASS.KEYWORD
data "SHORT"	, FB.TK.SHORT		, FB.TKCLASS.KEYWORD
data "USHORT"	, FB.TK.USHORT		, FB.TKCLASS.KEYWORD
data "UINTEGER"	, FB.TK.UINT		, FB.TKCLASS.KEYWORD
data "EXIT"		, FB.TK.EXIT		, FB.TKCLASS.KEYWORD
data "DO"		, FB.TK.DO			, FB.TKCLASS.KEYWORD
data "LOOP"		, FB.TK.LOOP		, FB.TKCLASS.KEYWORD
data "RETURN"	, FB.TK.RETURN		, FB.TKCLASS.KEYWORD
data "ANY"		, FB.TK.ANY			, FB.TKCLASS.KEYWORD
data "PTR"		, FB.TK.PTR			, FB.TKCLASS.KEYWORD
data "POINTER"	, FB.TK.POINTER		, FB.TKCLASS.KEYWORD
data "VARPTR"	, FB.TK.VARPTR		, FB.TKCLASS.KEYWORD
data "WHILE"	, FB.TK.WHILE		, FB.TKCLASS.KEYWORD
data "UNTIL"	, FB.TK.UNTIL		, FB.TKCLASS.KEYWORD
data "WEND"		, FB.TK.WEND		, FB.TKCLASS.KEYWORD
data "CONTINUE"	, FB.TK.CONTINUE	, FB.TKCLASS.KEYWORD
data "CINT"		, FB.TK.CINT		, FB.TKCLASS.KEYWORD
data "CLNG"		, FB.TK.CLNG		, FB.TKCLASS.KEYWORD
data "CSNG"		, FB.TK.CSNG		, FB.TKCLASS.KEYWORD
data "CDBL"		, FB.TK.CDBL		, FB.TKCLASS.KEYWORD
data "CBYTE"	, FB.TK.CBYTE		, FB.TKCLASS.KEYWORD
data "CSHORT"	, FB.TK.CSHORT		, FB.TKCLASS.KEYWORD
data "CSIGN"	, FB.TK.CSIGN		, FB.TKCLASS.KEYWORD
data "CUNSG"	, FB.TK.CUNSG		, FB.TKCLASS.KEYWORD
data "IF"		, FB.TK.IF			, FB.TKCLASS.KEYWORD
data "THEN"		, FB.TK.THEN		, FB.TKCLASS.KEYWORD
data "ELSE"		, FB.TK.ELSE		, FB.TKCLASS.KEYWORD
data "ELSEIF"	, FB.TK.ELSEIF		, FB.TKCLASS.KEYWORD
data "SELECT"	, FB.TK.SELECT		, FB.TKCLASS.KEYWORD
data "CASE"		, FB.TK.CASE		, FB.TKCLASS.KEYWORD
data "IS"		, FB.TK.IS			, FB.TKCLASS.KEYWORD
data "UNSIGNED"	, FB.TK.UNSIGNED	, FB.TKCLASS.KEYWORD
data "REDIM"	, FB.TK.REDIM		, FB.TKCLASS.KEYWORD
data "ERASE"	, FB.TK.ERASE		, FB.TKCLASS.KEYWORD
data "LBOUND"	, FB.TK.LBOUND		, FB.TKCLASS.KEYWORD
data "UBOUND"	, FB.TK.UBOUND		, FB.TKCLASS.KEYWORD
data "UNION"	, FB.TK.UNION		, FB.TKCLASS.KEYWORD
data "PUBLIC"	, FB.TK.PUBLIC		, FB.TKCLASS.KEYWORD
data "PRIVATE"	, FB.TK.PRIVATE		, FB.TKCLASS.KEYWORD
data "STR"		, FB.TK.STR			, FB.TKCLASS.KEYWORD
data "INSTR"	, FB.TK.INSTR		, FB.TKCLASS.KEYWORD
data "MID"		, FB.TK.MID			, FB.TKCLASS.KEYWORD
data "BYREF"	, FB.TK.BYREF		, FB.TKCLASS.KEYWORD
data "OPTION"	, FB.TK.OPTION		, FB.TKCLASS.KEYWORD
data "BASE"		, FB.TK.BASE		, FB.TKCLASS.KEYWORD
data "EXPLICIT"	, FB.TK.EXPLICIT	, FB.TKCLASS.KEYWORD
data "PASCAL"	, FB.TK.PASCAL		, FB.TKCLASS.KEYWORD
data "PROCPTR"	, FB.TK.PROCPTR		, FB.TKCLASS.KEYWORD
data "SADD"		, FB.TK.SADD		, FB.TKCLASS.KEYWORD
data "RESTORE"	, FB.TK.RESTORE		, FB.TKCLASS.KEYWORD
data "READ"		, FB.TK.READ		, FB.TKCLASS.KEYWORD
data "DATA"		, FB.TK.DATA		, FB.TKCLASS.KEYWORD
data "ABS"		, FB.TK.ABS			, FB.TKCLASS.KEYWORD
data "SGN"		, FB.TK.SGN			, FB.TKCLASS.KEYWORD
data "FIX"		, FB.TK.FIX			, FB.TKCLASS.KEYWORD
data "PRINT"	, FB.TK.PRINT		, FB.TKCLASS.KEYWORD
data "USING"	, FB.TK.USING		, FB.TKCLASS.KEYWORD
data "LEN"		, FB.TK.LEN			, FB.TKCLASS.KEYWORD
data "PEEK"		, FB.TK.PEEK		, FB.TKCLASS.KEYWORD
data "PEEKS"	, FB.TK.PEEKS		, FB.TKCLASS.KEYWORD
data "PEEKI"	, FB.TK.PEEKI		, FB.TKCLASS.KEYWORD
data "POKE"		, FB.TK.POKE		, FB.TKCLASS.KEYWORD
data "POKES"	, FB.TK.POKES		, FB.TKCLASS.KEYWORD
data "POKEI"	, FB.TK.POKEI		, FB.TKCLASS.KEYWORD
data "SWAP"		, FB.TK.SWAP		, FB.TKCLASS.KEYWORD
data "COMMON"	, FB.TK.COMMON		, FB.TKCLASS.KEYWORD
data "OPEN"		, FB.TK.OPEN		, FB.TKCLASS.KEYWORD
data "CLOSE"	, FB.TK.CLOSE		, FB.TKCLASS.KEYWORD
data "SEEK"		, FB.TK.SEEK		, FB.TKCLASS.KEYWORD
data "PUT"		, FB.TK.PUT			, FB.TKCLASS.KEYWORD
data "GET"		, FB.TK.GET			, FB.TKCLASS.KEYWORD
data "ACCESS"	, FB.TK.ACCESS		, FB.TKCLASS.KEYWORD
data "WRITE"	, FB.TK.WRITE		, FB.TKCLASS.KEYWORD
data "LOCK"		, FB.TK.LOCK		, FB.TKCLASS.KEYWORD
data "INPUT"	, FB.TK.INPUT		, FB.TKCLASS.KEYWORD
data "OUTPUT"	, FB.TK.OUTPUT		, FB.TKCLASS.KEYWORD
data "BINARY"	, FB.TK.BINARY		, FB.TKCLASS.KEYWORD
data "RANDOM"	, FB.TK.RANDOM		, FB.TKCLASS.KEYWORD
data "APPEND"	, FB.TK.APPEND		, FB.TKCLASS.KEYWORD
data "PRESERVE"	, FB.TK.PRESERVE	, FB.TKCLASS.KEYWORD
data "ON"		, FB.TK.ON			, FB.TKCLASS.KEYWORD
data "ERROR"	, FB.TK.ERROR		, FB.TKCLASS.KEYWORD
data "ENUM"		, FB.TK.ENUM		, FB.TKCLASS.KEYWORD
data "INCLIB"	, FB.TK.INCLIB		, FB.TKCLASS.KEYWORD
data "ASM"		, FB.TK.ASM			, FB.TKCLASS.KEYWORD
data "SPC"		, FB.TK.SPC			, FB.TKCLASS.KEYWORD
data "TAB"		, FB.TK.TAB			, FB.TKCLASS.KEYWORD
data "LINE"		, FB.TK.LINE		, FB.TKCLASS.KEYWORD
data "VIEW"		, FB.TK.VIEW		, FB.TKCLASS.KEYWORD
data "UNLOCK"	, FB.TK.UNLOCK		, FB.TKCLASS.KEYWORD
data "FIELD"	, FB.TK.FIELD		, FB.TKCLASS.KEYWORD
data "LOCAL"	, FB.TK.LOCAL		, FB.TKCLASS.KEYWORD
data "ERR"		, FB.TK.ERR			, FB.TKCLASS.KEYWORD
data "DEFINE"	, FB.TK.DEFINE		, FB.TKCLASS.KEYWORD
data "UNDEF"	, FB.TK.UNDEF		, FB.TKCLASS.KEYWORD
data "IFDEF"	, FB.TK.IFDEF		, FB.TKCLASS.KEYWORD
data "IFNDEF"	, FB.TK.IFNDEF		, FB.TKCLASS.KEYWORD
data "ENDIF"	, FB.TK.ENDIF		, FB.TKCLASS.KEYWORD
data "DEFINED"	, FB.TK.DEFINED		, FB.TKCLASS.KEYWORD
data "RESUME"	, FB.TK.RESUME		, FB.TKCLASS.KEYWORD
data "PSET"		, FB.TK.PSET		, FB.TKCLASS.KEYWORD
data "PRESET"	, FB.TK.PRESET		, FB.TKCLASS.KEYWORD
data "POINT"	, FB.TK.POINT		, FB.TKCLASS.KEYWORD
data "CIRCLE"	, FB.TK.CIRCLE		, FB.TKCLASS.KEYWORD
data "WINDOW"	, FB.TK.WINDOW		, FB.TKCLASS.KEYWORD
data "PALETTE"	, FB.TK.PALETTE		, FB.TKCLASS.KEYWORD
data "SCREEN"	, FB.TK.SCREEN		, FB.TKCLASS.KEYWORD
data "PAINT"	, FB.TK.PAINT		, FB.TKCLASS.KEYWORD
data "DRAW"		, FB.TK.DRAW		, FB.TKCLASS.KEYWORD
data "EXTERN"	, FB.TK.EXTERN		, FB.TKCLASS.KEYWORD
data "STRPTR"	, FB.TK.STRPTR		, FB.TKCLASS.KEYWORD
data "WITH"		, FB.TK.WITH		, FB.TKCLASS.KEYWORD
data "EXPORT"	, FB.TK.EXPORT		, FB.TKCLASS.KEYWORD
data "IMPORT"	, FB.TK.IMPORT		, FB.TKCLASS.KEYWORD
data "LIBPATH"	, FB.TK.LIBPATH		, FB.TKCLASS.KEYWORD
data "BLOAD"	, FB.TK.BLOAD		, FB.TKCLASS.KEYWORD
data "BSAVE"	, FB.TK.BSAVE		, FB.TKCLASS.KEYWORD
data "CHR"		, FB.TK.CHR			, FB.TKCLASS.KEYWORD
data "ASC"		, FB.TK.ASC			, FB.TKCLASS.KEYWORD
data ""


''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' init/end
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
sub symbInitSymbols static

	'' globals/module-level
	listNew @ctx.symlist, FB.INITSYMBOLNODES, len( FBSYMBOL )

	hashNew ctx.symhash, FB.INITSYMBOLNODES

	'' locals
	listNew @ctx.loclist, FB.INITLOCSYMBOLNODES, len( FBLOCSYMBOL )

	hashNew ctx.lochash, FB.INITLOCSYMBOLNODES

	'' sentinels
	listNew @ctx.senlist, FB.INITSYMBOLNODES, len( FBSENTINEL )

	hashNew ctx.senhash, FB.INITSYMBOLNODES

	'' local sentinels
	listNew @ctx.locsenlist, FB.INITLOCSYMBOLNODES, len( FBSENTINEL )

	hashNew ctx.locsenhash, FB.INITLOCSYMBOLNODES

end sub

'':::::
sub symbInitArgs static

	listNew @ctx.arglist, FB.INITARGNODES, len( FBPROCARG )

end sub

'':::::
sub symbInitDims static

	listNew @ctx.dimlist, FB.INITDIMNODES, len( FBVARDIM )

end sub

'':::::
sub symbInitLibs static

	listNew @ctx.liblist, FB.INITLIBNODES, len( FBLIBRARY )

    hashNew ctx.libhash, FB.INITLIBNODES

end sub

'':::::
sub symbInitDefines static
	dim def as string, value as string, is_string as integer

    restore definesdata
    do
    	read def
    	if( len( def ) = 0 ) then
    		exit do
    	end if
    	read value
    	read is_string
    	if( is_string ) then
    		value = chr$( CHAR_QUOTE ) + value + chr$( CHAR_QUOTE )
    	end if
    	symbAddDefine( def, value )
    loop

end sub

'':::::
sub symbInitKeywords static
	dim kname as string
	dim id as integer, class as integer

	restore keyworddata
	do
    	read kname
    	if( len( kname ) = 0 ) then
    		exit do
    	end if
    	read id, class
    	if( symbAddKeyword( kname, id, class ) = NULL ) then
    		exit sub
    	end if
    loop

end sub

'':::::
sub symbInit

	''
	if( ctx.inited ) then
		exit sub
	end if


	''
	hashInit

	''
	'' vars, arrays, procs & consts
	''
	symbInitSymbols

	''
	'' keywords
	symbInitKeywords

	''
	'' defines
	''
	symbInitDefines

	''
	'' proc args tb
	''
	symbInitArgs

	''
	'' arrays dim tb
	''
	symbInitDims

	''
	'' libraries
	''
	symbInitLibs

    ''
    ctx.inited 	= TRUE

end sub

'':::::
sub symbEnd

    if( not ctx.inited ) then
    	exit sub
    end if

    ''
	hashFree ctx.libhash

	hashFree ctx.locsenhash

	hashFree ctx.senhash

	hashFree ctx.lochash

    hashFree ctx.symhash

	''
	listFree( @ctx.liblist )

	listFree( @ctx.arglist )

	listFree( @ctx.dimlist )

	listFree( @ctx.locsenlist )

	listFree( @ctx.senlist )

	listFree( @ctx.loclist )

	listFree( @ctx.symlist )

	''
	ctx.inited = FALSE

end sub

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' add
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function hAddSentinel( id as string, byval class as integer, byval isglobal as integer, _
					   byval suffix as integer = INVALID ) as FBSENTINEL ptr static
    dim sname as string
    dim s as FBSENTINEL ptr

    hAddSentinel = NULL

	s = symbLookupSentinel( id, class, env.scope > 0 )

    '' already exists?
    if( s <> NULL ) then
    	'' not a var, no dup defs
    	if( (class <> FB.SYMBCLASS.VAR) or (s->class <> FB.SYMBCLASS.VAR) ) then
    		exit function
    	end if

    	'' allow local vars with same names as global ones, check only at same scope
    	if( env.scope = s->scope ) then
    		'' not suffixed?
    		if( (suffix = INVALID) or (s->suffix = INVALID) ) then
    			exit function
    		end if

    		'' same suffix?
    		if( suffix = s->suffix ) then
    			exit function
    		end if

    		s->count = s->count + 1

    		hAddSentinel = s
    		exit function
    	end if
    end if

    '' add to list
    if( env.scope = 0 ) then
    	s = listNewNode( @ctx.senlist )
    else
    	s = listNewNode( @ctx.locsenlist )
    end if

	sname = hCreateName( id )

    s->class 	= class
    s->scope    = env.scope
    s->suffix 	= suffix
    s->isglobal = isglobal
    s->count 	= 1
	s->nameidx	= strpAdd( sname )

    if( env.scope = 0 ) then
    	hashAdd ctx.senhash, sname, s, s->nameidx
    else
    	hashAdd ctx.locsenhash, sname, s, s->nameidx
    end if

    hAddSentinel = s

end function

'':::::
function hNewSymbol( symbol as string, aliasname as string, byval class as integer, _
					 byval isglobal as integer = TRUE, byval lookup as integer = FALSE ) as FBSYMBOL ptr static
    dim l as FBLOCSYMBOL ptr, s as FBSYMBOL ptr

    hNewSymbol = NULL

    if( lookup ) then
    	'' symbol already exists?
    	if( isglobal ) then
    		s = hashLookup( ctx.symhash, symbol )
    	else
    		s = hashLookup( ctx.lochash, symbol )
    	end if

    	if( s <> NULL ) then
    		exit function
    	end if
    end if

    s = listNewNode( @ctx.symlist )
    if( s = NULL ) then
    	exit function
    end if

    ''
    s->class		= class
    s->typ			= INVALID
    s->subtype		= NULL
	s->alloctype	= 0
	s->sentinel		= NULL
    s->initialized 	= FALSE
    s->inittextidx 	= INVALID
    s->lgt			= 0
    s->ofs			= 0

    s->nameidx	= strpAdd( symbol )
    if( len( aliasname ) > 0 ) then
    	s->aliasidx = strpAdd( aliasname )
    else
    	s->aliasidx = INVALID
    end if

	'' add node to local symbol table for fast deletion later
	if( not isglobal ) then
		l = listNewNode( @ctx.loclist )
		l->s = s
	end if

    ''
    hNewSymbol = s

end function

'':::::
function symbAddKeyword( keyname as string, byval id as integer, byval class as integer ) as FBSYMBOL ptr
    dim k as FBSYMBOL ptr
    dim kname as string

    kname = ucase$( keyname )

    k = hNewSymbol( kname, "", FB.SYMBCLASS.KEYWORD )
    if( k = NULL ) then
    	symbAddKeyword = NULL
    	exit function
    end if

    ''
    k->key.id		= id
    k->key.class	= class

    '' and to hash table
    hashAdd ctx.symhash, kname, k, k->nameidx

    symbAddKeyword = k

end function

'':::::
function symbAddDefine( defname as string, text as string ) as FBSYMBOL ptr static
    dim d as FBSYMBOL ptr
    dim dname as string

    symbAddDefine = NULL

    dname = ucase$( defname )

    '' allocate new node
    d = hNewSymbol( dname, "", FB.SYMBCLASS.DEFINE )
    if( d = NULL ) then
    	exit function
    end if

	''
	d->def.textidx 	= strpAdd( text )
	d->def.args		= 0

	'' and to hash table
	hashAdd ctx.symhash, dname, d, d->nameidx

	''
	symbAddDefine = d

end function

'':::::
function hCreateArrayDesc( byval s as FBSYMBOL ptr, byval dimensions as integer) as FBSYMBOL ptr static
    dim sname as string, aname as string, d as FBSYMBOL ptr
    dim lgt as integer, ofs as integer, isshared as integer, isstatic as integer

	hCreateArrayDesc = NULL

	isshared = (s->alloctype and FB.ALLOCTYPE.SHARED) > 0
	isstatic = (s->alloctype and FB.ALLOCTYPE.STATIC) > 0

	if( (s->alloctype and (FB.ALLOCTYPE.COMMON or FB.ALLOCTYPE.PUBLIC or FB.ALLOCTYPE.EXTERN)) = 0 ) then
		sname = hMakeTmpStr
	else
		symbGetVarName( s, sname )
	end if

	if( (env.scope = 0) or (isshared) or (isstatic) ) then
		aname = ""
		ofs = 0
	else
		lgt = FB.ARRAYDESCSIZE + dimensions * (4+4)
		aname = emitAllocLocal( lgt, ofs )
	end if

	d = hNewSymbol( sname, aname, FB.SYMBCLASS.VAR, (env.scope = 0) or isshared )
    if( d = NULL ) then
    	exit function
    end if

	''
	d->scope		= env.scope
	if( isshared ) then
		d->alloctype= FB.ALLOCTYPE.SHARED
	elseif( isstatic ) then
		d->alloctype= FB.ALLOCTYPE.STATIC
	else
		d->alloctype= 0
	end if
	d->typ		= FB.SYMBTYPE.USERDEF
	d->subtype	= FB.DESCTYPE.ARRAY
	d->lgt		= 0
	d->ofs		= ofs
	d->array.desc = NULL
	d->array.dif  = 0
	d->array.dims = 0

	''
	hCreateArrayDesc = d

end function

'':::::
function hCreateStringDesc( byval s as FBSYMBOL ptr ) as FBSYMBOL ptr static
    dim sname as string, d as FBSYMBOL ptr

	hCreateStringDesc = NULL

	sname = hMakeTmpStr

	d = hNewSymbol( sname, "", FB.SYMBCLASS.VAR, TRUE )
    if( d = NULL ) then
    	exit function
    end if

	''
	d->scope	= 0
	d->alloctype= FB.ALLOCTYPE.SHARED

	d->typ		= FB.SYMBTYPE.STRING 'FB.SYMBTYPE.USERDEF
	d->subtype	= FB.DESCTYPE.STR
	d->lgt		= 0
	d->array.desc = NULL
	d->array.dif  = 0
	d->array.dims = 0

	''
	hCreateStringDesc = d

end function

'':::::
function hNewDim( head as FBVARDIM ptr, tail as FBVARDIM ptr, _
				  byval lower as integer, byval upper as integer ) as FBVARDIM ptr static
    dim d as FBVARDIM ptr, n as FBVARDIM ptr

    hNewDim = NULL

    d = listNewNode( @ctx.dimlist )
    if( d = NULL ) then
    	exit function
    end if

    d->lower = lower
    d->upper = upper

	n = tail
	d->r = NULL
	tail = d
	if( n <> NULL ) then
		n->r = d
	else
		head = d
	end if

    hNewDim = d

end function

'':::::
sub hSetupVar( byval s as FBSYMBOL ptr, sname as string, aname as string, _
			   byval typ as integer, byval subtype as FBSYMBOL ptr, _
			   byval lgt as integer, byval ofs as integer, _
			   byval dimensions as integer, dTB() as FBARRAYDIM, _
			   byval alloctype as integer, byval sentinel as FBSENTINEL ptr ) static

    dim i as integer, res as integer
    dim isshared as integer, isstatic as integer, isdynamic as integer, ispublic as integer

    isshared  = (alloctype and FB.ALLOCTYPE.SHARED) > 0
    isstatic  = (alloctype and FB.ALLOCTYPE.STATIC) > 0
    isdynamic = (alloctype and FB.ALLOCTYPE.DYNAMIC) > 0
    ispublic  = (alloctype and FB.ALLOCTYPE.PUBLIC) > 0

	''
	s->scope	= env.scope
	s->alloctype= alloctype
	s->acccnt 	= 0

	s->typ		= typ
	s->subtype	= subtype
	s->lgt		= lgt
	s->ofs		= ofs

	'' array fields
	s->array.dimhead = NULL
	s->array.dimtail = NULL

	s->array.dif	= hCalcDiff( dimensions, dTB(), s->lgt )
	s->array.dims	= dimensions
	s->array.elms	= 0								'' real value doesn't matter
	if( dimensions > 0 ) then
		for i = 0 to dimensions-1
			if( hNewDim( s->array.dimhead, s->array.dimtail, dTB(i).lower, dTB(i).upper ) = NULL ) then
			end if
		next i
	end if

	if( dimensions <> 0 ) then
		s->array.desc = hCreateArrayDesc( s, dimensions )
	else
		s->array.desc = NULL
	end if

	s->sentinel = sentinel

	'' add to hash tables (local or global)
	if( (isshared) or (env.scope = 0) ) then
		hashAdd ctx.symhash, sname, s, s->nameidx
	else
		hashAdd ctx.lochash, sname, s, s->nameidx

		'' hack! add only the alias name to global table, DelLocalSymbols will do the rest
		if( isstatic ) then
			hashAdd ctx.symhash, aname, s, s->aliasidx
		end if
	end if

end sub

'':::::
function symbAddVarEx( symbol as string, aliasname as string, _
					   byval typ as integer, byval subtype as FBSYMBOL ptr, _
					   byval lgt as integer, byval dimensions as integer, dTB() as FBARRAYDIM, _
				       byval alloctype as integer, _
				       byval addsuffix as integer, _
				       byval preservecase as integer, _
				       byval clearname as integer ) as FBSYMBOL ptr static

    dim s as FBSYMBOL ptr, sname as string, aname as string
    dim elms as integer, stype as integer, arglen as integer
    dim isshared as integer, isstatic as integer, ispublic as integer, isextern as integer
    dim isarg as integer, islocal as integer, ofs as integer
    dim sentinel as FBSENTINEL ptr
    dim fields as string

    symbAddVarEx = NULL

    '' check for UDT symbols already declared if the symbol to be added contains an '.'
    if( clearname ) then
    	if( hCheckTypeField( symbol, preservecase, TRUE, fields ) <> NULL ) then
    		exit function
    	end if
    end if

    ''
    isshared = (alloctype and FB.ALLOCTYPE.SHARED) > 0
    isstatic = (alloctype and FB.ALLOCTYPE.STATIC) > 0
    ispublic = (alloctype and FB.ALLOCTYPE.PUBLIC) > 0
    isextern = (alloctype and FB.ALLOCTYPE.EXTERN) > 0
    isarg    = (alloctype and (FB.ALLOCTYPE.ARGUMENTBYDESC or _
    						   FB.ALLOCTYPE.ARGUMENTBYVAL or _
    						   FB.ALLOCTYPE.ARGUMENTBYREF)) > 0
	islocal  = FALSE

    ''
    if( addsuffix ) then
    	stype = typ
    else
    	stype = INVALID
    end if

    '' only create the sentinel if not a string|fpoint constant ("a" and "A" would be the same)
    if( clearname ) then
    	sentinel = hAddSentinel( symbol, FB.SYMBCLASS.VAR, isshared, stype )
    	if( sentinel = NULL ) then
    		exit function
    	end if
    else
    	sentinel = NULL
    end if

    ''
    sname = hCreateName( symbol, stype, preservecase, TRUE, clearname )

    ''
    if( lgt <= 0 ) then
		if( typ = INVALID ) then
			stype = hGetDefType( symbol )
		else
			stype = typ
 		end if
    	lgt	= symbCalcLen( stype, subtype )
    end if

    ''
    ofs = 0

	'' create an alias name (the real one that will be emited)
	if( len( aliasname ) > 0 ) then
		aname = aliasname
	else
		if( (not isshared) and (isstatic) ) then
			aname = hMakeTmpStr
		else
			if( (ispublic) or (isextern) ) then
			    aname = ""
			elseif( (isshared) or (env.scope = 0) ) then
				aname = ""
			else
				if( not isarg ) then
					elms = hCalcElements2( dimensions, dTB() )
					aname = emitAllocLocal( lgt * elms, ofs )
					islocal = TRUE
				else
        			if( alloctype = FB.ALLOCTYPE.ARGUMENTBYVAL ) then
        				arglen = lgt
        			else
        				arglen = FB.POINTERSIZE
        			end if
					aname = emitAllocArg( arglen, ofs )
				end if
			end if
		end if
	end if

	''
	s = hNewSymbol( sname, aname, FB.SYMBCLASS.VAR, (isshared) or (env.scope = 0), (clearname = FALSE) )

	if( s = NULL ) then
		'' remove a local or arg or else emit will reserve unused space for it..
		if( islocal ) then
			emitFreeLocal lgt * elms
		elseif( isarg ) then
			emitFreeArg arglen
		end if

		'' remove sentinel too
		hDelSentinel sentinel, isshared

		exit function
	end if

	''
	if( typ = INVALID ) then
		typ = hGetDefType( symbol )
	end if

	hSetupVar s, sname, aname, typ, subtype, lgt, ofs, dimensions, dTB(), alloctype, sentinel

	symbAddVarEx = s

end function

'':::::
function symbAddVar( symbol as string, byval typ as integer, byval subtype as FBSYMBOL ptr, _
				     byval dimensions as integer, dTB() as FBARRAYDIM, _
				     byval alloctype as integer ) as FBSYMBOL ptr static

    symbAddVar = symbAddVarEx( symbol, "", typ, subtype, _
    						   0, dimensions, dTB(), _
    						   alloctype, _
    						   TRUE, FALSE, TRUE )
end function

'':::::
function symbAddTempVar( byval typ as integer ) as FBSYMBOL ptr static
	dim sname as string, s as FBSYMBOL ptr, alloctype as integer
    dim dTB(0) as FBARRAYDIM

	sname = hMakeTmpStr

	alloctype = FB.ALLOCTYPE.TEMP
	if( (env.scope > 0) and (env.isprocstatic) ) then
		alloctype = alloctype or FB.ALLOCTYPE.STATIC
	end if

	s = symbAddVar( sname, typ, NULL, 0, dTB(), alloctype )

	symbAddTempVar = s

end function

'':::::
function hAllocFloatConst( sname as string, byval typ as integer ) as FBSYMBOL ptr static
	dim s as FBSYMBOL ptr, ofs as integer, dTB(0) as FBARRAYDIM
    dim cname as string, aname as string
    dim elm as FBSYMBOL ptr, subtype as FBSYMBOL ptr
    dim p as integer

	hAllocFloatConst = NULL

	cname = "_fc_" + sname

	aname = hMakeTmpStr

	s = symbAddVarEx( cname, aname, typ, NULL, 0, 0, dTB(), FB.ALLOCTYPE.SHARED, TRUE, FALSE, FALSE )
	if( s = NULL ) then
		hAllocFloatConst = symbLookupVar( cname, typ, ofs, elm, subtype, TRUE, FALSE, FALSE )
		exit function
	end if

	s->initialized = TRUE

	p = instr( sname, "D" )
	if( p <> 0 ) then
		mid$( sname, p, 1 ) = "E"
	end if
	s->inittextidx	= strpAdd( sname )

	hAllocFloatConst = s

end function

'':::::
function hAllocStringConst( sname as string, byval lgt as integer ) as FBSYMBOL ptr static
	dim s as FBSYMBOL ptr, ofs as integer, dTB(0) as FBARRAYDIM
    dim cname as string, aname as string
    dim elm as FBSYMBOL ptr, subtype as FBSYMBOL ptr

	hAllocStringConst = NULL

	if( lgt < 0 ) then
		lgt = len( sname )
	end if

	cname = "_sc_" + sname

	aname = hMakeTmpStr

	s = symbAddVarEx( cname, aname, FB.SYMBTYPE.FIXSTR, NULL, lgt + 1, 0, dTB(), FB.ALLOCTYPE.SHARED, FALSE, TRUE, FALSE )
	if( s = NULL ) then
		s = symbLookupVar( cname, FB.SYMBTYPE.FIXSTR, ofs, elm, subtype, FALSE, TRUE, FALSE )
		hAllocStringConst = s 's->array.desc
		exit function
	end if

	s->initialized = TRUE
	s->inittextidx = strpAdd( sname )

	'' can't fake a descriptor as the literal string passed to user procs can be modified/reused
	's->array.desc = hCreateStringDesc( s )

	hAllocStringConst = s 's->array.desc

end function

'':::::
function symbAddConst( id as string, byval typ as integer, text as string, byval lgt as integer ) as FBSYMBOL ptr static
    dim c as FBSYMBOL ptr
    dim cname as string
    dim sentinel as FBSENTINEL ptr

    symbAddConst = NULL

    ''
    sentinel = hAddSentinel( id, FB.SYMBCLASS.CONST, env.scope = 0 )
    if( sentinel = NULL ) then
    	exit function
    end if

    ''
    cname = ucase$( id )

    c = hNewSymbol( cname, "", FB.SYMBCLASS.CONST, env.scope = 0 )
	if( c = NULL ) then
		exit function
	end if

	c->scope   	= env.scope
	c->typ 		= typ
	c->lgt		= lgt
	c->sentinel	= sentinel
	c->con.textidx= strpAdd( text )

	''
	if( env.scope > 0 ) then
		hashAdd ctx.lochash, cname, c, c->nameidx
	else
		hashAdd ctx.symhash, cname, c, c->nameidx
		c->alloctype = FB.ALLOCTYPE.SHARED
	end if

	symbAddConst = c

end function

'':::::
function symbAddLabelEx( label as string, byval declaring as integer, byval createalias as integer = FALSE ) as FBSYMBOL ptr static
    dim l as FBSYMBOL ptr
    dim lname as string, aname as string

    symbAddLabelEx = NULL

    '' there's no sentinel, labels can be declared with the same name as any symbol

    ''
    lname = hCreateName( label, FB.SYMBTYPE.LABEL, FALSE, TRUE, TRUE )

    if( env.scope > 0 ) then
    	lname = "L" + lname
    end if

    '' check if label already exists
    if( env.scope = 0 ) then
    	l = hashLookup( ctx.symhash, lname )
    else
    	l = hashLookup( ctx.lochash, lname )
    end if

    if( l <> NULL ) then
    	if( l->class <> FB.SYMBCLASS.LABEL ) then
    		exit function
    	end if

    	if( declaring ) then
    		if( l->lbl.declared ) then
    			exit function
    		else
    			l->lbl.declared = TRUE
    			symbAddLabelEx = l
    			exit function
    		end if

    	else
    		symbAddLabelEx = l
    		exit function
    	end if
    end if

	'' add the new label
	if( not createalias ) then
		aname = ""
	else
		aname = hMakeTmpStr
	end if

    l = hNewSymbol( lname, aname, FB.SYMBCLASS.LABEL, env.scope = 0 )
    if( l = NULL ) then
    	exit function
    end if

	l->lbl.declared = declaring
	l->scope    	= env.scope

	if( env.scope = 0 ) then
		hashAdd ctx.symhash, lname, l, l->nameidx
	else
		hashAdd ctx.lochash, lname, l, l->nameidx
	end if

	symbAddLabelEx = l

end function

'':::::
function symbAddLabel( label as string ) as FBSYMBOL ptr static

	symbAddLabel = symbAddLabelEx( label, TRUE, FALSE )

end function


'':::::
function symbAddUDT( id as string, byval isunion as integer, byval align as integer ) as FBSYMBOL ptr static
    dim t as FBSYMBOL ptr
    dim tname as string

    symbAddUDT = NULL

    '' there's no sentinel, UDT's can be declared with the same name as
    '' any symbol, making it not so easy to len( ) decide..

    ''
    tname = hCreateName( id, FB.SYMBTYPE.USERDEF )

    t = hNewSymbol( tname, "", FB.SYMBCLASS.UDT, env.scope = 0, TRUE )
	if( t = NULL ) then
		exit function
	end if

	t->scope   		= env.scope
	t->lgt			= 0
	t->udt.isunion	= isunion
	t->udt.elements	= 0
	t->udt.head 	= NULL
	t->udt.tail 	= NULL
	t->udt.ofs		= 0
	t->udt.align	= align
	t->udt.innerlgt	= 0

	if( env.scope > 0 ) then
		hashAdd ctx.lochash, tname, t, t->nameidx
	else
		hashAdd ctx.symhash, tname, t, t->nameidx
		t->alloctype = FB.ALLOCTYPE.SHARED
	end if

	symbAddUDT = t

end function

'':::::
function hCalcALign( byval lgt as integer, byval ofs as integer, byval align as integer, _
					 byval typ as integer, byval subtype as FBSYMBOL ptr ) as integer static
    dim pad as integer
    dim e as FBSYMBOL ptr

	hCalcALign = 0

	if( align <= 1 ) then
		exit function
	end if

	'' if field is another UDT, loop until a non-UDT header field is found
	if( typ = FB.SYMBTYPE.USERDEF ) then
		do
			e = subtype->udt.head
    		typ = e->typ
    		subtype = e->subtype
		loop while( typ = FB.SYMBTYPE.USERDEF )

		lgt = e->lgt
		'' len = field's len + pad from current field to the next field, if any
		e = e->elm.r
		if( e <> NULL ) then
			lgt = lgt + (e->elm.ofs - lgt)
		end if
	end if

	select case as const lgt
	'' align byte, short, int's, float's and double's to the nearest boundary
	case 1, 2, 4, 8
		pad = lgt - 1
	'' anything else to align given (default: sizeof( int ))
	case else
		pad = align - 1
		lgt = align
	end select

	if( pad > 0 ) then
		hCalcALign = (lgt - (ofs and pad)) mod lgt
	end if

end function

'':::::
function symbAddUDTElement( byval t as FBSYMBOL ptr, elmname as string, _
						    byval dimensions as integer, dTB() as FBARRAYDIM, _
						    byval typ as integer, byval subtype as FBSYMBOL ptr, byval lgt as integer, _
						    byval isinnerunion as integer ) as FBSYMBOL ptr static
    dim i as integer
    dim e as FBSYMBOL ptr, n as FBSYMBOL ptr
    dim align as integer
    dim ename as string

    symbAddUDTElement = NULL

    ename = ucase$( elmname )

    '' check if element already exists in the current struct
    e = t->udt.head
    do while( e <> NULL )

    	if( strpGet( e->nameidx ) = ename ) then
    		exit function
    	end if

    	'' next
    	e = e->elm.r
    loop

    e = hNewSymbol( ename, "", FB.SYMBCLASS.UDTELM, TRUE )
    if( e = NULL ) then
    	exit function
    end if

	'' add to parent's linked-list
	n = t->udt.tail
	e->elm.l 		= n
	e->elm.r 		= NULL
    e->elm.parent	= t
	t->udt.tail 	= e
	if( n <> NULL ) then
		n->elm.r 	= e
	else
		t->udt.head = e
	end if

    t->udt.elements	= t->udt.elements + 1

    ''
    e->typ			= typ
    e->subtype		= subtype
	if( (lgt <= 0) or (typ = FB.SYMBTYPE.USERDEF) ) then
		lgt	= symbCalcLen( typ, subtype, TRUE )
	end if

	align = hCalcALign( lgt, t->udt.ofs, t->udt.align, typ, subtype )
	if( align > 0 ) then
		t->udt.ofs 	= t->udt.ofs + align
	end if

	e->lgt 			= lgt
	e->elm.ofs		= t->udt.ofs
	e->array.dif	= hCalcDiff( dimensions, dTB(), lgt )

	'' array fields
	e->array.dimhead= NULL
	e->array.dimtail= NULL

	e->array.dims	= dimensions
	if( dimensions > 0 ) then
		for i = 0 to dimensions-1
			if( hNewDim( e->array.dimhead, e->array.dimtail, dTB(i).lower, dTB(i).upper ) = NULL ) then
			end if
		next i
	end if

	e->array.elms 	= hCalcElements( e )

	lgt = lgt * e->array.elms

	if( not t->udt.isunion ) then
		if( not isinnerunion ) then
			t->udt.ofs = t->udt.ofs + lgt
			t->lgt = t->udt.ofs
		else
			if( lgt > t->udt.innerlgt ) then
				t->udt.innerlgt = lgt
			end if
		end if

	else
		t->udt.ofs = 0
		if( lgt > t->lgt ) then
			t->lgt = lgt
		end if
	end if


    symbAddUDTElement = e

end function

'':::::
sub symbRoundUDTSize( byval t as FBSYMBOL ptr ) static
    dim round as integer, align as integer

	align = t->udt.align

	if( align <= 1 ) then
		exit sub
	end if

	round = (align - (t->lgt and (align-1))) and (align-1)

	if( round > 0 ) then
		t->lgt = t->lgt + round
	end if

end sub

'':::::
sub symbRecalcUDTSize( byval t as FBSYMBOL ptr ) static
    dim lgt as integer

	lgt = t->udt.innerlgt
	if( lgt > 0 ) then
		t->udt.ofs		= t->udt.ofs + lgt
		t->lgt 			= t->udt.ofs
		t->udt.innerlgt 	= 0
	end if

end sub

'':::::
function symbAddEnum( id as string ) as FBSYMBOL ptr static
    dim i as integer, e as FBSYMBOL ptr
    dim ename as string
    dim sentinel as FBSENTINEL ptr

    symbAddEnum = NULL

    ''
    sentinel = hAddSentinel( id, FB.SYMBCLASS.ENUM, env.scope = 0 )
    if( sentinel = NULL ) then
    	exit function
    end if

    ''
    ename = hCreateName( id, FB.SYMBTYPE.USERDEF )

    e = hNewSymbol( ename, "", FB.SYMBCLASS.ENUM, env.scope = 0 )
	if( e = NULL ) then
		exit function
	end if

	e->scope   	= env.scope
	e->sentinel	= sentinel

	if( env.scope > 0 ) then
		hashAdd ctx.lochash, ename, e, e->nameidx
	else
		hashAdd ctx.symhash, ename, e, e->nameidx
	end if

	symbAddEnum = e

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' procs
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbAddLib( libname as string ) as FBLIBRARY ptr static
    dim l as FBLIBRARY ptr

    symbAddLib = NULL

    '' check if not already declared
    l = hashLookup( ctx.libhash, libname )
    if( l <> NULL ) then
    	symbAddLib = l
    	exit function
    end if

    l = listNewNode( @ctx.liblist )
	if( l = NULL ) then
		exit function
	end if

	''
	l->nameidx = strpAdd( libname )

	hashAdd ctx.libhash, libname, l, l->nameidx

	symbAddLib = l

end function

'':::::
function hCalcProcArgsLen( byval args as integer, argv() as FBPROCARG ) as integer
	dim i as integer, lgt as integer

	lgt	= 0
	for i = 0 to args-1
		if( argv(i).mode = FB.ARGMODE.BYVAL ) then
			lgt	= lgt + ((argv(i).lgt + 3) and not 3)	'' hack! x86 pmode assumption
		else
			lgt	= lgt + FB.POINTERSIZE
		end if
	next i

	hCalcProcArgsLen = lgt

end function

'':::::
private function hNewArg( byval f as FBSYMBOL ptr, arg as FBPROCARG ) as FBPROCARG ptr static
    dim a as FBPROCARG ptr, n as FBPROCARG ptr

    hNewArg = NULL

    a = listNewNode( @ctx.arglist )
    if( a = NULL ) then
    	exit function
    end if

	n = f->proc.argtail
	a->l = n
	a->r = NULL
	f->proc.argtail = a
	if( n <> NULL ) then
		n->r = a
	else
		f->proc.arghead = a
	end if

	f->proc.args = f->proc.args + 1

	''
    a->nameidx	= arg.nameidx
	a->typ		= arg.typ
	a->subtype	= arg.subtype
	a->lgt		= arg.lgt
	a->mode		= arg.mode
	a->suffix	= arg.suffix
	a->optional	= arg.optional
	a->defvalue	= arg.defvalue

    hNewArg = a

end function

'':::::
private function hSetupProc( id as string, aliasname as string, libname as string, _
				             byval typ as integer, byval subtype as FBSYMBOL ptr, byval alloctype as integer, _
				             byval mode as integer, byval argc as integer, argv() as FBPROCARG, _
			                 byval declaring as integer ) as FBSYMBOL ptr static

    dim lgt as integer
    dim f as FBSYMBOL ptr, sentinel as FBSENTINEL ptr
    dim sname as string, aname as string
    dim i as integer

    hSetupProc = NULL

    ''
    sentinel = hAddSentinel( id, FB.SYMBCLASS.PROC, TRUE )
    if( sentinel = NULL ) then
    	exit function
    end if

	''
	if( typ = INVALID ) then
		typ = hGetDefType( id )
		subtype = NULL
	end if

    lgt = hCalcProcArgsLen( argc, argv() )

    ''
    sname = ucase$( id )

    if( len( aliasname ) = 0 ) then
    	if( len( libname ) = 0 ) then
    		aname = sname
    	else
    		aname = id
    	end if
    else
    	aname = aliasname
    end if

    if( instr( aname, "@" ) = 0 ) then
    	aname = hCreateProcAlias( aname, lgt, mode )
    end if

	f = hNewSymbol( sname, aname, FB.SYMBCLASS.PROC )
	if( f = NULL ) then
		exit function
	end if

    ''
	f->scope		= env.scope
	f->alloctype	= alloctype or FB.ALLOCTYPE.SHARED
    f->sentinel 	= sentinel

	f->typ			= typ
	f->subtype		= subtype
	f->lgt			= lgt

	f->proc.isdeclared = declaring
	f->proc.mode	= mode

	if( len( libname ) > 0 ) then
		f->proc.lib = symbAddLib( libname )
	else
		f->proc.lib = NULL
	end if

	'' add arguments (w/o declaring them as symbols)
	f->proc.arghead	= NULL
	f->proc.argtail	= NULL
	f->proc.args 	= 0

	for i = 0 to argc-1
		if( hNewArg( f, argv(i) ) = NULL ) then
			exit function
		end if
	next i

	''
	hashAdd ctx.symhash, sname, f, f->nameidx

	hSetupProc = f

end function

'':::::
function symbAddPrototype( id as string, aliasname as string, libname as string, _
						   byval typ as integer, byval subtype as FBSYMBOL ptr, byval alloctype as integer, _
						   byval mode as integer, byval argc as integer, argv() as FBPROCARG, _
						   byval isexternal as integer ) as FBSYMBOL ptr static

    dim f as FBSYMBOL ptr

    symbAddPrototype = NULL

	f = hSetupProc( id, aliasname, libname, typ, subtype, alloctype, mode, argc, argv(), isexternal )
	if( f = NULL ) then
		exit function
	end if

	symbAddPrototype = f

end function

'':::::
function symbAddProc( id as string, aliasname as string, libname as string, _
					  byval typ as integer, byval subtype as FBSYMBOL ptr, byval alloctype as integer, _
					  byval mode as integer, byval argc as integer, argv() as FBPROCARG ) as FBSYMBOL ptr static

    dim f as FBSYMBOL ptr

    symbAddProc = NULL

	f = hSetupProc( id, aliasname, libname, typ, subtype, alloctype, mode, argc, argv(), TRUE )
	if( f = NULL ) then
		exit function
	end if

	symbAddProc = f

end function

'':::::
function symbAddArg( byval f as FBSYMBOL ptr, byval arg as FBPROCARG ptr ) as FBSYMBOL ptr
    dim dTB(0) as FBARRAYDIM
    dim s as FBSYMBOL ptr, alloctype as integer

	symbAddArg = NULL

	select case arg->mode
    case FB.ARGMODE.BYVAL
    	alloctype = FB.ALLOCTYPE.ARGUMENTBYVAL
	case FB.ARGMODE.BYDESC
    	alloctype = FB.ALLOCTYPE.ARGUMENTBYDESC
	case else
    	alloctype = FB.ALLOCTYPE.ARGUMENTBYREF
	end select

    s = symbAddVarEx( strpGet( arg->nameidx ), "", arg->typ, arg->subtype, 0, _
    				  0, dTB(), alloctype, arg->suffix <> INVALID, FALSE, TRUE )

    if( s = NULL ) then
    	exit function
    end if

	symbAddArg = s

end function

'':::::
function symbCalcArgsLen( byval f as FBSYMBOL ptr, byval args as integer ) as integer static
    dim lgt as integer

	'' use symbGetLen() with normal procs, this is only for C var-len progs
	lgt = f->lgt
	if( args > f->proc.args ) then
		lgt = lgt + ((args - f->proc.args) * FB.INTEGERSIZE)
	end if

	symbCalcArgsLen = lgt

end function

'':::::
function symbAddProcResult( byval f as FBSYMBOL ptr ) as FBSYMBOL ptr static
	dim rname as string
	dim dTB(0) as FBARRAYDIM

	rname = "_fbpr_" + strpGet( f->aliasidx )

	symbAddProcResult = symbAddVarEx( rname, "", f->typ, f->subtype, 0, _
			 			              0, dTB(), 0, TRUE, FALSE, TRUE )

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' lookups
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbLookup( symbname as string, id as integer, class as integer ) as FBSYMBOL ptr static
    dim s as FBSYMBOL ptr
    dim sname as string, index as uinteger

	id 	  = FB.TK.ID
	class = FB.TKCLASS.IDENTIFIER

    sname = ucase$( symbname )

	'' first check the local symbols if current scope > 0
	index = hashHash( sname )
	if( env.scope > 0 ) then
		s = hashLookupEx( ctx.lochash, sname, index )
    else
    	s = NULL
    end if

    '' and then the globals
    if( s = NULL ) then
    	s = hashLookupEx( ctx.symhash, sname, index )
    end if

	if( s <> NULL ) then
		select case as const s->class
		case FB.SYMBCLASS.KEYWORD
			id 		= s->key.id
			class 	= s->key.class

		case FB.SYMBCLASS.DEFINE
			id 		= FB.TK.IDDEFINE

		case FB.SYMBCLASS.PROC
			id 		= FB.TK.IDFUNCT

		case FB.SYMBCLASS.CONST
			id 		= FB.TK.IDCONST
		end select
	end if

	symbLookup = s

end function

'':::::
function symbLookupSentinel( id as string, byval class as integer, byval islocal as integer ) as FBSENTINEL ptr static
    dim sname as string, index as uinteger
    dim s as FBSENTINEL ptr

	sname = hCreateName( id )

	'' first check the local symbols if current scope > 0
	index = hashHash( sname )
	s = NULL
	if( islocal ) then
		s = hashLookupEx( ctx.locsenhash, sname, index )
	end if

	'' check module level symbols (and shared if current scope > 0)
	if( s = NULL ) then
		s = hashLookupEx( ctx.senhash, sname, index )
		if( s <> NULL ) then
			if( (islocal) and (not s->isglobal) ) then
				s = NULL
			end if
		end if
	end if

	symbLookupSentinel = s

end function

'':::::
function symbGetUDTElmOffset( elm as FBSYMBOL ptr, typ as integer, subtype as FBSYMBOL ptr, _
							  fields as string ) as integer
	dim e as FBSYMBOL ptr, ename as string
	dim p as integer, ofs as integer, o as integer
	dim flen as integer

	symbGetUDTElmOffset = INVALID

    flen = len( fields )

    p = instr( 1, fields, "." )
    if( p = 0 ) then
    	p = flen + 1
    end if

    ename = left$( fields, p-1 )
    hUcase ename

	elm = NULL
	ofs = INVALID

    if( subtype = NULL ) then
    	exit function
    end if

	e = subtype->udt.head
	do while( e <> NULL )

        if( strpGet( e->nameidx ) = ename ) then

        	elm 		= e
        	ofs 		= e->elm.ofs
        	typ 		= e->typ
        	subtype 	= e->subtype

        	if( typ = FB.SYMBTYPE.USERDEF ) then

    			if( p >= flen ) then
    				exit do
    			end if

    			o = symbGetUDTElmOffset( elm, typ, subtype, mid$( fields, p+1 ) )
    			if( o = INVALID ) then
    				exit function
    			end if
    			ofs = ofs + o

    		else
    			if( p < flen ) then
    				exit function
    			end if
    		end if

        	exit do
        end if

		e = e->elm.r
    loop

    symbGetUDTElmOffset = ofs

end function

'':::::
function hLookupVar( vname as string, byval lookupmode as integer ) as FBSYMBOL ptr static
    dim s as FBSYMBOL ptr
    dim index as uinteger

	hLookupVar = NULL

	s = NULL

	index = hashHash( vname )

	if( (lookupmode and FB.LOOKUPMODE.LOCAL) > 0 ) then
		'' first check the local symbols if current scope > 0
		if( env.scope > 0 ) then
			s = hashLookupEx( ctx.lochash, vname, index )
			if( s <> NULL ) then
				if( s->class = FB.SYMBCLASS.VAR ) then
					hLookupVar = s
				end if
				exit function
			end if
		end if
	end if

	if( (lookupmode and FB.LOOKUPMODE.GLOBAL) > 0 ) then
		'' check globals (and shared if current scope > 0)
		if( s = NULL ) then
			s = hashLookupEx( ctx.symhash, vname, index )
			if( s <> NULL ) then
				if( s->class = FB.SYMBCLASS.VAR ) then
					if( (env.scope = 0) or ((s->alloctype and FB.ALLOCTYPE.SHARED) > 0) ) then
						hLookupVar = s
					end if
				end if
				exit function
			end if
		end if
	end if

end function

'':::::
function hCheckTypeField( symbol as string, byval preservecase as integer, _
					      byval clearname as integer, fields as string ) as FBSYMBOL ptr static

  	dim s as FBSYMBOL ptr
  	dim p as integer
  	dim vname as string

  	hCheckTypeField = NULL

	p = instr( 1, symbol, "." )
	if( p <= 1 ) then
		exit function
	end if

	vname = hCreateName( left$( symbol, p-1 ), INVALID, preservecase, TRUE, clearname )

    s = hLookupVar( vname, FB.LOOKUPMODE.ALL )
	if( s = NULL ) then
		exit function
	end if

	if( s->class <> FB.SYMBCLASS.VAR ) then
		exit function
	end if

	if( s->typ <> FB.SYMBTYPE.USERDEF ) then
		exit function
	end if

	fields = mid$( symbol, p+1 )

    hCheckTypeField = s

end function

'':::::
function symbLookupVar( symbol as string, typ as integer, ofs as integer, _
					    elm as FBSYMBOL ptr, subtype as FBSYMBOL ptr, _
					    byval addsuffix as integer = TRUE, _
					    byval preservecase as integer = FALSE, _
					    byval clearname as integer = TRUE ) as FBSYMBOL ptr static

    dim s as FBSYMBOL ptr, stype as integer, t as integer
    dim vname as string
    dim cnt as integer
    dim lookupmode as integer
    dim fields as string

    symbLookupVar = NULL

    stype = typ									'' save type

    ''
	if( env.scope = 0 ) then
		lookupmode = FB.LOOKUPMODE.GLOBAL
	else
		lookupmode = FB.LOOKUPMODE.LOCAL
	end if

    do
    	typ = stype
    	cnt = 2									'' try twice, w/ and w/out suffixes
    	do
    		ofs 		= 0
    		elm	        = NULL
    		subtype 	= NULL

    		if( addsuffix ) then
    			t = typ
    		else
    			t = INVALID
    		end if

    		vname = hCreateName( symbol, t, preservecase, TRUE, clearname )

			''
			s = hLookupVar( vname, lookupmode )
			if( s <> NULL ) then
				typ = symbGetType( s )
				if( stype <> INVALID ) then
					'' same type?
					if( stype <> typ ) then
						hReportError FB.ERRMSG.DUPDEFINITION
						exit function
					end if
				end if

				s->acccnt = s->acccnt + 1
				subtype   = s->subtype

				symbLookupVar = s
				exit function
			end if

			''
			if( not clearname ) then
				exit do
			end if

			''
			'' check if it's an UDT field
			''
			s = hCheckTypeField( symbol, preservecase, clearname, fields )
			if( s <> NULL ) then
    			subtype	= s->subtype
    			typ 	= s->typ

    			ofs = symbGetUDTElmOffset( elm, typ, subtype, fields )
    			if( ofs = INVALID ) then
    				hReportError FB.ERRMSG.ELEMENTNOTDEFINED
    				exit function
    			end if

    			s->acccnt = s->acccnt + 1

				symbLookupVar = s
				exit function
			end if

			''
			if( not addsuffix ) then
				exit do
			end if

			''
			cnt = cnt - 1
			if( cnt = 0 ) then
				exit do
			end if

			'' try again, now with or without suffixes
			if( stype = INVALID ) then
				'' now with suffixes
				typ = hGetDefType( symbol )
			else
				'' now without suffixes
				typ = INVALID
			end if

    	loop

    	'' try next escope, if not yet
    	if( lookupmode = FB.LOOKUPMODE.GLOBAL ) then
    		exit do
    	end if

    	lookupmode = FB.LOOKUPMODE.GLOBAL
    loop

    typ = stype

end function

'':::::
function symbLookupFunctionResult( byval f as FBSYMBOL ptr ) as FBSYMBOL ptr static
	dim rname as string

	rname = hCreateName( "_fbpr_" + strpGet( f->aliasidx ), f->typ )

	symbLookupFunctionResult = hashLookup( ctx.lochash, rname )

end function

'':::::
function symbLookupUDT( typename as string, lgt as integer ) as FBSYMBOL ptr static
    dim tname as string, index as uinteger
    dim t as FBSYMBOL ptr

    symbLookupUDT = NULL

    tname = hCreateName( typename, FB.SYMBTYPE.USERDEF )

	'' first check the local symbols if current scope > 0
	index = hashHash( tname )
	if( env.scope > 0 ) then
    	t = hashLookupEx( ctx.lochash, tname, index )
    else
    	t = NULL
    end if

    '' and then the globals
    if( t = NULL ) then
    	t = hashLookupEx( ctx.symhash, tname, index )
    end if

	if( t = NULL ) then
		exit function
	end if

	if( t->class = FB.SYMBCLASS.UDT ) then
		lgt = t->lgt
		symbLookupUDT = t
	end if

end function

'':::::
function symbLookupEnum( id as string ) as FBSYMBOL ptr static
    dim ename as string, index as uinteger
    dim e as FBSYMBOL ptr

    symbLookupEnum = NULL

    ename = hCreateName( id, FB.SYMBTYPE.USERDEF )

	'' first check the local symbols if current scope > 0
	index = hashHash( ename )
	if( env.scope > 0 ) then
    	e = hashLookupEx( ctx.lochash, ename, index )
    else
    	e = NULL
    end if

    '' and then the globals
    if( e = NULL ) then
    	e = hashLookupEx( ctx.symhash, ename, index )
    end if

	if( e = NULL ) then
		exit function
	end if

	if( e->class = FB.SYMBCLASS.ENUM ) then
		symbLookupEnum = e
	end if

end function

'':::::
function symbLookupLabel( label as string ) as FBSYMBOL ptr static
    dim l as FBSYMBOL ptr, lname as string, index as uinteger

    symbLookupLabel = NULL

    lname = hCreateName( label, FB.SYMBTYPE.LABEL )

	'' first check the local symbols if current scope > 0
	index = hashHash( lname )
	if( env.scope > 0 ) then
    	l = hashLookupEx( ctx.lochash, lname, index )
    else
    	l = NULL
    end if

    '' and then the globals
    if( l = NULL ) then
    	l = hashLookupEx( ctx.symhash, lname, index )
    end if

	if( l = NULL ) then
		exit function
	end if

	if( l->class = FB.SYMBCLASS.LABEL ) then
		symbLookupLabel = l
	end if

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' helpers
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbCalcLen( byval typ as integer, byval subtype as FBSYMBOL ptr, byval realsize as integer = FALSE ) as integer static
    dim lgt as integer
    dim e as FBSYMBOL ptr

	lgt = 0

	select case as const typ
	case FB.SYMBTYPE.BYTE, FB.SYMBTYPE.UBYTE
		lgt = 1

	case FB.SYMBTYPE.SHORT, FB.SYMBTYPE.USHORT
		lgt = 2

	case FB.SYMBTYPE.INTEGER, FB.SYMBTYPE.LONG, FB.SYMBTYPE.UINT
		lgt = FB.INTEGERSIZE

	case FB.SYMBTYPE.SINGLE
		lgt = 4

	case FB.SYMBTYPE.DOUBLE
    	lgt = 8

	case FB.SYMBTYPE.FIXSTR
		lgt = 0									'' 0-len literal-strings

	case FB.SYMBTYPE.STRING
		lgt = FB.STRSTRUCTSIZE

	case FB.SYMBTYPE.USERDEF
		if( not realsize ) then
			lgt = subtype->lgt
		else
			e = subtype->udt.tail
			lgt = e->elm.ofs + (e->lgt * e->array.elms)
		end if

	case else
		if( typ >= FB.SYMBTYPE.POINTER ) then
			lgt = FB.POINTERSIZE
		end if
	end select

	symbCalcLen = lgt

end function

'':::::
function symbCalcArgLen( byval typ as integer, byval subtype as FBSYMBOL ptr, byval mode as integer ) as integer static
    dim lgt as integer

	select case mode
	case FB.ARGMODE.BYREF, FB.ARGMODE.BYDESC
		lgt = FB.POINTERSIZE
	case else
		if( typ = FB.SYMBTYPE.STRING ) then
			lgt = FB.POINTERSIZE
		else
			lgt = symbCalcLen( typ, subtype )
		end if
	end select

	symbCalcArgLen = lgt

end function

'':::::
function hCalcDiff( byval dimensions as integer, dTB() as FBARRAYDIM, byval lgt as integer ) as integer
    dim d as integer, diff as integer, elms as integer

	diff = 0
	for d = 0 to (dimensions-1)-1
		elms = (dTB(d+1).upper - dTB(d+1).lower) + 1
		diff = diff + (-dTB(d).lower * elms)
	next d

	if( dimensions > 0 ) then
		diff = diff + -dTB(dimensions-1).lower
	end if

	diff = diff * lgt

	hCalcDiff = diff

end function

'':::::
function hCalcElements( byval s as FBSYMBOL ptr ) as integer static
    dim e as integer, d as integer
    dim n as FBVARDIM ptr

	e = 1
	n = s->array.dimhead
	do while( n <> NULL )
		d = (n->upper - n->lower) + 1
		e = e * d
		n = n->r
	loop

	hCalcElements = e

end function

'':::::
function hCalcElements2( byval dimensions as integer, dTB() as FBARRAYDIM ) as integer static
    dim e as integer, i as integer, d as integer

	e = 1
	for i = 0 to dimensions-1
		d = (dTB(i).upper - dTB(i).lower) + 1
		e = e * d
	next i

	hCalcElements2 = e

end function

'':::::
function hIsStrFixed( byval dtype as integer ) as integer static

    hIsStrFixed = (dtype = IR.DATATYPE.FIXSTR)

end function

'':::::
function hIsString( byval dtype as integer ) as integer static

   	hIsString = (dtype = IR.DATATYPE.STRING) or (dtype = IR.DATATYPE.FIXSTR)

end function

'':::::
function symbIsString( byval s as FBSYMBOL ptr ) as integer static

    symbIsString = hIsString( s->typ )

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' getters and setters
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbGetDefineText( byval d as FBSYMBOL ptr ) as string static

	symbGetDefineText = strpGet( d->def.textidx )

end function

'':::::
function symbGetDefineLen( byval d as FBSYMBOL ptr ) as integer static

	symbGetDefineLen = len( strpGet( d->def.textidx ) )

end function

'':::::
function symbGetAccessCnt( byval s as FBSYMBOL ptr ) as integer

	symbGetAccessCnt = s->acccnt

end function

'':::::
function symbGetLen( byval s as FBSYMBOL ptr ) as integer static

	symbGetLen = s->lgt

end function

'':::::
function symbGetUDTLen( byval udt as FBSYMBOL ptr, byval realsize as integer = TRUE ) as integer static
    dim e as FBSYMBOL ptr

	if( realsize ) then
		e = udt->udt.tail
		symbGetUDTLen = e->elm.ofs + (e->lgt * e->array.elms)
	else
		symbGetUDTLen = udt->lgt
	end if

end function

'':::::
function symbGetFirstNode as FBSYMBOL ptr static

	symbGetFirstNode = ctx.symlist.head

end function

'':::::
function symbGetNextNode( byval n as FBSYMBOL ptr ) as FBSYMBOL ptr static

	if( n <> NULL ) then
		symbGetNextNode = n->nxt
	else
		symbGetNextNode = NULL
	end if

end function

'':::::
function symbGetType( byval s as FBSYMBOL ptr ) as integer static

	symbGetType = s->typ

end function

'':::::
function symbGetSubType( byval s as FBSYMBOL ptr ) as FBSYMBOL ptr static

	if( s <> NULL ) then
		symbGetSubType = s->subtype
	else
		symbGetSubType = NULL
	end if

end function

'':::::
function symbGetClass( byval s as FBSYMBOL ptr ) as integer static

	symbGetClass = s->class

end function

'':::::
function symbGetAllocType( byval s as FBSYMBOL ptr ) as integer static

	symbGetAllocType = s->alloctype

end function

'':::::
sub symbSetAllocType( byval s as FBSYMBOL ptr, byval alloctype as integer ) static

	s->alloctype = alloctype

end sub

'':::::
function symbGetInitialized( byval s as FBSYMBOL ptr ) as integer static

	if( s = NULL ) then
		symbGetInitialized = FALSE
	else
		symbGetInitialized = s->initialized
	end if

end function

'':::::
function symbGetIsDynamic( byval s as FBSYMBOL ptr ) as integer static

	if( s->class = FB.SYMBCLASS.UDTELM ) then
		symbGetIsDynamic = FALSE
	else
		symbGetIsDynamic = (s->alloctype and (FB.ALLOCTYPE.DYNAMIC or FB.ALLOCTYPE.ARGUMENTBYDESC)) > 0
	end if

end function

'':::::
function symbIsArray( byval s as FBSYMBOL ptr ) as integer static

	symbIsArray = FALSE

	if( s = NULL ) then
		exit function
	end if

	if( (s->alloctype and (FB.ALLOCTYPE.DYNAMIC or FB.ALLOCTYPE.ARGUMENTBYDESC)) > 0 ) then
		symbIsArray = TRUE
	else
		symbIsArray = s->array.dims > 0
	end if

end function

'':::::
function symbGetArrayDiff( byval s as FBSYMBOL ptr ) as integer static

	symbGetArrayDiff = s->array.dif

end function

'':::::
function symbGetArrayDimensions( byval s as FBSYMBOL ptr ) as integer static

	symbGetArrayDimensions = s->array.dims

end function

'':::::
sub symbSetArrayDimensions( byval s as FBSYMBOL ptr, byval dims as integer ) static

	s->array.dims = dims

end sub

'':::::
function symbGetArrayDescriptor( byval s as FBSYMBOL ptr ) as FBSYMBOL ptr static

	symbGetArrayDescriptor = s->array.desc

end function

'':::::
function symbGetProcArgs( byval f as FBSYMBOL ptr ) as integer static

	symbGetProcArgs = f->proc.args

end function

'':::::
function symbGetArrayFirstDim( byval s as FBSYMBOL ptr ) as FBVARDIM ptr static

	symbGetArrayFirstDim = s->array.dimhead

end function

'':::::
function symbGetFuncMode( byval f as FBSYMBOL ptr ) as integer static

	symbGetFuncMode = f->proc.mode

end function

'':::::
function symbGetFuncDataType( byval f as FBSYMBOL ptr ) as integer static

	symbGetFuncDataType = f->typ

end function

'':::::
function symbGetProcLib( byval p as FBSYMBOL ptr ) as string static
    dim l as FBLIBRARY ptr

	l = p->proc.lib
	if( l <> NULL ) then
		symbGetProcLib = strpGet( l->nameidx )
	else
	    symbGetProcLib = ""
	end if

end function

'':::::
function symbGetName( byval s as FBSYMBOL ptr ) as string static

	if( s <> NULL ) then
		symbGetName = strpGet( s->nameidx )
	else
		symbGetName = ""
	end if

end function

'':::::
function symbGetAlias( byval s as FBSYMBOL ptr ) as string static

	symbGetAlias = strpGet( s->aliasidx )

end function

'':::::
sub symbGetVarName( byval s as FBSYMBOL ptr, sname as string )  static

	if( s <> NULL ) then
		if( s->aliasidx <> INVALID ) then
			sname = strpGet( s->aliasidx )
		else
			sname = strpGet( s->nameidx )
		end if
	else
		sname = ""
	end if

end sub

'':::::
function symbGetVarOfs( byval s as FBSYMBOL ptr ) as integer static

	if( s <> NULL ) then
		symbGetVarOfs = s->ofs
	else
		symbGetVarOfs = 0
	end if

end function

'':::::
function symbGetVarDscName( byval s as FBSYMBOL ptr ) as string static
	dim d as FBSYMBOL ptr

	d = s->array.desc
	if( d <> NULL ) then
		symbGetVarDscName = strpGet( d->nameidx )
	else
		symbGetVarDscName = ""
	end if

end function

'':::::
function symbGetVarText( byval s as FBSYMBOL ptr ) as string static

	symbGetVarText = strpGet( s->inittextidx )

end function

'':::::
function symbGetConstName( byval c as FBSYMBOL ptr ) as string static

	if( c->aliasidx <> INVALID ) then
		symbGetConstName = strpGet( c->aliasidx )
	else
		symbGetConstName = strpGet( c->nameidx )
	end if

end function

'':::::
function symbGetConstText( byval c as FBSYMBOL ptr ) as string static

	symbGetConstText = strpGet( c->con.textidx )

end function

'':::::
function symbGetLabelIsDeclared( byval l as FBSYMBOL ptr ) as integer static

	symbGetLabelIsDeclared = l->lbl.declared

end function

'':::::
function symbGetProcName( byval p as FBSYMBOL ptr ) as string static

	if( p <> NULL ) then
		if( p->aliasidx <> INVALID ) then
			symbGetProcName = strpGet( p->aliasidx )
		else
			symbGetProcName = strpGet( p->nameidx )
		end if
	end if

end function

'':::::
function symbGetProcIsDeclared( byval f as FBSYMBOL ptr ) as integer static

	symbGetProcIsDeclared = f->proc.isdeclared

end function

'':::::
sub symbSetProcIsDeclared( byval f as FBSYMBOL ptr, byval isdeclared as integer ) static

	f->proc.isdeclared = isdeclared

end sub

'':::::
function symbGetProcFirstArg( byval f as FBSYMBOL ptr ) as FBPROCARG ptr static

	if( f->proc.mode = FB.FUNCMODE.PASCAL ) then
		symbGetProcFirstArg = f->proc.arghead
	else
		symbGetProcFirstArg = f->proc.argtail
	end if

end function

'':::::
function symbGetProcLastArg( byval f as FBSYMBOL ptr ) as FBPROCARG ptr static

	if( f->proc.mode = FB.FUNCMODE.PASCAL ) then
		symbGetProcLastArg = f->proc.argtail
	else
		symbGetProcLastArg = f->proc.arghead
	end if

end function

'':::::
function symbGetProcHeadArg( byval f as FBSYMBOL ptr ) as FBPROCARG ptr static

	symbGetProcHeadArg = f->proc.arghead

end function

'':::::
function symbGetProcTailArg( byval f as FBSYMBOL ptr ) as FBPROCARG ptr static

	symbGetProcTailArg = f->proc.argtail

end function

'':::::
function symbGetProcPrevArg( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, _
							 byval checkconv as integer = TRUE ) as FBPROCARG ptr static

	if( a = NULL ) then
		symbGetProcPrevArg = NULL
		exit function
	end if

	if( checkconv ) then
		if( f->proc.mode = FB.FUNCMODE.PASCAL ) then
			symbGetProcPrevArg = a->l
		else
			symbGetProcPrevArg = a->r
		end if
	else
		symbGetProcPrevArg = a->l
	end if

end function

'':::::
function symbGetProcNextArg( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, _
							 byval checkconv as integer = TRUE ) as FBPROCARG ptr static

	if( a = NULL ) then
		symbGetProcNextArg = NULL
		exit function
	end if

	if( checkconv ) then
		if( f->proc.mode = FB.FUNCMODE.PASCAL ) then
			symbGetProcNextArg = a->r
		else
			symbGetProcNextArg = a->l
		end if
	else
		symbGetProcNextArg = a->r
	end if

end function

'':::::
function symbGetArgDataType( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as integer static
	dim typ as integer

	symbGetArgDataType = INVALID

	if( a = NULL ) then
		exit function
	end if

	typ = a->typ
    if( typ <> INVALID ) then
		symbGetArgDataType = typ
		exit function
	end if

	if( f->proc.mode <> FB.FUNCMODE.CDECL ) then
		exit function
	end if

	'' it's really a "..." arg, so, it's always an integer
	symbGetArgDataType = FB.SYMBTYPE.INTEGER

end function

'':::::
function symbGetArgMode( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as integer static
	dim mode as integer

	symbGetArgMode = INVALID

	if( a = NULL ) then
		exit function
	end if

	mode = a->mode
	if( mode <> INVALID ) then
		symbGetArgMode = mode
		exit function
	end if

	if( f->proc.mode <> FB.FUNCMODE.CDECL ) then
		exit function
	end if

	'' it's really a "..." arg, so, it's always passed by value
	symbGetArgMode = FB.ARGMODE.BYVAL

end function

'':::::
sub symbSetArgMode( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, byval mode as integer ) static

	if( a <> NULL ) then
		a->mode = mode
	end if

end sub

'':::::
function symbGetArgName( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as string static

	symbGetArgName = strpGet( a->nameidx )

end function

'':::::
sub symbSetArgName( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, byval nameidx as integer ) static

	if( a <> NULL ) then
		strpDel a->nameidx
		a->nameidx = nameidx
	end if

end sub

'':::::
function symbGetArgType( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as integer static

	if( a <> NULL ) then
		symbGetArgType = a->typ
	else
		symbGetArgType = INVALID
	end if

end function

'':::::
sub symbSetArgType( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, byval typ as integer ) static

	if( a <> NULL ) then
		a->typ = typ
	end if

end sub

'':::::
function symbGetArgSubtype( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as FBSYMBOL ptr static

	if( a <> NULL ) then
		symbGetArgSubtype = a->subtype
	else
		symbGetArgSubtype = NULL
	end if

end function

'':::::
sub symbSetArgSubType( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, byval subtype as FBSYMBOL ptr ) static

	if( a <> NULL ) then
		a->subtype = subtype
	end if

end sub

'':::::
function symbGetArgSuffix( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as integer static

	if( a <> NULL ) then
		symbGetArgSuffix = a->suffix
	else
		symbGetArgSuffix = INVALID
	end if

end function

'':::::
sub symbSetArgSuffix( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr, byval suffix as integer ) static

	if( a <> NULL ) then
		a->suffix = suffix
	end if

end sub

'':::::
function symbGetArgsLen( byval f as FBSYMBOL ptr ) as integer static

	symbGetArgsLen = f->lgt

end function

'':::::
function symbGetArgOptional( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as integer static

	if( a <> NULL ) then
		symbGetArgOptional = a->optional
	else
		symbGetArgOptional = FALSE
	end if

end function

'':::::
function symbGetArgDefvalue( byval f as FBSYMBOL ptr, byval a as FBPROCARG ptr ) as double static

	if( a <> NULL ) then
		symbGetArgDefvalue = a->defvalue
	else
		symbGetArgDefvalue = 0.0
	end if

end function

'':::::
function symbGetLabelName( byval l as FBSYMBOL ptr ) as string static

	if( l->aliasidx <> INVALID ) then
		symbGetLabelName = strpGet( l->aliasidx )
	else
		symbGetLabelName = strpGet( l->nameidx )
	end if

end function

'':::::
function symbGetLabelScope( byval l as FBSYMBOL ptr ) as integer static

	symbGetLabelScope = l->scope

end function


'':::::
function hFindLib( libname as string, namelist() as string ) as integer
    dim i as integer

	hFindLib = INVALID

	for i = 0 to ubound( namelist ) - 1

		if( len( namelist(i) ) = 0 ) then
			exit function
		end if

		if( namelist(i) = libname ) then
			hFindLib = i
			exit function
		end if
	next i

end function

'':::::
function symbListLibs( namelist() as string, byval index as integer ) as integer static
    dim cnt as integer, node as FBLIBRARY ptr
    dim libname as string

	cnt = index
	node = ctx.liblist.head
	do while( node <> NULL )

		libname = strpGet( node->nameidx )
		if( hFindLib( libname, namelist() ) = INVALID ) then
			namelist(cnt) = libname
			cnt = cnt + 1
		end if

		node = node->nxt
	loop

	symbListLibs = cnt - index

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' del
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
sub hDelSentinel( byval s as FBSENTINEL ptr, byval isglobal as integer ) static

	if( s = NULL ) then
		exit sub
	end if

	s->count = s->count - 1
	if( s->count > 0 ) then
		exit sub
	end if

	'' del from list
	if( s->scope = 0 ) then
		hashDel ctx.senhash, strpGet( s->nameidx )
		listDelNode( @ctx.senlist, s )
	else
		hashDel ctx.locsenhash, strpGet( s->nameidx )
		listDelNode( @ctx.locsenlist, s )
	end if

end sub

'':::::
function symbDelKeyword( keyname as string ) as integer
    dim k as FBSYMBOL ptr
    dim kname as string

    symbDelKeyword = FALSE

	kname = ucase$( keyname )

	'' exists?
	k = hashLookup( ctx.symhash, kname )
	if( k = NULL ) then
		exit function
    elseif( k->class <> FB.SYMBCLASS.KEYWORD ) then
    	exit function
	end if

	'' del from hash table
	hashDel ctx.symhash, kname

	''
	strpDel k->nameidx

	'' del node
	listDelNode( @ctx.symlist, k )

	symbDelKeyword = TRUE

end function

'':::::
function symbDelDefine( byval d as FBSYMBOL ptr ) as integer static
    dim dname as string

    symbDelDefine = FALSE

    if( d = NULL ) then
    	exit function
    elseif( d->class <> FB.SYMBCLASS.DEFINE ) then
    	exit function
    end if

    dname = strpGet( d->nameidx )

	'' del from hash table
	hashDel ctx.symhash, dname

	''
	strpDel d->def.textidx
	strpDel d->nameidx

	'' del node
	listDelNode( @ctx.symlist, d )

	''
	symbDelDefine = TRUE

end function

'':::::
sub symbDelLabel( byval l as FBSYMBOL ptr ) static
    dim lname as string

    if( l = NULL ) then
    	exit sub
    end if

    lname = strpGet( l->nameidx )

    if( l->scope > 0 ) then
    	hashDel ctx.lochash, lname
    else
    	hashDel ctx.symhash, lname
    end if

    strpDel l->nameidx

    listDelNode @ctx.symlist, l

end sub

'':::::
sub hDelVarDims( byval s as FBSYMBOL ptr ) static
    dim n as FBVARDIM ptr, nxt as FBVARDIM ptr

    n = s->array.dimhead
    do while( n <> NULL )
    	nxt = n->r

    	listDelNode @ctx.dimlist, n

    	n = nxt
    loop

    s->array.dimhead = NULL
    s->array.dimtail = NULL
    s->array.dims	  = 0

end sub

'':::::
sub symbDelVar( byval s as FBSYMBOL ptr )
    dim sname as string, freeup as integer

    if( s = NULL ) then
    	exit sub
    end if

	freeup = TRUE

	sname = strpGet( s->nameidx )

	'' local?
	if( s->scope > 0 ) then
		hashDel ctx.lochash, sname

    	if( (s->alloctype and FB.ALLOCTYPE.STATIC) = 0 ) then
			strpDel s->nameidx
			strpDel s->aliasidx
    	else
    		freeup = FALSE
    		'' check if it's not a static array descriptor
    		if( (s->typ <> FB.SYMBTYPE.USERDEF) or (s->subtype <> FB.DESCTYPE.ARRAY) ) then
    			strpDel s->nameidx
    			s->nameidx = INVALID
    		end if
    	end if

    '' global..
    else
		hashDel ctx.symhash, sname

		strpDel s->nameidx
		strpDel s->aliasidx
	end if

    ''
    hDelSentinel s->sentinel, (s->alloctype and FB.ALLOCTYPE.SHARED) <> 0

	if( freeup ) then
    	if( s->array.dims > 0 ) then
    		hDelVarDims s

    		'' del the array descriptor, recursively
    		symbDelVar s->array.desc
    	end if

    	listDelNode @ctx.symlist, s
    end if

end sub

'':::::
sub symbDelConstUDTOrEnum( byval s as FBSYMBOL ptr )
    dim sname as string

    if( s = NULL ) then
    	exit sub
    end if

	sname = strpGet( s->nameidx )

	'' local?
	if( s->scope > 0 ) then
		hashDel ctx.lochash, sname

    '' global..
    else
		hashDel ctx.symhash, sname
	end if

	strpDel s->nameidx
	strpDel s->aliasidx

	''
	hDelSentinel s->sentinel, (s->alloctype and FB.ALLOCTYPE.SHARED) <> 0

    '' !!!FIXME!!! if it's an udt, del the elements too

    listDelNode @ctx.symlist, s

end sub

'':::::
sub symbDelLib( byval l as FBLIBRARY ptr ) static

	if( l = NULL ) then
		exit sub
	end if

	hashDel ctx.libhash, strpGet( l->nameidx )

	strpDel l->nameidx

    listDelNode( @ctx.liblist, l )

end sub

'':::::
private sub hDelArgs( byval f as FBSYMBOL ptr )
	dim a as FBPROCARG ptr, n as FBPROCARG ptr

    a = f->proc.arghead
    do while( a <> NULL )
    	n = a->r
    	strpDel a->nameidx
    	listDelNode( @ctx.arglist, a )
    	a = n
    loop

end sub

'':::::
sub symbDelPrototype( byval f as FBSYMBOL ptr )

    if( f = NULL ) then
    	exit sub
    end if

	hashDel ctx.symhash, strpGet( f->nameidx )

	strpDel f->nameidx
	strpDel f->aliasidx

    ''
    hDelSentinel f->sentinel, TRUE

	if( f->proc.args > 0 ) then
		hDelArgs f
	end if

    listDelNode( @ctx.symlist, f )

end sub

'':::::
sub symbDelLocalSymbols static
    dim node as FBLOCSYMBOL ptr, nxt as FBLOCSYMBOL ptr
    dim s as FBSYMBOL ptr

	node = ctx.loclist.head
    do while( node <> NULL )
    	nxt = node->nxt

    	s = node->s
    	if( (s->alloctype and FB.ALLOCTYPE.SHARED) = 0 ) then

    		select case as const s->class
    		case FB.SYMBCLASS.VAR
    			symbDelVar s
    		case FB.SYMBCLASS.CONST, FB.SYMBCLASS.UDT, FB.SYMBCLASS.ENUM
    			symbDelConstUDTOrEnum s
    		case FB.SYMBCLASS.LABEL
    			symbDelLabel s
    		end select

    	end if

		listDelNode @ctx.loclist, node

		node = nxt
    loop

end sub

'':::::
sub symbFreeLocalDynSymbols( byval proc as FBSYMBOL ptr, byval issub as integer ) static
    dim node as FBLOCSYMBOL ptr, nxt as FBLOCSYMBOL ptr
    dim s as FBSYMBOL ptr
    dim strg as integer, expr as integer, vr as integer
    dim fres as FBSYMBOL ptr

    '' can't free function's result, that's will be done by the rtlib
    if( issub ) then
    	fres = NULL
    else
    	fres = symbLookupFunctionResult( proc )
	end if

	node = ctx.loclist.head
    do while( node <> NULL )
    	nxt = node->nxt

    	s = node->s
    	if( s->class = FB.SYMBCLASS.VAR ) then
    		if( (s->alloctype and (FB.ALLOCTYPE.SHARED or FB.ALLOCTYPE.STATIC)) = 0 ) then

				'' not an argument?
    			if( (s->alloctype and (FB.ALLOCTYPE.ARGUMENTBYDESC or _
    				  				   FB.ALLOCTYPE.ARGUMENTBYVAL or _
    				  				   FB.ALLOCTYPE.ARGUMENTBYREF or _
    				  				   FB.ALLOCTYPE.TEMP)) = 0 ) then

					if( s->array.dims > 0 ) then
						if( (s->alloctype and FB.ALLOCTYPE.DYNAMIC) > 0 ) then
							rtlArrayErase astNewVAR( s, NULL, 0, s->typ )
						elseif( s->typ = FB.SYMBTYPE.STRING ) then
							rtlArrayStrErase s
						end if

					elseif( s->typ = FB.SYMBTYPE.STRING ) then
						'' not funct's result?
						if( s <> fres ) then
							strg = astNewVAR( s, NULL, 0, IR.DATATYPE.STRING )
							expr = rtlStrDelete( strg )
							astFlush expr, vr
						end if
					end if

				end if

    		end if
    	end if

    	node = nxt
    loop

end sub

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' misc
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbGetLastLabel as FBSYMBOL ptr static

	symbGetLastLabel = ctx.lastlbl

end function

'':::::
sub symbSetLastLabel( byval l as FBSYMBOL ptr ) static

	ctx.lastlbl = l

end sub

'':::::
function symbCheckLabels as FBSYMBOL ptr
    dim s as FBSYMBOL ptr

    s = symbGetFirstNode
    do while( s <> NULL )

    	if( s->scope = env.scope ) then
    		if( s->class = FB.SYMBCLASS.LABEL ) then
    			if( not s->lbl.declared ) then
    				symbCheckLabels = s
    				exit function
    			end if
    		end if
    	end if

    	s = symbGetNextNode( s )
    loop

	symbCheckLabels = NULL

end function
