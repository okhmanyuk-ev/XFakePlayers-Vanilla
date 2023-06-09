{*
** $Id: lua.h,v 1.325 2014/12/26 17:24:27 roberto Exp $
** Lua - A Scripting Language
** Lua.org, PUC-Rio, Brazil (http://www.lua.org)
** See Copyright Notice at the end of this file
*}

{*
** Translated to Delphi by Dennis D. Spreen <dennis@spreendigital.de>
** Notes:
    as lua_State is a not defined structure, it is not used as Plua_State
    LUA_VERSION suffixed by '_' for avoiding name collision
    lua_xmove parameter 'to' suffixed by '_' for avoiding name collision
    Comparison and arithmetic functions consts moved to constants
    garbage-collection function and options consts moved to constants
    compatibility macros for unsigned conversions not translated
    event codes consts moved to constants
    LUA_YIELD thread status suffixed by '_' for avoiding name collision
*}

unit Lua.Lib;

interface

// ***********************************
// Microsoft Windows declarations
// ***********************************
{$IF defined(MSWINDOWS)}
uses
  System.Classes,
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils;

const
  LUA_LIBRARY = 'lua5.3.0.dll'; {Do not Localize}

// ***********************************
// MacOs & iOS declarations
// ***********************************
{$ELSEIF defined(MACOS)}
uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Posix.SysTypes;

const
  {$IFDEF IOS}
    {$DEFINE STATICLIBRARY}
    {$IFDEF CPUARM} // iOS device
      LUA_LIBRARY = 'liblua.a'; {Do not Localize}
    {$ELSE} // iOS Simulator
      LUA_LIBRARY = 'liblua_sim.a'; {Do not Localize}
    {$ENDIF}
  {$ELSE} // MacOS
    LUA_LIBRARY = 'liblua5.3.0.dylib'; {Do not Localize}
  {$ENDIF}

// ***********************************
// Android declarations
// ***********************************
{$ELSEIF defined(ANDROID)}
uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Posix.SysTypes;

const
  LUA_LIBRARY = 'liblua.so'; {Do not Localize}
{$ENDIF}

{*
** luaconf.h
*}
  LUA_IDSIZE = 60;
  LUAI_FIRSTPSEUDOIDX = -1001000;

{*
** lua.h
*}
  LUA_VERSION_MAJOR   = '5';
  LUA_VERSION_MINOR   = '3';
  LUA_VERSION_NUM     = 503;
  LUA_VERSION_RELEASE = '0';

  LUA_VERSION_    = 'Lua ' + LUA_VERSION_MAJOR + '.' + LUA_VERSION_MINOR;
  LUA_RELEASE     = LUA_VERSION_ + '.' + LUA_VERSION_RELEASE;
  LUA_COPYRIGHT   = LUA_RELEASE + '  Copyright (C) 1994-2015 Lua.org, PUC-Rio';
  LUA_AUTHORS	  = 'R. Ierusalimschy, L. H. de Figueiredo, W. Celes';


{* mark for precompiled code ('<esc>Lua') *}
  LUA_SIGNATURE	= #$1b'Lua';

{* option for multiple returns in 'lua_pcall' and 'lua_call' *}
  LUA_MULTRET	= -1;


{*
** pseudo-indices
*}
   LUA_REGISTRYINDEX = LUAI_FIRSTPSEUDOIDX;

{* thread status *}
  LUA_OK = 0;
  LUA_YIELD_ = 1;
  LUA_ERRRUN = 2;
  LUA_ERRSYNTAX = 3;
  LUA_ERRMEM = 4;
  LUA_ERRGCMM = 5;
  LUA_ERRERR = 6;

{*
** basic types
*}
  LUA_TNONE          = (-1);

  LUA_TNIL	     = 0;
  LUA_TBOOLEAN	     = 1;
  LUA_TLIGHTUSERDATA = 2;
  LUA_TNUMBER	     = 3;
  LUA_TSTRING	     = 4;
  LUA_TTABLE	     = 5;
  LUA_TFUNCTION	     = 6;
  LUA_TUSERDATA	     = 7;
  LUA_TTHREAD	     = 8;

  LUA_NUMTAGS	     = 9;


{* minimum Lua stack available to a C function *}
  LUA_MINSTACK	     = 20;


{* predefined values in the registry *}
  LUA_RIDX_MAINTHREAD	= 1;
  LUA_RIDX_GLOBALS	= 2;
  LUA_RIDX_LAST		= LUA_RIDX_GLOBALS;

{*
** Comparison and arithmetic functions
*}

  LUA_OPADD  = 0; {* ORDER TM, ORDER OP *}
  LUA_OPSUB  = 1;
  LUA_OPMUL  = 2;
  LUA_OPMOD  = 3;
  LUA_OPPOW  = 4;
  LUA_OPDIV  = 5;
  LUA_OPIDIV = 6;
  LUA_OPBAND = 7;
  LUA_OPBOR  = 8;
  LUA_OPBXOR = 9;
  LUA_OPSHL  = 10;
  LUA_OPSHR  = 11;
  LUA_OPUNM  = 12;
  LUA_OPBNOT = 13;

  LUA_OPEQ  = 0;
  LUA_OPLT  = 1;
  LUA_OPLE  = 2;

{*
** garbage-collection function and options
*}

  LUA_GCSTOP	   = 0;
  LUA_GCRESTART	   = 1;
  LUA_GCCOLLECT	   = 2;
  LUA_GCCOUNT	   = 3;
  LUA_GCCOUNTB	   = 4;
  LUA_GCSTEP	   = 5;
  LUA_GCSETPAUSE   = 6;
  LUA_GCSETSTEPMUL = 7;
  LUA_GCISRUNNING  = 9;

{*
** Event codes
*}
  LUA_HOOKCALL     = 0;
  LUA_HOOKRET      = 1;
  LUA_HOOKLINE     = 2;
  LUA_HOOKCOUNT	   = 3;
  LUA_HOOKTAILCALL = 4;


{*
** Event masks
*}
  LUA_MASKCALL = 1 shl LUA_HOOKCALL;
  LUA_MASKRET = 1 shl LUA_HOOKRET;
  LUA_MASKLINE = 1 shl LUA_HOOKLINE;
  LUA_MASKCOUNT = 1 shl LUA_HOOKCOUNT;

{*
**  lualib.h
*}
  LUA_COLIBNAME = 'coroutine';
  LUA_TABLIBNAME = 'table';
  LUA_IOLIBNAME = 'io';
  LUA_OSLIBNAME	= 'os';
  LUA_STRLIBNAME = 'string';
  LUA_UTF8LIBNAME = 'utf8';
  LUA_BITLIBNAME = 'bit32';
  LUA_MATHLIBNAME = 'math';
  LUA_DBLIBNAME = 'debug';
  LUA_LOADLIBNAME = 'package';

{*
** lauxlib.h
*}

  LUAL_NUMSIZES = sizeof(NativeInt)*16 + sizeof(Double);

{* pre-defined references *}
  LUA_NOREF  = -2;
  LUA_REFNIL = -1;

{*
@@ LUAL_BUFFERSIZE is the buffer size used by the lauxlib buffer system.
** CHANGE it if it uses too much C-stack space.
*}
  LUAL_BUFFERSIZE = Integer($80 * sizeof(Pointer) * sizeof(NativeInt));

{*
** A file handle is a userdata with metatable 'LUA_FILEHANDLE' and
** initial structure 'luaL_Stream' (it may contain other fields
** after that initial structure).
*}

  LUA_FILEHANDLE = 'FILE*';

type
  TLuaHandle = Pointer;

  ptrdiff_t = NativeInt;

{* type of numbers in Lua *}
   lua_Number   = Double;

{* type for integer functions *}
  lua_Integer  = Int64;//NativeInt;

{* unsigned integer type *}
   lua_Unsigned = Uint64; //NativeUInt;

{* type for continuation-function contexts *}
  lua_KContext = ptrdiff_t;


{*
** Type for C functions registered with Lua
*}
  lua_CFunction = function(L: TLuaHandle): Integer; cdecl;

{*
** Type for continuation functions
*}
  lua_KFunction = function(L: TLuaHandle; status: Integer; ctx: lua_KContext): Integer; cdecl;


{*
** Type for functions that read/write blocks when loading/dumping Lua chunks
*}
  lua_Reader = function(L: TLuaHandle; ud: Pointer; sz: size_t): MarshaledAString; cdecl;
  lua_Writer = function(L: TLuaHandle; p: Pointer; sz: size_t; ud: Pointer): Integer; cdecl;

{*
** Type for memory-allocation functions
*}
  lua_Alloc = function(ud: Pointer; ptr: Pointer; osize: size_t; nsize: size_t): Pointer; cdecl;


{*
** generic extra include file
*}
{#if defined(LUA_USER_H)
#include LUA_USER_H
#endif}


{*
** RCS ident string
*}
//extern const char lua_ident[];

 lua_Debug = record            (* activation record *)
    event: Integer;
    name: MarshaledAString;               (* (n) *)
    namewhat: MarshaledAString;           (* (n) `global', `local', `field', `method' *)
    what: MarshaledAString;               (* (S) `Lua', `C', `main', `tail'*)
    source: MarshaledAString;             (* (S) *)
    currentline: Integer;      (* (l) *)
    linedefined: Integer;      (* (S) *)
    lastlinedefined: Integer;  (* (S) *)
    nups: Byte;                (* (u) number of upvalues *)
    nparams: Byte;             (* (u) number of parameters *)
    isvararg: ByteBool;        (* (u) *)
    istailcall: ByteBool;      (* (t) *)
    short_src: array[0..LUA_IDSIZE - 1] of Char; (* (S) *)
    (* private part *)
    i_ci: Pointer;             (* active function *)  // ptr to struct CallInfo
 end;
 Plua_Debug = ^lua_Debug;


{* Functions to be called by the debugger in specific events *}
  lua_Hook = procedure(L: TLuaHandle; ar: Plua_Debug); cdecl;

   luaL_Reg = record
      name: MarshaledAString;
      func: lua_CFunction;
   end;
   PluaL_Reg = ^luaL_Reg;

{*
** Generic Buffer manipulation
*}

   luaL_Buffer = record
     b: MarshaledAString; {* buffer address *}
     size: size_t;  {* buffer size *}
     n: size_t;  {* number of characters in buffer *}
     L: TLuaHandle;
     initb: array[0..LUAL_BUFFERSIZE - 1] of Byte;  {* initial buffer *}
   end;

   Plual_Buffer = ^lual_Buffer;

{*
** File handles for IO library
*}
   luaL_Stream = record
     f: Pointer; {* stream (NULL for incompletely created streams) *}
     closef: lua_CFunction; {* to close stream (NULL for closed streams) *}
   end;

// Use procedure entries as variables (only if dynamic library)
{$IFNDEF STATICLIBRARY}
var
{$ENDIF}

{*
** state manipulation
*}
{$IFDEF STATICLIBRARY}
  function lua_newstate(f: lua_Alloc; ud: Pointer): TLuaHandle; cdecl; external LUA_LIBRARY;
  procedure lua_close(L: TLuaHandle); cdecl; external LUA_LIBRARY;
  function lua_newthread(L: TLuaHandle): TLuaHandle; cdecl; external LUA_LIBRARY;
  function lua_atpanic(L: TLuaHandle; panicf: lua_CFunction): lua_CFunction; cdecl; external LUA_LIBRARY;
  function lua_version(L: TLuaHandle): lua_Number; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_newstate: function(f: lua_Alloc; ud: Pointer): TLuaHandle; cdecl;
  lua_close: procedure (L: TLuaHandle); cdecl;
  lua_newthread: function(L: TLuaHandle): TLuaHandle; cdecl;
  lua_atpanic: function(L: TLuaHandle; panicf: lua_CFunction): lua_CFunction; cdecl;
  lua_version: function(L: TLuaHandle): lua_Number; cdecl;
{$ENDIF}


{*
** basic stack manipulation
*}
{$IFDEF STATICLIBRARY}
  function lua_absindex(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_gettop(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  procedure lua_settop(L: TLuaHandle; idx: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_pushvalue(L: TLuaHandle; idx: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_rotate(L: TLuaHandle; idx: Integer; n: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_copy(L: TLuaHandle; fromidx: Integer; toidx: Integer); cdecl; external LUA_LIBRARY;
  function lua_checkstack(L: TLuaHandle; n: Integer): Integer; cdecl; external LUA_LIBRARY;
  procedure lua_xmove(from: TLuaHandle; to_: TLuaHandle; n: Integer); cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_absindex: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_gettop: function(L: TLuaHandle): Integer; cdecl;
  lua_settop: procedure(L: TLuaHandle; idx: Integer); cdecl;
  lua_pushvalue: procedure(L: TLuaHandle; idx: Integer); cdecl;
  lua_rotate: procedure(L: TLuaHandle; idx: Integer; n: Integer); cdecl;
  lua_copy: procedure(L: TLuaHandle; fromidx: Integer; toidx: Integer); cdecl;
  lua_checkstack: function(L: TLuaHandle; n: Integer): Integer; cdecl;
  lua_xmove: procedure(from: TLuaHandle; to_: TLuaHandle; n: Integer); cdecl;
{$ENDIF}


{*
** access functions (stack -> C)
*}
{$IFDEF STATICLIBRARY}
  function lua_isnumber(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_isstring(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_iscfunction(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_isinteger(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_isuserdata(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_type(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_typename(L: TLuaHandle; tp: Integer): MarshaledAString; cdecl; external LUA_LIBRARY;

  function lua_tonumberx(L: TLuaHandle; idx: Integer; isnum: PLongBool): lua_Number; cdecl; external LUA_LIBRARY;
  function lua_tointegerx(L: TLuaHandle; idx: Integer; isnum: PLongBool): lua_Integer; cdecl; external LUA_LIBRARY;
  function lua_toboolean(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_tolstring(L: TLuaHandle; idx: Integer; len: Psize_t): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_rawlen(L: TLuaHandle; idx: Integer): size_t; cdecl; external LUA_LIBRARY;
  function lua_tocfunction(L: TLuaHandle; idx: Integer): lua_CFunction; cdecl; external LUA_LIBRARY;
  function lua_touserdata(L: TLuaHandle; idx: Integer): Pointer; cdecl; external LUA_LIBRARY;
  function lua_tothread(L: TLuaHandle; idx: Integer): TLuaHandle; cdecl; external LUA_LIBRARY;
  function lua_topointer(L: TLuaHandle; idx: Integer): Pointer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_isnumber: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_isstring: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_iscfunction: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_isinteger: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_isuserdata: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_type: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_typename: function(L: TLuaHandle; tp: Integer): MarshaledAString; cdecl;

  lua_tonumberx: function(L: TLuaHandle; idx: Integer; isnum: PLongBool): lua_Number; cdecl;
  lua_tointegerx: function(L: TLuaHandle; idx: Integer; isnum: PLongBool): lua_Integer; cdecl;
  lua_toboolean: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_tolstring: function(L: TLuaHandle; idx: Integer; len: Psize_t): MarshaledAString; cdecl;
  lua_rawlen: function(L: TLuaHandle; idx: Integer): size_t; cdecl;
  lua_tocfunction: function(L: TLuaHandle; idx: Integer): lua_CFunction; cdecl;
  lua_touserdata: function(L: TLuaHandle; idx: Integer): Pointer; cdecl;
  lua_tothread: function(L: TLuaHandle; idx: Integer): TLuaHandle; cdecl;
  lua_topointer: function(L: TLuaHandle; idx: Integer): Pointer; cdecl;
{$ENDIF}

{*
** Comparison and arithmetic functions
*}
{$IFDEF STATICLIBRARY}
  procedure lua_arith(L: TLuaHandle; op: Integer); cdecl; external LUA_LIBRARY;
  function lua_rawequal(L: TLuaHandle; idx1: Integer; idx2: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_compare(L: TLuaHandle; idx1: Integer; idx2: Integer; op: Integer): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_arith: procedure(L: TLuaHandle; op: Integer); cdecl;
  lua_rawequal: function(L: TLuaHandle; idx1: Integer; idx2: Integer): Integer; cdecl;
  lua_compare: function(L: TLuaHandle; idx1: Integer; idx2: Integer; op: Integer): Integer; cdecl;
{$ENDIF}


{*
** push functions (C -> stack)
*}
{$IFDEF STATICLIBRARY}
  procedure lua_pushnil(L: TLuaHandle); cdecl; external LUA_LIBRARY;
  procedure lua_pushnumber(L: TLuaHandle; n: lua_Number); cdecl; external LUA_LIBRARY;
  procedure lua_pushinteger(L: TLuaHandle; n: lua_Integer); cdecl; external LUA_LIBRARY;
  function lua_pushlstring(L: TLuaHandle; s: MarshaledAString; len: size_t): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_pushstring(L: TLuaHandle; s: MarshaledAString): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_pushvfstring(L: TLuaHandle; fmt: MarshaledAString; argp: Pointer): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_pushfstring(L: TLuaHandle; fmt: MarshaledAString; args: array of const): MarshaledAString; cdecl; external LUA_LIBRARY;
  procedure lua_pushcclosure(L: TLuaHandle; fn: lua_CFunction; n: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_pushboolean(L: TLuaHandle; b: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_pushlightuserdata(L: TLuaHandle; p: Pointer); cdecl; external LUA_LIBRARY;
  function lua_pushthread(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_pushnil: procedure(L: TLuaHandle); cdecl;
  lua_pushnumber: procedure(L: TLuaHandle; n: lua_Number); cdecl;
  lua_pushinteger: procedure(L: TLuaHandle; n: lua_Integer); cdecl;
  lua_pushlstring: function(L: TLuaHandle; s: MarshaledAString; len: size_t): MarshaledAString; cdecl;
  lua_pushstring: function(L: TLuaHandle; s: MarshaledAString): MarshaledAString; cdecl;
  lua_pushvfstring: function(L: TLuaHandle; fmt: MarshaledAString; argp: Pointer): MarshaledAString; cdecl;
  lua_pushfstring: function(L: TLuaHandle; fmt: MarshaledAString; args: array of const): MarshaledAString; cdecl;
  lua_pushcclosure: procedure(L: TLuaHandle; fn: lua_CFunction; n: Integer); cdecl;
  lua_pushboolean: procedure(L: TLuaHandle; b: Integer); cdecl;
  lua_pushlightuserdata: procedure(L: TLuaHandle; p: Pointer); cdecl;
  lua_pushthread: function(L: TLuaHandle): Integer; cdecl;
{$ENDIF}


{*
** get functions (Lua -> stack)
*}
{$IFDEF STATICLIBRARY}
  function lua_getglobal(L: TLuaHandle; const name: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function lua_gettable(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_getfield(L: TLuaHandle; idx: Integer; k: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function lua_geti(L: TLuaHandle; idx: Integer; n: lua_Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_rawget(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_rawgeti(L: TLuaHandle; idx: Integer; n: lua_Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_rawgetp(L: TLuaHandle; idx: Integer; p: Pointer): Integer; cdecl; external LUA_LIBRARY;

  procedure lua_createtable(L: TLuaHandle; narr: Integer; nrec: Integer); cdecl; external LUA_LIBRARY;
  function lua_newuserdata(L: TLuaHandle; sz: size_t): Pointer; cdecl; external LUA_LIBRARY;
  function lua_getmetatable(L: TLuaHandle; objindex: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_getuservalue(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_getglobal: function(L: TLuaHandle; const name: MarshaledAString): Integer; cdecl;
  lua_gettable: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_getfield: function(L: TLuaHandle; idx: Integer; k: MarshaledAString): Integer; cdecl;
  lua_geti: function(L: TLuaHandle; idx: Integer; n: lua_Integer): Integer; cdecl;
  lua_rawget: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
  lua_rawgeti: function(L: TLuaHandle; idx: Integer; n: lua_Integer): Integer; cdecl;
  lua_rawgetp: function(L: TLuaHandle; idx: Integer; p: Pointer): Integer; cdecl;

  lua_createtable: procedure(L: TLuaHandle; narr: Integer; nrec: Integer); cdecl;
  lua_newuserdata: function(L: TLuaHandle; sz: size_t): Pointer; cdecl;
  lua_getmetatable: function(L: TLuaHandle; objindex: Integer): Integer; cdecl;
  lua_getuservalue: function(L: TLuaHandle; idx: Integer): Integer; cdecl;
{$ENDIF}


{*
** set functions (stack -> Lua)
*}
{$IFDEF STATICLIBRARY}
  procedure lua_setglobal(L: TLuaHandle; name: MarshaledAString); cdecl; external LUA_LIBRARY;
  procedure lua_settable(L: TLuaHandle; idx: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_setfield(L: TLuaHandle; idx: Integer; k: MarshaledAString); cdecl; external LUA_LIBRARY;
  procedure lua_seti(L: TLuaHandle; idx: Integer; n: lua_Integer); cdecl; external LUA_LIBRARY;
  procedure lua_rawset(L: TLuaHandle; idx: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_rawseti(L: TLuaHandle; idx: Integer; n: lua_Integer); cdecl; external LUA_LIBRARY;
  procedure lua_rawsetp(L: TLuaHandle; idx: Integer; p: Pointer); cdecl; external LUA_LIBRARY;
  function lua_setmetatable(L: TLuaHandle; objindex: Integer): Integer; cdecl; external LUA_LIBRARY;
  procedure lua_setuservalue(L: TLuaHandle; idx: Integer); cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_setglobal: procedure(L: TLuaHandle; name: MarshaledAString); cdecl;
  lua_settable: procedure(L: TLuaHandle; idx: Integer); cdecl;
  lua_setfield: procedure(L: TLuaHandle; idx: Integer; k: MarshaledAString); cdecl;
  lua_seti: procedure(L: TLuaHandle; idx: Integer; n: lua_Integer); cdecl;
  lua_rawset: procedure(L: TLuaHandle; idx: Integer); cdecl;
  lua_rawseti: procedure(L: TLuaHandle; idx: Integer; n: lua_Integer); cdecl;
  lua_rawsetp: procedure(L: TLuaHandle; idx: Integer; p: Pointer); cdecl;
  lua_setmetatable: function(L: TLuaHandle; objindex: Integer): Integer; cdecl;
  lua_setuservalue: procedure(L: TLuaHandle; idx: Integer); cdecl;
{$ENDIF}


{*
** 'load' and 'call' functions (load and run Lua code)
*}
{$IFDEF STATICLIBRARY}
  procedure lua_callk(L: TLuaHandle; nargs: Integer; nresults: Integer; ctx: lua_KContext; k: lua_KFunction); cdecl; external LUA_LIBRARY;

  function lua_pcallk(L: TLuaHandle; nargs: Integer; nresults: Integer; errfunc: Integer;
    ctx: lua_KContext; k: lua_KFunction): Integer; cdecl; external LUA_LIBRARY;

  function lua_load(L: TLuaHandle; reader: lua_Reader; dt: Pointer; const chunkname: MarshaledAString;
    const mode: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;

  function lua_dump(L: TLuaHandle; writer: lua_Writer; data: Pointer; strip: Integer): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_callk: procedure(L: TLuaHandle; nargs: Integer; nresults: Integer; ctx: lua_KContext; k: lua_KFunction); cdecl;

  lua_pcallk: function(L: TLuaHandle; nargs: Integer; nresults: Integer; errfunc: Integer;
    ctx: lua_KContext; k: lua_KFunction): Integer; cdecl;

  lua_load: function(L: TLuaHandle; reader: lua_Reader; dt: Pointer; const chunkname: MarshaledAString;
    const mode: MarshaledAString): Integer; cdecl;

  lua_dump: function(L: TLuaHandle; writer: lua_Writer; data: Pointer; strip: Integer): Integer; cdecl;
{$ENDIF}


{*
** coroutine functions
*}
{$IFDEF STATICLIBRARY}
  function lua_yieldk(L: TLuaHandle; nresults: Integer; ctx: lua_KContext; k: lua_KFunction): Integer; cdecl; external LUA_LIBRARY;
  function lua_resume(L: TLuaHandle; from: TLuaHandle; narg: Integer): Integer; cdecl; external LUA_LIBRARY;
  function lua_status(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function lua_isyieldable(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_yieldk: function(L: TLuaHandle; nresults: Integer; ctx: lua_KContext; k: lua_KFunction): Integer; cdecl;
  lua_resume: function(L: TLuaHandle; from: TLuaHandle; narg: Integer): Integer; cdecl;
  lua_status: function(L: TLuaHandle): Integer; cdecl;
  lua_isyieldable: function(L: TLuaHandle): Integer; cdecl;
{$ENDIF}

{*
** garbage-collection function and options
*}
{$IFDEF STATICLIBRARY}
  function lua_gc(L: TLuaHandle; what: Integer; data: Integer): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_gc: function(L: TLuaHandle; what: Integer; data: Integer): Integer; cdecl;
{$ENDIF}


{*
** miscellaneous functions
*}
{$IFDEF STATICLIBRARY}
  function lua_error(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function lua_next(L: TLuaHandle; idx: Integer): Integer; cdecl; external LUA_LIBRARY;

  procedure lua_concat(L: TLuaHandle; n: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_len(L: TLuaHandle; idx: Integer); cdecl; external LUA_LIBRARY;

  function lua_stringtonumber(L: TLuaHandle; const s: MarshaledAString): size_t; cdecl; external LUA_LIBRARY;

  function lua_getallocf(L: TLuaHandle; ud: PPointer): lua_Alloc; cdecl; external LUA_LIBRARY;
  procedure lua_setallocf(L: TLuaHandle; f: lua_Alloc; ud: Pointer); cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_error: function(L: TLuaHandle): Integer; cdecl;
  lua_next: function(L: TLuaHandle; idx: Integer): Integer; cdecl;

  lua_concat: procedure(L: TLuaHandle; n: Integer); cdecl;
  lua_len: procedure(L: TLuaHandle; idx: Integer); cdecl;

  lua_stringtonumber: function(L: TLuaHandle; const s: MarshaledAString): size_t; cdecl;

  lua_getallocf: function(L: TLuaHandle; ud: PPointer): lua_Alloc; cdecl;
  lua_setallocf: procedure(L: TLuaHandle; f: lua_Alloc; ud: Pointer); cdecl;
{$ENDIF}


{*
** ======================================================================
** Debug API
** ======================================================================
*}
{$IFDEF STATICLIBRARY}
  function lua_getstack(L: TLuaHandle; level: Integer; ar: Plua_Debug): Integer; cdecl; external LUA_LIBRARY;
  function lua_getinfo(L: TLuaHandle; const what: MarshaledAString; ar: Plua_Debug): Integer; cdecl; external LUA_LIBRARY;
  function lua_getlocal(L: TLuaHandle; const ar: Plua_Debug; n: Integer): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_setlocal(L: TLuaHandle; const ar: Plua_Debug; n: Integer): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_getupvalue(L: TLuaHandle; funcindex, n: Integer): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_setupvalue(L: TLuaHandle; funcindex, n: Integer): MarshaledAString; cdecl; external LUA_LIBRARY;
  function lua_upvalueid(L: TLuaHandle; fidx, n: Integer): Pointer; cdecl; external LUA_LIBRARY;
  procedure lua_upvaluejoin(L: TLuaHandle; fix1, n1, fidx2, n2: Integer); cdecl; external LUA_LIBRARY;
  procedure lua_sethook(L: TLuaHandle; func: lua_Hook; mask: Integer; count: Integer); cdecl; external LUA_LIBRARY;
  function lua_gethook(L: TLuaHandle): lua_Hook; cdecl; external LUA_LIBRARY;
  function lua_gethookmask(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function lua_gethookcount(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
{$ELSE}
  lua_getstack: function(L: TLuaHandle; level: Integer; ar: Plua_Debug): Integer; cdecl;
  lua_getinfo: function(L: TLuaHandle; const what: MarshaledAString; ar: Plua_Debug): Integer; cdecl;
  lua_getlocal: function(L: TLuaHandle; const ar: Plua_Debug; n: Integer): MarshaledAString; cdecl;
  lua_setlocal: function(L: TLuaHandle; const ar: Plua_Debug; n: Integer): MarshaledAString; cdecl;
  lua_getupvalue: function(L: TLuaHandle; funcindex, n: Integer): MarshaledAString; cdecl;
  lua_setupvalue: function(L: TLuaHandle; funcindex, n: Integer): MarshaledAString; cdecl;
  lua_upvalueid: function(L: TLuaHandle; fidx, n: Integer): Pointer; cdecl;
  lua_upvaluejoin: procedure(L: TLuaHandle; fix1, n1, fidx2, n2: Integer); cdecl;
  lua_sethook: procedure(L: TLuaHandle; func: lua_Hook; mask: Integer; count: Integer); cdecl;
  lua_gethook: function(L: TLuaHandle): lua_Hook; cdecl;
  lua_gethookmask: function(L: TLuaHandle): Integer; cdecl;
  lua_gethookcount: function(L: TLuaHandle): Integer; cdecl;
{$ENDIF}



{*
** ======================================================================
** lualib.h
** ======================================================================
*}
{$IFDEF STATICLIBRARY}
  function luaopen_base(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_coroutine(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_table(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_io(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_os(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_string(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_utf8(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_bit32(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_math(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_debug(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;
  function luaopen_package(L: TLuaHandle): Integer; cdecl; external LUA_LIBRARY;

 {* open all previous libraries *}
  procedure luaL_openlibs(L: TLuaHandle); cdecl; external LUA_LIBRARY;
{$ELSE}
  luaopen_base: function(L: TLuaHandle): Integer; cdecl;
  luaopen_coroutine: function(L: TLuaHandle): Integer; cdecl;
  luaopen_table: function(L: TLuaHandle): Integer; cdecl;
  luaopen_io: function(L: TLuaHandle): Integer; cdecl;
  luaopen_os: function(L: TLuaHandle): Integer; cdecl;
  luaopen_string: function(L: TLuaHandle): Integer; cdecl;
  luaopen_utf8: function(L: TLuaHandle): Integer; cdecl;
  luaopen_bit32: function(L: TLuaHandle): Integer; cdecl;
  luaopen_math: function(L: TLuaHandle): Integer; cdecl;
  luaopen_debug: function(L: TLuaHandle): Integer; cdecl;
  luaopen_package: function(L: TLuaHandle): Integer; cdecl;

 {* open all previous libraries *}
  luaL_openlibs: procedure(L: TLuaHandle); cdecl;
{$ENDIF}


{*
** ======================================================================
** lauxlib.h
** ======================================================================
*}
{$IFDEF STATICLIBRARY}
  procedure luaL_checkversion_(L: TLuaHandle; ver: lua_Number; sz: size_t); cdecl; external LUA_LIBRARY;
  function luaL_getmetafield(L: TLuaHandle; obj: Integer; e: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function luaL_callmeta(L: TLuaHandle; obj: Integer; e: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function luaL_tolstring(L: TLuaHandle; idx: Integer; len: Psize_t): MarshaledAString; cdecl; external LUA_LIBRARY;
  function luaL_argerror(L: TLuaHandle; arg: Integer; extramsg: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function luaL_checklstring(L: TLuaHandle; arg: Integer; l_: Psize_t): MarshaledAString; cdecl; external LUA_LIBRARY;
  function luaL_optlstring(L: TLuaHandle; arg: Integer; const def: MarshaledAString; l_: Psize_t): MarshaledAString; cdecl; external LUA_LIBRARY;
  function luaL_checknumber(L: TLuaHandle; arg: Integer): lua_Number; cdecl; external LUA_LIBRARY;
  function luaL_optnumber(L: TLuaHandle; arg: Integer; def: lua_Number): lua_Number; cdecl; external LUA_LIBRARY;
  function luaL_checkinteger(L: TLuaHandle; arg: Integer): lua_Integer; cdecl; external LUA_LIBRARY;
  function luaL_optinteger(L: TLuaHandle; arg: Integer; def: lua_Integer): lua_Integer; cdecl; external LUA_LIBRARY;

  procedure luaL_checkstack(L: TLuaHandle; sz: Integer; const msg: MarshaledAString); cdecl; external LUA_LIBRARY;
  procedure luaL_checktype(L: TLuaHandle; arg: Integer; t: Integer); cdecl; external LUA_LIBRARY;
  procedure luaL_checkany(L: TLuaHandle; arg: Integer); cdecl; external LUA_LIBRARY;

  function luaL_newmetatable(L: TLuaHandle; const tname: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  procedure luaL_setmetatable(L: TLuaHandle; const tname: MarshaledAString); cdecl; external LUA_LIBRARY;
  procedure luaL_testudata(L: TLuaHandle; ud: Integer; const tname: MarshaledAString); cdecl; external LUA_LIBRARY;
  function luaL_checkudata(L: TLuaHandle; ud: Integer; const tname: MarshaledAString): Pointer; cdecl; external LUA_LIBRARY;

  procedure luaL_where(L: TLuaHandle; lvl: Integer); cdecl; external LUA_LIBRARY;
  function luaL_error(L: TLuaHandle; fmt: MarshaledAString; args: array of const): Integer; cdecl; external LUA_LIBRARY;

  function luaL_checkoption(L: TLuaHandle; arg: Integer; const def: MarshaledAString; const lst: PMarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function luaL_fileresult(L: TLuaHandle; stat: Integer; fname: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function luaL_execresult(L: TLuaHandle; stat: Integer): Integer; cdecl; external LUA_LIBRARY;


  function luaL_ref(L: TLuaHandle; t: Integer): Integer; cdecl; external LUA_LIBRARY;
  procedure luaL_unref(L: TLuaHandle; t: Integer; ref: Integer); cdecl; external LUA_LIBRARY;
  function luaL_loadfilex(L: TLuaHandle; const filename: MarshaledAString; const mode: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;

  function luaL_loadbufferx(L: TLuaHandle; const buff: MarshaledAString; sz: size_t;
                                   const name: MarshaledAString; const mode: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;
  function luaL_loadstring(L: TLuaHandle; const s: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;

  function luaL_newstate(): TLuaHandle; cdecl; external LUA_LIBRARY;
  function luaL_len(L: TLuaHandle; idx: Integer): lua_Integer; cdecl; external LUA_LIBRARY;

  function luaL_gsub(L: TLuaHandle; const s: MarshaledAString; const p: MarshaledAString; const r: MarshaledAString): MarshaledAString; cdecl; external LUA_LIBRARY;
  procedure luaL_setfuncs(L: TLuaHandle; const l_: PluaL_Reg; nup: Integer); cdecl; external LUA_LIBRARY;

  function luaL_getsubtable(L: TLuaHandle; idx: Integer; const fname: MarshaledAString): Integer; cdecl; external LUA_LIBRARY;

  procedure luaL_traceback(L: TLuaHandle; L1: TLuaHandle; const msg: MarshaledAString; level: Integer); cdecl; external LUA_LIBRARY;

  procedure luaL_requiref(L: TLuaHandle; const modname: MarshaledAString; openf: lua_CFunction; glb: Integer); cdecl; external LUA_LIBRARY;
{$ELSE}
  luaL_checkversion_: procedure(L: TLuaHandle; ver: lua_Number; sz: size_t); cdecl;
  luaL_getmetafield: function(L: TLuaHandle; obj: Integer; e: MarshaledAString): Integer; cdecl;
  luaL_callmeta: function(L: TLuaHandle; obj: Integer; e: MarshaledAString): Integer; cdecl;
  luaL_tolstring: function(L: TLuaHandle; idx: Integer; len: Psize_t): MarshaledAString; cdecl;
  luaL_argerror: function(L: TLuaHandle; arg: Integer; extramsg: MarshaledAString): Integer; cdecl;
  luaL_checklstring: function(L: TLuaHandle; arg: Integer; l_: Psize_t): MarshaledAString; cdecl;
  luaL_optlstring: function(L: TLuaHandle; arg: Integer; const def: MarshaledAString; l_: Psize_t): MarshaledAString; cdecl;
  luaL_checknumber: function(L: TLuaHandle; arg: Integer): lua_Number; cdecl;
  luaL_optnumber: function(L: TLuaHandle; arg: Integer; def: lua_Number): lua_Number; cdecl;
  luaL_checkinteger: function(L: TLuaHandle; arg: Integer): lua_Integer; cdecl;
  luaL_optinteger: function(L: TLuaHandle; arg: Integer; def: lua_Integer): lua_Integer; cdecl;

  luaL_checkstack: procedure(L: TLuaHandle; sz: Integer; const msg: MarshaledAString); cdecl;
  luaL_checktype: procedure(L: TLuaHandle; arg: Integer; t: Integer); cdecl;
  luaL_checkany: procedure(L: TLuaHandle; arg: Integer); cdecl;

  luaL_newmetatable: function(L: TLuaHandle; const tname: MarshaledAString): Integer; cdecl;
  luaL_setmetatable: procedure(L: TLuaHandle; const tname: MarshaledAString); cdecl;
  luaL_testudata: procedure(L: TLuaHandle; ud: Integer; const tname: MarshaledAString); cdecl;
  luaL_checkudata: function(L: TLuaHandle; ud: Integer; const tname: MarshaledAString): Pointer; cdecl;

  luaL_where: procedure(L: TLuaHandle; lvl: Integer); cdecl;
  luaL_error: function(L: TLuaHandle; fmt: MarshaledAString; args: array of const): Integer; cdecl;

  luaL_checkoption: function(L: TLuaHandle; arg: Integer; const def: MarshaledAString; const lst: PMarshaledAString): Integer; cdecl;
  luaL_fileresult: function(L: TLuaHandle; stat: Integer; fname: MarshaledAString): Integer; cdecl;
  luaL_execresult: function(L: TLuaHandle; stat: Integer): Integer; cdecl;


  luaL_ref: function(L: TLuaHandle; t: Integer): Integer; cdecl;
  luaL_unref: procedure(L: TLuaHandle; t: Integer; ref: Integer); cdecl;
  luaL_loadfilex: function(L: TLuaHandle; const filename: MarshaledAString; const mode: MarshaledAString): Integer; cdecl;

  luaL_loadbufferx: function(L: TLuaHandle; const buff: MarshaledAString; sz: size_t;
                                   const name: MarshaledAString; const mode: MarshaledAString): Integer; cdecl;
  luaL_loadstring: function(L: TLuaHandle; const s: MarshaledAString): Integer; cdecl;

  luaL_newstate: function(): TLuaHandle; cdecl;
  luaL_len: function(L: TLuaHandle; idx: Integer): lua_Integer; cdecl;

  luaL_gsub: function(L: TLuaHandle; const s: MarshaledAString; const p: MarshaledAString; const r: MarshaledAString): MarshaledAString; cdecl;
  luaL_setfuncs: procedure(L: TLuaHandle; const l_: PluaL_Reg; nup: Integer); cdecl;

  luaL_getsubtable: function(L: TLuaHandle; idx: Integer; const fname: MarshaledAString): Integer; cdecl;

  luaL_traceback: procedure(L: TLuaHandle; L1: TLuaHandle; const msg: MarshaledAString; level: Integer); cdecl;

  luaL_requiref: procedure(L: TLuaHandle; const modname: MarshaledAString; openf: lua_CFunction; glb: Integer); cdecl;
{$ENDIF}



{*
** ======================================================
** Generic Buffer manipulation
** ======================================================
*}
{$IFDEF STATICLIBRARY}
  procedure luaL_buffinit(L: TLuaHandle; B: PluaL_Buffer); cdecl; external LUA_LIBRARY;
  function luaL_prepbuffsize(B: Plual_buffer; sz: size_t): Pointer; cdecl; external LUA_LIBRARY;
  procedure luaL_addlstring(B: Plual_buffer; const s: MarshaledAString; l: size_t); cdecl; external LUA_LIBRARY;
  procedure luaL_addstring(B: Plual_buffer; const s: MarshaledAString); cdecl; external LUA_LIBRARY;
  procedure luaL_addvalue(B: Plual_buffer); cdecl; external LUA_LIBRARY;
  procedure luaL_pushresult(B: Plual_buffer); cdecl; external LUA_LIBRARY;
  procedure luaL_pushresultsize(B: Plual_buffer; sz: size_t); cdecl; external LUA_LIBRARY;
  function luaL_buffinitsize(L: TLuaHandle; B: Plual_buffer; sz: size_t): Pointer; cdecl; external LUA_LIBRARY;
{$ELSE}
  luaL_buffinit: procedure(L: TLuaHandle; B: PluaL_Buffer); cdecl;
  luaL_prepbuffsize: function(B: Plual_buffer; sz: size_t): Pointer; cdecl;
  luaL_addlstring: procedure(B: Plual_buffer; const s: MarshaledAString; l: size_t); cdecl;
  luaL_addstring: procedure(B: Plual_buffer; const s: MarshaledAString); cdecl;
  luaL_addvalue: procedure(B: Plual_buffer); cdecl;
  luaL_pushresult: procedure(B: Plual_buffer); cdecl;
  luaL_pushresultsize: procedure(B: Plual_buffer; sz: size_t); cdecl;
  luaL_buffinitsize: function(L: TLuaHandle; B: Plual_buffer; sz: size_t): Pointer; cdecl;
{$ENDIF}


{* ====================================================== *}


{* compatibility with old module system */
#if defined(LUA_COMPAT_MODULE)

LUALIB_API void (luaL_pushmodule) (L: TLuaHandle; const char *modname,
                                   int sizehint);
LUALIB_API void (luaL_openlib) (L: TLuaHandle; const char *libname,
                                const luaL_Reg *l, int nup);

#define luaL_register(L,n,l)	(luaL_openlib(L,(n),(l),0))

#endif}


{*
** {============================================================
** Compatibility with deprecated conversions
** =============================================================
*/
#if defined(LUA_COMPAT_APIINTCASTS)

#define luaL_checkunsigned(L,a)	((lua_Unsigned)luaL_checkinteger(L,a))
#define luaL_optunsigned(L,a,d)	\
	((lua_Unsigned)luaL_optinteger(L,a,(lua_Integer)(d)))

#define luaL_checkint(L,n)	((int)luaL_checkinteger(L, (n)))
#define luaL_optint(L,n,d)	((int)luaL_optinteger(L, (n), (d)))

#define luaL_checklong(L,n)	((long)luaL_checkinteger(L, (n)))
#define luaL_optlong(L,n,d)	((long)luaL_optinteger(L, (n), (d)))

#endif
}


{*
** ==============================================================
** some useful macros
** ==============================================================
*}
  //#define lua_getextraspace(L)	((void *)((char *)(L) - LUA_EXTRASPACE))
  function lua_tonumber(L: TLuaHandle; idx: Integer): lua_Number; inline;
  function lua_tointeger(L: TLuaHandle; idx: Integer): lua_Integer; inline;
  procedure lua_pop(L: TLuaHandle; n: Integer); inline;
  procedure lua_newtable(L: TLuaHandle); inline;
  procedure lua_register(L: TLuaHandle; const n: MarshaledAString; f: lua_CFunction); inline;
  procedure lua_pushcfunction(L: TLuaHandle; f: lua_CFunction); inline;
  function lua_isfunction(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_istable(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_islightuserdata(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_isnil(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_isboolean(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_isthread(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_isnone(L: TLuaHandle; n: Integer): Boolean; inline;
  function lua_isnoneornil(L: TLuaHandle; n: Integer): Boolean; inline;
  procedure lua_pushliteral(L: TLuaHandle; s: MarshaledAString); inline;
  procedure lua_pushglobaltable(L: TLuaHandle); inline;
  function lua_tostring(L: TLuaHandle; i: Integer): MarshaledAString;
  procedure lua_insert(L: TLuaHandle; idx: Integer); inline;
  procedure lua_remove(L: TLuaHandle; idx: Integer); inline;
  procedure lua_replace(L: TLuaHandle; idx: Integer); inline;

{*
** ===============================================================
** some useful lauxlib macros
** ===============================================================
*}

  procedure luaL_newlibtable(L: TLuaHandle; lr: array of luaL_Reg); overload;
  procedure luaL_newlibtable(L: TLuaHandle; lr: PluaL_Reg); overload;
  procedure luaL_newlib(L: TLuaHandle; lr: array of luaL_Reg); overload;
  procedure luaL_newlib(L: TLuaHandle; lr: PluaL_Reg); overload;
  procedure luaL_argcheck(L: TLuaHandle; cond: Boolean; arg: Integer; extramsg: MarshaledAString);
  function luaL_checkstring(L: TLuaHandle; n: Integer): MarshaledAString;
  function luaL_optstring(L: TLuaHandle; n: Integer; d: MarshaledAString): MarshaledAString;
  function luaL_typename(L: TLuaHandle; i: Integer): MarshaledAString;
  function luaL_dofile(L: TLuaHandle; const fn: MarshaledAString): Integer;
  function luaL_dostring(L: TLuaHandle; const s: MarshaledAString): Integer;
  procedure luaL_getmetatable(L: TLuaHandle; n: MarshaledAString);
  function luaL_loadbuffer(L: TLuaHandle; const s: MarshaledAString; sz: size_t; const n: MarshaledAString): Integer;
{

#define luaL_addchar(B,c) \
  ((void)((B)->n < (B)->size || luaL_prepbuffsize((B), 1)), \
   ((B)->b[(B)->n++] = (c)))

procedure luaL_addsize(B: PluaL_Buffer; s: MarshaledAString);

#define B,s)	((B)->n += (s))}


{*
** ==============================================================
** other macros needed
** ==============================================================
*}
  procedure lua_call(L: TLuaHandle; nargs: Integer; nresults: Integer); inline;
  function lua_pcall(L: TLuaHandle; nargs: Integer; nresults: Integer; errfunc: Integer): Integer; inline;
  function lua_yield(L: TLuaHandle; nresults: Integer): Integer; inline;
  function lua_upvalueindex(i: Integer): Integer; inline;
  procedure luaL_checkversion(L: TLuaHandle); inline;
  function lual_loadfile(L: TLuaHandle; const filename: MarshaledAString): Integer; inline;
  function luaL_prepbuffer(B: Plual_buffer): MarshaledAString; inline;

{*
** ==================================================================
** "Abstraction Layer" for basic report of messages and errors
** ==================================================================
*}

{* print a string *
#if !defined(lua_writestring)
#define lua_writestring(s,l)   fwrite((s), sizeof(char), (l), stdout)
#endif

/* print a newline and flush the output */
#if !defined(lua_writeline)
#define lua_writeline()        (lua_writestring("\n", 1), fflush(stdout))
#endif

/* print an error message */
#if !defined(lua_writestringerror)
#define lua_writestringerror(s,p) \
        (fprintf(stderr, (s), (p)), fflush(stderr))
#endif
}

{*
** ==============================================================
** compatibility macros for unsigned conversions
** ===============================================================
*/
#if defined(LUA_COMPAT_APIINTCASTS)

#define lua_pushunsigned(L,n)	lua_pushinteger(L, (lua_Integer)(n))
#define lua_tounsignedx(L,i,is)	((lua_Unsigned)lua_tointegerx(L,i,is))
#define lua_tounsigned(L,i)	lua_tounsignedx(L,(i),NULL)

#endif
* ============================================================== *}

{* ====================================================================== *}

implementation

function lua_tonumber(L: TLuaHandle; idx: Integer): lua_Number; inline;
begin
  Result := lua_tonumberx(L, idx, NIL);
end;

function lua_tointeger(L: TLuaHandle; idx: Integer): lua_Integer; inline;
begin
  Result := lua_tointegerx(L, idx, NIL);
end;

procedure lua_pop(L: TLuaHandle; n: Integer); inline;
begin
  lua_settop(L, -(n)-1);
end;

procedure lua_newtable(L: TLuaHandle); inline;
begin
  lua_createtable(L, 0, 0);
end;

procedure lua_register(L: TLuaHandle; const n: MarshaledAString; f: lua_CFunction);
begin
  lua_pushcfunction(L, f);
  lua_setglobal(L, n);
end;

procedure lua_pushcfunction(L: TLuaHandle; f: lua_CFunction);
begin
  lua_pushcclosure(L, f, 0);
end;

function lua_isfunction(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TFUNCTION);
end;

function lua_istable(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TTABLE);
end;

function lua_islightuserdata(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TLIGHTUSERDATA);
end;

function lua_isnil(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TNIL);
end;

function lua_isboolean(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TBOOLEAN);
end;

function lua_isthread(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TTHREAD);
end;

function lua_isnone(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) = LUA_TNONE);
end;

function lua_isnoneornil(L: TLuaHandle; n: Integer): Boolean;
begin
   Result := (lua_type(L, n) <= 0);
end;

procedure lua_pushliteral(L: TLuaHandle; s: MarshaledAString);
begin
   lua_pushlstring(L, s, Length(s));
end;

procedure lua_pushglobaltable(L: TLuaHandle);
begin
   lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
end;

function lua_tostring(L: TLuaHandle; i: Integer): MarshaledAString;
begin
   Result := lua_tolstring(L, i, NIL);
end;

procedure lua_insert(L: TLuaHandle; idx: Integer);
begin
  lua_rotate(L, idx, 1);
end;

procedure lua_remove(L: TLuaHandle; idx: Integer);
begin
  lua_rotate(L, idx, -1);
  lua_pop(L, 1);
end;

procedure lua_replace(L: TLuaHandle; idx: Integer);
begin
  lua_copy(L, -1, idx);
  lua_pop(L, 1);
end;

procedure lua_call(L: TLuaHandle; nargs: Integer; nresults: Integer); inline;
begin
  lua_callk(L, nargs, nresults, 0, NIL);
end;

function lua_pcall(L: TLuaHandle; nargs: Integer; nresults: Integer; errfunc: Integer): Integer; inline;
begin
  Result := lua_pcallk(L, nargs, nresults, errfunc, 0, NIL);
end;

function lua_yield(L: TLuaHandle; nresults: Integer): Integer; inline;
begin
  Result := lua_yieldk(L, nresults, 0, NIL);
end;

function lua_upvalueindex(i: Integer): Integer; inline;
begin
  Result := LUA_REGISTRYINDEX - i;
end;

{*
** ===============================================================
** some useful lauxlib macros
** ===============================================================
*}

procedure luaL_newlibtable(L: TLuaHandle; lr: array of luaL_Reg); overload;
begin
  lua_createtable(L, 0, High(lr));
end;

procedure luaL_newlibtable(L: TLuaHandle; lr: PluaL_Reg); overload;
var
  n: Integer;
begin
  n := 0;
  while lr^.name <> nil do
  begin
    inc(n);
    inc(lr);
  end;
  lua_createtable(L, 0, n);
end;

procedure luaL_newlib(L: TLuaHandle; lr: array of luaL_Reg); overload;
begin
  luaL_newlibtable(L, lr);
  luaL_setfuncs(L, @lr, 0);
end;

procedure luaL_newlib(L: TLuaHandle; lr: PluaL_Reg); overload;
begin
  luaL_newlibtable(L, lr);
  luaL_setfuncs(L, lr, 0);
end;

procedure luaL_argcheck(L: TLuaHandle; cond: Boolean; arg: Integer; extramsg: MarshaledAString);
begin
  if not cond then
    luaL_argerror(L, arg, extramsg);
end;


function luaL_checkstring(L: TLuaHandle; n: Integer): MarshaledAString;
begin
   Result := luaL_checklstring(L, n, nil);
end;

function luaL_optstring(L: TLuaHandle; n: Integer; d: MarshaledAString): MarshaledAString;
begin
   Result := luaL_optlstring(L, n, d, nil);
end;

function luaL_typename(L: TLuaHandle; i: Integer): MarshaledAString;
begin
   Result := lua_typename(L, lua_type(L, i));
end;

function luaL_dofile(L: TLuaHandle; const fn: MarshaledAString): Integer;
begin
   Result := luaL_loadfile(L, fn);
   if Result = 0 then
      Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;


function luaL_dostring(L: TLuaHandle; const s: MarshaledAString): Integer;
begin
   Result := luaL_loadstring(L, s);
   if Result = 0 then
      Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;

procedure luaL_getmetatable(L: TLuaHandle; n: MarshaledAString);
begin
   lua_getfield(L, LUA_REGISTRYINDEX, n);
end;

function luaL_loadbuffer(L: TLuaHandle; const s: MarshaledAString; sz: size_t; const n: MarshaledAString): Integer;
begin
  Result := luaL_loadbufferx(L, s, sz, n, NIL);
end;


procedure luaL_checkversion(L: TLuaHandle); inline;
begin
  luaL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES);
end;

function lual_loadfile(L: TLuaHandle; const filename: MarshaledAString): Integer; inline;
begin
  Result := luaL_loadfilex(L, filename, NIL);
end;

function luaL_prepbuffer(B: Plual_buffer): MarshaledAString; inline;
begin
  Result := luaL_prepbuffsize(B, LUAL_BUFFERSIZE);
end;



{******************************************************************************
* Copyright (C) 1994-2015 Lua.org, PUC-Rio.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
******************************************************************************}
end.
