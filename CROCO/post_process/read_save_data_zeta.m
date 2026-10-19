%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read CROCO free-surface elevation and save MATLAB variables
% Run this script ONLY ONCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc;

fname = '../Output/bonassola_libeccio5yr_his.nc';

yindex = 2;

%% Read time

time = double(ncread(fname,'scrum_time'));
time = time(:);

%% Read x-coordinate

xall = double(ncread(fname,'x_rho'));

x = xall(:,yindex);

clear xall

%% Read free-surface elevation

% Expected dimensions:
% xi_rho, eta_rho, time

zeta = double(ncread(fname,'zeta'));

% Select the desired y-index
zeta = squeeze(zeta(:,yindex,:));

% Ensure dimensions are [x, time]
zeta = reshape(zeta,length(x),length(time));

%% Check dimensions

fprintf('Number of time records: %d\n',length(time));
fprintf('Number of x-points: %d\n',length(x));
fprintf('Size of zeta: %d x %d\n',size(zeta,1),size(zeta,2));

assert(size(zeta,1)==length(x), ...
       'Mismatch between zeta and x dimensions.');

assert(size(zeta,2)==length(time), ...
       'Mismatch between zeta and time dimensions.');

%% Save variables

fprintf('Saving MATLAB data...\n');

save('Bonassola2DV_JONSWAP_TR5y_dx40cmSponge_data_zeta.mat', ...
     'time','x','zeta','-v7.3');

fprintf('Done! Data saved successfully.\n');
