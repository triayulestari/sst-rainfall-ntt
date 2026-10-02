%% =========================================================
% spatial_climatology.m
%
% SPATIAL CLIMATOLOGY OF SST AND RAINFALL
% East Nusa Tenggara, Indonesia
%
% Period : 2016-2025
%
% INPUT:
%   Cropped monthly Himawari SST:
%       sst_YYYYMM.nc
%
%   Cropped yearly CHIRPS rainfall:
%       prec_YYYY.NTT.nc
%
% OUTPUT:
%   Spatial_Climatology_NTT.mat
%   Figure01_Spatial_Climatology_NTT.png
%
% UNITS:
%   SST      = degree Celsius
%   Rainfall = mm month^-1
%
% NOTE:
%   Monthly Level-3 SST files for October and November 2025
%   are unavailable. Missing files are automatically skipped.
%
% SOFTWARE:
%   MATLAB R2021a
%   Requires m_map and cmocean
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. USER SETTINGS
%% =========================================================

% ---------------------------------------------------------
% EDIT THESE PATHS according to the location of the
% cropped data on your computer.
% ---------------------------------------------------------

folder_sst  = 'PATH_TO_CROPPED_SST_DATA';
folder_prec = 'PATH_TO_CROPPED_CHIRPS_DATA';

% Variable names inside NetCDF files
var_sst  = 'sst';
var_prec = 'prec';

% Study period
years  = 2016:2025;
nYear  = length(years);
nMonth = 12;

monthName = {...
    'Jan','Feb','Mar','Apr',...
    'May','Jun','Jul','Aug',...
    'Sep','Oct','Nov','Dec'};


%% =========================================================
% 2. READ SST GRID
%% =========================================================

first_sst_file = fullfile(...
    folder_sst,...
    'sst_201601.nc');

lon_sst = double(ncread(first_sst_file,'lon'));
lat_sst = double(ncread(first_sst_file,'lat'));

lon_sst = lon_sst(:);
lat_sst = lat_sst(:);


fprintf('\n============================================\n')
fprintf('SST GRID\n')
fprintf('============================================\n')

fprintf('Longitude : %.3f to %.3f (%d grids)\n',...
    min(lon_sst),max(lon_sst),length(lon_sst));

fprintf('Latitude  : %.3f to %.3f (%d grids)\n',...
    min(lat_sst),max(lat_sst),length(lat_sst));


%% =========================================================
% 3. READ SST 2016-2025
%
% Dimension:
% longitude x latitude x year x month
%% =========================================================

SST_all = NaN(...
    length(lon_sst),...
    length(lat_sst),...
    nYear,...
    nMonth);


fprintf('\n============================================\n')
fprintf('READING SST 2016-2025\n')
fprintf('============================================\n')


for mon = 1:nMonth

    fprintf('\n--- %s ---\n',monthName{mon})

    for iy = 1:nYear

        yr = years(iy);

        namefile = sprintf(...
            'sst_%d%02d.nc',...
            yr,...
            mon);

        file = fullfile(...
            folder_sst,...
            namefile);

        fprintf('%s : ',namefile)


        % --------------------------------------------------
        % Missing SST files are retained as NaN
        % --------------------------------------------------

        if ~isfile(file)

            fprintf('FILE MISSING\n')
            continue

        end


        % --------------------------------------------------
        % Read SST
        % --------------------------------------------------

        temp = double(...
            ncread(...
            file,...
            var_sst));

        temp = squeeze(temp);

        % Protect against non-finite values
        temp(~isfinite(temp)) = NaN;

        SST_all(:,:,iy,mon) = temp;

        fprintf('OK\n')

    end

end


%% =========================================================
% 4. SST MONTHLY CLIMATOLOGY
%
% Each calendar month is averaged separately across years.
% This ensures that all calendar months receive equal weight
% in the final climatological mean, even though October and
% November 2025 SST are unavailable.
%% =========================================================

clim_sst = NaN(...
    length(lon_sst),...
    length(lat_sst),...
    nMonth);


for mon = 1:nMonth

    clim_sst(:,:,mon) = ...
        mean(...
        SST_all(:,:,:,mon),...
        3,...
        'omitnan');

end


%% =========================================================
% 5. OVERALL SST SPATIAL CLIMATOLOGY
%
% Mean of the 12 calendar-month climatologies
% Unit = degree Celsius
%% =========================================================

sst_clim = mean(...
    clim_sst,...
    3,...
    'omitnan');


%% =========================================================
% 6. READ CHIRPS GRID
%% =========================================================

first_prec_file = fullfile(...
    folder_prec,...
    'prec_2016.NTT.nc');

lon_prec = double(ncread(first_prec_file,'lon'));
lat_prec = double(ncread(first_prec_file,'lat'));

lon_prec = lon_prec(:);
lat_prec = lat_prec(:);


fprintf('\n============================================\n')
fprintf('RAINFALL GRID\n')
fprintf('============================================\n')

fprintf('Longitude : %.3f to %.3f (%d grids)\n',...
    min(lon_prec),max(lon_prec),length(lon_prec));

fprintf('Latitude  : %.3f to %.3f (%d grids)\n',...
    min(lat_prec),max(lat_prec),length(lat_prec));


%% =========================================================
% 7. READ CHIRPS RAINFALL 2016-2025
%
% CHIRPS native monthly unit = mm/month
%
% Dimension:
% longitude x latitude x year x month
%% =========================================================

PREC_all = NaN(...
    length(lon_prec),...
    length(lat_prec),...
    nYear,...
    nMonth);


fprintf('\n============================================\n')
fprintf('READING CHIRPS RAINFALL 2016-2025\n')
fprintf('============================================\n')


for iy = 1:nYear

    yr = years(iy);

    namefile = sprintf(...
        'prec_%d.NTT.nc',...
        yr);

    file = fullfile(...
        folder_prec,...
        namefile);

    fprintf('\n%s\n',namefile)


    if ~isfile(file)

        fprintf('FILE MISSING\n')
        continue

    end


    for mon = 1:nMonth

        fprintf('Month %02d : ',mon)


        temp = double(...
            ncread(...
            file,...
            var_prec,...
            [1 1 mon],...
            [Inf Inf 1]));

        temp = squeeze(temp);

        % Protect against non-finite values
        temp(~isfinite(temp)) = NaN;

        PREC_all(:,:,iy,mon) = temp;

        fprintf('OK\n')

    end

end


%% =========================================================
% 8. RAINFALL MONTHLY CLIMATOLOGY
%
% Each calendar month is averaged across 2016-2025.
% Unit remains mm/month.
%% =========================================================

clim_prec = NaN(...
    length(lon_prec),...
    length(lat_prec),...
    nMonth);


for mon = 1:nMonth

    clim_prec(:,:,mon) = ...
        mean(...
        PREC_all(:,:,:,mon),...
        3,...
        'omitnan');

end


%% =========================================================
% 9. OVERALL RAINFALL SPATIAL CLIMATOLOGY
%
% Mean of the 12 calendar-month climatologies
%
% IMPORTANT:
% This is a climatological mean monthly rainfall field,
% NOT annual accumulated rainfall.
%
% Unit = mm/month
%% =========================================================

prec_clim = mean(...
    clim_prec,...
    3,...
    'omitnan');


%% =========================================================
% 10. BASIC CHECK
%% =========================================================

fprintf('\n============================================\n')
fprintf('SPATIAL CLIMATOLOGY - NTT 2016-2025\n')
fprintf('============================================\n')


fprintf('\nSST climatology\n')

fprintf('Mean = %.2f C\n',...
    mean(sst_clim(:),'omitnan'));

fprintf('Min  = %.2f C\n',...
    min(sst_clim(:),[],'omitnan'));

fprintf('Max  = %.2f C\n',...
    max(sst_clim(:),[],'omitnan'));


fprintf('\nRainfall climatology\n')

fprintf('Mean = %.2f mm/month\n',...
    mean(prec_clim(:),'omitnan'));

fprintf('Min  = %.2f mm/month\n',...
    min(prec_clim(:),[],'omitnan'));

fprintf('Max  = %.2f mm/month\n',...
    max(prec_clim(:),[],'omitnan'));


%% =========================================================
% 11. REGIONAL ANALYSIS BOXES
%
% CHIRPS grid boundaries used in the manuscript
%% =========================================================

% FLORES
lonF = [118.975 123.525 123.525 118.975 118.975];
latF = [-9.225 -9.225 -7.875 -7.875 -9.225];

% SUMBA
lonS = [118.775 121.225 121.225 118.775 118.775];
latS = [-10.525 -10.525 -9.175 -9.175 -10.525];

% TIMOR
lonT = [123.275 126.025 126.025 123.275 123.275];
latT = [-10.625 -10.625 -8.575 -8.575 -10.625];


%% =========================================================
% 12. CREATE FIGURE 1
%
% Panel (a) = Rainfall
% Panel (b) = SST
%% =========================================================

figure

set(gcf,...
    'Color','w',...
    'Position',[50 100 1500 570]);


tiledlayout(...
    1,...
    2,...
    'TileSpacing','compact',...
    'Padding','compact');


%% =========================================================
% PANEL (a) - RAINFALL
%% =========================================================

nexttile


m_proj(...
    'mercator',...
    'lon',[118 127],...
    'lat',[-11.5 -7.5]);


h = m_pcolor(...
    lon_prec,...
    lat_prec,...
    prec_clim');

set(h,'EdgeColor','none');

shading flat
hold on


% Coastline
m_gshhs_h(...
    'color','k',...
    'linewidth',0.8);


% Geographic grid
m_grid(...
    'box','fancy',...
    'tickdir','in',...
    'fontsize',10,...
    'linestyle',':',...
    'linewidth',0.8);


% Rainfall colormap
try
    cmocean('rain',41)
catch
    colormap(gca,parula(41))
end


% Same scale as manuscript figure
caxis([0 450]);


% Colorbar
cb1 = colorbar;

ylabel(...
    cb1,...
    'Rainfall (mm month^{-1})',...
    'FontSize',11);


% Analysis boxes
m_line(...
    lonF,latF,...
    'Color','r',...
    'LineWidth',2);

m_line(...
    lonS,latS,...
    'Color','r',...
    'LineWidth',2);

m_line(...
    lonT,latT,...
    'Color','r',...
    'LineWidth',2);


% Region labels
m_text(...
    122.1,-8.75,...
    'Flores',...
    'FontSize',11,...
    'FontWeight','bold');

m_text(...
    119.55,-10.05,...
    'Sumba',...
    'FontSize',11,...
    'FontWeight','bold');

m_text(...
    124.7,-9.8,...
    'Timor',...
    'FontSize',11,...
    'FontWeight','bold');


title(...
    '(a)',...
    'FontWeight','bold',...
    'FontSize',12);


%% =========================================================
% PANEL (b) - SST
%% =========================================================

nexttile


m_proj(...
    'mercator',...
    'lon',[118 127],...
    'lat',[-11.5 -7.5]);


h = m_pcolor(...
    lon_sst,...
    lat_sst,...
    sst_clim');

set(h,'EdgeColor','none');

shading flat
hold on


% Coastline
m_gshhs_h(...
    'color','k',...
    'linewidth',0.8);


% Geographic grid
m_grid(...
    'box','fancy',...
    'tickdir','in',...
    'fontsize',10,...
    'linestyle',':',...
    'linewidth',0.8);


% SST colormap
cmocean('thermal',41);


% Same scale as manuscript figure
caxis([27.5 29.5]);


% Colorbar
cb2 = colorbar;

ylabel(...
    cb2,...
    'Sea Surface Temperature (^{\circ}C)',...
    'FontSize',11);


% Marine labels
m_text(...
    121.6,-7.9,...
    'Flores Sea',...
    'FontSize',10,...
    'FontWeight','bold');

m_text(...
    121.7,-9.45,...
    'Savu Sea',...
    'FontSize',10,...
    'FontWeight','bold');

m_text(...
    125.3,-10.2,...
    'Timor Sea',...
    'FontSize',10,...
    'FontWeight','bold');

m_text(...
    119.0,-10.85,...
    'Indian Ocean',...
    'FontSize',10,...
    'FontWeight','bold');


title(...
    '(b)',...
    'FontWeight','bold',...
    'FontSize',12);


%% =========================================================
% 13. SAVE FIGURE
%% =========================================================

exportgraphics(...
    gcf,...
    'Figure01_Spatial_Climatology_NTT.png',...
    'Resolution',300);


%% =========================================================
% 14. SAVE PROCESSED CLIMATOLOGY
%% =========================================================

save(...
    'Spatial_Climatology_NTT.mat',...
    'sst_clim',...
    'prec_clim',...
    'clim_sst',...
    'clim_prec',...
    'lon_sst',...
    'lat_sst',...
    'lon_prec',...
    'lat_prec',...
    'years');


%% =========================================================
% 15. FINAL MESSAGE
%% =========================================================

fprintf('\n============================================\n')
fprintf('SPATIAL CLIMATOLOGY COMPLETED\n')
fprintf('============================================\n')

fprintf('\nSaved files:\n')
fprintf('1. Figure01_Spatial_Climatology_NTT.png\n')
fprintf('2. Spatial_Climatology_NTT.mat\n')

fprintf('\nUnits:\n')
fprintf('SST      = degree Celsius\n')
fprintf('Rainfall = mm/month\n')

fprintf('\n')