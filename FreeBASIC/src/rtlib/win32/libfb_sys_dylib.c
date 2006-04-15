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
 * sys_dylib.c -- Dynamic library loading and symbols retrieving
 *
 * chng: feb/2005 written [lillo]
 *
 */

#include <stdio.h>
#include "fb.h"

/*:::::*/
FBCALL void *fb_DylibLoad( FBSTRING *library )
{
	void *res = NULL;

	if( (library) && (library->data) )
		res = LoadLibrary( library->data );

	/* del if temp */
	fb_hStrDelTemp( library );

	return res;
}

/*:::::*/
FBCALL void *fb_DylibSymbol( void *library, FBSTRING *symbol )
{
	void *proc = NULL;
	char procname[1024];
	int i;

	if( library == NULL )
		library = GetModuleHandle( NULL );

	if( (symbol) && (symbol->data) )
	{
		proc = (void*) GetProcAddress( (HINSTANCE) library, symbol->data );
		if( (!proc) && (!strchr( symbol->data, '@' )) ) {
			procname[1023] = '\0';
			for( i = 0; i < 256; i += 4 ) {
				snprintf( procname, 1023, "%s@%d", symbol->data, i );
				proc = (void*) GetProcAddress( (HINSTANCE) library, procname );
				if( proc )
					break;
			}
		}
	}

	/* del if temp */
	fb_hStrDelTemp( symbol );

	return proc;
}


/*:::::*/
FBCALL void fb_DylibFree( void *library )
{
	FreeLibrary((HINSTANCE) library);
}
