function [mix, options, errlog] = ml_gmmem(mix, x, options, weights)
%GMMEM	EM algorithm for Gaussian mixture model.
%
%	Description
%	[MIX, OPTIONS, ERRLOG] = ML_GMMEM(MIX, X, OPTIONS) uses the Expectation
%	Maximization algorithm of Dempster et al. to estimate the parameters
%	of a Gaussian mixture model defined by a data structure MIX. The
%	matrix X represents the data whose expectation is maximized, with
%	each row corresponding to a vector.    The optional parameters have
%	the following interpretations.
%
%	OPTIONS(1) is set to 1 to display error values; also logs error
%	values in the return argument ERRLOG. If OPTIONS(1) is set to 0, then
%	only warning messages are displayed.  If OPTIONS(1) is -1, then
%	nothing is displayed.
%
%	OPTIONS(3) is a measure of the absolute precision required of the
%	error function at the solution. If the change in log likelihood
%	between two steps of the EM algorithm is less than this value, then
%	the function terminates.
%
%	OPTIONS(5) is set to 1 if a covariance matrix is reset to its
%	original value when any of its singular values are too small (less
%	than MIN_COVAR which has the value eps).   With the default value of
%	0 no action is taken.
%
%	OPTIONS(14) is the maximum number of iterations; default 100.
%
%   OPTIONS(2) is for how to estimate the population with one component. If
%   it is 0, full covariance matrix will be used. If it is 1, the
%   covariance matrix will be the same as specified by MIX
%
%	The optional return value OPTIONS contains the final error value
%	(i.e. data log likelihood) in OPTIONS(8).
%
%	See also
%	GMM, GMMINIT
%

%	Copyright (c) Ian T Nabney (1996-2001)
%   18-Jul-2006 Modified by T. Zhao
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

if ~exist('weights','var')
    weights = [];
end

if isempty(weights)
    weights = ones(size(x,1),1);
end

%If there is only one component
if mix.ncentres==1
    errlog = 0;
    mix.priors = 1;
    
    if options(2)==0
        [mix.centres,mix.covars] = ml_objgauss([x weights]);
        mix.covar_type = 'full';
    else
        [mix.centres,mix.covars] = ml_objgauss([x weights],mix.covar_type);
    end
    return;
end

% Check that inputs are consistent
errstring = consist(mix, 'gmm', x);
if ~isempty(errstring)
    error(errstring);
end

[ndata, xdim] = size(x);
ndata = sum(weights);

% Sort out the options
if (options(14))
    niters = options(14);
else
    niters = 100;
end

display = options(1);
store = 0;
if (nargout > 2)
    store = 1;	% Store the error values to return them
    errlog = zeros(1, niters);
end
test = 0;
if options(3) > 0.0
    test = 1;	% Test log likelihood for termination
end

check_covars = 0;
if options(5) >= 1
    if display >= 0
        disp('check_covars is on');
    end
    check_covars = 1;	% Ensure that covariances don't collapse
    MIN_COVAR = eps;	% Minimum singular value of covariance matrix
    init_covars = mix.covars;
end

es = [];
% Main loop of algorithm
for n = 1:niters

    % Calculate posteriors based on old parameters
    [post, act] = gmmpost(mix, x);

    % Calculate error value if needed
    if (display | store | test)
        prob = act*(mix.priors)';
        % Error value is negative log likelihood of data
        e = - sum(log(prob).*weights);
%         es = [es e];
%         if(length(es)>2)
%             plot(es(3:end)-es(2:end-1));
%             drawnow
%         end
        if store
            errlog(n) = e;
        end
        if display > 0
            fprintf(1, 'Cycle %4d  Error %11.6f\n', n, e);
        end
        if test
            if (n > 1 & abs(e - eold) < options(3))
                options(8) = e;
                return;
            else
                eold = e;
            end
        end
    end

    % Adjust the new estimates for the parameters
    post = ml_multrow(post',weights')';
    new_pr = sum(post, 1);
    new_c = post' * x;

    % Now move new estimates to old parameter vectors
    mix.priors = new_pr ./ ndata;

    mix.centres = new_c ./ (new_pr' * ones(1, mix.nin));

    switch mix.covar_type
        case 'spherical'
            n2 = dist2(x, mix.centres);
            for j = 1:mix.ncentres
                v(j) = (post(:,j)'*n2(:,j));
            end
            mix.covars = ((v./new_pr))./mix.nin;
            if check_covars
                % Ensure that no covariance is too small
                for j = 1:mix.ncentres
                    if mix.covars(j) < MIN_COVAR
                        mix.covars(j) = init_covars(j);
                    end
                end
            end
        case 'diag'
            for j = 1:mix.ncentres
                diffs = x - (ones(size(x,1), 1) * mix.centres(j,:));
                mix.covars(j,:) = sum((diffs.*diffs).*(post(:,j)*ones(1, ...
                    mix.nin)), 1)./new_pr(j);
            end
            if check_covars
                % Ensure that no covariance is too small
                for j = 1:mix.ncentres
                    if min(mix.covars(j,:)) < MIN_COVAR
                        mix.covars(j,:) = init_covars(j,:);
                    end
                end
            end
        case 'full'
            for j = 1:mix.ncentres
                diffs = x - (ones(size(x,1), 1) * mix.centres(j,:));
                diffs = diffs.*(sqrt(post(:,j))*ones(1, mix.nin));
                mix.covars(:,:,j) = (diffs'*diffs)/new_pr(j);
            end
            if check_covars
                % Ensure that no covariance is too small
                for j = 1:mix.ncentres
                    if min(svd(mix.covars(:,:,j))) < MIN_COVAR
                        mix.covars(:,:,j) = init_covars(:,:,j);
                    end
                end
            end
        case 'ppca'
            for j = 1:mix.ncentres
                diffs = x - (ones(size(x,1), 1) * mix.centres(j,:));
                diffs = diffs.*(sqrt(post(:,j))*ones(1, mix.nin));
                [tempcovars, tempU, templambda] = ...
                    ppca((diffs'*diffs)/new_pr(j), mix.ppca_dim);
                if length(templambda) ~= mix.ppca_dim
                    error('Unable to extract enough components');
                else
                    mix.covars(j) = tempcovars;
                    mix.U(:, :, j) = tempU;
                    mix.lambda(j, :) = templambda;
                end
            end
            if check_covars
                if mix.covars(j) < MIN_COVAR
                    mix.covars(j) = init_covars(j);
                end
            end
        otherwise
            error(['Unknown covariance type ', mix.covar_type]);
    end
end

options(8) = -sum(log(gmmprob(mix, x)));
if (display >= 0)
    disp('Warning: Maximum number of iterations has been exceeded');
end
