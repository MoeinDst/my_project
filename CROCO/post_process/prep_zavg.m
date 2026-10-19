%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREP_ZAVG
%
% Prepares surface-elevation statistics from a CROCO history file.
% This script also needs the `start.m` from croco-tools to read
% and create files.
%
% Extracts:
%   x               : cross-shore coordinate
%   zeta_snapshot   : instantaneous free-surface profile
%   snapshot_time   : time corresponding to zeta_snapshot
%   MSL_high        : time-averaged free-surface elevation
%   Hs_high         : variance-based wave height
%
% NOTE:
%
%   All quantities are saved in the NATIVE units of the CROCO simulation.
%
%   NO spatial, temporal, or amplitude scaling/downscaling is performed
%   here. For an upscaled simulation, the resulting MAT-file therefore
%   contains quantities on the UPSCALED model scale.
%
%   Any conversion back to the original B2/A2 scale will be performed
%   later in the plotting/comparison script.
%
%
% Wave-height definition:
%       MSL_high = <eta>
%       variance = <eta^2> - <eta>^2
%       Hs_high = 4 * sqrt(variance)
%
% ------ MoeinDst, 09/2026 ------
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ========================================================================
% 1. FILE PATHS
% =========================================================================
tic
hisfile = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/croco_output/' ...
    'real_bathy_extended_JONSWAP_TR5y_dx40cmSponge/Output/bonassola_libeccio5yr_his.nc'];

outfile = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/output_dataMat/'...
    '/real_bathy_extended_JONSWAP_TR5y_dx40cmSponge/real_bathy_extended_JONSWAP_TR5y_dx40cmSponge_zeta_avg.mat'];


%% ========================================================================
% 2. USER SETTINGS
% =========================================================================

% Cross-shore slice
yindex = 2;

% -------------------------------------------------------------------------
% Averaging interval
%
% IMPORTANT:
% These are times in the NATIVE UPSCALED simulation.
%
% The corresponding original-scale interval is:
%
%       89.2 <= t <= 208.0 s
%
% with lambda_T = 4.5.
%
% Therefore:
%
%       89.2 * 4.5 = 401.4 s
%       208.0 * 4.5 = 936.0 s
%
% -------------------------------------------------------------------------

t_start = 89.2 * 4.5;
t_end   = 208.0 * 4.5;
% t_start = 185.0;
% t_end   = 285.0;

% -------------------------------------------------------------------------
% Instantaneous zeta snapshot
%
% Use the LAST available history-file record.
%
% If you later want a snapshot at a particular time instead, this section
% can easily be changed.
% -------------------------------------------------------------------------

use_last_record_for_snapshot = true;

%% ========================================================================
% 3. PRINT SETTINGS
% =========================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('PREP_ZAVG\n');
fprintf('============================================================\n');

fprintf('History file:\n');
fprintf('    %s\n\n',hisfile);

fprintf('Output file:\n');
fprintf('    %s\n\n',outfile);

fprintf('y-index:\n');
fprintf('    %d\n\n',yindex);

fprintf('Native-model averaging interval:\n');
fprintf('    %.4f - %.4f s\n',t_start,t_end);

fprintf('============================================================\n\n');


%% ========================================================================
% 4. Open CROCO his and read x-ccordinate and native time,
% =========================================================================
tic

nc = netcdf(hisfile);

x = squeeze(nc{'x_rho'}(yindex,:));
x = double(x(:));
fprintf('Number of x points: %d\n\n',length(x));

time = nc{'scrum_time'}(:);
time = double(time(:));
fprintf('History-file time range:\n');
fprintf('    %.4f - %.4f s\n\n',time(1),time(end));

toc

%% ========================================================================
% 7. FIND RECORDS IN AVERAGING WINDOW
% =========================================================================

i1 = find(time >= t_start,1,'first');
i2 = find(time <= t_end,1,'last');

if isempty(i1) || isempty(i2)

    error(['Requested averaging interval %.3f - %.3f s is outside ' ...
           'the history-file time range %.3f - %.3f s.'], ...
           t_start,t_end,time(1),time(end));

end

if i2 < i1

    error('Invalid averaging interval.');

end

nrec = i2-i1+1;

fprintf('ZETA AVERAGING\n');
fprintf('------------------------------------------------------------\n');

fprintf('First record : %d\n',i1);
fprintf('Last record  : %d\n',i2);
fprintf('Records      : %d\n',nrec);
fprintf('\nActual averaging interval:\n');
fprintf('    %.4f - %.4f s\n\n',time(i1),time(i2));

%% ========================================================================
% 8. CALCULATE MSL AND Hs
%
% Accumulate:
%
%       sum(eta)
%       sum(eta^2)
%
% so the entire zeta(time,y,x) array does not need to be loaded into
% memory.
%
% EVERYTHING REMAINS IN NATIVE MODEL UNITS.
% =========================================================================
tic

nx = length(x);
% Allocate accumulation arrays
zeta_sum  = zeros(nx,1);
zeta_sum2 = zeros(nx,1);
fprintf('Reading history-file zeta...\n\n');

for it = i1:i2

    % Read one zeta profile
    zeta_profile = squeeze( ...
        nc{'zeta'}(it,yindex,:) );
    zeta_profile = double(zeta_profile(:));

    % Accumulate first and second moments
    zeta_sum = zeta_sum + zeta_profile;
    zeta_sum2 = zeta_sum2 + zeta_profile.^2;

    % Progress information

    if mod(it-i1+1,100) == 0 || it == i2

        fprintf('zeta processed: %d / %d records\n', ...
            it-i1+1,nrec);

    end

end


% MEAN SEA LEVEL
MSL_high = zeta_sum / nrec;

% ZETA VARIANCE
zeta_variance = zeta_sum2/nrec - MSL_high.^2;
% Protect against tiny negative values caused by floating-point roundoff
zeta_variance(zeta_variance < 0) = 0;

toc

%% ========================================================================
% 11. VARIANCE-BASED WAVE HEIGHT
%
%       Hs = 4 * sqrt(m0)
%
% with m0 represented by the variance of surface elevation.
% =========================================================================

Hs_high = 4*sqrt(zeta_variance);
fprintf('\nMSL and Hs calculation complete.\n');

%% ========================================================================
% 12. EXTRACT INSTANTANEOUS ZETA SNAPSHOT
%
% By default use the LAST available history-file record.
%
% The snapshot is also kept in NATIVE model units.
% =========================================================================

if use_last_record_for_snapshot
    snapshot_index = length(time);

else
    error(['No alternative snapshot-selection method has been ' ...
           'specified.']);
end

snapshot_time = time(snapshot_index);
zeta_snapshot = squeeze( ...
    nc{'zeta'}(snapshot_index,yindex,:) );
zeta_snapshot = double(zeta_snapshot(:));


fprintf('\nINSTANTANEOUS ZETA SNAPSHOT\n');
fprintf('------------------------------------------------------------\n');
fprintf('Record : %d\n',snapshot_index);
fprintf('Time   : %.4f s\n',snapshot_time);

% 13. CLOSE HISTORY FILE & CLEAN TEMPORARY VARIABLES
close(nc);

clear zeta_sum
clear zeta_sum2
clear zeta_variance
clear zeta_profile

%% ========================================================================
% 15. SAVE OUTPUT
%
% These variable names intentionally match the existing zeta-average
% files, so downstream scripts can use:
%
%     Z = load(filename, ...
%         'x','zeta_snapshot','snapshot_time','Hs_high','MSL_high');
%
% IMPORTANT:
% All saved variables are in NATIVE MODEL UNITS.
% =========================================================================

save(outfile, ...
    'x', ...
    'zeta_snapshot', ...
    'snapshot_time', ...
    'Hs_high', ...
    'MSL_high', ...
    't_start', ...
    't_end', ...
    'nrec', ...
    'snapshot_index');


%% ========================================================================
% 16. FINAL DIAGNOSTICS
% =========================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('PREP_ZAVG COMPLETE\n');
fprintf('============================================================\n');

fprintf('\nSaved:\n');
fprintf('    %s\n',outfile);

fprintf('\nAveraging interval requested:\n');
fprintf('    %.4f - %.4f s\n',t_start,t_end);

fprintf('\nAveraging interval actually used:\n');
fprintf('    %.4f - %.4f s\n',time(i1),time(i2));

fprintf('\nNumber of averaging records:\n');
fprintf('    %d\n',nrec);

fprintf('\nSnapshot:\n');
fprintf('    record = %d\n',snapshot_index);
fprintf('    time   = %.4f s\n',snapshot_time);

fprintf('\nSaved primary variables:\n');
fprintf('    x\n');
fprintf('    zeta_snapshot\n');
fprintf('    snapshot_time\n');
fprintf('    Hs_high\n');
fprintf('    MSL_high\n');

fprintf('\nNO scaling/downscaling was performed.\n');

fprintf('============================================================\n\n');


toc