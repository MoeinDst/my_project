%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREP_ZAVG_WETDRY
%
% Prepare wet-only surface-elevation statistics from a CROCO history file.
% Uses the legacy CROCOTOOLS netcdf interface (as in original prep_zavg.m).
% Requires the same start.m / MATLAB paths as the original script.
%
% Output is in NATIVE CROCO units; NO downscaling is performed here.
% MSL_high = mean(zeta | wet)
% Hs_high  = 4*sqrt(mean(zeta^2 | wet) - MSL_high^2)
%
% The conditional wet-only statistics are not conventional shoreline
% wave statistics at intermittently inundated cells.
%
% ------ MoeinDst, 10/2026 ------
%
% ** AI disclaimer:
% PArt of the code that accounts for the wetting/drying scheme is mainly
% written by ChatGPT, and only then human-checked for functionality.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
tic;

%% 1. FILE PATHS
hisfile = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/croco_output/' ...
    'swash2DV_dx1cm_A2JONSWAP/Output/swash_his_A2.nc'];

outfile = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/output_dataMat/' ...
    '/swash2DV_dx1cm_A2JONSWAP/swash2DV_dx1cm_A2JONSWAP_zeta_avg_wetdry_adjusted.mat'];

%% 2. SETTINGS
yindex = 2;
% lambda_T = 4.5;
lambda_T = 1.0;
% t_start = 89.2;
% t_end   = 208.0;
t_start = 57.4;
t_end   = 176.2;
use_last_record_for_snapshot = false;
% Requested snapshot time (native CROCO time)
snapshot_target_time = t_end;
progress_interval = 100;

%% 3. OPEN FILE AND READ GRID / TIME
tic
fprintf('\n============================================================\n');
fprintf('PREP_ZAVG_WETDRY\n');
fprintf('History: %s\nOutput:  %s\n',hisfile,outfile);
fprintf('Requested averaging interval: %.4f - %.4f s\n',t_start,t_end);
fprintf('y-index: %d\n',yindex);

nc = netcdf(hisfile);
x = double(squeeze(nc{'x_rho'}(yindex,:)));
x = x(:);
hr = double(squeeze(nc{'h'}(yindex,:)));
hr = hr(:);
time = double(nc{'scrum_time'}(:));
time = time(:);
Dcrit = double(nc{'Dcrit'}(:));
if isempty(Dcrit) || ~isscalar(Dcrit) || ~isfinite(Dcrit)
    close(nc);
    error('Dcrit must be a finite scalar in the history file.');
end

nx = numel(x);
if numel(hr) ~= nx || isempty(time)
    close(nc);
    error('Inconsistent x, h, or time dimensions.');
end

% Match original plot_swash.m:
% Dcrit = Dcrit + 1.e-6;
% ztop(D < Dcrit + 0.01) = NaN;
wet_threshold = Dcrit + 1.e-6 + 0.01;

fprintf('Grid points: %d; history records: %d\n',nx,numel(time));
fprintf('Dcrit = %.8g m; wet threshold = %.8g m\n',Dcrit,wet_threshold);
toc

%% 4. SELECT TIME WINDOW
i1 = find(time >= t_start,1,'first');
i2 = find(time <= t_end,1,'last');
if isempty(i1) || isempty(i2) || i2 < i1
    close(nc);
    error('No valid history records in requested interval %.4f - %.4f s.',t_start,t_end);
end
nrec = i2-i1+1;
time_start_actual = time(i1);
time_end_actual = time(i2);
fprintf('Actual interval: %.4f - %.4f s (%d records)\n', ...
    time_start_actual,time_end_actual,nrec);

%% 5. ACCUMULATE WET-ONLY FIRST AND SECOND MOMENTS
tic
zeta_sum  = zeros(nx,1);
zeta_sum2 = zeros(nx,1);
wet_count = zeros(nx,1);

for it = i1:i2
    zeta_profile = double(squeeze(nc{'zeta'}(it,yindex,:)));
    zeta_profile = zeta_profile(:);
    if numel(zeta_profile) ~= nx
        close(nc);
        error('zeta dimension mismatch at record %d.',it);
    end

    D = hr + zeta_profile;
    wet = isfinite(hr) & isfinite(zeta_profile) & ...
          isfinite(D) & (D >= wet_threshold);

    zeta_sum(wet)  = zeta_sum(wet)  + zeta_profile(wet);
    zeta_sum2(wet) = zeta_sum2(wet) + zeta_profile(wet).^2;
    wet_count(wet) = wet_count(wet) + 1;

    if mod(it-i1+1,progress_interval) == 0 || it == i2
        fprintf('zeta processed: %d / %d records\n',it-i1+1,nrec);
    end
end

toc

%% 6. CALCULATE CONDITIONAL WET-ONLY STATISTICS
MSL_high = NaN(nx,1);
zeta_variance = NaN(nx,1);
Hs_high = NaN(nx,1);
wet_fraction = wet_count / nrec;
valid = wet_count > 0;

MSL_high(valid) = zeta_sum(valid) ./ wet_count(valid);
zeta_variance(valid) = zeta_sum2(valid) ./ wet_count(valid) ...
                       - MSL_high(valid).^2;
zeta_variance(valid) = max(zeta_variance(valid),0);
Hs_high(valid) = 4 * sqrt(zeta_variance(valid));

%% 7. INSTANTANEOUS SNAPSHOT
if use_last_record_for_snapshot
    snapshot_index = numel(time);
else
    % Find record closest to requested time
    [~, snapshot_index] = min(abs(time - snapshot_target_time));
end
snapshot_time = time(snapshot_index);
zeta_snapshot = double(squeeze(nc{'zeta'}(snapshot_index,yindex,:)));
zeta_snapshot = zeta_snapshot(:);
D_snapshot = hr + zeta_snapshot;
snapshot_wet = isfinite(hr) & isfinite(zeta_snapshot) & ...
               isfinite(D_snapshot) & (D_snapshot >= wet_threshold);
zeta_snapshot(~snapshot_wet) = NaN;

%% 8. CLOSE FILE
close(nc);

%% 9. SAVE (NEW FILE; ORIGINAL UNCHANGED)
save(outfile, ...
    'x','hr','zeta_snapshot','snapshot_time', ...
    'Hs_high','MSL_high', ...
    'wet_count','wet_fraction','wet_threshold','Dcrit', ...
    't_start','t_end','time_start_actual','time_end_actual', ...
    'nrec','snapshot_index','yindex','lambda_T', ...
    '-v7.3');

%% 10. DIAGNOSTICS
fprintf('\n============================================================\n');
fprintf('PREP_ZAVG_WETDRY COMPLETE\n');
fprintf('Saved: %s\n',outfile);
fprintf('Wet at least once: %d / %d grid points\n',nnz(valid),nx);
fprintf('Always wet:       %d / %d grid points\n',nnz(wet_count == nrec),nx);
fprintf('Never wet:        %d / %d grid points\n',nnz(wet_count == 0),nx);
fprintf('Partially wet:    %d / %d grid points\n', ...
    nnz(wet_count > 0 & wet_count < nrec),nx);
fprintf('Snapshot: record %d at %.4f s; wet cells %d / %d\n', ...
    snapshot_index,snapshot_time,nnz(snapshot_wet),nx);
fprintf('All outputs remain in native model units.\n');
fprintf('============================================================\n');
toc;
