%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script is dedicated to create and plot time-averaged values
% needed to address project requirements.
%
% ------------------------- MoeinDst, 22/10/2026 ------------------------
%
% This version is built on my original script, after modifications and
% improvements introduced by Umberto (usasso). The current version deals
% more with the plotting part and cosmetics such as legend name, panel
% header, and so on. Also removed some parts of his plots for the client
% meeting, renamed the 4th panel to near-bed velocity rather than undetow
% to be more physically accurate.
%------------------------------------------------------------------------
%  COPY modified by usasso (20/10/2026) for the hazard values asked by
%  the client.
%  Original: Moein_Matlab_Script/plot4panel_SingleRun_precomputed.m
%
%  MODIFICATIONS (find one with Ctrl+F, e.g. "[U5]")
%   [U3]  Moein's time-averaged u is no longer loaded
%   [U4]  dry threshold (Dcrit) for undertow
%   [U5]  zeta in the window: std, maximum, run-up, profile at the max run-up
%   [U6]  snapshot at the max run-up, dry cells hidden
%   [U7]  undertow record by record: mean, std, strongest, profile at the
%         strongest, position where the ground = 0 m
%
%  HOW THEY ARE MARKED
%  Every modification is a block that opens and closes with a comment:
%   % >>>>> [Ux] ADDED (usasso): ...     new code
%   % >>>>> [Ux] CHANGED (usasso): ...   Moein's line(s) modified: first his
%                                        original, commented, then the new
%                                        line(s). To use Moein's version:
%                                        comment the new line(s) and
%                                        uncomment his
%   % >>>>> [Ux] REMOVED (usasso): ...   Moein's line(s) switched off
%   % <<<<< END [Ux] - back to Moein's code
%  To jump between them: Ctrl+F on ">>>>>" (or on a tag, e.g. "[U5]").
%  EVERYTHING OUTSIDE THESE BLOCKS IS MOEIN'S ORIGINAL CODE.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ========================================================================
% FILE PATHS
% =========================================================================

run_name = 'real_bathy_extended_JONSWAP_TR5y_dx40cmSponge';

zeta_avg_original = fullfile('/folder_path/',...
    run_name, ...
    [run_name '_zeta_avg_wetdry.mat']);

zeta_original_matfile = fullfile('/folder_path/',...
    run_name, ...
    'post_process', ...
    [run_name '_data_zeta.mat']);

hisfile_original = fullfile('/folder_path/',...
    [run_name '/Output/bonassola_libeccio5yr_his.nc']);

% u at every x point, level and record (for the undertow range and peak)
u_original_matfile = fullfile('/folder_path/',...
    run_name, ...
    'post_process', ...
    [run_name '_data_u.mat']);

%% ========================================================================
% SETTINGS
% =========================================================================
yindex = 2;

lambda_L = 20.0;  % scaling factor for lenght
lambda_T = 4.5;   % scaling factor for time

% Original B2 averaging window
% t_start = 89.2;
% t_end   = 208.0;
t_start = 89.2*lambda_T;
t_end   = 208.0*lambda_T;

% Plot limits -- zoom on the last 150 m, wider y limits

% Moein's original:
% xlimits = [1500 2140];
xlimits = [2000 2145];

% Moein's original:
% ylimits = { ...
%     [-31.00 9.50], ...
%     [-0.25 2.5], ...
%     [-0.05 5.50], ...
%     [-1.00 0.15]};
ylimits = { ...
    [-15.50 10.00], ...
    [-15.50 10.00], ...
    [-0.05 5.50], ...
    [-5.00 3.00]};

% -------------- LOAD PROCESSED ZETA STATISTICS
O_z = load(zeta_avg_original, 'x','zeta_snapshot','snapshot_time','Hs_high','MSL_high');

% -------------- ORIGINAL SWASH QUANTITIES
x_original = O_z.x(:);
MSL_original = O_z.MSL_high(:);
Hs_original = O_z.Hs_high(:);
zeta_snapshot_original = O_z.zeta_snapshot(:);
snapshot_time_original = O_z.snapshot_time;

%% ========================================================================
% LOAD PRE-COMPUTED MEAN U
% =========================================================================

% >>>>> [U3] REMOVED (usasso): Moein's time-averaged u is no longer loaded
% The mean undertow is now computed record by record from data_u.mat,
% in block [U7] below
% Moein's original (switched off):
% tic
%
% % O_u = load('swash_original_u_mean.mat');
% O_u = load(umean_original_matfile);
%
% u_mean_original = O_u.u_mean_upscaled_raw;
% x_u_original    = O_u.x_u_upscaled_raw;
%
% toc
% <<<<< END [U3] - back to Moein's code

%% ========================================================================
% READ BATHYMETRY
% =========================================================================

% Original
h_original = double(ncread(hisfile_original,'h'));
h_original = h_original(:,yindex);
bottom_original = -h_original;

% >>>>> [U4] ADDED (usasso): dry threshold
% A cell is dry when the water depth D = h + zeta is below this threshold
% (same as prep_zavg_wetdry.m)
Dcrit = double(ncread(hisfile_original,'Dcrit'));
wet_threshold = Dcrit + 1.e-6 + 0.01;
% <<<<< END [U4] - back to Moein's code

%% ========================================================================
% HIGH-FREQUENCY INSTANTANEOUS ZETA
% Use the LAST record from each simulation.
% For the upscaled case, both x and zeta are normalized back to B2 scale.
% =========================================================================

% -------------------------------------------------------------------------
% ORIGINAL
% -------------------------------------------------------------------------

ZO = matfile(zeta_original_matfile);
time_zeta_original = ZO.time;
x_zeta_original    = ZO.x;

% >>>>> [U5] ADDED (usasso): zeta in the window - std, maximum, run-up
% zeta is the water elevation above the zero level: on a wet land cell
% zeta = ground + D, so NO topography has to be added to it.
tic

i1 = find(time_zeta_original >= t_start,1,'first');
i2 = find(time_zeta_original <= t_end,1,'last');
window_time = time_zeta_original(i1:i2);
n_records = i2 - i1 + 1;

% zeta: one row per x point, one column per record
zeta_window = double(ZO.zeta(:,i1:i2));

% Dry records become NaN
is_dry = (h_original + zeta_window) < wet_threshold;
zeta_window(is_dry) = NaN;

% Standard deviation at each x point over the wet records
% 'omitnan' = skip dry records
std_sea_level = std(zeta_window,1,2,'omitnan');

% Highest water level reached at each x point (max skips NaN)
max_sea_level = max(zeta_window,[],2);

% Run-up: water level at the most landward wet cell, record by record
runup_level = NaN(n_records,1);
runup_x     = NaN(n_records,1);
for k = 1:n_records
    last_wet = find(not(is_dry(:,k)),1,'last');
    runup_level(k) = zeta_window(last_wet,k);
    runup_x(k)     = x_zeta_original(last_wet);
end

[max_runup, k_max] = max(runup_level);
x_max_runup    = runup_x(k_max);
time_max_runup = window_time(k_max);

% Sea-level profile at the instant of the maximum run-up (dry cells = NaN)
zeta_at_max_runup = zeta_window(:,k_max);

toc
% <<<<< END [U5] - back to Moein's code

% last_original = length(time_zeta_original);
% zeta_inst_original = double(ZO.zeta(:,last_original));
% time_inst_original = time_zeta_original(last_original);

% >>>>> [U6] CHANGED (usasso): snapshot at the instant of the maximum run-up
% Moein's original:
% target_time_original_str = 0.0*lambda_T; % 208.0
target_time_original_str = time_max_runup;
% <<<<< END [U6] - back to Moein's code

% target_time_original_str = 867.6405; %TR5y:867.6405 - TR1y:627.003
[~,index_original] = min(abs(time_zeta_original - target_time_original_str));
zeta_inst_original = double(ZO.zeta(:,index_original));
time_inst_original = time_zeta_original(index_original);

% >>>>> ADDED [M] (MoeinDst): ------- t_start
target_time_start_str = 401.4;
[~,index_str] = min(abs(time_zeta_original - target_time_start_str));
zeta_inst_str = double(ZO.zeta(:,index_str));
time_inst_str = time_zeta_original(index_str);

target_time_end_str = 936.0;
[~,index_end] = min(abs(time_zeta_original - target_time_end_str));
zeta_inst_end = double(ZO.zeta(:,index_end));
time_inst_end = time_zeta_original(index_end);

Dcrit=double(ncread(hisfile_original,'Dcrit'));
D=h_original+zeta_inst_original;
zeta_inst_original(D<Dcrit+0.01)=NaN;

D=h_original+zeta_inst_str;
zeta_inst_str(D<Dcrit+0.01)=NaN;

D=h_original+zeta_inst_end;
zeta_inst_end(D<Dcrit+0.01)=NaN;
% <<<<< END [M]
fprintf('Target original time:   %.4f s\n',target_time_original_str);
fprintf('Selected original time: %.4f s\n',time_inst_original);

%% ========================================================================
% Undertow definitions for original and upscaled
%
% It has been decided to define an average of the
% 1st 5 levels (closest to teh bed) as undertow.
%
% u_mean_* has shape (time,levels)
% In this modified version (after usasso) we actually
% load the entire u_data and do the averaging here
% while accounting for the dry-cell counts, consistent
% with the zeta records.
% =========================================================================

tic

UO = matfile(u_original_matfile);
x_u_original = UO.x;

% Read the 5 lowest levels of all the records of the window at once
u_window = double(UO.u(:,1:5,i1:i2));

% Mean of the 5 lowest levels: one value per x_u point and record
near_bed_u = squeeze(mean(u_window,2));

clear u_window

% A u point lies between two zeta points: it is dry if one of them is dry
is_dry_u = is_dry(1:end-1,:) | is_dry(2:end,:);    % | means "or"
near_bed_u(is_dry_u) = NaN;

% Same name as Moein's variable
undertow_original  = mean(near_bed_u,2,'omitnan');
std_undertow       = std(near_bed_u,1,2,'omitnan');

% First point where the profile crosses the zero level
i_shoreline = find(bottom_original > 0,1,'first');
x_shoreline = x_original(i_shoreline);

toc
% <<<<< END [U7] - back to Moein's code

%% ========================================================================
% FOUR-PANEL FIGURE
% =========================================================================

f1 = figure( ...
    'Color','w', ...
    'Position',[100 80 1100 1100]);

% PANEL 1 - Instantaneous free surface
subplot(4,1,1);
% Original bathymetry
plot(x_original,bottom_original,'k-','LineWidth',1.5);
hold on;

plot(x_zeta_original,zeta_inst_original,'b','LineWidth',1.2);                       % Instantaneous zeta at the time of max(MSL)
plot(x_zeta_original,zeta_inst_str,'-.','Color',[0.13 0.55 0.13],'LineWidth',1.0);  % Instantaneous zeta at the start of averaging window
plot(x_zeta_original,zeta_inst_end,'-.','Color',[0 0.4 0],'LineWidth',1.0);         % Instantaneous zeta at the end of averaging window

% >>>>> [U8] ADDED (usasso): panel 1 - max run-up line, point and label
plot(x_max_runup,max_runup,'ro','MarkerFaceColor','r', ...
    'HandleVisibility','off');
yline(max_runup,'r--','HandleVisibility','off');
text(x_max_runup + 1,max_runup,{'max run-up',sprintf('%.2f m',max_runup)}, ...
    'Color','r','VerticalAlignment','top');
% <<<<< END [U8] - back to Moein's code

ylabel('Elevation [m]');

legend( ...
    'Topography', ...
    '\eta at t=648.0 s', ...
    '\eta at t=401.4 s', ...
    '\eta at t=936.0 s', ...
    'Location','southwest', ...
    'FontSize',10);

% Add a specific tick while preserving existing ticks
% yticks(sort(unique([ax.YTick, 8.0])));

title(sprintf( ...
    'Instantaneous free surface (maximum run-up: t = %.2f s)', ...
    time_inst_original));

% PANEL 2- Mean Sea Level
subplot(4,1,2);

% >>>>> [U9] ADDED (usasso): panel 2
plot(x_original,bottom_original,'k-','LineWidth',1.5);
hold on;
% <<<<< END [U9] - back to Moein's code

plot(x_original,MSL_original,'b','LineWidth',1.2);

% >>>>> ADDED (usasso): panel 2 - mean +/- 1 std, maximum, profile, max run-up
plot(x_original,MSL_original + std_sea_level,'b--','LineWidth',1.0);   % mean + 1 std
plot(x_original,MSL_original - std_sea_level,'b--','LineWidth',1.0, ...
    'HandleVisibility','off');                                         % mean - 1 std (one legend entry)
plot(x_max_runup,max_runup,'ro','MarkerFaceColor','r', ...
    'HandleVisibility','off');                                         % maximum run-up
text(x_max_runup + 1,max_runup,{'max run-up',sprintf('%.2f m',max_runup)}, ...
    'Color','r','VerticalAlignment','top');                            % label next to the point
% <<<<< END - back to Moein's code

ylabel('Elevation [m]');

legend( ...
    'Ground (bathymetry)', ...
    'Mean sea level', ...
    'Mean sea level \pm 1 std', ...
    'Location','best', ...
    'FontSize',10);

% Moein's original:
title(sprintf('Mean sea level'));

% PANEL 3 - Hm0

subplot(4,1,3);
plot(x_original,Hs_original,'b','LineWidth',1.2);

ylabel('H_{s} [m]');

legend( ...
    'Calculated from CROCO outputs', ...
    'Location','southwest', ...
    'FontSize',10);

title(sprintf('Significant Wave Height H_{s}'));

% PANEL 4 - Undertow
subplot(4,1,4);

plot(x_u_original,undertow_original,'b','LineWidth',1.2);

% >>>>> ADDED (usasso): panel 4 - mean +/- 1 std, profile, vertical lines
hold on;
plot(x_u_original,undertow_original + std_undertow,'b--','LineWidth',1.0);    % mean + 1 std
plot(x_u_original,undertow_original - std_undertow,'b--','LineWidth',1.0, ...
    'HandleVisibility','off');                                                % mean - 1 std

% <<<<< END [U11] - back to Moein's code

% Position references instead of the ground (only one y axis: velocity)
xline(x_shoreline,'k:','ground: 0m','HandleVisibility','off');
xline(x_max_runup,'k:','max run-up','HandleVisibility','off');

ylabel('Velocity [m/s]');

xlabel('Cross-shore distance [m]');

legend( ...
    'Mean', ...
    'Mean \pm 1 std', ...
    'Location','southwest', ...
    'FontSize',10);
% >>>>> ADDED [M] (MoeinDst): no longer calling it undertow, as it really
%                             is not! near-bed velocity is more accurate.

title(sprintf('Near-bed velocity (negative: seaward)'));


% COMMON AXES

for k = 1:4

    ax = subplot(4,1,k);
    grid(ax,'on');
    xlim(ax,xlimits);
    ylim(ax,ylimits{k});

end


sgtitle(sprintf( ...
    ['Bonassola_JONSWAP_TR5y_dx40cm ' ...
     '(t_start = %.1f, t_end = %.1f)'], ...
    t_start, t_end), ...
    'Interpreter', 'none');


fprintf('\n============================================================\n');
fprintf('RUN-UP (elevation above still water level)\n');
fprintf('  maximum            : %.2f m (x = %.1f m, t = %.2f s)\n', ...
    max_runup, x_max_runup, time_max_runup);
fprintf('UNDERTOW (near-bed velocity, negative = offshore)\n');
fprintf('  strongest          : %.2f m/s (x = %.1f m, t = %.2f s)\n', ...
    strongest_undertow_value, x_strongest_undertow, time_strongest_undertow);
fprintf('============================================================\n');

% >>>>> [U13] ADDED (usasso): save the figure in the folder figs
% figs_folder = fullfile(swash_folder, 'post_processing_scripts', 'figs');
% if not(isfolder(figs_folder))
%     mkdir(figs_folder);    % create the folder the first time
% end
% figure_file = fullfile(figs_folder, [run_name '_4panel_usasso.png']);
% exportgraphics(f1, figure_file, 'Resolution', 300);
% fprintf('Figure saved: %s\n', figure_file);
% <<<<< END [U13]
