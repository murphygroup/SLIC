/*
 * Copyright (C) 2006 Murphy Lab,Carnegie Mellon University
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 * 
 * For additional information visit http://murphylab.web.cmu.edu or
 * send email to murphy@cmu.edu
 */

#include "mex.h"

/*Get Process ID for current matlab*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double* p_pid;
  int outputsize[2];
  outputsize[0] = 1;
  outputsize[1] = 1;
  plhs[0] = mxCreateNumericArray(1,outputsize,mxDOUBLE_CLASS,mxREAL);
  if (!plhs[0]) 
    mexErrMsgTxt("ml_getpid: error allocating return variable.");
  p_pid = (double *)mxGetData(plhs[0]);
  p_pid[0] = getpid();
}