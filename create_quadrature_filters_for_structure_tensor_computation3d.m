function create_quadrature_filters_for_structure_tensor_computation3d(varargin)
% CREATE_QUADRATURE_FILTERS_FOR_STRUCTURE_TESNOR_COMPUTATION3D
% Creates 3D quadrature filters for structure tensor estimation
%
% create_quadrature_filters_for_struncture_tensor_computation3d()
%
% Creates three sets of quadrature filters and stores them in
% 'quadratureFiltersForStructureTensor3D.mat'.
%
% INPUT_ARGUMENTS
% N/A
%
% OPTIONAL INPUT ARGUMENTS:
% N/A
%
% OUTPUT ARGUMENTSls

% N/A
%
% See "Advanced filter design" by Knutsson et al for detailed explanation
% of the parameters used.
%
% See also F_weightgensnr, goodsw, quadrature, krnopt

% Copyright (c) 2012 Daniel Forsberg
% danne.forsberg@outlook.com
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

clear coarse intermediate fine
filePath = fileparts(mfilename('fullpath'));
currentPath = pwd;
cd(filePath);
scales = {'coarse','intermediate','fine'};

%%

if ~exist('F_weightgensnr.m','file') || ~exist('goodsw.m','file') || ...
        ~exist('quadrature.m','file') || ~exist('krnopt.m','file')
    error(['You appear to be missing vital functions for optimizing filters. ',...
        'Please download: https://www.imt.liu.se/edu/courses/TBMI02/code/kerngen.zip'])
end

for k = 1 : length(scales)
    scale = scales{k};
    
    switch scale
        case 'coarse'
            % Filter parameters
            n = 9;
            spatial_rexp = 2;
            frequency_rexp = -1.0;
            cosexp = 1;
            SNRest = 30;
            DCamp = 1000;
            fw_amp = 30;
            
            % Center frequency and bandwidth (in octaves)
            u0 = pi/3;
            B = 2.0;
        case 'intermediate'
            % Filter parameters
            n = 7;
            spatial_rexp = 2;
            frequency_rexp = -1.0;
            cosexp = 1;
            SNRest = 30;
            DCamp = 1000;
            fw_amp = 30;
            
            % Center frequency and bandwidth (in octaves)
            u0 = pi*sqrt(2)/3;
            B = 2.0;
        case 'fine'
            % Filter parameters
            n = 7;
            spatial_rexp = 2;
            frequency_rexp = -1.0;
            cosexp = 1;
            SNRest = 30;
            DCamp = 1000;
            fw_amp = 30;
            
            % Center frequency and bandwidth (in octaves)
            u0 = pi*2/3;
            B = 2.0;
        otherwise
            error('Undefined scale')
    end
    
    fprintf('Optimizing quadrature filters for structure tensor computation in 3d\n');
    
    % Sizes
    spatialSize = [n n n];
    frequencySize = 2*spatialSize+1;
    
    % Frequency weights
    Fw = F_weightgensnr(frequencySize,frequency_rexp,cosexp,SNRest,DCamp);
    
    % Spatial weights
    fw0 = goodsw(spatialSize,spatial_rexp);
    fw = fw_amp.*fw0;
    
    % Spatial ideal filter
    fi = wa(spatialSize,0);
    fi = putorigo(fi,1);
    
    % Spatial mask
    fm = wa(spatialSize,0);
    fm = putdata(fm,ones(spatialSize));
    
    % Filter directions
    a = 2;
    b = 1 + sqrt(5);
    c = 1/sqrt(10 + 2*sqrt(5));
    dir{1} = c * [ 0  a  b];
    dir{2} = c * [ 0 -a  b];
    dir{3} = c * [ a  b  0];
    dir{4} = c * [-a  b  0];
    dir{5} = c * [ b  0  a];
    dir{6} = c * [ b  0 -a];
    
    % Frequency ideal filters
    for k = 1 : length(dir)
        Fi{k} = quadrature(frequencySize,u0,B,dir{k});
    end
    
    % Optimize the quadrature filters
    for k = 1 : length(dir)
        [f{k},F{k}] = krnopt(Fi{k},Fw,fm,fi,fw);
    end
    
    for k = 1 : length(dir)
        f{k} = getdata(f{k});
    end
    
    % Create dual tensors
    for k = 1 : length(dir)
        M = 5/4.*dir{k}'*dir{k} - 1/4.*eye(3);
        m11{k} = M(1,1);
        m12{k} = M(1,2);
        m13{k} = M(1,3);
        m22{k} = M(2,2);
        m23{k} = M(2,3);
        m33{k} = M(3,3);
    end
    
    % Remember filter parameters
    filterInfo.n = n;
    filterInfo.spatial_rexp = spatial_rexp;
    filterInfo.frequency_rexp = frequency_rexp;
    filterInfo.cosexp = cosexp;
    filterInfo.SNRest = SNRest;
    filterInfo.DCamp = DCamp;
    filterInfo.fw_amp = fw_amp;
    filterInfo.u0 = u0;
    filterInfo.B = B;
    
    switch scale
        case 'coarse'
            coarse.f = f;
            coarse.m11 = m11;
            coarse.m12 = m12;
            coarse.m13 = m13;
            coarse.m22 = m22;
            coarse.m23 = m23;
            coarse.m33 = m33;
            coarse.filterInfo = filterInfo;
        case 'intermediate'
            intermediate.f = f;
            intermediate.m11 = m11;
            intermediate.m12 = m12;
            intermediate.m13 = m13;
            intermediate.m22 = m22;
            intermediate.m23 = m23;
            intermediate.m33 = m33;
            intermediate.filterInfo = filterInfo;
        case 'fine'
            fine.f = f;
            fine.m11 = m11;
            fine.m12 = m12;
            fine.m13 = m13;
            fine.m22 = m22;
            fine.m23 = m23;
            fine.m33 = m33;
            fine.filterInfo = filterInfo;
    end
end
save quadratureFiltersForStructureTensor3D coarse intermediate fine

cd(currentPath)