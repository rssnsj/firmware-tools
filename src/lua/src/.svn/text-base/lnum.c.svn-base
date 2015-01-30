/*
** $Id: lnum.c,v ... $
** Internal number model
** See Copyright Notice in lua.h
*/

#include <stdlib.h>
#include <math.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

#define lnum_c
#define LUA_CORE

#include "lua.h"
#include "llex.h"
#include "lnum.h"

/*
** lua_real2str converts a (non-complex) number to a string.
** lua_str2real converts a string to a (non-complex) number.
*/
#define lua_real2str(s,n)  sprintf((s), LUA_NUMBER_FMT, (n))

/*
* Note: Only 'strtod()' is part of ANSI C; others are C99 and
* may need '--std=c99' compiler setting (at least on Ubuntu 7.10).
* 
* Visual C++ 2008 Express does not have 'strtof()', nor 'strtold()'.
* References to '_strtold()' exist but don't compile. It seems best
* to leave Windows users with DOUBLE only (or compile with MinGW).
*
* In practise, using '(long double)strtod' is a risky thing, since
* it will cause accuracy loss in reading in numbers, and such losses
* will pile up in later processing. Get a real 'strtold()' or don't
* use that mode at all.
*/
#ifdef LNUM_DOUBLE
# define lua_str2real	strtod
#elif defined(LNUM_FLOAT)
# define lua_str2real	strtof
#elif defined(LNUM_LDOUBLE)
# define lua_str2real	strtold
#endif

#define lua_integer2str(s,v) sprintf((s), LUA_INTEGER_FMT, (v))

/* 's' is expected to be LUAI_MAXNUMBER2STR long (enough for any number)
*/
void luaO_num2buf( char *s, const TValue *o )
{
  lua_Number n;
  lua_assert( ttisnumber(o) );

  /* Reason to handle integers differently is not only speed, but accuracy as
   * well. We want to make any integer tostring() without roundings, at all.
   */
  if (ttisint(o)) {
    lua_integer2str( s, ivalue(o) );
    return;
  }
  n= nvalue_fast(o);
  lua_real2str(s, n);

#ifdef LNUM_COMPLEX
  lua_Number n2= nvalue_img_fast(o);
  if (n2!=0) {   /* Postfix with +-Ni */
      int re0= (n == 0);
      char *s2= re0 ? s : strchr(s,'\0'); 
      if ((!re0) && (n2>0)) *s2++= '+';
      lua_real2str( s2, n2 );
      strcat(s2,"i");
  }
#endif
}

/*
* If a LUA_TNUMBER has integer value, give it.
*/
int /*bool*/ tt_integer_valued( const TValue *o, lua_Integer *ref ) {
  lua_Number d;
  lua_Integer i;

  lua_assert( ttype(o)==LUA_TNUMBER );
  lua_assert( ref );
#ifdef LNUM_COMPLEX
  if (nvalue_img_fast(o)!=0) return 0;
#endif
  d= nvalue_fast(o);
  lua_number2integer(i, d);
  if (cast_num(i) == d) {
    *ref= i; return 1;
  }
  return 0;
}

/* 
 * Lua 5.1.3 (using 'strtod()') allows 0x+hex but not 0+octal. This is good,
 * and we should NOT use 'autobase' 0 with 'strtoul[l]()' for this reason.
 *
 * Lua 5.1.3 allows '0x...' numbers to overflow and lose precision; this is not
 * good. On Visual C++ 2008, 'strtod()' does not even take them in. Better to
 * require hex values to fit 'lua_Integer' or give an error that they don't?
 *
 * Full hex range (0 .. 0xff..ff) is stored as integers, not to lose any bits.
 * Numerical value of 0xff..ff will be -1, if used in calculations.
 * 
 * Returns: TK_INT for a valid integer, '*endptr_ref' updated
 *          TK_NUMBER for seemingly numeric, to be parsed as floating point
 *          0 for bad characters, not a number (or '0x' out of range)
 */
static int luaO_str2i (const char *s, lua_Integer *res, char **endptr_ref) {
  char *endptr;
  /* 'v' gets ULONG_MAX on possible overflow (which is > LUA_INTEGER_MAX);
   * we don't have to check 'errno' here.
   */
  unsigned LUA_INTEGER v= lua_str2ul(s, &endptr, 10);
  if (endptr == s) return 0;  /* nothing numeric */
  if (v==0 && *endptr=='x') {
    errno= 0;   /* needs to be set, 'strtoul[l]' does not clear it */
    v= lua_str2ul(endptr+1, &endptr, 16);  /* retry as hex, unsigned range */
    if (errno==ERANGE) {   /* clamped to 0xff..ff */
#if (defined(LNUM_INT32) && !defined(LNUM_FLOAT)) || defined(LNUM_LDOUBLE)
      return TK_NUMBER; /* Allow to be read as floating point (has more integer range) */
#else
      return 0;  /* Reject the number */
#endif
    }
  } else if ((v > LUA_INTEGER_MAX) || (*endptr && (!isspace(*endptr)))) {
    return TK_NUMBER;	/* not in signed range, or has '.', 'e' etc. trailing */
  }
  *res= (lua_Integer)v;
  *endptr_ref= endptr;
  return TK_INT;
}

/* 0 / TK_NUMBER / TK_INT (/ TK_NUMBER2) */
int luaO_str2d (const char *s, lua_Number *res_n, lua_Integer *res_i) {
  char *endptr;
  int ret= TK_NUMBER;
  /* Check integers first, if caller is allowing. 
   * If 'res2'==NULL, they're only looking for floating point. 
   */
  if (res_i) {
    ret= luaO_str2i(s,res_i,&endptr);
    if (ret==0) return 0;
  }
  if (ret==TK_NUMBER) {
    lua_assert(res_n);
    /* Note: Visual C++ 2008 Express 'strtod()' does not read in "0x..."
     *       numbers; it will read '0' and spit 'x' as endptr.
     *       This means hex constants not fitting in 'lua_Integer' won't 
     *       be read in at all. What to do?
     */
    *res_n = lua_str2real(s, &endptr);
    if (endptr == s) return 0;  /* conversion failed */
    /* Visual C++ 2008 'strtod()' does not allow "0x..." input. */
#if defined(_MSC_VER) && !defined(LNUM_FLOAT) && !defined(LNUM_INT64)
    if (*res_n==0 && *endptr=='x') {
      /* Hex constant too big for 'lua_Integer' but that could fit in 'lua_Number'
       * integer bits 
       */
      unsigned __int64 v= _strtoui64( s, &endptr, 16 );
      /* We just let > 64 bit values be clamped to _UI64_MAX (MSDN does not say 'errno'==ERANGE would be set) */
      *res_n= cast_num(v);
      if (*res_n != v) return 0;    /* Would have lost accuracy */
    }
#endif
#ifdef LNUM_COMPLEX
    if (*endptr == 'i') { endptr++; ret= TK_NUMBER2; }
#endif
  }
  if (*endptr) {
    while (isspace(cast(unsigned char, *endptr))) endptr++;
    if (*endptr) return 0;  /* invalid trail */
  }
  return ret;
}


/* Functions for finding out, when integer operations remain in range
 * (and doing them).
 */
int try_addint( lua_Integer *r, lua_Integer ib, lua_Integer ic ) {
  lua_Integer v= ib+ic; /* may overflow */
  if (ib>0 && ic>0)      { if (v < 0) return 0; /*overflow, use floats*/ }
  else if (ib<0 && ic<0) { if (v >= 0) return 0; }
  *r= v;
  return 1;
}

int try_subint( lua_Integer *r, lua_Integer ib, lua_Integer ic ) {
  lua_Integer v= ib-ic; /* may overflow */
  if (ib>=0 && ic<0)     { if (v < 0) return 0; /*overflow, use floats*/ }
  else if (ib<0 && ic>0) { if (v >= 0) return 0; }
  *r= v;
  return 1;
}

int try_mulint( lua_Integer *r, lua_Integer ib, lua_Integer ic ) {
  if (ib!=LUA_INTEGER_MIN && ic!=LUA_INTEGER_MIN) {
    lua_Integer b= luai_abs(ib), c= luai_abs(ic);
    if ( (ib==0) || (LUA_INTEGER_MAX/b >= c) ) {
      *r= ib*ic;  /* no overflow */
      return 1;
    }
  } else if (ib==0 || ic==0) {
    *r= 0; return 1;
  }

  /* Result can be LUA_INTEGER_MIN; if it is, calculating it using floating 
   * point will not cause accuracy loss.
   */
  if ( luai_nummul( cast_num(ib), cast_num(ic) ) == LUA_INTEGER_MIN ) {
    *r= LUA_INTEGER_MIN;
    return 1;
  }
  return 0;
}

int try_divint( lua_Integer *r, lua_Integer ib, lua_Integer ic ) {
  /* N/0: leave to float side, to give an error
  */
  if (ic==0) return 0;

  /* N/LUA_INTEGER_MIN: always non-integer results, or 0 or +1
  */
  if (ic==LUA_INTEGER_MIN) {
    if (ib==LUA_INTEGER_MIN) { *r=1; return 1; }
    if (ib==0) { *r=0; return 1; }

  /* LUA_INTEGER_MIN (-2^31|63)/N: calculate using float side (either the division 
   *    causes non-integer results, or there is no accuracy loss in int->fp->int
   *    conversions (N=2,4,8,..,256 and N=2^30,2^29,..2^23).
   */
  } else if (ib==LUA_INTEGER_MIN) {
    lua_Number d= luai_numdiv( cast_num(LUA_INTEGER_MIN), cast_num(ic) );
    lua_Integer i; lua_number2integer(i,d);
    if (cast_num(i)==d) { *r= i; return 1; }
  
  } else {
    /* Note: We _can_ use ANSI C mod here, even on negative values, since
     *       we only test for == 0 (the sign would be implementation dependent).
     */
     if (ib%ic == 0) { *r= ib/ic; return 1; }
  }

  return 0;
}

int try_modint( lua_Integer *r, lua_Integer ib, lua_Integer ic ) {
  if (ic!=0) {
    /* ANSI C can be trusted when b%c==0, or when values are non-negative. 
     * b - (floor(b/c) * c)
     *   -->
     * + +: b - (b/c) * c (b % c can be used)
     * - -: b - (b/c) * c (b % c could work, but not defined by ANSI C)
     * 0 -: b - (b/c) * c (=0, b % c could work, but not defined by ANSI C)
     * - +: b - (b/c-1) * c (when b!=-c)
     * + -: b - (b/c-1) * c (when b!=-c)
     *
     * o MIN%MIN ends up 0, via overflow in calcs but that does not matter.
     * o MIN%MAX ends up MAX-1 (and other such numbers), also after overflow,
     *   but that does not matter, results do.
     */
    lua_Integer v= ib % ic;
    if ( v!=0 && (ib<0 || ic<0) ) {
      v= ib - ((ib/ic) - ((ib<=0 && ic<0) ? 0:1)) * ic;
    }      
    /* Result should always have same sign as 2nd argument. (PIL2) */
    lua_assert( (v<0) ? (ic<0) : (v>0) ? (ic>0) : 1 );
    *r= v;
    return 1;
  }
  return 0;  /* let float side return NaN */
}

int try_powint( lua_Integer *r, lua_Integer ib, lua_Integer ic ) {

    /* In FLOAT/INT32 or FLOAT|DOUBLE/INT64 modes, calculating integer powers 
     * via FP realm may lose accuracy (i.e. 7^11 = 1977326743, which fits int32
     * but not 23-bit float mantissa). 
     *
     * The current solution is dumb, but it works and uses little code. Use of
     * integer powers is not anticipated to be very frequent (apart from 2^x,
     * which is separately optimized).
     */
  if (ib==0) *r=0;
  else if (ic<0) return 0;  /* FP realm */
  else if (ib==2 && ic < (int)sizeof(lua_Integer)*8-1) *r= ((lua_Integer)1)<<ic;   /* 1,2,4,...2^30 | 2^62 optimization */
  else if (ic==0) *r=1;
  else if (luai_abs(ib)==1) *r= (ic%2) ? ib:1;
  else {
    lua_Integer x= ib;
    while( --ic ) {
      if (!try_mulint( &x, x, ib ))
        return 0; /* FP realm */
    }
    *r= x;
  }
  return 1;
}

int try_unmint( lua_Integer *r, lua_Integer ib ) {
  /* Negating LUA_INTEGER_MIN leaves the range. */
  if ( ib != LUA_INTEGER_MIN )  
    { *r= -ib; return 1; }
  return 0;
}

