function img2=ml_setimglnpixel2(img,s,a,len)
%ML_SETIMGLNPIXEL2 Obsolete. See ML_SETIMGLNPIXEL2.
%   IMG2 = ML_SETIMGLNPIXEL2(IMG,S,A,LEN) draw a line from the starting
%   [point] S with an angle A and length LEN.
%   
%   See also ML_SETIMGLNPIXEL

%   17-Sep-2005 Initial write T. Zhao
%   Copyright (c) Murphy Lab, Carnegie Mellon University

% Copyright (C) 2006  Murphy Lab
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

pts=ml_getlinept2(s,a,len);
img2=ml_setimgptspixel(img,pts);
