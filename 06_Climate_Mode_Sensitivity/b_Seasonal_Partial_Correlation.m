%% ========================================================================
% b_seasonal_partial_correlation.m
% SEASONAL SST-RAINFALL PARTIAL CORRELATIONS | NINO 3.4 vs DMI SEPARATELY
% MATLAB R2021a
%
% INPUTS:
%   ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
%   ./climate_indices_2016_2025.mat (from script a)
%
% OUTPUTS:
%   seasonal_partial_correlation_results.csv/.mat
%   seasonal_partial_correlation_QC.csv
%
% X=SST seasonal means of deseasonalized monthly anomalies.
% Y=Rainfall seasonal means of deseasonalized monthly anomalies.
% Z=seasonal Niño 3.4 OR seasonal DMI, never both simultaneously.
% Partial r is Pearson correlation between X~(1,Z) and Y~(1,Z)
% residuals. Significance used in manuscript will come from script c,
% not unadjusted parametric p-values computed here.
%% ========================================================================
clc;
clear;

%% 1. Paths
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this script as b_seasonal_partial_correlation.m.');
end
out_dir = fileparts(script_file);
data_root = fileparts(out_dir);
season_file = fullfile(data_root,'04_Seasonal_Analysis', ...
                       'seasonal_mean_anomalies.mat');
indices_file = fullfile(out_dir,'climate_indices_2016_2025.mat');
if ~isfile(season_file) || ~isfile(indices_file)
    error('Missing seasonal means or climate indices MAT. Run script a first.');
end
S = load(season_file,'Seasonal');
C = load(indices_file,'ClimateSeasonal');
if ~isfield(S,'Seasonal') || ~isfield(C,'ClimateSeasonal')
    error('Expected Seasonal and ClimateSeasonal structs.');
end

%% 2. Prepare 12 region x season comparisons
regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};
Region = cell(12,1); Season = cell(12,1);
N = zeros(12,1); Original_r = NaN(12,1);
SST_Nino_r = NaN(12,1); Rain_Nino_r = NaN(12,1);
Partial_Nino_r = NaN(12,1); Partial_Nino_p = NaN(12,1);
SST_DMI_r = NaN(12,1); Rain_DMI_r = NaN(12,1);
Partial_DMI_r = NaN(12,1); Partial_DMI_p = NaN(12,1);
Data = struct();
row = 0;

for ir = 1:3
    for is = 1:4
        row = row+1;
        reg = regions{ir}; ss = seasons{is};
        Region{row} = reg; Season{row} = ss;
        A = S.Seasonal.(ss);
        B = C.ClimateSeasonal.(ss);
        if ~isequal(A.Year(:),B.Year(:))
            error('Mismatched season-year order in %s.',ss);
        end
        xx = double(A.SST(:,ir));
        yy = double(A.RAIN(:,ir));
        zn = double(B.Nino34(:));
        zd = double(B.DMI(:));
        yr = double(A.Year(:));
        if ~isequal(size(xx),size(yy)) || ...
           ~isequal(size(xx),size(zn)) || ...
           ~isequal(size(xx),size(zd))
            error('Seasonal data dimensions incompatible: %s %s.',reg,ss);
        end
        % Common complete-case years for both controls (matches prior QC).
        valid = isfinite(xx) & isfinite(yy) & isfinite(zn) & isfinite(zd);
        x = xx(valid); y = yy(valid); nino = zn(valid); dmi = zd(valid);
        years = yr(valid);
        n = numel(x);
        N(row) = n;
        n_expected = size(A.SST,1);
        if n~=n_expected || n<6
            error('%s %s: expected %d complete seasonal years, got %d.', ...
                  reg,ss,n_expected,n);
        end

        Original_r(row) = pearson_r(x,y);
        SST_Nino_r(row) = pearson_r(x,nino);
        Rain_Nino_r(row) = pearson_r(y,nino);
        SST_DMI_r(row) = pearson_r(x,dmi);
        Rain_DMI_r(row) = pearson_r(y,dmi);
        Partial_Nino_r(row) = residual_partial_r(x,y,nino);
        Partial_DMI_r(row) = residual_partial_r(x,y,dmi);
        Partial_Nino_p(row) = partial_p(Partial_Nino_r(row),n);
        Partial_DMI_p(row) = partial_p(Partial_DMI_r(row),n);
        Data.(reg).(ss).Year = years;
        Data.(reg).(ss).SST = x;
        Data.(reg).(ss).RAIN = y;
        Data.(reg).(ss).Nino34 = nino;
        Data.(reg).(ss).DMI = dmi;
    end
end

%% 3. Save outputs and cross-check original seasonal r
PartialTable = table(Region,Season,N,Original_r, ...
    SST_Nino_r,Rain_Nino_r,Partial_Nino_r,Partial_Nino_p, ...
    SST_DMI_r,Rain_DMI_r,Partial_DMI_r,Partial_DMI_p);

% Numerical equivalence of observed r from existing seasonal analysis.
season_result = fullfile(data_root,'04_Seasonal_Analysis', ...
    'seasonal_correlation_basic.csv');
max_abs_r_difference = NaN;
if isfile(season_result)
    R = readtable(season_result);
    if ~all(ismember({'Region','Season'},R.Properties.VariableNames))
        error('Missing Region/Season columns in seasonal correlation CSV.');
    end
    rfield = '';
    for choice={'Pearson_r','r','R','Correlation_r'}
        if ismember(choice{1},R.Properties.VariableNames)
            rfield = choice{1}; break;
        end
    end
    if ~isempty(rfield)
        diffs = NaN(12,1);
        for j=1:12
            idx = strcmp(cellstr(string(R.Region)),Region{j}) & ...
                  strcmp(cellstr(string(R.Season)),Season{j});
            if sum(idx)~=1
                error('Seasonal correlation CSV has missing/duplicate row.');
            end
            reference_r = R.(rfield);
            diffs(j) = abs(reference_r(idx)-Original_r(j));
        end
        max_abs_r_difference = max(diffs);
        if max_abs_r_difference>1e-9
            error('Original seasonal r disagrees with stage 04: %.4g.', ...
                max_abs_r_difference);
        end
    end
end
QCType = {'Region-season tests';'Missing partial coefficients'; ...
          'Maximum disagreement with stage 04 (if available)'};
QCValue = [12;sum(~isfinite(Partial_Nino_r)|~isfinite(Partial_DMI_r)); ...
           max_abs_r_difference];
QCTable = table(QCType,QCValue);
writetable(PartialTable,fullfile(out_dir, ...
    'seasonal_partial_correlation_results.csv'));
writetable(QCTable,fullfile(out_dir, ...
    'seasonal_partial_correlation_QC.csv'));
save(fullfile(out_dir,'seasonal_partial_correlation_results.mat'), ...
    'PartialTable','QCTable','Data','regions','seasons');

fprintf('\n===== SEASONAL PARTIAL CORRELATION QC =====\n');
fprintf('Region     Season   N      Raw r    Nino34 partial r   DMI partial r\n');
for j=1:12
    fprintf('%-10s %-4s  %2d    %+0.4f     %+0.4f          %+0.4f\n', ...
        Region{j},Season{j},N(j),Original_r(j), ...
        Partial_Nino_r(j),Partial_DMI_r(j));
end
fprintf('Only coefficients are final here; qFDR is computed by script c.\n');
fprintf('Saved: seasonal_partial_correlation_results.csv/.mat and QC CSV\n');

%% Local functions
function r=pearson_r(x,y)
    x=double(x(:)); y=double(y(:));
    if numel(x)~=numel(y) || any(~isfinite(x)) || any(~isfinite(y))
        error('Pearson r requires equally-sized, finite paired series.');
    end
    x=x-mean(x); y=y-mean(y);
    den=sqrt(sum(x.^2)*sum(y.^2));
    if den<=eps, error('Constant series encountered.'); end
    r=max(-1,min(1,sum(x.*y)/den));
end
function r=residual_partial_r(x,y,z)
    z=double(z(:));
    B=[ones(numel(z),1),z];
    if rank(B)<2, error('Climate index is constant.'); end
    xr=x-B*(B\x);
    yr=y-B*(B\y);
    r=pearson_r(xr,yr);
end
function p=partial_p(r,n)
    % Partial correlation controls one covariate: df=n-3.
    df=n-3;
    if df<=0, error('Insufficient degrees of freedom.'); end
    t2=(r*r)*df/max(eps,(1-r*r));
    % Equivalent to two-sided t distribution, without Stats Toolbox.
    p=betainc(df/(df+t2),df/2,0.5);
end
