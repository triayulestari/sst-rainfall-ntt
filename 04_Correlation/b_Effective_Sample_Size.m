%% =========================================================
% 02_Autocorrelation_EffectiveN.m
%
% AUTOCORRELATION-ADJUSTED SIGNIFICANCE
% Monthly deseasonalized SST vs rainfall anomalies
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Period:
%   January 2016 - December 2025
%
% Input:
%   ..\3-Timeseries\regional_timeseries_anomaly.mat
%
% Output:
%   autocorrelation_effectiveN.mat
%   autocorrelation_effectiveN.csv
%
% Method:
%   1. Calculate zero-lag Pearson correlation
%   2. Calculate lag-1 autocorrelation of SST anomaly
%   3. Calculate lag-1 autocorrelation of rainfall anomaly
%   4. Estimate effective sample size (Neff)
%   5. Recalculate correlation significance using Neff
%
% NOTE:
%   Missing SST months are NOT interpolated.
%   Lag-1 autocorrelation only uses consecutive valid pairs.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD DESEASONALIZED ANOMALIES
%% =========================================================

load('..\3-Timeseries\regional_timeseries_anomaly.mat',...
    'time',...
    'anom_sst_flores',...
    'anom_sst_sumba',...
    'anom_sst_timor',...
    'anom_prec_flores',...
    'anom_prec_sumba',...
    'anom_prec_timor');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('AUTOCORRELATION AND EFFECTIVE SAMPLE SIZE\n')
fprintf('=========================================================\n')

fprintf('Period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));


%% =========================================================
% 2. ZERO-LAG CORRELATION - FLORES
%% =========================================================

valid_F = ...
    ~isnan(anom_sst_flores) & ...
    ~isnan(anom_prec_flores);

xF = anom_sst_flores(valid_F);
yF = anom_prec_flores(valid_F);

n_F = length(xF);

[r_F,p_F] = corr(...
    xF,...
    yF,...
    'Type','Pearson');


%% =========================================================
% 3. ZERO-LAG CORRELATION - SUMBA
%% =========================================================

valid_S = ...
    ~isnan(anom_sst_sumba) & ...
    ~isnan(anom_prec_sumba);

xS = anom_sst_sumba(valid_S);
yS = anom_prec_sumba(valid_S);

n_S = length(xS);

[r_S,p_S] = corr(...
    xS,...
    yS,...
    'Type','Pearson');


%% =========================================================
% 4. ZERO-LAG CORRELATION - TIMOR
%% =========================================================

valid_T = ...
    ~isnan(anom_sst_timor) & ...
    ~isnan(anom_prec_timor);

xT = anom_sst_timor(valid_T);
yT = anom_prec_timor(valid_T);

n_T = length(xT);

[r_T,p_T] = corr(...
    xT,...
    yT,...
    'Type','Pearson');


%% =========================================================
% 5. LAG-1 AUTOCORRELATION - FLORES SST
%
% IMPORTANT:
% Only consecutive valid months are paired.
% This avoids bridging across Oct-Nov 2025 missing SST.
%% =========================================================

x1 = anom_sst_flores(1:end-1);
x2 = anom_sst_flores(2:end);

valid = ~isnan(x1) & ~isnan(x2);

r1_sst_F = corr(...
    x1(valid),...
    x2(valid),...
    'Type','Pearson');

nlag_sst_F = sum(valid);


%% =========================================================
% 6. LAG-1 AUTOCORRELATION - FLORES RAINFALL
%% =========================================================

y1 = anom_prec_flores(1:end-1);
y2 = anom_prec_flores(2:end);

valid = ~isnan(y1) & ~isnan(y2);

r1_prec_F = corr(...
    y1(valid),...
    y2(valid),...
    'Type','Pearson');

nlag_prec_F = sum(valid);


%% =========================================================
% 7. LAG-1 AUTOCORRELATION - SUMBA SST
%% =========================================================

x1 = anom_sst_sumba(1:end-1);
x2 = anom_sst_sumba(2:end);

valid = ~isnan(x1) & ~isnan(x2);

r1_sst_S = corr(...
    x1(valid),...
    x2(valid),...
    'Type','Pearson');

nlag_sst_S = sum(valid);


%% =========================================================
% 8. LAG-1 AUTOCORRELATION - SUMBA RAINFALL
%% =========================================================

y1 = anom_prec_sumba(1:end-1);
y2 = anom_prec_sumba(2:end);

valid = ~isnan(y1) & ~isnan(y2);

r1_prec_S = corr(...
    y1(valid),...
    y2(valid),...
    'Type','Pearson');

nlag_prec_S = sum(valid);


%% =========================================================
% 9. LAG-1 AUTOCORRELATION - TIMOR SST
%% =========================================================

x1 = anom_sst_timor(1:end-1);
x2 = anom_sst_timor(2:end);

valid = ~isnan(x1) & ~isnan(x2);

r1_sst_T = corr(...
    x1(valid),...
    x2(valid),...
    'Type','Pearson');

nlag_sst_T = sum(valid);


%% =========================================================
% 10. LAG-1 AUTOCORRELATION - TIMOR RAINFALL
%% =========================================================

y1 = anom_prec_timor(1:end-1);
y2 = anom_prec_timor(2:end);

valid = ~isnan(y1) & ~isnan(y2);

r1_prec_T = corr(...
    y1(valid),...
    y2(valid),...
    'Type','Pearson');

nlag_prec_T = sum(valid);


%% =========================================================
% 11. EFFECTIVE SAMPLE SIZE
%
% Neff = N * (1 - r1x*r1y) / (1 + r1x*r1y)
%% =========================================================

Neff_F = n_F * ...
    (1 - r1_sst_F*r1_prec_F) / ...
    (1 + r1_sst_F*r1_prec_F);

Neff_S = n_S * ...
    (1 - r1_sst_S*r1_prec_S) / ...
    (1 + r1_sst_S*r1_prec_S);

Neff_T = n_T * ...
    (1 - r1_sst_T*r1_prec_T) / ...
    (1 + r1_sst_T*r1_prec_T);


%% =========================================================
% 12. CONSERVATIVE BOUNDS
%
% Neff should not exceed original N and must remain > 2.
%% =========================================================

Neff_F = min(Neff_F,n_F);
Neff_S = min(Neff_S,n_S);
Neff_T = min(Neff_T,n_T);

Neff_F = max(Neff_F,3);
Neff_S = max(Neff_S,3);
Neff_T = max(Neff_T,3);


%% =========================================================
% 13. ADJUSTED SIGNIFICANCE
%
% t = r * sqrt((Neff-2)/(1-r^2))
%
% df = Neff - 2
%% =========================================================

df_F = Neff_F - 2;

t_F = r_F * ...
    sqrt(df_F / (1-r_F^2));

p_adj_F = 2 * ...
    (1 - tcdf(abs(t_F),df_F));


df_S = Neff_S - 2;

t_S = r_S * ...
    sqrt(df_S / (1-r_S^2));

p_adj_S = 2 * ...
    (1 - tcdf(abs(t_S),df_S));


df_T = Neff_T - 2;

t_T = r_T * ...
    sqrt(df_T / (1-r_T^2));

p_adj_T = 2 * ...
    (1 - tcdf(abs(t_T),df_T));


%% =========================================================
% 14. DISPLAY LAG-1 AUTOCORRELATION
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('LAG-1 AUTOCORRELATION\n')
fprintf('=========================================================\n')

fprintf('\n')
fprintf('Region      SST r1      Rain r1     SST pairs   Rain pairs\n')
fprintf('-----------------------------------------------------------\n')

fprintf('Flores     %+0.4f      %+0.4f       %3d          %3d\n',...
    r1_sst_F,...
    r1_prec_F,...
    nlag_sst_F,...
    nlag_prec_F);

fprintf('Sumba      %+0.4f      %+0.4f       %3d          %3d\n',...
    r1_sst_S,...
    r1_prec_S,...
    nlag_sst_S,...
    nlag_prec_S);

fprintf('Timor      %+0.4f      %+0.4f       %3d          %3d\n',...
    r1_sst_T,...
    r1_prec_T,...
    nlag_sst_T,...
    nlag_prec_T);


%% =========================================================
% 15. DISPLAY EFFECTIVE N RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('AUTOCORRELATION-ADJUSTED ZERO-LAG CORRELATION\n')
fprintf('=========================================================\n')

fprintf('\n')
fprintf('Region       r       n      Neff     p(raw)    p(adjusted)\n')
fprintf('-----------------------------------------------------------\n')

fprintf('Flores    %+0.4f   %3d    %6.1f    %.4f      %.4f\n',...
    r_F,...
    n_F,...
    Neff_F,...
    p_F,...
    p_adj_F);

fprintf('Sumba     %+0.4f   %3d    %6.1f    %.4f      %.4f\n',...
    r_S,...
    n_S,...
    Neff_S,...
    p_S,...
    p_adj_S);

fprintf('Timor     %+0.4f   %3d    %6.1f    %.4f      %.4f\n',...
    r_T,...
    n_T,...
    Neff_T,...
    p_T,...
    p_adj_T);


%% =========================================================
% 16. SAMPLE-SIZE REDUCTION
%% =========================================================

reduction_F = ...
    100 * (1 - Neff_F/n_F);

reduction_S = ...
    100 * (1 - Neff_S/n_S);

reduction_T = ...
    100 * (1 - Neff_T/n_T);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('EFFECTIVE SAMPLE SIZE REDUCTION\n')
fprintf('=========================================================\n')

fprintf('Flores : %.1f %%\n',reduction_F);
fprintf('Sumba  : %.1f %%\n',reduction_S);
fprintf('Timor  : %.1f %%\n',reduction_T);


%% =========================================================
% 17. INTERPRETATION CHECK
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SIGNIFICANCE AFTER AUTOCORRELATION ADJUSTMENT\n')
fprintf('=========================================================\n')


if p_adj_F < 0.05
    status_F = 'significant';
else
    status_F = 'not significant';
end


if p_adj_S < 0.05
    status_S = 'significant';
else
    status_S = 'not significant';
end


if p_adj_T < 0.05
    status_T = 'significant';
else
    status_T = 'not significant';
end


fprintf('Flores : %s (p = %.4f)\n',...
    status_F,...
    p_adj_F);

fprintf('Sumba  : %s (p = %.4f)\n',...
    status_S,...
    p_adj_S);

fprintf('Timor  : %s (p = %.4f)\n',...
    status_T,...
    p_adj_T);


%% =========================================================
% 18. CREATE RESULT TABLE
%% =========================================================

Region = {...
    'Flores';...
    'Sumba';...
    'Timor'};


Pearson_r = [...
    r_F;...
    r_S;...
    r_T];


N_original = [...
    n_F;...
    n_S;...
    n_T];


SST_lag1 = [...
    r1_sst_F;...
    r1_sst_S;...
    r1_sst_T];


Rain_lag1 = [...
    r1_prec_F;...
    r1_prec_S;...
    r1_prec_T];


N_effective = [...
    Neff_F;...
    Neff_S;...
    Neff_T];


p_raw = [...
    p_F;...
    p_S;...
    p_T];


p_adjusted = [...
    p_adj_F;...
    p_adj_S;...
    p_adj_T];


Reduction_percent = [...
    reduction_F;...
    reduction_S;...
    reduction_T];


ResultTable = table(...
    Region,...
    Pearson_r,...
    N_original,...
    SST_lag1,...
    Rain_lag1,...
    N_effective,...
    Reduction_percent,...
    p_raw,...
    p_adjusted,...
    'VariableNames',{...
    'Region',...
    'Pearson_r',...
    'N_original',...
    'SST_lag1',...
    'Rain_lag1',...
    'N_effective',...
    'N_reduction_percent',...
    'p_raw',...
    'p_autocorr_adjusted'});


%% =========================================================
% 19. DISPLAY RESULT TABLE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL RESULT TABLE\n')
fprintf('=========================================================\n')

disp(ResultTable)


%% =========================================================
% 20. SAVE OUTPUT
%% =========================================================

save(...
    'autocorrelation_effectiveN.mat',...
    'r_F','p_F','n_F',...
    'r_S','p_S','n_S',...
    'r_T','p_T','n_T',...
    'r1_sst_F','r1_prec_F',...
    'r1_sst_S','r1_prec_S',...
    'r1_sst_T','r1_prec_T',...
    'Neff_F','Neff_S','Neff_T',...
    'p_adj_F','p_adj_S','p_adj_T',...
    'ResultTable');


writetable(...
    ResultTable,...
    'autocorrelation_effectiveN.csv');


%% =========================================================
% 21. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('AUTOCORRELATION ANALYSIS COMPLETED\n')
fprintf('=========================================================\n')

fprintf('\nFiles saved:\n')
fprintf('1. autocorrelation_effectiveN.mat\n')
fprintf('2. autocorrelation_effectiveN.csv\n')

fprintf('\nIMPORTANT:\n')
fprintf('Pearson r itself does NOT change.\n')
fprintf('Only the effective sample size and significance are adjusted.\n')

fprintf('\nNext step:\n')
fprintf('Seasonal correlation analysis (DJF, MAM, JJA, SON).\n')