/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2006 Andre V. T. Vicentini (av1ctor@yahoo.com.br) and
 *  the FreeBASIC development team.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  As a special exception, the copyright holders of this library give
 *  you permission to link this library with independent modules to
 *  produce an executable, regardless of the license terms of these
 *  independent modules, and to copy and distribute the resulting
 *  executable under terms of your choice, provided that you also meet,
 *  for each linked independent module, the terms and conditions of the
 *  license of that module. An independent module is a module which is
 *  not derived from or based on this library. If you modify this library,
 *  you may extend this exception to your version of the library, but
 *  you are not obligated to do so. If you do not wish to do so, delete
 *  this exception statement from your version.
 */

/*
 * exit.c -- end and system routines
 *
 * chng: oct/2004 written [v1ctor]
 *
 */

#include <stdlib.h>
#include "fb.h"

char *fb_error_message = NULL;


/*:::::*/
FBCALL void fb_End ( int errlevel )
{
	/* do nothing, real job is done at fb_RtExit(), invoked by atexit() */

	exit( errlevel );
}


/*:::::*/
void fb_RtExit ( void )
{
#ifdef MULTITHREADED
    int i;
#endif

	/* os-dep termination */
	fb_hEnd( 0 );

#ifdef MULTITHREADED
	/* free thread local storage plus the keys */
	for( i = 0; i < FB_TLSKEYS; i++ )
	{
     	fb_TlsDelCtx( i );

		/* del key/index */
		FB_TLSFREE( fb_tls_ctxtb[i] );
	}
#endif

	/* if an error has to be displayed, do it now */
	if( fb_error_message )
		fprintf( stderr, fb_error_message );
}


