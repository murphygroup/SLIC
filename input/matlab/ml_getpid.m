function pid = ml_getpid()
% ml_getpid Get Process ID for current matlab 

% This method is an adaptation of ml_getpid.c.

% Input: none

% Output: pid, the Process ID for current matlab


% Author: Yue Yu (yuey1@andrew.cmu.edu)

% Created: June 18, 2012

%

% Copyright (C) 2006-2012 Lane Center for Computational Biology

% Carnegie Mellon University

%

% This program is free software; you can redistribute it and/or modify

% it under the terms of the GNU General Public License as published

% by the Free Software Foundation; either version 2 of the License,

% or (at your option) any later version.

%

% This program is distributed in the hope that it will be useful, but

% WITHOUT ANY WARRANTY; without even the implied warranty of

% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU

% General Public License for more details.

%

% You should have received a copy of the GNU General Public License

% along with this program; if not, write to the Free Software

% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA

% 02110-1301, USA.

%

% For additional information visit http://murphylab.web.cmu.edu or

% send email to murphy@cmu.edu
pid = feature('GetPid');
