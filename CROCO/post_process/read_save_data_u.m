%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read CROCO u velocity at one y-index and save MATLAB variables
% All x-points, all vertical levels, all times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clear; clc;

fname = '../Output/bonassola_libeccio5yr_his.nc';

yindex = 2;

fprintf('Opening NetCDF file...\n');

%% Open using CROCO NetCDF interface

nc = netcdf(fname);

%% Read time

time = double(nc{'scrum_time'}(:));
time = time(:);

fprintf('Number of time records: %d\n',length(time));

%% Read horizontal coordinate

xr = double(squeeze(nc{'x_rho'}(yindex,:)));
xr = xr(:);

% u is staggered between rho-points
x = 0.5 * (xr(1:end-1) + xr(2:end));

clear xr

fprintf('Number of u-points: %d\n',length(x));

%% Read u velocity

% CROCO ordering:
% (time, s_rho, eta_rho, xi_u)
%
% Read:
%   all times
%   all vertical levels
%   only yindex
%   all x-points

fprintf('Reading u velocity...\n');

u = double(squeeze(nc{'u'}(:,:,yindex,:)));

fprintf('Finished reading u.\n');

%% Close NetCDF

close(nc);

%% Reorder dimensions

% After reading, expected:
% u = [time, s_rho, xi_u]
%
% Convert to:
% u = [xi_u, s_rho, time]

u = permute(u,[3 2 1]);

%% Check

fprintf('Size of u: ');
fprintf('%d ',size(u));
fprintf('\n');

fprintf('Expected: [x, vertical level, time]\n');

assert(size(u,1) == length(x), ...
    'Mismatch between x and u.');

assert(size(u,3) == length(time), ...
    'Mismatch between time and u.');

%% Save

fprintf('Saving MATLAB data...\n');

save('Bonassola2DV_JONSWAP_TR5y_dx40cmSponge_data_u.mat', ...
     'time','x','u','-v7.3');

fprintf('Done! Data saved successfully.\n');
