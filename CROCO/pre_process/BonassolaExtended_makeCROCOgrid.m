%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script is intended to process the bathymetry data from
% 5 different transects related to the LaFrancesca Bonassola.
% Then the representative bathymetry will be used to make the
% CROCO grid with necessary variables and respective definitions.
%
% This version includes the possibility to add an extended
% flat-bottom to the actual bathymetry offshore.
% This helps with a smoother transition from boundary towards
% interior of the domain. This also enables you to have even
% number of grid cells and consequently disect the domain to
% desired number of cores/threads.
%
% The current script is adapted from Martial Boutet and Gaetano Porcile,
% setup of laboratory test cases in 2024 at the M2C Laboratory (University
% of Caen, Normandie, France), and now modified to meet my specific
% requirements. In some lines also explanation is added to improve
% readability and clarity of the code.
%
% ------ MoeinDst, 09/2026
%
% --- Contact Gaetano Porcile regarding the bathymetry data.
% --- (gaetano.porcile@weatherwatersand.com)
%
% ---- This script also needs start.m from croco-tools! ----
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Processing bathymetric data and save to NetCDF file CROCO grid

clearvars,
close all,
clc

%% setting working directory:

inpdir = '/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/Bonassola/bathy/';
cd(inpdir)

outdir = '/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/Bonassola/grd/';

%% setting input/output files:

addpath '/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/Bonassola/bathy/v2_extended'

ifiles = {
    'bathy_croco_NBQ_2DV_2km_offshore_n1.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n2.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n3.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n4.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n5.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n6.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n7.mat'
};

nprofiles = length(ifiles);

ofile = 'croco_grd_Bonassola_DX40cm_2DV_ExtendedFlatBot_smoothedGaus5_2kmBathyExtent.nc'; %  output NetCDF file
% ofile = 'croco_grd_Bonassola_DX10cm_2DV.nc'; %  output NetCDF file

%% setting user parameters:
deltax = 0.4;                % horizontal longitudinal resolution
twoDV = true;                % logical for 2DV configuration
ysize = 1.0;                 % domain size in transverse direction
l_z0 = false;                % logical for non-uniform roughness
n_ext = 501;                 % number of cells for flat-bottom region at offshore
ext_length = n_ext * deltax; % added flat-bottom length [m]

%% loading and interpolating input bathymetric data:

% loading input bathymetric data:
xin  = cell(nprofiles,1);
hin  = cell(nprofiles,1);
xshf = cell(nprofiles,1);

for ip = 1:nprofiles

    % load profile
    data = load(ifiles{ip});

    % x-coordinate: cumulative along-transect distance
    xin{ip} = data.distance(:,1);

    % water depth
    hin{ip} = -data.Z(:,1);

    % shift x-coordinate to start from zero
    xmin = min(xin{ip});
    xshf{ip} = xin{ip} - xmin;

end
%% interpolating all profiles onto common model grid:

% maximum distance covered by ALL profiles
xmax_common = min(cellfun(@max, xshf));

% common x-coordinate
% x1_0 = 0:deltax:xmax_common;
x1_0 = 0:deltax:2000;

% initiating matrix for interpolated bathymetry
h_interp = zeros(nprofiles, length(x1_0));

for ip = 1:nprofiles

    h_interp(ip,:) = interp1(xshf{ip}, hin{ip}, x1_0, 'linear','extrap');

end

% ---- NaN diagnostics after interpolation ----
% CROCO does not like NaNs and will complain if it
% finds some during the file read and initiation.

fprintf('\nNaN diagnostics for h_interp:\n');

for ip = 1:nprofiles
    inan = isnan(h_interp(ip,:));

    fprintf('  Profile %d: %d NaNs out of %d points\n', ...
        ip, nnz(inan), numel(inan));

    if any(inan)
        fprintf('      x-range containing NaNs: %.3f to %.3f m\n', ...
            min(x1_0(inan)), max(x1_0(inan)));
    end
end

fprintf('  Total NaNs in h_interp: %d\n\n', nnz(isnan(h_interp)));

% transverse coordinate:
if twoDV
    y1 = linspace(-deltax, deltax, 3);
else
    y1 = 0:deltax:ysize;
end

h_mean0 = mean(h_interp, 1, 'omitnan'); % mean of all transects

fprintf('NaNs in h_mean: %d / %d\n', ...
    nnz(isnan(h_mean0)), numel(h_mean0));

%% Applying the domain extension
%%---------------------------------------

% Flat offshore extension
h0 = repmat(h_mean0(1), 1, n_ext);
% Extend bathymetry
h_mean = [h0, h_mean0];
% Rebuild model coordinate
x1 = 0:deltax:(length(h_mean)-1)*deltax;
% Checking the NaNs again
fprintf('NaNs in extended h_mean: %d / %d\n', ...
    nnz(isnan(h_mean)), numel(h_mean));

%% ---- checking the created bathymetry:
%  ---- also inspecting smoothing choices
%----------------------------------------

bathy = figure('position',[50 50 1200 400]);
hold on

% zero-elevation line
plot(x1, zeros(size(x1)), 'b--','linewidth', 0.5, 'DisplayName', 'zero');

% --- plotting all transects ---
% for ip = 1:nprofiles
% 
%     plot(x1, -h_interp(ip,:),'linewidth', 1.0,'DisplayName', sprintf('n%d', ip));
% 
% end

plot(x1, -h_mean, 'k','linewidth', 2,'DisplayName', 'mean');
plot(x1, smoothdata(-h_mean,'gaussian',5),'linewidth', 2,'DisplayName', 'guassian-5');
plot(x1, smoothdata(-h_mean,'gaussian',10),'linewidth', 2,'DisplayName', 'guassian-10');
plot(x1, smoothdata(-h_mean,'sgolay',10),'linewidth', 2,'DisplayName', 'Sgolay-10');


xlabel('Streamwise coordinate [m]', 'interpreter', 'latex');
ylabel('Elevation [m]', 'interpreter', 'latex');
legend('Location','best');
title('Bathymetry', 'interpreter', 'latex');

set(gca, 'FontSize', 14);

%% Selecting the desired representative bathymetry
h_interp = smoothdata(h_mean,'gaussian',5); %  interpolated & smoothed bathymetry

fprintf('NaNs after smoothdata on the final bathymetry: %d / %d\n', ...
    nnz(isnan(h_interp)), numel(h_interp));

h1 = repmat(h_interp, length(y1), 1); % replicate in transverse direction
[x_rho, y_rho] = meshgrid(x1, y1);    % 2DH computational grid coordinates

%% checking the created bathymetry:

bathy=figure('position',[50 50 1200 400]); hold on,

plot(x1,zeros(size(x1)),'-b','linewidth',3)
plot(x1,-h1(2,:),'-k','linewidth',3)

% axis([min(x1) max(x1) min(-h1(2,:)) max(-h1(2,:))])
% axis([4.8 5.2 -30.1 -14.9])
xlabel('Streamwise coordinate [m]','interpreter','latex');
ylabel('Elevation [m]','interpreter','latex');
title('Bathymetry','interpreter','latex');
set(gca,'FontSize',14)

%% computing grid metrics:

xl = max(x_rho(:)) - min(x_rho(:)); %  computational domain length in x-direction
el = max(y_rho(:)) - min(y_rho(:)); %  computational domain length in y-direction

xi_rho = size(x_rho,2);             %  number of points in x-direction
eta_rho = size(y_rho,1);            %  number of points in y-direction

[x_u, x_v, x_psi] = rho2uvp(x_rho); %  number of points for u, v, psi for x-direction
[y_u, y_v, y_psi] = rho2uvp(y_rho); %  number of points for u, v, psi for y-direction

dx = deltax * ones(size(h1));       % constant spacing in x-direction
dy = deltax * ones(size(h1));       % constant spacing in y-direction

pm = 1 ./ dx;                       % inverse grid spacing in x-direction
pn = 1 ./ dy;                       % inverse grid spacing in y-direction

dndx = zeros(size(h1));             % derivative of pn in x-direction (zero for uniform grid)
dmde = zeros(size(h1));             % derivative of pm in y-direction (zero for uniform grid)

%% initializing Coriolis parameter:

f = ones(size(h1)); % To be replace with actual Coriolis calculation if needed

%% writing in output NetCDF file:

% start NetCDF file creation:
ncid = netcdf.create([outdir ofile],'CLOBBER'); %  creating/overwriting

% define dimensions:
dim_xi_rho = netcdf.defDim(ncid, 'xi_rho', xi_rho);
dim_xi_u = netcdf.defDim(ncid, 'xi_u', xi_rho-1);
dim_xi_v = netcdf.defDim(ncid, 'xi_v', xi_rho);
dim_xi_psi = netcdf.defDim(ncid, 'xi_psi', xi_rho-1);

dim_eta_rho = netcdf.defDim(ncid, 'eta_rho', eta_rho);
dim_eta_u = netcdf.defDim(ncid, 'eta_u', eta_rho);
dim_eta_v = netcdf.defDim(ncid, 'eta_v', eta_rho-1);
dim_eta_psi = netcdf.defDim(ncid, 'eta_psi', eta_rho-1);

dim_one = netcdf.defDim(ncid, 'one', 1);

% ----------- define variables -----------
var_xl = netcdf.defVar(ncid, 'xl', 'double', dim_one);
var_el = netcdf.defVar(ncid, 'el', 'double', dim_one);
var_spherical = netcdf.defVar(ncid, 'spherical', 'char', dim_one);

var_x_rho = netcdf.defVar(ncid, 'x_rho', 'double', [dim_xi_rho, dim_eta_rho]);
var_x_u = netcdf.defVar(ncid, 'x_u', 'double', [dim_xi_u, dim_eta_u]);
var_x_v = netcdf.defVar(ncid, 'x_v', 'double', [dim_xi_v, dim_eta_v]);
var_x_psi = netcdf.defVar(ncid, 'x_psi', 'double', [dim_xi_psi, dim_eta_psi]);

var_y_rho = netcdf.defVar(ncid, 'y_rho', 'double', [dim_xi_rho, dim_eta_rho]);
var_y_u = netcdf.defVar(ncid, 'y_u', 'double', [dim_xi_u, dim_eta_u]);
var_y_v = netcdf.defVar(ncid, 'y_v', 'double', [dim_xi_v, dim_eta_v]);
var_y_psi = netcdf.defVar(ncid, 'y_psi', 'double', [dim_xi_psi, dim_eta_psi]);

var_pm = netcdf.defVar(ncid, 'pm', 'double', [dim_xi_rho, dim_eta_rho]);
var_pn = netcdf.defVar(ncid, 'pn', 'double', [dim_xi_rho, dim_eta_rho]);
var_dndx = netcdf.defVar(ncid, 'dndx', 'double', [dim_xi_rho, dim_eta_rho]);
var_dmde = netcdf.defVar(ncid, 'dmde', 'double', [dim_xi_rho, dim_eta_rho]);

var_h = netcdf.defVar(ncid, 'h', 'double', [dim_xi_rho, dim_eta_rho]);
var_f = netcdf.defVar(ncid, 'f', 'double', [dim_xi_rho, dim_eta_rho]);

% ------ add attirbutes to variables ------
netcdf.putAtt(ncid, var_xl, 'long_name', 'domain length in x-direction');
netcdf.putAtt(ncid, var_xl, 'units', 'meters');
netcdf.putAtt(ncid, var_el, 'long_name', 'domain length in y-direction');
netcdf.putAtt(ncid, var_el, 'units', 'meters');
netcdf.putAtt(ncid, var_spherical, 'long_name', 'grid type logical');
netcdf.putAtt(ncid, var_spherical, 'option', 'T (spherical) or F (Cartesian)');

netcdf.putAtt(ncid, var_x_rho, 'long_name', 'x-location of RHO-points');
netcdf.putAtt(ncid, var_x_rho, 'units', 'meters');
netcdf.putAtt(ncid, var_x_u, 'long_name', 'x-location of U-points');
netcdf.putAtt(ncid, var_x_u, 'units', 'meters');
netcdf.putAtt(ncid, var_x_v, 'long_name', 'x-location of V-points');
netcdf.putAtt(ncid, var_x_v, 'units', 'meters');
netcdf.putAtt(ncid, var_x_psi, 'long_name', 'x-location of PSI-points');
netcdf.putAtt(ncid, var_x_psi, 'units', 'meters');

netcdf.putAtt(ncid, var_y_rho, 'long_name', 'y-location of RHO-points');
netcdf.putAtt(ncid, var_y_rho, 'units', 'meters');
netcdf.putAtt(ncid, var_y_u, 'long_name', 'y-location of U-points');
netcdf.putAtt(ncid, var_y_u, 'units', 'meters');
netcdf.putAtt(ncid, var_y_v, 'long_name', 'y-location of V-points');
netcdf.putAtt(ncid, var_y_v, 'units', 'meters');
netcdf.putAtt(ncid, var_y_psi, 'long_name', 'y-location of PSI-points');
netcdf.putAtt(ncid, var_y_psi, 'units', 'meters');

netcdf.putAtt(ncid, var_pm, 'long_name', 'inverse of grid spacing in x');
netcdf.putAtt(ncid, var_pm, 'units', 'meters^-1');
netcdf.putAtt(ncid, var_pn, 'long_name', 'inverse of grid spacing in y');
netcdf.putAtt(ncid, var_pn, 'units', 'meters^-1');
netcdf.putAtt(ncid, var_dndx, 'long_name', 'xi-derivative of inverse grid spacing in y');
netcdf.putAtt(ncid, var_dndx, 'units', 'meters^-2');
netcdf.putAtt(ncid, var_dmde, 'long_name', 'eta-derivative of inverse grid spacing in x');
netcdf.putAtt(ncid, var_dmde, 'units', 'meters^-2');

netcdf.putAtt(ncid, var_h, 'long_name', 'bathymetry at RHO-points');
netcdf.putAtt(ncid, var_h, 'units', 'meters');
netcdf.putAtt(ncid, var_f, 'long_name', 'Coriolis parameter at RHO-points');
netcdf.putAtt(ncid, var_f, 'units', 's^-1');

% ---- end of define mode ----
netcdf.endDef(ncid);

% ---- write data to variables ----
netcdf.putVar(ncid, var_xl, xl);
netcdf.putVar(ncid, var_el, el);

netcdf.putVar(ncid, var_x_rho, x_rho');
netcdf.putVar(ncid, var_x_u, x_u');
netcdf.putVar(ncid, var_x_v, x_v');
netcdf.putVar(ncid, var_x_psi, x_psi');

netcdf.putVar(ncid, var_y_rho, y_rho');
netcdf.putVar(ncid, var_y_u, y_u');
netcdf.putVar(ncid, var_y_v, y_v');
netcdf.putVar(ncid, var_y_psi, y_psi');

netcdf.putVar(ncid, var_pm, pm');
netcdf.putVar(ncid, var_pn, pn');
netcdf.putVar(ncid, var_dndx, dndx');
netcdf.putVar(ncid, var_dmde, dmde');

netcdf.putVar(ncid, var_h, h1');
netcdf.putVar(ncid, var_f, f');

% ------ close NetCDF output file ------
netcdf.close(ncid);
disp(['NetCDF file created successfully: ' outdir ofile]);

%% Check directly on MATLAB the created NetCDF file:

% clearvars, close all, clc
% 
% % loading croco netcdf grid file:
% fname='croco_grd_dx.0025_2D_matlab.nc';
% ncdisp(fname);
% x=ncread(fname,'x_rho');% longitude
% y=ncread(fname,'y_rho');% latitude
% h=ncread(fname,'h');

%% Helper Function: Compute rho2uvp
function [ufield, vfield, pfield] = rho2uvp(rfield)
    % Compute u, v, psi fields from rho fields
    [Mp, Lp] = size(rfield);
    M = Mp - 1;
    L = Lp - 1;

    % Compute v, u, and psi fields
    vfield = 0.5 * (rfield(1:M, :) + rfield(2:Mp, :));
    ufield = 0.5 * (rfield(:, 1:L) + rfield(:, 2:Lp));
    pfield = 0.5 * (ufield(1:M, :) + ufield(2:Mp, :));
end
