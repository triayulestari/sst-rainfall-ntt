%% ========================================================================
% c_seasonal_detrend_missing2025.m
% TREND / 2025-EXCLUSION SENSITIVITY, PLUS JJA RAINFALL MAGNITUDES
% MATLAB R2021a; Statistics and Machine Learning Toolbox (corr).
%
% INPUTS: ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
%         ../04_Seasonal_Analysis/seasonal_robustness_results.csv
% OUTPUTS: seasonal_detrend_sensitivity.csv
%          seasonal_exclude2025_sensitivity.csv
%          JJA_rainfall_magnitude.csv
%
% Detrending is fit separately ON EACH seasonal interannual series:
%    SST_season(year) ~ year; RAIN_season(year) ~ year.
% Correlate their linear residuals (each has n=9 or 10 seasons).
% No new p-values or q-values are claimed for these sensitivity r values.
% Excluding 2025 uses complete season-year records <= 2024; therefore SON
% is unchanged. Missing SST Oct-Nov 2025 is NEVER interpolated.
% JJA anomaly magnitudes are in mm per calendar month, NOT mm per season.
%% ========================================================================
clc; clear;
path=mfilename('fullpath');
if isempty(path), error('Save script as c_seasonal_detrend_missing2025.m.'); end
outdir=fileparts(path); root=fileparts(outdir);
matfile=fullfile(root,'04_Seasonal_Analysis','seasonal_mean_anomalies.mat');
robfile=fullfile(root,'04_Seasonal_Analysis','seasonal_robustness_results.csv');
if ~isfile(matfile) || ~isfile(robfile), error('Missing Stage 04 results.'); end
M=load(matfile,'Seasonal');
U=readtable(robfile);
reg={'Flores','Sumba','Timor'}; season={'DJF','MAM','JJA','SON'};
Region={}; Season={}; N=[]; First_year=[]; Last_year=[];
r_baseline=[]; r_detrended=[]; Delta_r=[];
Trend_SST_C_per_year=[]; Trend_rain_mm_month_per_year=[];
N_no2025=[]; r_no2025=[]; Delta_r_no2025=[];
Rain_JJA_mean_mm_month=[]; Rain_JJA_min_mm_month=[];
Rain_JJA_max_mm_month=[]; Rain_JJA_anom_min_mm_month=[];
Rain_JJA_anom_max_mm_month=[];
k=0;
for ir=1:3
    for is=1:4
        k=k+1; ss=season{is};
        y=M.Seasonal.(ss).Year(:);
        x=M.Seasonal.(ss).SST(:,ir);
        z=M.Seasonal.(ss).RAIN(:,ir);
        valid=isfinite(x)&isfinite(z)&isfinite(y);
        x=x(valid);z=z(valid);y=y(valid);
        if numel(x)<8, error('Unexpected missing seasonal sample.'); end
        r0=corr(x,z,'Type','Pearson');
        match=strcmp(U.Region,reg{ir}) & strcmp(U.Season,ss);
        if sum(match)~=1, error('Could not find exactly one Stage 04 reference.'); end
        if abs(r0-U.Pearson_r(match))>1e-9
            error('Stage 04 baseline disagrees with Stage 07 data (%s %s).',reg{ir},ss);
        end
        yy=y-mean(y);
        px=polyfit(yy,x,1); pz=polyfit(yy,z,1);
        xd=x-polyval(px,yy); zd=z-polyval(pz,yy);
        rd=corr(xd,zd,'Type','Pearson');
        keep=y<=2024;
        if sum(keep)<7, error('Not enough seasons when excluding 2025.'); end
        rn=corr(x(keep),z(keep),'Type','Pearson');
        Region{end+1,1}=reg{ir}; %#ok<SAGROW>
        Season{end+1,1}=ss; %#ok<SAGROW>
        N(end+1,1)=numel(y); %#ok<SAGROW>
        First_year(end+1,1)=y(1); %#ok<SAGROW>
        Last_year(end+1,1)=y(end); %#ok<SAGROW>
        r_baseline(end+1,1)=r0; %#ok<SAGROW>
        r_detrended(end+1,1)=rd; %#ok<SAGROW>
        Delta_r(end+1,1)=rd-r0; %#ok<SAGROW>
        Trend_SST_C_per_year(end+1,1)=px(1); %#ok<SAGROW>
        Trend_rain_mm_month_per_year(end+1,1)=pz(1); %#ok<SAGROW>
        N_no2025(end+1,1)=sum(keep); %#ok<SAGROW>
        r_no2025(end+1,1)=rn; %#ok<SAGROW>
        Delta_r_no2025(end+1,1)=rn-r0; %#ok<SAGROW>
        if strcmp(ss,'SON') && abs(rn-r0)>1e-10
            error('SON has no 2025 season: excluding 2025 must change nothing.');
        end
    end
end
Detr=table(Region,Season,N,First_year,Last_year,r_baseline, ...
    r_detrended,Delta_r,Trend_SST_C_per_year,Trend_rain_mm_month_per_year);
Excl=table(Region,Season,N,N_no2025,r_baseline,r_no2025,Delta_r_no2025);
writetable(Detr,fullfile(outdir,'seasonal_detrend_sensitivity.csv'));
writetable(Excl,fullfile(outdir,'seasonal_exclude2025_sensitivity.csv'));
% JJA physically meaningful rainfall anomaly magnitude (no regression claim)
RegionJJA=reg(:); N_JJA=zeros(3,1);
Mean_rain_JJA_mm_month=NaN(3,1);
Min_rain_JJA_mm_month=NaN(3,1);
Max_rain_JJA_mm_month=NaN(3,1);
Min_anom_JJA_mm_month=NaN(3,1);
Max_anom_JJA_mm_month=NaN(3,1);
Mean_abs_anom_JJA_mm_month=NaN(3,1);
for ir=1:3
    rainraw=M.Seasonal.JJA.RAIN_raw(:,ir);
    rainanom=M.Seasonal.JJA.RAIN(:,ir);
    valid=isfinite(rainraw)&isfinite(rainanom);
    N_JJA(ir)=sum(valid);
    Mean_rain_JJA_mm_month(ir)=mean(rainraw(valid));
    Min_rain_JJA_mm_month(ir)=min(rainraw(valid));
    Max_rain_JJA_mm_month(ir)=max(rainraw(valid));
    Min_anom_JJA_mm_month(ir)=min(rainanom(valid));
    Max_anom_JJA_mm_month(ir)=max(rainanom(valid));
    Mean_abs_anom_JJA_mm_month(ir)=mean(abs(rainanom(valid)));
end
JJA=table(RegionJJA,N_JJA,Mean_rain_JJA_mm_month, ...
    Min_rain_JJA_mm_month,Max_rain_JJA_mm_month, ...
    Min_anom_JJA_mm_month,Max_anom_JJA_mm_month,Mean_abs_anom_JJA_mm_month);
writetable(JJA,fullfile(outdir,'JJA_rainfall_magnitude.csv'));
fprintf('\n===== SEASONAL DETREND AND EXCLUDE-2025 QC =====\n');
for ir=1:3
    k=find(strcmp(Detr.Region,reg{ir}) & strcmp(Detr.Season,'JJA'));
    fprintf('%s JJA: r=%.4f, detrended=%.4f, exclude2025=%.4f\n', ...
        reg{ir},Detr.r_baseline(k),Detr.r_detrended(k),Excl.r_no2025(k));
end
fprintf('Saved 3 CSVs in %s\n',outdir);
fprintf('CAUTION: Sensitivity coefficients do not carry recalculated permutation qFDR.\n');
