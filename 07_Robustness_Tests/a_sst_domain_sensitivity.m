%% ========================================================================
% a_sst_domain_sensitivity.m
% SST-BOX DOMAIN SENSITIVITY (JJA), FLORES / SUMBA / TIMOR, 2016-2025
% MATLAB R2021a; Statistics Toolbox for corr.
%
% INPUTS:
% ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_YYYYMM.nc
% ../02_Regional_Timeseries/regional_anomalies.mat
% ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
% OUTPUTS IN THIS FOLDER: sst_domain_sensitivity_JJA.csv/.mat
%
% All four borders of each baseline rectangle move symmetrically by
% -0.2,-0.1,0,+0.1,+0.2 degrees. Positive = outward expansion.
% SST (degree Celsius) is an unweighted mean of finite ocean pixels.
% Each domain gets its OWN 2016-2025 calendar-month SST mean, then
% deseasonalized SST anomalies are averaged over complete JJA seasons.
% RAIN (CHIRPS, mm/month) and rainfall geographical boxes remain unchanged.
% No interpolation; Oct and Nov 2025 SST remain NaN.
% These are exploratory correlations, NOT new FDR-adjusted significance tests.
%% ========================================================================
clc; clear;
script_file = mfilename('fullpath');
if isempty(script_file), error('Save this file with its .m filename first.'); end
outdir = fileparts(script_file); rootdir = fileparts(outdir);
sstdir = fullfile(rootdir,'01_SST_Rainfall_NTT_2016_2025','01_Crop_SST_NTT');
regfile = fullfile(rootdir,'02_Regional_Timeseries','regional_anomalies.mat');
seasfile = fullfile(rootdir,'04_Seasonal_Analysis','seasonal_mean_anomalies.mat');
if ~isfolder(sstdir) || ~isfile(regfile) || ~isfile(seasfile)
    error('Required cropped SST folder or regional/seasonal MAT file not found.');
end
D = load(regfile,'time','SST','RAIN_deseason');
S = load(seasfile,'Seasonal');
if ~isfield(D,'time') || ~isfield(D,'SST') || ~isfield(D,'RAIN_deseason') || ...
        ~isequal(size(D.SST),[120 3]) || ~isequal(size(D.RAIN_deseason),[120 3])
    error('Unexpected regional_anomalies.mat format.');
end
time = D.time(:);
if ~isdatetime(time) || numel(time)~=120, error('Expected 120 datetime months.'); end
sample = fullfile(sstdir,'sst_201601.nc');
lon = double(ncread(sample,'lon')); lon=lon(:);
lat = double(ncread(sample,'lat')); lat=lat(:);
unit = char(ncreadatt(sample,'sst','units'));
if ~contains(lower(unit),'celsius'), error('Expected SST degrees Celsius.'); end
regions = {'Flores';'Sumba';'Timor'};
boxes = [119.0 123.5 -9.2 -7.9; 118.8 121.2 -10.5 -9.2; 123.3 126.0 -10.6 -8.6];
changes = [-0.2 -0.1 0 0.1 0.2];
nd = numel(changes); tol=1e-4;
LonIndex=cell(3,nd); LatIndex=cell(3,nd); Box=NaN(3,nd,4);
for ir=1:3
    for jd=1:nd
        delta=changes(jd);
        b=boxes(ir,:) + [-delta delta -delta delta];
        Box(ir,jd,:)=b;
        LonIndex{ir,jd}=find(lon>=b(1)-tol & lon<=b(2)+tol);
        LatIndex{ir,jd}=find(lat>=b(3)-tol & lat<=b(4)+tol);
        if isempty(LonIndex{ir,jd}) || isempty(LatIndex{ir,jd})
            error('Empty SST box %s delta %+.1f.',regions{ir},delta);
        end
    end
end
% Read each NetCDF only once per month, including all 15 geographic boxes.
SSTraw=NaN(120,3,nd);
PixelCount=zeros(120,3,nd);
missing2025=year(time)==2025 & ismember(month(time),[10 11]);
for k=1:120
    yr=year(time(k)); mo=month(time(k));
    f=fullfile(sstdir,sprintf('sst_%04d%02d.nc',yr,mo));
    if missing2025(k)
        if isfile(f), error('Unexpected SST input at missing month %04d-%02d.',yr,mo); end
        continue;
    end
    if ~isfile(f), error('Required SST monthly NetCDF missing: %s',f); end
    a=double(ncread(f,'sst'));
    if size(a,1)~=numel(lon) || size(a,2)~=numel(lat)
        error('SST grid mismatch in %s',f);
    end
    a=reshape(a,numel(lon),numel(lat));
    a(~isfinite(a) | abs(a)>1e7)=NaN;
    for ir=1:3
        for jd=1:nd
            v=a(LonIndex{ir,jd},LatIndex{ir,jd});
            v=v(isfinite(v));
            PixelCount(k,ir,jd)=numel(v);
            if isempty(v), error('No SST pixels for %s %04d-%02d.',regions{ir},yr,mo); end
            SSTraw(k,ir,jd)=mean(v);
        end
    end
end
% Critical consistency check against main regional SST used in the paper.
ib=find(changes==0,1);
dif=abs(SSTraw(:,:,ib)-D.SST);
maxdiff=max(dif(~missing2025,:)); maxdiff=max(maxdiff);
fprintf('\n===== SST DOMAIN QC =====\n');
fprintf('Baseline monthly SST vs Stage 02: max abs difference %.12g C\n',maxdiff);
if ~isfinite(maxdiff) || maxdiff>1e-8
    error('SST baseline does not match Stage 02. Review spatial boxes / input data.');
end
% Form calendar-month SST anomalies independently for EACH domain.
SSTanom=NaN(size(SSTraw));
for ir=1:3
    for jd=1:nd
        for mo=1:12
            ix=month(time)==mo;
            x=SSTraw(ix,ir,jd);
            x=x(isfinite(x));
            if numel(x)<9, error('Insufficient calendar-month SST samples.'); end
            clim=mean(x);
            SSTanom(ix,ir,jd)=SSTraw(ix,ir,jd)-clim;
        end
    end
end
Region={}; Domain_delta_deg=[]; Requested_Lon_min=[]; Requested_Lon_max=[];
Requested_Lat_min=[]; Requested_Lat_max=[]; N_seasons=[];
Mean_valid_pixels_monthly=[]; r_JJA=[]; r_JJA_baseline=[]; delta_r=[];
JJA_year=(2016:2025)';
for ir=1:3
    rain=NaN(10,1);
    for iy=1:10
        ix=year(time)==JJA_year(iy) & ismember(month(time),[6 7 8]);
        if sum(ix)~=3, error('JJA date construction failed.'); end
        v=D.RAIN_deseason(ix,ir);
        if ~all(isfinite(v)), error('JJA rainfall anomaly missing.'); end
        rain(iy)=mean(v);
    end
    baseline_r=corr(S.Seasonal.JJA.SST(:,ir),S.Seasonal.JJA.RAIN(:,ir),'Type','Pearson');
    for jd=1:nd
        sst=NaN(10,1);
        for iy=1:10
            ix=year(time)==JJA_year(iy) & ismember(month(time),[6 7 8]);
            v=SSTanom(ix,ir,jd);
            if ~all(isfinite(v)), error('Incomplete JJA SST at %s.',regions{ir}); end
            sst(iy)=mean(v);
        end
        rr=corr(sst,rain,'Type','Pearson');
        b=reshape(Box(ir,jd,:),1,4);
        Region{end+1,1}=regions{ir}; %#ok<SAGROW>
        Domain_delta_deg(end+1,1)=changes(jd); %#ok<SAGROW>
        Requested_Lon_min(end+1,1)=b(1); %#ok<SAGROW>
        Requested_Lon_max(end+1,1)=b(2); %#ok<SAGROW>
        Requested_Lat_min(end+1,1)=b(3); %#ok<SAGROW>
        Requested_Lat_max(end+1,1)=b(4); %#ok<SAGROW>
        N_seasons(end+1,1)=10; %#ok<SAGROW>
        pc=PixelCount(:,ir,jd); pc=pc(~missing2025);
        Mean_valid_pixels_monthly(end+1,1)=mean(pc); %#ok<SAGROW>
        r_JJA(end+1,1)=rr; %#ok<SAGROW>
        r_JJA_baseline(end+1,1)=baseline_r; %#ok<SAGROW>
        delta_r(end+1,1)=rr-baseline_r; %#ok<SAGROW>
        if changes(jd)==0 && abs(rr-baseline_r)>1e-9
            error('Baseline JJA r disagreement at %s.',regions{ir});
        end
    end
end
Results=table(Region,Domain_delta_deg,Requested_Lon_min,Requested_Lon_max, ...
    Requested_Lat_min,Requested_Lat_max,N_seasons,Mean_valid_pixels_monthly, ...
    r_JJA,r_JJA_baseline,delta_r);
writetable(Results,fullfile(outdir,'sst_domain_sensitivity_JJA.csv'));
save(fullfile(outdir,'sst_domain_sensitivity_JJA.mat'), ...
    'Results','SSTraw','SSTanom','PixelCount','changes','boxes','time','JJA_year');
disp(Results(:,{'Region','Domain_delta_deg','r_JJA','delta_r'}));
fprintf('Saved: sst_domain_sensitivity_JJA.csv/.mat\n');
fprintf('Exploratory r sensitivity only; no new p/qFDR tests.\n');
