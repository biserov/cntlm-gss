/*
 * CNTLM is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later
 * version.
 *
 * CNTLM is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
 * St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * Copyright (c) 2007 David Kubicek
 *
 */
#ifndef _PAGES_H
#define _PAGES_H

#include "utils.h"
#include <string.h>
#include <stdio.h>

extern char *gen_407_page(const char *http);
extern char *gen_401_page(const char *http, const char *host, int port);
extern char *gen_denied_page(const char *ip);

extern char *gen_502_page(const char *http, const char *msg);
extern void send_502_page(int cd, const char *msg, const char *format, ...);

#endif /* _PAGES_H */
