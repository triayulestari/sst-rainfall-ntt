%% ========================================================================
% c_lagged_correlation.m
% MONTHLY DESEASONALIZED SST-RAINFALL LAG CORRELATION | NTT 2016-2025
%
% MATLAB R2021a; requires Statistics and Machine Learning Toolbox.
% Save in: Data/03_Monthly_and_Lagged/
% Input:   ../02_Regional_Timeseries/regional_anomalies.mat
% Outputs (same folder as script):
%   lagged_correlation_results.csv
%   lagged_correlation_results.mat
%
% Lag convention:
%   lag +k: corr(SST(t),Rain(t+k))    SST leads rainfall
%   lag -k: corr(SST(t+k),Rain(t))    rainfall leads SST
%   lag  0: concurrent relationship
%
% Primary inference: BH-FDR correction of autocorrelation-adjusted p-values
% over ALL 39 region-lag tests (3 regions x 13 lags [-6,+6]).
% Secondary, clearly separated sensitivity: BH-FDR for 21 tests [0,+6].
% Lag-1 autocorrelations calculated on each UNCOMPRESSED ALIGNED time vector.
% Oct-Nov 2025 missing SST months are not filled or joined across gaps.
% Neither correlations nor leads establish prediction or causation.
%% ========================================================================
clc;
clear;

%% 1. Resolve path and validate input
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this script as c_lagged_correlation.m before running.');
end
out_dir = fileparts(script_file);
data_dir = fileparts(out_dir);
input_file = fullfile(data_dir,'02_Regional_Timeseries','regional_anomalies.mat');
if ~isfile(input_file)
    error('Input not found: %s',input_file);
end
D = load(input_file);
required = {'time','SST_deseason','RAIN_deseason'};
for k = 1:numel(required)
    if ~isfield(D,required{k})
        error('Missing input variable: %s',required{k});
    end
end
if ~isdatetime(D.time) || numel(D.time)~=120 || ...
        ~isequal(size(D.SST_deseason),[120,3]) || ...
        ~isequal(size(D.RAIN_deseason),[120,3])
    error('Expected datetime time and [120 x 3] deseasonalized arrays.');
end
expected_time = datetime(2016,1,1)+calmonths((0:119)');
if ~all(D.time(:)==expected_time)
    error('Time positions are not consecutive Jan 2016 to Dec 2025.');
end

%% 2. Allocate exactly 39 tests (Flores, Sumba, Timor; each lag -6 to +6)
regions = {'Flores','Sumba','Timor'};
lags = (-6:6)';
nLag = numel(lags);
nTest = 3*nLag;
Region = cell(nTest,1);
Lag_month = NaN(nTest,1);
Direction = cell(nTest,1);
N = NaN(nTest,1);
Pearson_r = NaN(nTest,1);
p_raw = NaN(nTest,1);
SST_lag1 = NaN(nTest,1);
Rain_lag1 = NaN(nTest,1);
SST_adjacent_pairs = NaN(nTest,1);
Rain_adjacent_pairs = NaN(nTest,1);
N_effective = NaN(nTest,1);
p_autocorr_adjusted = NaN(nTest,1);

%% 3. All regions and lags
row = 0;
for ir = 1:3
    sst = D.SST_deseason(:,ir);
    rain = D.RAIN_deseason(:,ir);
    for il = 1:nLag
        row = row+1;
        L = lags(il);
        Region{row} = regions{ir};
        Lag_month(row) = L;
        if L > 0
            Direction{row} = 'SST leads rainfall';
            x_raw = sst(1:end-L);
            y_raw = rain(1+L:end);
        elseif L < 0
            Direction{row} = 'Rainfall leads SST';
            K = -L;
            x_raw = sst(1+K:end);
            y_raw = rain(1:end-K);
        else
            Direction{row} = 'Concurrent';
            x_raw = sst;
            y_raw = rain;
        end

        % Use pairwise valid months only for r. Do NOT compress x_raw/y_raw
        % before lag-1 autocorrelation, as doing so bridges missing months.
        valid_pair = isfinite(x_raw) & isfinite(y_raw);
        n = sum(valid_pair);
        N(row) = n;
        if n < 4
            error('Too few data pairs for %s, lag %+d.',Region{row},L);
        end
        [Pearson_r(row),p_raw(row)] = corr(x_raw(valid_pair), ...
            y_raw(valid_pair),'Type','Pearson');

        valid_x1 = isfinite(x_raw(1:end-1)) & isfinite(x_raw(2:end));
        valid_y1 = isfinite(y_raw(1:end-1)) & isfinite(y_raw(2:end));
        SST_adjacent_pairs(row) = sum(valid_x1);
        Rain_adjacent_pairs(row) = sum(valid_y1);
        if sum(valid_x1) < 3 || sum(valid_y1) < 3
            error('Insufficient adjacent pairs for %s lag %+d.',Region{row},L);
        end
        idx_x = find(valid_x1);
        idx_y = find(valid_y1);
        SST_lag1(row) = corr(x_raw(idx_x),x_raw(idx_x+1),'Type','Pearson');
        Rain_lag1(row) = corr(y_raw(idx_y),y_raw(idx_y+1),'Type','Pearson');

        rho_prod = SST_lag1(row)*Rain_lag1(row);
        if ~isfinite(rho_prod) || (1+rho_prod)<=0
            error('Invalid lag-1 autocorrelation at %s lag %+d.',Region{row},L);
        end
        neff = n*(1-rho_prod)/(1+rho_prod);
        neff = max(3,min(n,neff));
        N_effective(row) = neff;
        df = neff - 2;
        r0 = Pearson_r(row);
        if abs(r0)>=1
            p_autocorr_adjusted(row) = 0;
        else
            tstat = r0*sqrt(df/(1-r0^2));
            p_autocorr_adjusted(row) = 2*tcdf(-abs(tstat),df);
        end
    end
end

%% 4. Primary BH-FDR: 39 tests for both positive and negative lags
if any(~isfinite(p_autocorr_adjusted)) || ...
        any(p_autocorr_adjusted<0 | p_autocorr_adjusted>1)
    error('Invalid adjusted p-values; cannot apply BH-FDR.');
end
[ps,order] = sort(p_autocorr_adjusted);
qsorted = ps * nTest ./ (1:nTest)';
for i = nTest-1:-1:1
    qsorted(i) = min(qsorted(i),qsorted(i+1));
end
qsorted = min(1,qsorted);
q_FDR_all39 = NaN(nTest,1);
q_FDR_all39(order) = qsorted;

%% 5. Secondary FDR: nonnegative lags 0 through +6 (21 tests)
pos = Lag_month>=0;
np = sum(pos);
[pps,porder] = sort(p_autocorr_adjusted(pos));
qpos_sorted = pps*np./(1:np)';
for i = np-1:-1:1
    qpos_sorted(i) = min(qpos_sorted(i),qpos_sorted(i+1));
end
qpos_sorted = min(1,qpos_sorted);
qpos = NaN(np,1);
qpos(porder) = qpos_sorted;
q_FDR_lag0_to_plus6 = NaN(nTest,1);
q_FDR_lag0_to_plus6(pos) = qpos;

%% 6. Classify results based only on primary q across all 39 tests
FDR_status_all39 = repmat({'q>=0.10'},nTest,1);
mask_suggestive = (q_FDR_all39>=0.05 & q_FDR_all39<0.10);
mask_retained = q_FDR_all39<0.05;
FDR_status_all39(mask_suggestive) = ...
    repmat({'0.05<=q<0.10 (suggestive)'},sum(mask_suggestive),1);
FDR_status_all39(mask_retained) = ...
    repmat({'q<0.05 (FDR-retained)'},sum(mask_retained),1);

%% 7. Save reproducible outputs
Results = table(Region,Lag_month,Direction,N,Pearson_r, ...
    SST_lag1,Rain_lag1,N_effective,p_raw,p_autocorr_adjusted, ...
    q_FDR_all39,q_FDR_lag0_to_plus6,FDR_status_all39, ...
    SST_adjacent_pairs,Rain_adjacent_pairs);
writetable(Results,fullfile(out_dir,'lagged_correlation_results.csv'));
save(fullfile(out_dir,'lagged_correlation_results.mat'), ...
    'Results','lags','Region','Lag_month','N','Pearson_r','p_raw', ...
    'SST_lag1','Rain_lag1','N_effective','p_autocorr_adjusted', ...
    'q_FDR_all39','q_FDR_lag0_to_plus6','FDR_status_all39');

%% 8. QC summary
fprintf('\n===== MONTHLY LAG CORRELATION QC =====\n');
fprintf('Lags: -6 to +6 | 3 regions | primary BH-FDR: %d tests\n',nTest);
fprintf('Secondary BH-FDR: %d tests (lag 0 through +6)\n',np);
for ir = 1:3
    rows = (ir-1)*nLag+(1:nLag);
    positive_rows = rows(Lag_month(rows)>=0);
    [~,iBest] = min(p_autocorr_adjusted(positive_rows));
    jj = positive_rows(iBest);
    fprintf('%-6s: +lag strongest adjusted-p = %+d months; r=%+.4f; p=%.4f; q39=%.4f\n', ...
        regions{ir},Lag_month(jj),Pearson_r(jj), ...
        p_autocorr_adjusted(jj),q_FDR_all39(jj));
end
fprintf('Tests with q39<0.05: %d\n',sum(q_FDR_all39<0.05));
fprintf('Tests with 0.05<=q39<0.10: %d\n', ...
    sum(q_FDR_all39>=0.05 & q_FDR_all39<0.10));
fprintf('Saved: lagged_correlation_results.csv/.mat\n');
fprintf('Positive lag means SST LEADS rainfall; NOT causation.\n');
