%% ========================================================================
% a_figure1_spatial_climatology.m  |  MATLAB R2021a
% MANUSCRIPT FIGURE 1 (original two-panel layout retained)
% REVISION 3: Latitude labels 8-11 S on BOTH panels via transparent
%             native MATLAB tick axes, independent of M_Map text clipping.
%             Original climatology, color maps and domain boxes unchanged.
%
% (a) CHIRPS v3 mean monthly rainfall over land (2016-2025)
% (b) Himawari L3 mean SST over ocean (2016-2025)
%
% INPUTS (relative to this script under Data/08_Figures):
%   ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_YYYYMM.nc
%   ../01_SST_Rainfall_NTT_2016_2025/02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc
%
% REQUIRED: M_Map with high-resolution GSHHS coastline (m_gshhs_h).
% OPTIONAL: cmocean. Fallback colormaps are provided.
%
% STATISTICAL RULE:
%  - Mean each calendar month across available years, then average the
%    12 calendar-month means with equal weight.
%  - This avoids overweighting Jan-Sep and Dec for SST, since Oct-Nov 2025
%    are missing (118/120 months).
%  - CHIRPS units remain mm/month; cropped SST remains degree Celsius.
%  - Region rectangles are geographic coordinate boxes, NOT polygon masks.
%  - No temporal/spatial interpolation or area weighting.
%
% OUTPUTS (beside this script):
%   Figure_1_Spatial_Climatology.png (600 dpi)
%   Figure_1_Spatial_Climatology.pdf (400 dpi)
%   Figure_1_Spatial_Climatology_Data.mat
%   Figure_1_Monthly_Data_QC.csv
%   Figure_1_Geographic_Metadata.txt
%% ========================================================================
clc;
close all;

%% 1. Resolve project paths
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this MATLAB script as a .m file before running.');
end
out_dir  = fileparts(script_file);
data_dir = fileparts(out_dir);
crop_dir = fullfile(data_dir,'01_SST_Rainfall_NTT_2016_2025');
sst_dir  = fullfile(crop_dir,'01_Crop_SST_NTT');
prec_dir = fullfile(crop_dir,'02_Crop_CHIRPS_NTT');
assert(isfolder(sst_dir),'SST crop directory not found: %s',sst_dir);
assert(isfolder(prec_dir),'CHIRPS crop directory not found: %s',prec_dir);
if exist('m_proj','file')~=2 || exist('m_pcolor','file')~=2 || ...
        exist('m_gshhs_h','file')~=2
    error(['M_Map and its high-resolution GSHHS coastline are required. ' ...
           'Check MATLAB path for m_proj, m_pcolor, and m_gshhs_h.']);
end

%% 2. Read sample grids and check native cropped units
sst_sample  = fullfile(sst_dir,'sst_201601.nc');
prec_sample = fullfile(prec_dir,'prec_2016.NTT.nc');
assert(isfile(sst_sample),'SST crop not found: %s',sst_sample);
assert(isfile(prec_sample),'CHIRPS crop not found: %s',prec_sample);

lon_sst = double(ncread(sst_sample,'lon')); lon_sst = lon_sst(:);
lat_sst = double(ncread(sst_sample,'lat')); lat_sst = lat_sst(:);
lon_prec = double(ncread(prec_sample,'lon')); lon_prec = lon_prec(:);
lat_prec = double(ncread(prec_sample,'lat')); lat_prec = lat_prec(:);
sst_units = strtrim(char(ncreadatt(sst_sample,'sst','units')));
prec_units = strtrim(char(ncreadatt(prec_sample,'prec','units')));
if ~contains(lower(sst_units),'celsius')
    error('SST unit must be Celsius after crop, found: %s',sst_units);
end
if ~strcmpi(prec_units,'mm')
    error('CHIRPS crop unit must be mm per calendar month, found: %s',prec_units);
end

nxS = numel(lon_sst); nyS = numel(lat_sst);
nxP = numel(lon_prec); nyP = numel(lat_prec);
Ssum = zeros(nxS,nyS,12); Scnt = zeros(nxS,nyS,12);
Psum = zeros(nxP,nyP,12); Pcnt = zeros(nxP,nyP,12);
N_sst_file = zeros(12,1); N_prec_month = zeros(12,1);

fprintf('\n===== FIGURE 1: SPATIAL CLIMATOLOGY =====\n');
fprintf('SST grid %d x %d | units %s\n',nxS,nyS,sst_units);
fprintf('CHIRPS grid %d x %d | units %s/month\n',nxP,nyP,prec_units);

%% 3. Streaming monthly means (no large 4-D array)
for yy = 2016:2025
    % One CHIRPS file containing all 12 monthly fields.
    fP = fullfile(prec_dir,sprintf('prec_%04d.NTT.nc',yy));
    if ~isfile(fP)
        error('Missing CHIRPS file for %d: %s',yy,fP);
    end
    for mm = 1:12
        Vp = double(ncread(fP,'prec',[1 1 mm],[Inf Inf 1]));
        Vp = squeeze(Vp);
        if ~isequal(size(Vp),[nxP nyP])
            error('Unexpected CHIRPS grid size: %s, month %d.',fP,mm);
        end
        vp = isfinite(Vp);
        Vp(~vp)=0;
        Psum(:,:,mm) = Psum(:,:,mm) + Vp;
        Pcnt(:,:,mm) = Pcnt(:,:,mm) + vp;
        N_prec_month(mm) = N_prec_month(mm)+1;

        fS = fullfile(sst_dir,sprintf('sst_%04d%02d.nc',yy,mm));
        if ~isfile(fS)
            if ~(yy==2025 && (mm==10 || mm==11))
                warning('Unexpected missing SST file: %s',fS);
            end
            continue;
        end
        Vs = double(ncread(fS,'sst'));
        Vs = squeeze(Vs);
        if ~isequal(size(Vs),[nxS nyS])
            error('Unexpected SST grid size: %s.',fS);
        end
        vs = isfinite(Vs);
        Vs(~vs)=0;
        Ssum(:,:,mm) = Ssum(:,:,mm)+Vs;
        Scnt(:,:,mm) = Scnt(:,:,mm)+vs;
        N_sst_file(mm)=N_sst_file(mm)+1;
    end
    fprintf('Read CHIRPS + available SST: %d\n',yy);
end
if any(N_prec_month~=10) || sum(N_sst_file)~=118 || ...
        N_sst_file(10)~=9 || N_sst_file(11)~=9
    error('Unexpected month availability. Inspect input filenames before plotting.');
end

%% 4. Climatology: equal weight for all 12 calendar months
clim_sst_month = Ssum ./ Scnt;
clim_prec_month = Psum ./ Pcnt;
clim_sst_month(Scnt==0) = NaN;
clim_prec_month(Pcnt==0) = NaN;
sst_clim = mean(clim_sst_month,3,'omitnan');
prec_clim = mean(clim_prec_month,3,'omitnan');

% The map field is intentionally finite wherever the underlying satellite
% or CHIRPS data support it; it is not a shapefile/administrative mask.
T = table((1:12)',N_sst_file,N_prec_month, ...
    'VariableNames',{'Calendar_month','SST_available_years','CHIRPS_available_years'});
writetable(T,fullfile(out_dir,'Figure_1_Monthly_Data_QC.csv'));
save(fullfile(out_dir,'Figure_1_Spatial_Climatology_Data.mat'), ...
    'sst_clim','prec_clim','clim_sst_month','clim_prec_month', ...
    'lon_sst','lat_sst','lon_prec','lat_prec','N_sst_file','N_prec_month', ...
    '-v7.3');

fprintf('SST months: %d/120; rainfall months: %d/120\n', ...
    sum(N_sst_file),sum(N_prec_month));
fprintf('SST mean (finite ocean pixels): %.2f C\n',mean(sst_clim(:),'omitnan'));
fprintf('Rain mean (finite land pixels): %.2f mm/month\n',mean(prec_clim(:),'omitnan'));

%% 5. Styling: retain two-panel layout from original Figure 1
fig = figure('Color','white','Units','pixels','Position',[50 80 1760 720]);
% Use non-tight outer padding: latitude labels need space left of each map.
L = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','loose');
fontName = 'Arial';
fontSize = 12;
map_lon = [118 127.5];
map_lat = [-11.5 -7.0];
lat_label_ticks = -11:1:-8;  % ascending numeric latitude: -11, -10, -9, -8

% Original CHIRPS rectangular domains (WGS84 decimal lon/lat).
% [lonmin lonmax latmin latmax]
boxes = [118.975 123.525 -9.225 -7.875; ...
         118.775 121.225 -10.525 -9.175; ...
         123.275 126.025 -10.625 -8.575];

%% 6. Panel (a): land rainfall climatology
ax1 = nexttile(L,1);
axes(ax1);
m_proj('mercator','lon',map_lon,'lat',map_lat);
h1 = m_pcolor(lon_prec,lat_prec,prec_clim');
set(h1,'EdgeColor','none'); shading flat;
hold on;
m_gshhs_h('color',[0.15 0.15 0.15],'linewidth',0.75);
m_grid('box','on','tickdir','out','fontsize',fontSize, ...
       'xtick',118:2:126,'ytick',lat_label_ticks, ...
       'xaxislocation','bottom','yaxislocation','left', ...
       'yticklabels',[], ... % labels are placed explicitly below
       'linestyle','none','linewidth',0.8);
if exist('cmocean','file')==2
    colormap(ax1,cmocean('rain',256));
else
    colormap(ax1,flipud(parula(256)));
end
caxis(ax1,[0 450]);
cb1 = colorbar(ax1,'eastoutside');
cb1.FontName = fontName;
cb1.FontSize = fontSize-1;
ylabel(cb1,'Rainfall (mm month^{-1})','FontName',fontName,'FontSize',fontSize);
for r = 1:3
    b = boxes(r,:);
    m_line([b(1) b(2) b(2) b(1) b(1)], ...
           [b(3) b(3) b(4) b(4) b(3)], ...
           'color',[0.86 0.12 0.10],'linewidth',1.7);
end
% m_text(121.5,-8.72,'Flores','FontName',fontName,'FontSize',fontSize,'FontWeight','bold');
% m_text(119.53,-10.00,'Sumba','FontName',fontName,'FontSize',fontSize,'FontWeight','bold');
% m_text(124.65,-9.85,'Timor','FontName',fontName,'FontSize',fontSize,'FontWeight','bold');

% Label wilayah pada panel (a)
% Posisi disesuaikan agar tidak menutupi data curah hujan
% dan tetap berada di dalam kotak domain merah.

m_text(122.5,-9.05,'Flores', ...
    'horizontalalignment','center', ...
    'FontName',fontName,'FontSize',fontSize, ...
    'FontWeight','bold');

m_text(119.55,-10.25,'Sumba', ...
    'horizontalalignment','center', ...
    'FontName',fontName,'FontSize',fontSize, ...
    'FontWeight','bold');

m_text(125.25,-10.25,'Timor', ...
    'horizontalalignment','center', ...
    'FontName',fontName,'FontSize',fontSize, ...
    'FontWeight','bold');
m_text(118.35,-7.38,'(a)','FontName',fontName,'FontSize',14,'FontWeight','bold');

% North direction: small cartographic marker, without oversized decoration.
m_line([126.85 126.85],[-8.55 -8.18],'color','k','linewidth',1.2);
m_line(126.85,-8.18,'marker','^','markersize',5, ...
       'markerfacecolor','k','markeredgecolor','k','linestyle','none');
m_text(126.85,-7.99,'N','horizontalalignment','center', ...
       'FontName',fontName,'FontSize',11,'FontWeight','bold');

% Approximate 100-km east-west scale at 11.15 degrees south; geographic
% length estimated using 111.32 km per degree at Equator with cos(lat).
scale_lon = 100/(111.32*cosd(11.15));
x0=124.95; y0=-11.14;
m_line([x0 x0+scale_lon],[y0 y0],'color','k','linewidth',2);
m_line([x0 x0],[y0-0.035 y0+0.035],'color','k','linewidth',1.5);
m_line([x0+scale_lon x0+scale_lon],[y0-0.035 y0+0.035], ...
       'color','k','linewidth',1.5);
m_text(x0+scale_lon/2,-11.33,'~100 km', ...
       'horizontalalignment','center','FontName',fontName,'FontSize',10);

%% 7. Panel (b): marine SST climatology
ax2 = nexttile(L,2);
axes(ax2);
m_proj('mercator','lon',map_lon,'lat',map_lat);
h2=m_pcolor(lon_sst,lat_sst,sst_clim');
set(h2,'EdgeColor','none'); shading flat;
hold on;
m_gshhs_h('color',[0.15 0.15 0.15],'linewidth',0.75);
m_grid('box','on','tickdir','out','fontsize',fontSize, ...
       'xtick',118:2:126,'ytick',lat_label_ticks, ...
       'xaxislocation','bottom','yaxislocation','left', ...
       'yticklabels',[], ... % labels are placed explicitly below
       'linestyle','none','linewidth',0.8);
if exist('cmocean','file')==2
    colormap(ax2,cmocean('thermal',256));
else
    colormap(ax2,parula(256));
end
caxis(ax2,[27.5 29.5]);
cb2=colorbar(ax2,'eastoutside');
cb2.FontName=fontName;
cb2.FontSize=fontSize-1;
ylabel(cb2,'SST (^{\circ}C)','FontName',fontName,'FontSize',fontSize);
m_text(121.5,-7.93,'Flores Sea','horizontalalignment','center', ...
       'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');
m_text(122.15,-9.54,'Savu Sea','horizontalalignment','center', ...
       'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');
m_text(125.45,-10.17,'Timor Sea','horizontalalignment','center', ...
       'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');
m_text(119.22,-10.97,'Indian Ocean','horizontalalignment','center', ...
       'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');
m_text(118.35,-7.38,'(b)','FontName',fontName,'FontSize',14,'FontWeight','bold');
set([ax1 ax2],'FontName',fontName,'FontSize',fontSize);

% IMPORTANT: tiledlayout + m_grid + separate colorbars can hide M_Map's
% latitude text labels at the tile boundary. The earlier attempt to place
% out-of-bounds text with text(...,'Clipping','off') was not exported.
% Instead, create a transparent MATLAB overlay AXES on top of each map,
% with its native YTick/YTickLabel. These are real axis labels, not map text.
% A 'drawnow' first settles tiledlayout/colorbar positions in pixels.
drawnow;
lat_axis_a = add_native_latitude_axis(fig,ax1,map_lon(1), ...
    lat_label_ticks,fontName,fontSize);
lat_axis_b = add_native_latitude_axis(fig,ax2,map_lon(1), ...
    lat_label_ticks,fontName,fontSize);
% Sanity check before export (in addition to examining the saved PNG).
assert(numel(lat_axis_a.YTick)==4 && numel(lat_axis_b.YTick)==4, ...
    'Latitude tick overlay was not configured correctly.');
drawnow;

%% 8. Save figure at journal-ready resolution
exportgraphics(fig,fullfile(out_dir,'Figure_1_Spatial_Climatology.png'), ...
    'Resolution',600,'BackgroundColor','white');
exportgraphics(fig,fullfile(out_dir,'Figure_1_Spatial_Climatology.pdf'), ...
    'ContentType','image','Resolution',400,'BackgroundColor','white');

%% 9. Record data and boundary provenance (version intentionally not guessed)
fid=fopen(fullfile(out_dir,'Figure_1_Geographic_Metadata.txt'),'w');
if fid==-1
    error('Unable to write Figure 1 geographic metadata.');
end
fprintf(fid,'Figure 1 geographic and source metadata\n');
fprintf(fid,'Map projection: Mercator (M_Map MATLAB toolkit).\n');
fprintf(fid,'Coordinate reference: decimal longitude/latitude, WGS84 convention.\n');
fprintf(fid,'View: 118 to 127.5 E, -11.5 to -7.0 latitude.\n');
fprintf(fid,'Latitude ticks shown in BOTH panels: 8, 9, 10, 11 degrees South.\n');
fprintf(fid,'Coastline: GSHHS high-resolution via M_Map m_gshhs_h.\n');
fprintf(fid,'Coastline MATLAB function: %s\n',which('m_gshhs_h'));
fprintf(fid,'ACTION BEFORE SUBMISSION: record exact installed GSHHS release, source URL, and supply/link geographic boundary data subject to license.\n');
fprintf(fid,'Red boxes: CHIRPS rectangular coordinate selections, NOT polygon masks.\n');
fprintf(fid,'No administrative masking or coastline clipping performed in analysis.\n');
fprintf(fid,'Rainfall: CHIRPS v3, native monthly totals (mm), 120 months.\n');
fprintf(fid,'SST: cropped Himawari L3 (H08 then H09), degree Celsius, 118 months; Oct-Nov 2025 unavailable.\n');
fprintf(fid,'SST climatology: 12 equally weighted calendar-month means, each built from available years.\n');
fprintf(fid,'Map-scale bar: approximate, at 11.15 degrees south.\n');
fclose(fid);

fprintf('\n===== FIGURE 1 COMPLETE =====\n');
fprintf('Outputs: PNG 600 dpi, PDF 400 dpi, MAT, monthly QC CSV, metadata TXT.\n');
fprintf('Latitude overlay: 8S, 9S, 10S, 11S on BOTH map panels.\n');
fprintf('Verify latitude labels visually on exported PNG, not only on screen.\n');

%% Local plotting function (MATLAB R2021a compatible)
function tick_ax = add_native_latitude_axis(fig, source_ax, lon_west, lat_ticks, fontName, fontSize)
% A transparent axes with native Y ticks, exactly over the source M_Map axes.
% Native MATLAB tick labels survive exportgraphics/tiledlayout clipping,
% unlike text() placed at X coordinates outside the plot boundaries.
%
% M_Map's m_ll2xy converts geographic latitude to the source map's
% Mercator Y data coordinates; the overlay inherits the source axes limits.
    lat_ticks = lat_ticks(:)';
    if numel(lat_ticks) ~= 4 || ~isequal(lat_ticks,[-11 -10 -9 -8])
        error('Expected exactly -11, -10, -9, -8 degrees latitude.');
    end
    [~, y_projected] = m_ll2xy(lon_west*ones(size(lat_ticks)),lat_ticks);
    y_projected = double(y_projected(:)');
    if any(~isfinite(y_projected))
        error('Unable to project geographic latitude tick locations.');
    end
    original_ylim = ylim(source_ax);
    if any(y_projected <= min(original_ylim)) || any(y_projected >= max(original_ylim))
        warning('At least one requested latitude is outside the projected axes limits.');
    end

    % true = return pixel position relative to figure, not tiledlayout.
    % Freeze at final geometry AFTER all colorbars and m_grid calls.
    pos_px = getpixelposition(source_ax,true);
    if any(pos_px(3:4)<=0)
        error('The map axes have invalid pixel dimensions.');
    end
    labels = arrayfun(@(v) sprintf('%d%cS',abs(v),char(176)), ...
                      lat_ticks,'UniformOutput',false);

    % Separate real axes: original map, raster fields, coastal outlines,
    % boxes, grids and colorbars are left untouched.
    tick_ax = axes('Parent',fig, ...
        'Units','pixels', ...
        'Position',pos_px, ...
        'Color','none', ...
        'Box','off', ...
        'XLim',xlim(source_ax), ...
        'YLim',original_ylim, ...
        'XDir',get(source_ax,'XDir'), ...
        'YDir',get(source_ax,'YDir'), ...
        'XTick',[], ...
        'XColor','none', ...
        'YAxisLocation','left', ...
        'YColor',[0 0 0], ...
        'YTick',y_projected, ...
        'YTickLabel',labels, ...
        'TickLabelInterpreter','none', ...
        'TickDir','out', ...
        'TickLength',[0.006 0.006], ...
        'FontName',fontName, ...
        'FontSize',fontSize-1, ...
        'HitTest','off', ...
        'HandleVisibility','off');
    % Topmost graphical layer; no patch/background over the map.
    uistack(tick_ax,'top');
end
