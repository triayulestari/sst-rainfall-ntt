%% ========================================================================
% c_seasonal_partial_robustness.m
% CONDITIONAL RESIDUAL PERMUTATION SENSITIVITY FOR PARTIAL CORRELATIONS
% MATLAB R2021a | FINAL PROCEDURE (Freedman-Lane-style)
%
% INPUT:
%   seasonal_partial_correlation_results.mat (from script b)
%
% OUTPUTS (same folder):
%   seasonal_partial_robustness_results.csv/.mat
%   seasonal_partial_LOYO_results.csv
%   seasonal_partial_permutation_QC.csv
%
% Controls: Nino 3.4 and DMI SEPARATELY; 12 region-season tests per
% family for BH-FDR. 10,000 permutations; rng(2026,'twister').
% All season-year observations must be complete; n=9-10.
%
% For each control Z:
%   1. Fit Y~intercept+Z; save fitted Y and residual eY.
%   2. Residualize X on intercept+Z, get observed partial r.
%   3. Permute eY, form Y*=fittedY+permuted(eY).
%   4. Refit Y*~intercept+Z; correlate residuals(X) and residuals(Y*).
%   5. Two-sided p=(1+number of |r*|>=|r_obs|)/(10000+1).
%
% NOTE: Unrestricted year permutations do not preserve climate persistence.
% Results are associations, not causal effects or forecasts.
%% ========================================================================
clc;
clear;

%% 1. Inputs, reproducible RNG
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this script as c_seasonal_partial_robustness.m.');
end
out_dir = fileparts(script_file);
in_file = fullfile(out_dir,'seasonal_partial_correlation_results.mat');
if ~isfile(in_file)
    error('Missing %s. Run scripts a and b first.',in_file);
end
D = load(in_file,'Data','PartialTable');
if ~isfield(D,'Data') || ~isfield(D,'PartialTable')
    error('The input MAT must contain Data and PartialTable.');
end
n_perm = 10000;
rng_seed = 2026;
rng(rng_seed,'twister');
regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};
controls = {'Nino34','DMI'};

%% 2. Allocate outputs with established field names
Region = cell(12,1); Season = cell(12,1);
N = NaN(12,1); Original_r = NaN(12,1);
Partial_Nino_r = NaN(12,1);
Nino_CI_low = NaN(12,1); Nino_CI_high = NaN(12,1);
Nino_p_perm = NaN(12,1); Nino_q_FDR = NaN(12,1);
Nino_LOYO_min = NaN(12,1); Nino_LOYO_max = NaN(12,1);
Nino_LOYO_mean = NaN(12,1); Nino_LOYO_sign_percent = NaN(12,1);
Partial_DMI_r = NaN(12,1);
DMI_CI_low = NaN(12,1); DMI_CI_high = NaN(12,1);
DMI_p_perm = NaN(12,1); DMI_q_FDR = NaN(12,1);
DMI_LOYO_min = NaN(12,1); DMI_LOYO_max = NaN(12,1);
DMI_LOYO_mean = NaN(12,1); DMI_LOYO_sign_percent = NaN(12,1);
LOYO_Region = cell(0,1); LOYO_Season = cell(0,1);
LOYO_Control = cell(0,1); LOYO_OmittedYear = zeros(0,1);
LOYO_Partial_r = zeros(0,1);

%% 3. Region-major, season-minor order (matches previous revision)
row = 0;
for ir=1:3
    for is=1:4
        row=row+1;
        reg=regions{ir}; ss=seasons{is};
        Q=D.Data.(reg).(ss);
        x=double(Q.SST(:)); y=double(Q.RAIN(:));
        zn=double(Q.Nino34(:)); zd=double(Q.DMI(:));
        years=double(Q.Year(:));
        valid=isfinite(x)&isfinite(y)&isfinite(zn)&isfinite(zd);
        x=x(valid); y=y(valid); zn=zn(valid);
        zd=zd(valid); years=years(valid);
        n=numel(x);
        if n<6 || any(diff(years)~=1)
            error('Insufficient or nonconsecutive season years: %s %s.',reg,ss);
        end
        Region{row}=reg; Season{row}=ss;
        N(row)=n; Original_r(row)=pearson_r(x,y);

        for im=1:2
            if im==1, z=zn; else, z=zd; end
            control=controls{im};
            B=[ones(n,1),z];
            if rank(B)<2
                error('Constant index for %s %s %s.',reg,ss,control);
            end
            fit_y=B*(B\y);
            residual_y=y-fit_y;
            residual_x=x-B*(B\x);
            r_obs=pearson_r(residual_x,residual_y);

            % Fisher-z 95% approximate CI for 1 control, NOT FDR corrected.
            safe_r=max(-0.999999999,min(0.999999999,r_obs));
            z_se=1/sqrt(n-4);
            ci_lo=tanh(atanh(safe_r)-1.96*z_se);
            ci_hi=tanh(atanh(safe_r)+1.96*z_se);

            exceed=0;
            for ip=1:n_perm
                order=randperm(n);
                y_star=fit_y+residual_y(order);
                y_star_res=y_star-B*(B\y_star);
                r_star=pearson_r(residual_x,y_star_res);
                if abs(r_star)>=abs(r_obs)
                    exceed=exceed+1;
                end
            end
            perm_p=(exceed+1)/(n_perm+1);

            % Leave-one-year-out: estimate the adjustment anew each time.
            r_loyo=NaN(n,1);
            for omit=1:n
                keep=true(n,1); keep(omit)=false;
                xl=x(keep); yl=y(keep); zl=z(keep);
                B_loyo=[ones(n-1,1),zl];
                if rank(B_loyo)<2
                    error('LOYO regression rank deficient.');
                end
                xlres=xl-B_loyo*(B_loyo\xl);
                ylres=yl-B_loyo*(B_loyo\yl);
                r_loyo(omit)=pearson_r(xlres,ylres);
                LOYO_Region{end+1,1}=reg; %#ok<SAGROW>
                LOYO_Season{end+1,1}=ss; %#ok<SAGROW>
                LOYO_Control{end+1,1}=control; %#ok<SAGROW>
                LOYO_OmittedYear(end+1,1)=years(omit); %#ok<SAGROW>
                LOYO_Partial_r(end+1,1)=r_loyo(omit); %#ok<SAGROW>
            end
            lmin=min(r_loyo); lmax=max(r_loyo); lmean=mean(r_loyo);
            if r_obs>0
                sign_pct=100*mean(r_loyo>0);
            elseif r_obs<0
                sign_pct=100*mean(r_loyo<0);
            else
                sign_pct=NaN;
            end
            if im==1
                Partial_Nino_r(row)=r_obs;
                Nino_CI_low(row)=ci_lo; Nino_CI_high(row)=ci_hi;
                Nino_p_perm(row)=perm_p;
                Nino_LOYO_min(row)=lmin; Nino_LOYO_max(row)=lmax;
                Nino_LOYO_mean(row)=lmean;
                Nino_LOYO_sign_percent(row)=sign_pct;
            else
                Partial_DMI_r(row)=r_obs;
                DMI_CI_low(row)=ci_lo; DMI_CI_high(row)=ci_hi;
                DMI_p_perm(row)=perm_p;
                DMI_LOYO_min(row)=lmin; DMI_LOYO_max(row)=lmax;
                DMI_LOYO_mean(row)=lmean;
                DMI_LOYO_sign_percent(row)=sign_pct;
            end
        end
    end
end

%% 4. Corrections and QC
Nino_q_FDR=bh_fdr(Nino_p_perm);
DMI_q_FDR=bh_fdr(DMI_p_perm);

% Check that observed coefficients match script b, not an old input.
P=D.PartialTable;
if height(P)~=12 || ...
   max(abs(P.Partial_Nino_r-Partial_Nino_r))>1e-9 || ...
   max(abs(P.Partial_DMI_r-Partial_DMI_r))>1e-9 || ...
   max(abs(P.Original_r-Original_r))>1e-9
    error('Partial coefficient QC failed against script b.');
end

%% 5. Write publication-ready output tables
RobustnessTable=table(Region,Season,N,Original_r, ...
    Partial_Nino_r,Nino_CI_low,Nino_CI_high,Nino_p_perm,Nino_q_FDR, ...
    Nino_LOYO_min,Nino_LOYO_max,Nino_LOYO_mean,Nino_LOYO_sign_percent, ...
    Partial_DMI_r,DMI_CI_low,DMI_CI_high,DMI_p_perm,DMI_q_FDR, ...
    DMI_LOYO_min,DMI_LOYO_max,DMI_LOYO_mean,DMI_LOYO_sign_percent);
LOYOTable=table(LOYO_Region,LOYO_Season,LOYO_Control, ...
    LOYO_OmittedYear,LOYO_Partial_r, ...
    'VariableNames',{'Region','Season','Control','OmittedYear','Partial_r'});
Control={'Nino34';'DMI'};
FDR_retained=[sum(Nino_q_FDR<0.05);sum(DMI_q_FDR<0.05)];
Suggestive=[sum(Nino_q_FDR>=0.05 & Nino_q_FDR<0.10); ...
            sum(DMI_q_FDR>=0.05 & DMI_q_FDR<0.10)];
Number_of_tests=[12;12];
QCTable=table(Control,Number_of_tests,FDR_retained,Suggestive);

method_note=['Conditional residual permutations (Freedman-Lane-style): ' ...
    'fit Y~1+Z, permute residuals across season-years, reconstruct Y*, ' ...
    'refit Y*~1+Z, correlate residuals of X and Y*. ' ...
    'Two-sided Monte Carlo p=(exceed+1)/(nperm+1). ' ...
    'Niño and DMI controlled separately, BH FDR in separate 12-test families. ' ...
    'No adjustment for serial dependence of year permutations.'];

writetable(RobustnessTable,fullfile(out_dir, ...
    'seasonal_partial_robustness_results.csv'));
writetable(LOYOTable,fullfile(out_dir, ...
    'seasonal_partial_LOYO_results.csv'));
writetable(QCTable,fullfile(out_dir, ...
    'seasonal_partial_permutation_QC.csv'));
save(fullfile(out_dir,'seasonal_partial_robustness_results.mat'), ...
    'RobustnessTable','LOYOTable','QCTable','n_perm','rng_seed', ...
    'method_note');

fprintf('\n===== CONDITIONAL PERMUTATION QC =====\n');
fprintf('10,000 two-sided permutations; rng(2026,''twister'').\n');
fprintf('Niño 3.4 and DMI are separate 12-test FDR families.\n');
fprintf('Region    Season N  Original r  Nino partial r  Nino q  DMI partial r  DMI q\n');
for j=1:12
    fprintf('%-9s %-4s  %2d   %+0.3f      %+0.3f        %.4f    %+0.3f      %.4f\n',...
        Region{j},Season{j},N(j),Original_r(j), ...
        Partial_Nino_r(j),Nino_q_FDR(j),Partial_DMI_r(j),DMI_q_FDR(j));
end
fprintf('FDR q<0.05: Nino34=%d/12, DMI=%d/12.\n', ...
    FDR_retained(1),FDR_retained(2));
fprintf('Saved: seasonal_partial_robustness_results.csv/.mat and LOYO/QC CSVs\n');

%% Local functions (MATLAB R2021a supports functions at end of scripts)
function r=pearson_r(x,y)
    x=double(x(:));y=double(y(:));
    if numel(x)~=numel(y) || any(~isfinite(x)) || any(~isfinite(y))
        error('Expected paired, finite series.');
    end
    x=x-mean(x);y=y-mean(y);
    den=sqrt(sum(x.^2)*sum(y.^2));
    if den<=eps,error('Constant series in correlation.');end
    r=max(-1,min(1,sum(x.*y)/den));
end
function q=bh_fdr(p)
    p=double(p(:));
    if any(~isfinite(p)) || any(p<0) || any(p>1)
        error('BH correction requires p values in [0,1].');
    end
    m=numel(p);
    [ps,order]=sort(p);
    qs=ps.*(m./(1:m)');
    for j=m-1:-1:1
        qs(j)=min(qs(j),qs(j+1));
    end
    q=NaN(m,1);
    q(order)=min(1,qs);
end
