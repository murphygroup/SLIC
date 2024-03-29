function [fname, feat, SLFname] = ml_3dfeat(protimg, dnaimg, featidx, ...
    tratio, tgray, scale, threshmeth)
%ML_3DFEAT calculate features for 3d protein image
%   [FNAME, FEAT, SLFNAME] = ML_3DFEAT(PORTIMG, DNAIMG, FEATIDX, ...
%					      TRATIO, TGRAY,THRESHMETH)
%   is the general feature calculation code for a 3D static single cell image.
%   Multi-cell images should be background substracted and segmented prior to
%   this step.  Background subtraction could be performed using ml_3dbgsub
%   function included in this package.  It works for uint8 3D images.
%   protimg: a 3D matrix, should be uint8 format
%   dnaimg: a 3D parallel DNA image, same format as protimg.  If not provided,
%         following features will yield a nan value:9-14, 21-28
%   featidx: an array of indices for desired features.  If omitted, all features
%          will be returned
%   tratio: a vector specifying 3D downsampling ratio for texture feature calcul-
%         ation.  A scalar or a two-element vector.  All values should not be
%         less than 1.  If it is a scalar, all three dimensions will be down-
%         sampled at this ratio.  If a two-element vector is provided, the
%         first element stands for the ratio on the XY plane and the second
%         element stands for the ratio on Z.
%   tgray: Number of gray levels used in texture feature calculation.  The
%        maximum number allowed is 256 (uint8).  If omitted, either 256 or the
%        raw gray levels, whichever is smaller will be used.
%   scale: micrometers per pixel in the sample plane
%   threshmeth: thresholding method
%       'nih' - nih thresholding (default)
%       'rc' - rc thresholding
%   fname: a cell array of descriptions for features calculated.
%   feat: the returned feature vector for this image.
%   SLFname: a cell array of SLF index for features calculated.
% Following are the descriptions for all 56 features:
%
% 1) No. of objects in the image
% 2) Euler number of the image
% 3) Average object volume (average number of above threshold voxels per object)
% 4) Std.Dev of object volumes
% 5) Ratio of Max(object volumes) to Min(object volumes)
% 6) Average Obj to protein COF distance
% 7) Std.Dev of Obj to protein COF distances
% 8) Ratio of Max to Min obj distance from prot COF
% 9) Average Obj to DNA COF distance
%10) Std.Dev of Obj to DNA COF distances
%11) Ratio of Max to Min obj distance from DNA COF
%12) Distance between Prot COF and DNA COF
%13) Ratio of protein volume to DNA volume
%14) Fraction of protein fluorescence overlapping with DNA fluorescence
%
%15-28) horizontal-vertical directional features based on 6-12 above
%
%29) The fraction of above threshold pixels that are along an edge
%30) The fraction of fluorescence in above threshold pixels that are along an edge
%31/44) Average/range of angular second moment
%32/45) Average/range of contrast
%33/46) Average/range of correlation
%34/47) Average/range of sum of squares of variance
%35/48) Average/range of inverse difference moment
%36/49) Average/range of sum average
%37/50) Average/range of sum variance
%38/51) Average/range of sum entropy
%39/52) Average/range of entropy
%40/53) Average/range of difference variance
%41/54) Average/range of difference entropy
%42/55) Average/range of info measure of correlation 1
%43/56) Average/range of info measure of correlation 2
%57-60 texture features from joint Protein:DNA cooccurrence
%61-86) Same as 31-56 but after two-fold downsampling (beyond whatever
%specified by tratio)
%87-112) Same as 31-56 but after four-fold downsampling (beyond whatever
%specified by tratio)
%113-114) Intensity weighted distances between protein and DNA images

% Copyright (C) 2006,2010,2011  Murphy Lab
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

% revised December 17, 2010 R.F. Murphy to add overlap cooccurence features
% revised December 19, 2010 R.F. Murphy to add additional texture features
%       after downsampled by 2 and 4 fold
% revised August 28, 2011 R.F. Murphy to add distance transform features

if ~exist('threshmeth','var')
    threshmeth='nih';
end

if ~exist('scale','var') || isempty(scale)
    scale=[1 1 1];
end

if scale(3) == 0
    scale(3)=scale(2);
end

fnames = {'No. of objects in the image',...
    'Euler number of the image',...
    'Average object volume (average number of above threshold voxels per object)', ...
    'Std.Dev of object volumes',...
    'Ratio of Max(object volumes) to Min(object volumes)',...
    'Average Obj to protein COF distance',...
    'Std.Dev of Obj to protein COF distances',...
    'Ratio of Max to Min obj distance from prot COF',...
    'Average Obj to DNA COF distance',...
    'Std.Dev of Obj to DNA COF distances',...
    'Ratio of Max to Min obj distance from DNA COF',...
    'Distance between Prot COF and DNA COF',...
    'Ratio of protein volume to DNA volume',...
    'Fraction of protein fluorescence overlapping with DNA fluorescence',...
    'Horizontal projection of average Obj to protein COF distance',...
    'Horizontal projection of Std.Dev of Obj to protein COF distances',...
    'Horizontal projection of ratio of Max to Min obj distance from prot COF',...
    'Vertical projection of average Obj to protein COF distance',...
    'Vertical projection of Std.Dev of Obj to protein COF distances',...
    'Vertical projection of ratio of Max to Min obj distance from prot COF',...
    'Horizontal projection of average Obj to DNA COF distance',...
    'Horizontal projection of Std.Dev of Obj to DNA COF distances',...
    'Horizontal projection of ratio of Max to Min obj distance from DNA COF',...
    'Vertical projection of average Obj to DNA COF distance',...
    'Vertical projection of Std.Dev of Obj to DNA COF distances',...
    'Vertical projection of ratio of Max to Min obj distance from DNA COF',...
    'Horizontal projection of distance between Prot COF and DNA COF',...
    'Vertical projection of distance between Prot COF and DNA COF',...
    'The fraction of above threshold pixels that are along an edge',...
    'The fraction of fluorescence in above threshold pixels that are along an edge',...
    'Average of angular second moment',...
    'Average of contrast',...
    'Average of correlation',...
    'Average of sum of squares of variance',...
    'Average of inverse difference moment',...
    'Average of sum average',...
    'Average of sum variance',...
    'Average of sum entropy',...
    'Average of entropy',...
    'Average of difference variance',...
    'Average of difference entropy',...
    'Average of info measure of correlation 1',...
    'Average of info measure of correlation 2',...
    'Range of angular second moment',...
    'Range of contrast',...
    'Range of correlation',...
    'Range of sum of squares of variance',...
    'Range of inverse difference moment',...
    'Range of sum average',...
    'Range of sum variance',...
    'Range of sum entropy',...
    'Range of entropy',...
    'Range of difference variance',...
    'Range of difference entropy',...
    'Range of info measure of correlation 1',...
    'Range of info measure of correlation 2',...
    'Protein:DNA Contrast',...
    'Protein:DNA Correlation',...
    'Protein:DNA Energy',...
    'Protein:DNA Homogeneity'};
for i=61:86
    fnames{i}=['dx2:' fnames{i-30}];
end
for i=87:112
    fnames{i}=['dx4:' fnames{i-56}];
end
fnames{113}='Protein weighted distance to DNA';
fnames{114}='DNA weighted distance to protein';
SLFnames = {'SLF9.1',...
    'SLF9.2',...
    'SLF9.3',...
    'SLF9.4',...
    'SLF9.5',...
    'SLF9.6',...
    'SLF9.7',...
    'SLF9.8',...
    'SLF9.9',...
    'SLF9.10',...
    'SLF9.11',...
    'SLF9.12',...
    'SLF9.13',...
    'SLF9.14',...
    'SLF9.15', ...% (SLF11.9)',...
    'SLF9.16', ...%  (SLF11.10)',...
    'SLF9.17', ...%  (SLF11.11)',...
    'SLF9.18', ...%  (SLF11.12)',...
    'SLF9.19', ...%  (SLF11.13)',...
    'SLF9.20', ...%  (SLF11.14)',...
    'SLF9.21',...
    'SLF9.22',...
    'SLF9.23',...
    'SLF9.24',...
    'SLF9.25',...
    'SLF9.26',...
    'SLF9.27',...
    'SLF9.28'};
for i=29:56
    SLFnames{i}=['SLF11.' int2str(i-14)];
end
for i=57:112
    SLFnames{i}=['SLF37.' int2str(i)];
end
SLFnames{113}=['SLF38.113'];
SLFnames{114}=['SLF38.114'];

if (~exist('featidx', 'var') || isempty(featidx))
    featidx = 1: 56;
end

fname = fnames(featidx);
SLFname = SLFnames(featidx);

% Check whether the input is compatible
imgsize = size(protimg);
if (length(imgsize) ~= 3)
    error('ml_3dfeat only calulcate feature for a 3D image.  Please check input.');
end

if (exist('dnaimg', 'var'))
    if (isempty(dnaimg))
        clear dnaimg
    else
        if any(imgsize~=size(dnaimg))
            error('dnaimg should be of same size of protimg.  Please check input.');
        end
    end
end

if (exist('tratio', 'var') && ~isempty(tratio))
    if ((length(tratio) > 2) || length(tratio) < 1)
        error('tratio must be a scalar of a two element vector.');
    end
    if (sum(tratio < 1))
        error('Value(s) in tratio should not be less than 1.');
    end
    if (length(tratio) == 1)
        tratio = [tratio tratio];
    end
end

if (exist('tgray', 'var') && ~isempty(tgray) && (tgray > 256 || tgray < 2))
    error('tgray must be an integer between 2 and 256.');
end

% Preprocessing

%protimg = double(protimg);
%protimg = uint8(protimg * 255 / max(protimg(:)));
%protimg = ml_3dbgsub(protimg);
switch threshmeth
    case 'nih'
        protthresh = 255*ml_threshold(protimg);
    case 'rc'
        protthresh = ml_rcthreshold( protimg);
    otherwise
        error('Unknown thresholding method');
end

protbin = ml_binarize( protimg, uint8(floor(protthresh)));
if (exist('dnaimg', 'var'))
    dnaimg = double(dnaimg);
    dnaimg = uint8(floor(dnaimg * 255 / max(dnaimg(:))));
    dnaimg = ml_3dbgsub(dnaimg);
    dnaCOF = ml_findCOF( ml_sparse( dnaimg));
    dnathresh = 255*ml_threshold( dnaimg);
    dnabin = ml_binarize( dnaimg, uint8(floor(dnathresh)));
else
    dnaCOF = [];
    dnabin = [];
end
% Feature calculation
if (min(featidx) <= 28)
    %Object finding
    %change min_obj_size to 1, by juchangh, 10/01/05
    protobj = ml_3dfindobj( protbin, 1, 1);
    
    feat = ml_obj2feat( protobj, dnaCOF, ...
        protimg, ...
        protbin, dnabin,scale);
else
    feat(1:28) = nan;
end

if (max(featidx) > 28)
    protimg4texture = ml_mask(protimg, protbin);
    if (max(featidx)>56) dnaimg4texture = ml_mask(dnaimg,dnabin); end
    if (sum(find(featidx == 29)) + sum(find(featidx == 30)))
        [feat(29), feat(30)] = ml_3dedgefeatures(protimg4texture, protbin);
    else
        feat(29:30) = nan;
    end
    
    needDNA4texture = (find(featidx==57));
    if (max(featidx) > 30)
        err = 0;
        if (exist('tratio', 'var') && ~isempty(tratio))
            if (~isempty(find(tratio - round(tratio), 1)))
                protimg4texture = ml_3dimresize(protimg4texture, 1/tratio(1), 1/tratio(2));
                if (needDNA4texture) dnaimg4texture = ml_3dimresize(dnaimg4texture, 1/tratio(1), 1/tratio(2)); end
            else
                protimg4texture = ml_downsize(protimg4texture, [tratio(1) tratio(1) tratio(2)]);
                if (needDNA4texture) dnaimg4texture = ml_downsize(dnaimg4texture, [tratio(1) tratio(1) tratio(2)]); end
            end
        end
        if(exist('tgray', 'var') && ~isempty(tgray))
            protimg4texture = uint8(floor(double (protimg4texture) * (tgray - 1) /...
                double(max(protimg4texture(:)))));
            if (needDNA4texture), dnaimg4texture = uint8(floor(double (dnaimg4texture) * (tgray - 1) /...
                    double(max(dnaimg4texture(:))))); nlevels = tgray - 1; end
        end
        
        eval('z = ml_3Dtexture(protimg4texture);', 'err = 1;')
        if err
            z2(1:26) = nan;
        else
            z2 = [z(1:13, 14)' z(1:13, 15)'];
        end
        feat = [feat z2];
        
        if (needDNA4texture)
            zz = ml_3Doverlapfeatures(protimg4texture,protthresh,dnaimg4texture,dnathresh,nlevels);
        else
            zz(1:4) = nan;
        end
        feat = [feat zz];
    end
end

if (max(featidx) > 60)
% downsample by 2 two times
    for i=1:2
        protimg4texture = ml_downsize(protimg4texture, [2 2 2]);
        if(exist('tgray', 'var') && ~isempty(tgray))
            protimg4texture = uint8(floor(double (protimg4texture) * (tgray - 1) /...
                double(max(protimg4texture(:)))));
        end
        eval('z = ml_3Dtexture(protimg4texture);', 'err = 1;')
        if err
            z2(1:26) = nan;
        else
            z2 = [z(1:13, 14)' z(1:13, 15)'];
        end
        feat = [feat z2];
    end
end

if (max(featidx) > 112)
    dtfeat = ml_3dDTfeatures(protimg,protbin,dnaimg,dnabin);
    feat = [feat dtfeat];
end

feat = feat(featidx);
