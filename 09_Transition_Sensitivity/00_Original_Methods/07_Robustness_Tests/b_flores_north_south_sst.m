%% ========================================================================
% b_flores_north_south_sst.m
% FLORES NORTH vs SOUTH MARINE SST, 2016-2025 | MATLAB R2021a
%
% Reuses Stage 07a's monthly SST files (no independent recropping).
% FLORES reference SST box: 119.0-123.5 E; -9.2 to -7.9 degrees N.
% NORTH: lat > -8.55; SOUTH: lat < -8.55, no overlap.
% Monthly subregional mean = mean of finite SST ocean pixels, unweighted.
% Deseason = SST minus 2016-2025 same-calendar-month mean.
% Rainfall = EXISTING FLORES regional-mean CHIRPS deseason anomaly.
% Seasonal complete three-month means use Stage 04 season definitions.
% Output: flores_north_south_monthly.csv/.mat,
%         flores_north_south_seasonal_correlations.csv
% Correlation differences are descriptive sensitivity results; no new FDR.
%% ========================================================================
clc; clear;
file=mfilename('fullpath');
if isempty(file), error('Save script as b_flores_north_south_sst.m.'); end
outdir=fileparts(file); root=fileparts(outdir);
sstdir=fullfile(root,'01_SST_Rainfall_NTT_2016_2025','01_Crop_SST_NTT');
regfile=fullfile(root,'02_Regional_Timeseries','regional_anomalies.mat');
seasfile=fullfile(root,'04_Seasonal_Analysis','seasonal_mean_anomalies.mat');
if ~isfolder(sstdir) || ~isfile(regfile) || ~isfile(seasfile)
    error('Missing SST crop directory or Stage 02/04 MAT files.');
end
D=load(regfile,'time','SST','SST_deseason','RAIN_deseason');
S=load(seasfile,'Seasonal');
time=D.time(:);
if ~isdatetime(time) || numel(time)~=120, error('Expected monthly datetime 2016-2025.'); end
f=fullfile(sstdir,'sst_201601.nc');
lon=double(ncread(f,'lon')); lon=lon(:);
lat=double(ncread(f,'lat')); lat=lat(:);
tol=1e-4; split=-8.55;
iLon=find(lon>=119.0-tol & lon<=123.5+tol);
iAll=find(lat>=-9.2-tol & lat<=-7.9+tol);
iN=find(lat>=-9.2-tol & lat<=-7.9+tol & lat>split);
iS=find(lat>=-9.2-tol & lat<=-7.9+tol & lat<split);
if isempty(iN) || isempty(iS) || numel([iN;iS])~=numel(iAll) || ...
        ~isequal(sort([iN;iS]),sort(iAll))
    error('North/south latitude partition is incomplete or overlapping.');
end
Raw=NaN(120,3); ValidPixels=zeros(120,3); % North, South, Full
missing=year(time)==2025 & ismember(month(time),[10 11]);
for k=1:120
    if missing(k), continue; end
    ff=fullfile(sstdir,sprintf('sst_%04d%02d.nc',year(time(k)),month(time(k))));
    if ~isfile(ff), error('Missing SST file %s',ff); end
    a=double(ncread(ff,'sst'));
    a=reshape(a,numel(lon),numel(lat));
    a(~isfinite(a) | abs(a)>1e7)=NaN;
    ii={iN,iS,iAll};
    for j=1:3
        block=a(iLon,ii{j}); v=block(isfinite(block));
        ValidPixels(k,j)=numel(v);
        if isempty(v), error('No SST pixels in Flores %s.',datestr(time(k))); end
        Raw(k,j)=mean(v);
    end
end
fullErr=abs(Raw(~missing,3)-D.SST(~missing,1));
maxerr=max(fullErr);
fprintf('\n===== FLORES NORTH-SOUTH QC =====\n');
fprintf('Full Flores monthly SST agreement: max abs error %.12g C\n',maxerr);
if ~isfinite(maxerr) || maxerr>1e-8
    error('Full Flores SST differs from Stage 02.');
end
% Deseasonalize both halves independently. The north-minus-south anomaly
% is computed as North anomaly - South anomaly, not a new raw mean.
Anom=NaN(120,3);
for j=1:3
    for mo=1:12
        ix=month(time)==mo; v=Raw(ix,j); v=v(isfinite(v));
        if numel(v)<9, error('Not enough years for calendar month %d.',mo); end
        Anom(ix,j)=Raw(ix,j)-mean(v);
    end
end
DeltaRaw=Raw(:,1)-Raw(:,2);
DeltaAnom=Anom(:,1)-Anom(:,2);
T=table(time,Raw(:,1),Raw(:,2),Raw(:,3),DeltaRaw, ...
    Anom(:,1),Anom(:,2),Anom(:,3),DeltaAnom, ...
    ValidPixels(:,1),ValidPixels(:,2),ValidPixels(:,3), ...
    'VariableNames',{'Time','SST_North_C','SST_South_C','SST_Full_C', ...
    'North_minus_South_C','Anom_North_C','Anom_South_C', ...
    'Anom_Full_C','Anom_North_minus_South_C', ...
    'Valid_pixels_North','Valid_pixels_South','Valid_pixels_Full'});
writetable(T,fullfile(outdir,'flores_north_south_monthly.csv'));
save(fullfile(outdir,'flores_north_south_monthly.mat'), ...
    'T','time','Raw','Anom','DeltaRaw','DeltaAnom','ValidPixels','split');
% Reuse EXACT season-year definitions of Stage 04.
seasons={'DJF','MAM','JJA','SON'};
pred={'North_SST','South_SST','North_minus_South_SST'};
Region={}; Predictor={}; Season={}; N=[]; Pearson_r=[];
for js=1:4
    ss=seasons{js}; years=S.Seasonal.(ss).Year;
    rain=S.Seasonal.(ss).RAIN(:,1);
    allX=NaN(numel(years),3);
    for iy=1:numel(years)
        y=years(iy);
        if strcmp(ss,'DJF')
            ix=(year(time)==y-1 & month(time)==12) | ...
               (year(time)==y & ismember(month(time),[1 2]));
        else
            if strcmp(ss,'MAM'), mm=[3 4 5];
            elseif strcmp(ss,'JJA'), mm=[6 7 8];
            else, mm=[9 10 11]; end
            ix=year(time)==y & ismember(month(time),mm);
        end
        if sum(ix)~=3 || ~all(isfinite(Anom(ix,1))) || ...
                ~all(isfinite(Anom(ix,2)))
            error('Incomplete SST season: %s %d',ss,y);
        end
        allX(iy,:)=[mean(Anom(ix,1)),mean(Anom(ix,2)),mean(DeltaAnom(ix))];
    end
    if any(~isfinite(rain)), error('Missing Flores rainfall season.'); end
    for jp=1:3
        Region{end+1,1}='Flores'; %#ok<SAGROW>
        Predictor{end+1,1}=pred{jp}; %#ok<SAGROW>
        Season{end+1,1}=ss; %#ok<SAGROW>
        N(end+1,1)=numel(years); %#ok<SAGROW>
        Pearson_r(end+1,1)=corr(allX(:,jp),rain,'Type','Pearson'); %#ok<SAGROW>
    end
end
C=table(Region,Predictor,Season,N,Pearson_r);
writetable(C,fullfile(outdir,'flores_north_south_seasonal_correlations.csv'));
fprintf('SST north/south split at latitude %.2f degrees.\n',split);
fprintf('JJA north r = %+.4f, south r = %+.4f\n', ...
    C.Pearson_r(strcmp(C.Predictor,'North_SST') & strcmp(C.Season,'JJA')), ...
    C.Pearson_r(strcmp(C.Predictor,'South_SST') & strcmp(C.Season,'JJA')));
fprintf('Saved 3 files in %s\n',outdir);
fprintf('NOTE: Descriptive sensitivity, not a new multiple-testing inference.\n');
