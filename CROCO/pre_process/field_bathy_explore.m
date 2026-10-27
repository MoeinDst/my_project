%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script is intended to inspect the bathymetry data from
% 5 different transects related to the LaFrancesca Bonassola.
% The goal is to select the best representative profile that
% meets project requirements.
%
%  MoeinDst, 09/2026
%
% --- Contact Gaetano Porcile regarding the bathymetry data.
% --- (gaetano.porcile@weatherwatersand.com)
%
% ---- Also needs start.m from croco-tools! ----
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars,
close all,
clc

%% setting working directory:

inpdir = '/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/Bonassola/bathy/v2_extended/';
cd(inpdir)

%% setting input files:

% transects that reach 100 meters depth.
ifiles_2km = {
    'bathy_croco_NBQ_2DV_2km_offshore_n1.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n2.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n3.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n4.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n5.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n6.mat'
    'bathy_croco_NBQ_2DV_2km_offshore_n7.mat'
};

% transects that reach extend 2km.
ifiles_100m = {
    'bathy_croco_NBQ_2DV_100m_depth_n1.mat'
    'bathy_croco_NBQ_2DV_100m_depth_n2.mat'
    'bathy_croco_NBQ_2DV_100m_depth_n3.mat'
    'bathy_croco_NBQ_2DV_100m_depth_n4.mat'
    'bathy_croco_NBQ_2DV_100m_depth_n5.mat'
    'bathy_croco_NBQ_2DV_100m_depth_n6.mat'
    'bathy_croco_NBQ_2DV_100m_depth_n7.mat'
};

% transects of full SWAN domain.
ifiles_SWAN = {
    'bathy_croco_NBQ_2DV_offshore_n1.mat'
    'bathy_croco_NBQ_2DV_offshore_n2.mat'
    'bathy_croco_NBQ_2DV_offshore_n3.mat'
    'bathy_croco_NBQ_2DV_offshore_n4.mat'
    'bathy_croco_NBQ_2DV_offshore_n5.mat'
    'bathy_croco_NBQ_2DV_offshore_n6.mat'
    'bathy_croco_NBQ_2DV_offshore_n7.mat'
};

ifiles = ifiles_2km;
nprofiles = length(ifiles);

%% setting user parameters:
deltax = 0.2; %  horizontal longitudinal resolution
twoDV = true; %  logical for 2DV configuration
ysize = 1.0; %  domain size in transverse direction
l_z0 = false; %  logical for non-uniform roughness

%% loading and interpolating input bathymetric data:
tic

xin      = cell(nprofiles,1);
hin      = cell(nprofiles,1);
xshf     = cell(nprofiles,1);
x1       = cell(nprofiles,1);
h_interp = cell(nprofiles,1);
h1       = cell(nprofiles,1);
x_rho    = cell(nprofiles,1);
y_rho    = cell(nprofiles,1);

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

    % interpolate onto grid with deltax resolution
    x1{ip} = min(xshf{ip}):deltax:max(xshf{ip});
    
    % transverse coordinate
    if twoDV
        y1{ip} = linspace(-deltax, deltax, 3);
    else
        y1{ip} = 0:deltax:ysize;
    end

    h_interp{ip} = interp1(xshf{ip},hin{ip},x1{ip},'linear','extrap');
    
    % replicate in transverse direction
    h1{ip} = repmat(h_interp{ip}, length(y1{ip}), 1);

    % 2DH computational grid
    [x_rho{ip}, y_rho{ip}] = meshgrid(x1{ip}, y1{ip});

end

toc
%% ---- checking the created bathymetry:
%---------------------------------------

bathy = figure('position',[50 50 1200 400]);
hold on

% zero-elevation line
plot(x1{1}, zeros(size(x1{1})), 'b--','linewidth', 0.5, 'DisplayName', 'zero');

% plot all bathymetric profiles
for ip = 1:nprofiles

    plot(x1{ip}, -h1{ip}(2,:),'linewidth', 1.5,'DisplayName', sprintf('n%d', ip));

end

xlabel('Streamwise coordinate [m]', 'interpreter', 'latex');
ylabel('Elevation [m]', 'interpreter', 'latex');

legend('Location','best');
title('Bathymetry', 'interpreter', 'latex');

set(gca, 'FontSize', 14);

%------------------------------
%% ----- Plan View
%------------------------------
figure;
hold on

for ip = 1:nprofiles
    data = load(ifiles{ip});

    plot(data.X(:,1), data.Y(:,1),'LineWidth', 1.5,'DisplayName', sprintf('n%d', ip));
end

xlabel('X [m]');
ylabel('Y [m]');
title('Bathymetric transects - Plan view');
legend('Location','best');

axis equal
grid on

%------------------------------
%% ----- 3D
%------------------------------
figure;
hold on

for ip = 1:nprofiles
    data = load(ifiles{ip});

    plot3(data.X(:,1), data.Y(:,1), data.Z(:,1),'LineWidth', 1.5,'DisplayName', sprintf('n%d', ip));
end

xlabel('X [m]');
ylabel('Y [m]');
zlabel('Elevation [m]');

title('Bathymetric transects - 3D view');
legend('Location','best');

axis equal
grid on
view(3)

%%
%% plan-view bathymetry

Xall = [];
Yall = [];
Zall = [];
% combine all transects
for ip = 1:nprofiles

    data = load(ifiles{ip});

    Xall = [Xall; data.X(:,1)];
    Yall = [Yall; data.Y(:,1)];
    Zall = [Zall; data.Z(:,1)];

end

% create regular XY grid
dx_plot = 0.5;  % resolution for visualization
xq = min(Xall):dx_plot:max(Xall);
yq = min(Yall):dx_plot:max(Yall);
[Xq,Yq] = meshgrid(xq,yq);

% interpolate scattered transect data
F = scatteredInterpolant(Xall,Yall,Zall,'natural','none');

Zq = F(Xq,Yq);

% plot
figure
pcolor(Xq,Yq,Zq)
shading interp

hold on

for ip = 1:nprofiles
    data = load(ifiles{ip});

    plot(data.X(:,1), data.Y(:,1),'LineWidth', 1.5,'DisplayName', sprintf('n%d', ip));
end

colorbar
axis equal tight

xlabel('X [m]')
ylabel('Y [m]')
title('Bathymetry - Plan View')


%% 3D bathymetry

figure

surf(Xq, Yq, Zq, Zq)
shading interp
hold on

for ip = 1:nprofiles

    data = load(ifiles{ip});

    plot3(data.X(:,1),data.Y(:,1),data.Z(:,1),'k-', 'LineWidth', 1.5);

end

xlabel('X [m]')
ylabel('Y [m]')
zlabel('Elevation [m]')

colorbar
axis equal
grid on
view(3)

title('Bathymetry - 3D View')

%% local coordinates
X0 = min(Xall);
Y0 = min(Yall);

Xlocal = Xall - X0;
Ylocal = Yall - Y0;

dx_plot = 0.5;

xq = min(Xlocal):dx_plot:max(Xlocal);
yq = min(Ylocal):dx_plot:max(Ylocal);

[Xq,Yq] = meshgrid(xq,yq);

F = scatteredInterpolant(Xlocal,Ylocal,Zall,'natural','none');

Zq = F(Xq,Yq);

%% 3D plot
figure

surf(Xq,Yq,Zq,Zq,'EdgeColor','none');

hold on

% plot measured transects
for ip = 1:nprofiles

    data = load(ifiles{ip});

    Xp = data.X(:,1) - X0;
    Yp = data.Y(:,1) - Y0;

    plot3(Xp,Yp,data.Z(:,1),'k-', 'LineWidth',1.0);
end

xlabel('X [m]')
ylabel('Y [m]')
zlabel('Elevation [m]')

colorbar
grid on
box on

view(45,30)