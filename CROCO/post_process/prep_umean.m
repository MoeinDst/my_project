%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script is intended to read CROCO history files(s), then create and
% save matlab structures accordingly. In cases that one may have/need
% frequent outputs from the model, history file(s) may become hundreds of
% GB making post-processing scripts somewhat time-consuming and messy. By
% saving the averages once, modifying the plots and relevant workflow turns
% quicker and more straightforward.
%
% I am dealing with both Original and Upscaled cases in the same script,
% so that I ensure consistency of the approaches and calculations
% (see `prep_zavg.m` for more details).
%
% Later we will downscale the upscaled case to the original spatio-temporal
% dimensions and values to cross-compare two cases.
%
% ------ MoeinDst, 09/2026 ------
%
% ** AI disclaimer:
% in some aprts of the code, I have consulted with
% ChatGPT to improve the performance of the code
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PREPARE TIME-AVERAGED U FOR ORIGINAL AND UPSCALED SWASH
clear; clc;

%% ========================================================================
% FILE PATHS
% =========================================================================

% u_original_matfile = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/croco_output/'...
%     'real_bathy_extended_JONSWAP_TR5y_dx40cmSponge/post_process/Bonassola2DV_JONSWAP_TR5y_dx40cmSponge_data_u.mat'];

% output_original = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/output_dataMat/'...
%     '/real_bathy_extended_JONSWAP_TR5y_dx40cmSponge/real_bathy_extended_JONSWAP_TR5y_dx40cmSponge_umean.mat'];

u_upscaled_matfile = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/croco_output/'...
    'real_bathy_extended_JONSWAP_TR1y_dx40cmSponge/post_process/real_bathy_extended_JONSWAP_TR1y_dx40cmSponge_data_u.mat'];

output_upscaled = ['/Users/moein/Desktop/WWS/GLOBEX_CROCO/matlab_scripts/output_dataMat/'...
    '/real_bathy_extended_JONSWAP_TR1y_dx40cmSponge/real_bathy_extended_JONSWAP_TR1y_dx40cmSponge_umean.mat'];


%% ========================================================================
% SETTINGS
% =========================================================================

lambda_L = 20.0;
lambda_T = 4.5;

% Original-scale averaging interval
t_start = 89.2;
t_end   = 208.0;
% t_start = 185.0;
% t_end   = 285.0;

% Number of time records loaded at once. Working
% with chunks prevents overloading of the memory.
chunk_size = 500;


%% ========================================================================
% ORIGINAL SWASH
% =========================================================================
% tic

BO = matfile(u_original_matfile);

time_u_original = BO.time;
x_u_original    = BO.x;
u_original = BO.u;
%%
% Records belonging to requested interval
i1 = find(time_u_original >= t_start,1,'first');
i2 = find(time_u_original <= t_end,1,'last');

nrec_original = i2-i1+1;

fprintf('\n============================================================\n');
fprintf('ORIGINAL SWASH\n');
fprintf('Averaging %d records\n',nrec_original);
fprintf('Requested interval: %.3f - %.3f s\n',t_start,t_end);
fprintf('Actual interval:    %.3f - %.3f s\n', ...
    time_u_original(i1),time_u_original(i2));

% Dimensions
nx = length(x_u_original);
nz = size(BO,'u',2);

fprintf('Grid dimensions: nx = %d, nz = %d\n',nx,nz);
%%
tic;
% Accumulator
u_sum = zeros(nx,nz);

for istart = i1:chunk_size:i2

    iend = min(istart + chunk_size - 1,i2);

    fprintf('Processing records %d - %d of %d\n', ...
        istart-i1+1,iend-i1+1,nrec_original);

    u_chunk = double(BO.u(:,:,istart:iend));

    u_sum = u_sum + sum(u_chunk,3);

end

u_mean_original = u_sum / nrec_original;

clear u_sum u_chunk BO

toc;
%% ========================================================================
% SAVE ORIGINAL
% =========================================================================

time_start_actual = time_u_original(i1);
time_end_actual   = time_u_original(i2);

save(output_original, ...
    'x_u_original', ...
    'u_mean_original', ...
    't_start','t_end', ...
    'time_start_actual','time_end_actual', ...
    'nrec_original', ...
    '-v7.3');

fprintf('\nSaved:\n%s\n',output_original);


%% ========================================================================
% UPSCALED SWASH
% =========================================================================
tic

BU = matfile(u_upscaled_matfile);

time_u_upscaled = BU.time;
x_u_upscaled_raw = BU.x;

% Corresponding interval in the upscaled simulation
t_start_upscaled = t_start * lambda_T;
t_end_upscaled   = t_end   * lambda_T;

i1 = find(time_u_upscaled >= t_start_upscaled,1,'first');
i2 = find(time_u_upscaled <= t_end_upscaled,1,'last');

nrec_upscaled = i2-i1+1;

fprintf('\n============================================================\n');
fprintf('UPSCALED SWASH\n');
fprintf('Averaging %d records\n',nrec_upscaled);
fprintf('Requested upscaled interval: %.3f - %.3f s\n', ...
    t_start_upscaled,t_end_upscaled);
fprintf('Actual upscaled interval:    %.3f - %.3f s\n', ...
    time_u_upscaled(i1),time_u_upscaled(i2));
fprintf('Equivalent original interval: %.3f - %.3f s\n', ...
    time_u_upscaled(i1)/lambda_T, ...
    time_u_upscaled(i2)/lambda_T);

% Dimensions
nx = length(x_u_upscaled_raw);
nz = size(BU,'u',2);

fprintf('Grid dimensions: nx = %d, nz = %d\n',nx,nz);

% Accumulator
u_sum = zeros(nx,nz);

for istart = i1:chunk_size:i2

    iend = min(istart + chunk_size - 1,i2);

    fprintf('Processing records %d - %d of %d\n', ...
        istart-i1+1,iend-i1+1,nrec_upscaled);

    u_chunk = double(BU.u(:,:,istart:iend));

    u_sum = u_sum + sum(u_chunk,3);

end

u_mean_upscaled_raw = u_sum / nrec_upscaled;

clear u_sum u_chunk BU

toc
%% ========================================================================
% SAVE UPSCALED
% =========================================================================

time_start_upscaled_actual = time_u_upscaled(i1);
time_end_upscaled_actual   = time_u_upscaled(i2);

save(output_upscaled, ...
    'x_u_upscaled_raw', ...
    'u_mean_upscaled_raw', ...
    't_start','t_end', ...
    't_start_upscaled','t_end_upscaled', ...
    'time_start_upscaled_actual','time_end_upscaled_actual', ...
    'nrec_upscaled', ...
    'lambda_L','lambda_T', ...
    '-v7.3');

fprintf('\nSaved:\n%s\n',output_upscaled);

fprintf('\n============================================================\n');
fprintf('DONE\n');
toc