/* Copyright (C) 1994 DJ Delorie, see COPYING.DJ for details */

#include <ctype.h>
#include <string.h>


/*
 * @implemented
 */
int _wcsicmp(const wchar_t* cs,const wchar_t * ct)  
{
	while (towlower(*cs) == towlower(*ct))
	{
		if (*cs == 0)
			return 0;
		cs++;
		ct++;
	}
	return towlower(*cs) - towlower(*ct);
}
