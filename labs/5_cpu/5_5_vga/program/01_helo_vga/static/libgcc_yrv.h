/* Integer arithmetic support for Lattice Mico32.
   Contributed by Jon Beniston <jon@beniston.com> 
   
   Copyright (C) 2009-2023 Free Software Foundation, Inc.

   This file is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any
   later version.
   
   This file is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.
   
   Under Section 7 of GPL version 3, you are granted additional
   permissions described in the GCC Runtime Library Exception, version
   3.1, as published by the Free Software Foundation.
   
   You should have received a copy of the GNU General Public License and
   a copy of the GCC Runtime Library Exception along with this program;
   see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
   <http://www.gnu.org/licenses/>. */

#ifndef LIBGCC_YRV_H
#define LIBGCC_YRV_H 

/* Types.  */

int __mulsi3 (int a, int b);
unsigned int __udivmodsi4 (unsigned int num, unsigned int den, int modwanted);
int __divsi3 (int a, int b);
int __modsi3 (int a, int b);
unsigned int __udivsi3 (unsigned int a, unsigned int b);
unsigned int __umodsi3 (unsigned int a, unsigned int b);

#endif 
