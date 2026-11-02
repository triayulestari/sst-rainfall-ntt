%% ========================================================================
% d_figure4_spatial_correlations.m | MATLAB R2021a
% FIGURE 4 - EXACT FIGURE 1 BOXES, CLEAN LATITUDES, STRONGER COLORS
%
% (a) Flores (b) Sumba (c) Timor (d) boxplot
% Data: regional deseasonalized SST vs each CHIRPS rainfall grid (zero lag).
% Read saved Stage 05 Pearson r and qFDR. NO statistical recalculation.
% M_Map Mercator + GSHHS coastlines, as in Figure 1.
% Exactly 110 individual dots in Flores (within-region qFDR<0.05).
% Pooled BH-FDR across 2,811 grids: NO significant cells.
%
% SAVE IN Data/08_Figures/ and run: d_figure4_spatial_correlations
%% ========================================================================
clc; close all;

%% 1. Files and exact regional coordinate boxes
scriptName = mfilename('fullpath');
assert(~isempty(scriptName),'Please save as a .m file before running.');
outDir = fileparts(scriptName);
rootDir = fileparts(outDir);
fMat = fullfile(rootDir,'05_Spatial_Analysis','spatial_correlation_results.mat');
fCsv = fullfile(rootDir,'05_Spatial_Analysis','spatial_correlation_summary.csv');
assert(isfile(fMat),'Missing input MAT: %s',fMat);
assert(isfile(fCsv),'Missing input CSV: %s',fCsv);
assert(exist('m_proj','file')==2 && exist('m_pcolor','file')==2 && ...
       exist('m_grid','file')==2 && exist('m_gshhs_h','file')==2 && ...
       exist('m_line','file')==2, 'M_Map/GSHHS is missing from MATLAB path.');
M = load(fMat);
S = readtable(fCsv);

% [lonmin lonmax latmin latmax], MATCH Figure 1 CHIRPS boxes
boxes = [118.975 123.525  -9.225  -7.875; ...  % Flores
         118.775 121.225 -10.525  -9.175; ...  % Sumba
         123.275 126.025 -10.625  -8.575];    % Timor
names = {'Flores','Sumba','Timor'};
tags  = {'F','S','T'};
pooledColumn = 'N_FDR_pooled_lt_0_05';
if ~ismember(pooledColumn,S.Properties.VariableNames)
    pooledColumn = 'N_FDR_global_lt_0_05';
end
needed = {'Region','Valid_grids','r_median', ...
          'N_FDR_region_lt_0_05',pooledColumn};
assert(all(ismember(needed,S.Properties.VariableNames)), ...
    'Stage 05 summary CSV has unexpected columns.');

%% 2. Read and check the original statistical fields
D = repmat(struct('lon',[],'lat',[],'r',[],'mask',[], ...
    'sig',[],'sigPooled',[],'values',[], ...
    'n',0,'nSig',0,'nPooled',0,'nDots',0,'medianR',NaN),1,3);
fprintf('\n===== FIGURE 4: SOURCE DATA QC =====\n');
for k = 1:3
    t = tags{k};
    fields = {['lon_' t],['lat_' t],['r_map_' t], ...
              ['mask_' t],['q_region_map_' t],['q_global_map_' t]};
    for j=1:numel(fields)
        assert(isfield(M,fields{j}),'Missing MAT variable: %s',fields{j});
    end
    lon = double(M.(fields{1})); lon=lon(:);
    lat = double(M.(fields{2})); lat=lat(:);
    r = double(M.(fields{3}));
    mask = logical(M.(fields{4}));
    qr = double(M.(fields{5}));
    qp = double(M.(fields{6}));
    sz = [numel(lon) numel(lat)];
    assert(isequal(size(r),sz) && isequal(size(mask),sz) && ...
           isequal(size(qr),sz) && isequal(size(qp),sz), ...
           'Grid dimension mismatch: %s',names{k});
    assert(all(diff(lon)>0) && all(diff(lat)>0), ...
           'Grid coordinates are not ascending: %s',names{k});
    assert(max(abs([lon(1) lon(end) lat(1) lat(end)] - boxes(k,:)))<1e-3, ...
           'Study box differs from Figure 1: %s',names{k});
    assert(all(isfinite(r(mask))) && all(abs(r(mask))<=1) && ...
           all(isfinite(qr(mask))) && all(isfinite(qp(mask))), ...
           'Missing/invalid statistical data in %s',names{k});
    sig = mask & qr<0.05;
    sigPooled = mask & qp<0.05;
    row = find(strcmpi(strtrim(string(S.Region)),names{k}));
    assert(numel(row)==1,'Region missing/duplicated in CSV: %s',names{k});
    pooledCounts = S.(pooledColumn);
    assert(nnz(mask)==S.Valid_grids(row) && ...
           nnz(sig)==S.N_FDR_region_lt_0_05(row) && ...
           nnz(sigPooled)==pooledCounts(row), ...
           'Grid/FDR count mismatch in %s',names{k});
    vals=r(mask);
    assert(abs(median(vals)-S.r_median(row))<1e-7, ...
           'Median r mismatch in %s',names{k});
    D(k).lon=lon; D(k).lat=lat; D(k).r=r; D(k).mask=mask;
    D(k).sig=sig; D(k).sigPooled=sigPooled; D(k).values=vals;
    D(k).n=nnz(mask); D(k).nSig=nnz(sig);
    D(k).nPooled=nnz(sigPooled); D(k).medianR=median(vals);
    fprintf('%-6s grids=%d | within-region q<0.05: %d | pooled: %d\n', ...
        names{k},D(k).n,D(k).nSig,D(k).nPooled);
end
assert(isequal([D.n],[1158 565 1088]),'Unexpected grid counts.');
assert(isequal([D.nSig],[110 0 0]),'Unexpected regional qFDR results.');
assert(sum([D.nPooled])==0,'Expected zero pooled-significant cells.');

%% 3. Higher-contrast diverging colormap, still centered at REAL r = 0
% All r values are unchanged and colorbar is numeric -0.4...+0.4.
% Intermediate color stops improve readability for modest |r| (0.1-0.2).
% Negative: blue; zero: warm white; positive: orange/red.
anchorR = [-0.40 -0.20 -0.10  0  0.10  0.20  0.40];
anchorRGB = [0.08 0.20 0.44; ...   % -0.40 strong blue
             0.29 0.49 0.71; ...   % -0.20 medium blue
             0.57 0.73 0.85; ...   % -0.10 pale blue
             0.985 0.985 0.975;... %  0.00 neutral
             0.93 0.65 0.58; ...   % +0.10 visible coral
             0.83 0.37 0.32; ...   % +0.20 red/orange
             0.61 0.13 0.15];      % +0.40 deep brick red
cmap = interp1(anchorR,anchorRGB,linspace(-0.4,0.4,256),'linear');
brightness = cmap*[0.2126;0.7152;0.0722];
cmapGray = [brightness brightness brightness];
cLim = [-0.4 0.4];

%% 4. Compact layout - SAME four-panel arrangement
fig=figure('Color','white','Units','pixels', ...
    'Position',[50 60 1680 720],'PaperPositionMode','auto');
fontName='Arial'; fs=11;
posF=[0.060 0.575 0.580 0.358];
posS=[0.060 0.175 0.285 0.320];
posT=[0.414 0.175 0.226 0.365];
posCB=[0.667 0.242 0.014 0.608];
posB=[0.782 0.195 0.192 0.700];
posNote=[0.065 0.010 0.910 0.060];
axF=axes('Parent',fig,'Units','normalized','Position',posF);
axS=axes('Parent',fig,'Units','normalized','Position',posS);
axT=axes('Parent',fig,'Units','normalized','Position',posT);
axB=axes('Parent',fig,'Units','normalized','Position',posB);
mapAxes=[axF axS axT];
panelLetters={'(a)','(b)','(c)'};

%% 5. Draw projected correlation maps with EXPLICIT latitude labels
for k=1:3
    ax=mapAxes(k); d=D(k); box=boxes(k,:);
    axes(ax); %#ok<LAXES>
    m_proj('mercator','lon',box(1:2),'lat',box(3:4));
    hold on;

    % Native CHIRPS grid cell edges, no interpolation or new data.
    dx=median(diff(d.lon)); dy=median(diff(d.lat));
    lonEdge=[d.lon(1)-dx/2; ...
        (d.lon(1:end-1)+d.lon(2:end))/2;d.lon(end)+dx/2];
    latEdge=[d.lat(1)-dy/2; ...
        (d.lat(1:end-1)+d.lat(2:end))/2;d.lat(end)+dy/2];
    C=d.r'; C(~d.mask')=NaN;
    Ce=[C C(:,end)]; Ce=[Ce;Ce(end,:)];
    p=m_pcolor(lonEdge,latEdge,Ce);
    set(p,'FaceColor','flat','EdgeColor','none');
    colormap(ax,cmap); caxis(ax,cLim);

    % Same GSHHS reference as Figure 1 (line only, no patch).
    m_gshhs_h('color',[0.25 0.25 0.25],'linewidth',0.65);

    % Each black dot is the center of ONE within-region significant grid.
    if any(d.sig(:))
        [ii,jj]=find(d.sig);
        m_line(d.lon(ii),d.lat(jj),'Marker','.', ...
            'MarkerSize',5.3,'LineStyle','none','Color','k');
        D(k).nDots=numel(ii);
    end

    % ALWAYS pass a VECTOR of latitude ticks (not a scalar).
    switch k
        case 1
            xt=[119 120 121 122 123];
            yt=[-9 -8.5 -8];
        case 2
            xt=[119 120 121];
            yt=[-10.5 -10 -9.5];
        case 3
            xt=[124 125 126];
            yt=[-10.5 -10 -9.5 -9];
    end

    % Explicit latitude strings prevent M_Map's automatic minutes
    % labels (e.g., the incorrect-looking 10.50' and 31.50').
    latLabels=arrayfun(@(v)sprintf('%g%cS',abs(v),char(176)), ...
        yt,'UniformOutput',false);
    m_grid('box','on','tickdir','out','fontsize',fs, ...
        'xtick',xt,'ytick',yt, ...
        'yticklabels',char(latLabels), ...
        'tickstyle','dd', ...
        'xaxislocation','bottom','yaxislocation','left', ...
        'linestyle','none','linewidth',0.8);

    set(ax,'FontName',fontName,'FontSize',fs,'Color','white');
    daspect(ax,[1 1 1]);
    text(ax,0.020,0.978,sprintf('%s %s',panelLetters{k},names{k}), ...
        'Units','normalized','FontName',fontName,'FontSize',fs+2, ...
        'FontWeight','bold','HorizontalAlignment','left', ...
        'VerticalAlignment','top','BackgroundColor','white','Margin',1);
end

%% 6. Shared map colorbar
cb=colorbar(axT,'eastoutside');
cb.FontName=fontName; cb.FontSize=fs;
cb.Ticks=[-0.4 -0.2 0 0.2 0.4];
cb.Label.String='r';
cb.Label.FontName=fontName;
cb.Label.FontSize=fs+1;

%% 7. Panel (d): descriptive boxplot
allR=[]; group=[];
for k=1:3
    allR=[allR;D(k).values(:)]; %#ok<AGROW>
    group=[group;k*ones(numel(D(k).values),1)]; %#ok<AGROW>
end
boxplot(axB,allR,group,'Labels',names,'Colors',[.15 .15 .15], ...
    'Widths',0.55,'Whisker',1.5,'Symbol','');
hold(axB,'on');
yline(axB,0,':','Color',[.5 .5 .5],'LineWidth',0.8, ...
    'HandleVisibility','off');
set(axB,'FontName',fontName,'FontSize',fs,'LineWidth',0.8, ...
    'Box','on','TickDir','out');
axB.YGrid='on'; axB.GridAlpha=0.10;
ylim(axB,[-0.25 0.42]);
ylabel(axB,'Pearson r','FontName',fontName,'FontSize',fs+1);
xlabel(axB,'Region','FontName',fontName,'FontSize',fs);
text(axB,0.025,0.978,'(d)','Units','normalized', ...
    'FontName',fontName,'FontSize',fs+3,'FontWeight','bold', ...
    'VerticalAlignment','top','BackgroundColor','white','Margin',1);
for k=1:3
    text(axB,k,-0.195,sprintf('n=%d',D(k).n), ...
        'HorizontalAlignment','center','FontName',fontName,'FontSize',fs-2);
end

%% 8. Statistical disclaimer
annotation(fig,'textbox',posNote,'String',{ ...
    'Black dots: within-region BH-FDR q < 0.05 (Flores: 110 of 1,158 CHIRPS grids).', ...
    'Pooled BH-FDR across all 2,811 grids: NO significant grid.'}, ...
    'FontName',fontName,'FontSize',fs-1,'Interpreter','none', ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'EdgeColor','none','Color',[.15 .15 .15],'FitBoxToText','off');

%% 9. Final panel geometry
% Colorbars can resize M_Map axes, so restore the approved layout.
drawnow;
set(axF,'Units','normalized','Position',posF);
set(axS,'Units','normalized','Position',posS);
set(axT,'Units','normalized','Position',posT);
set(axB,'Units','normalized','Position',posB);
set(cb,'Units','normalized','Position',posCB);
drawnow;

%% 10. Export manuscript and grayscale QC
pngPath=fullfile(outDir,'Figure_4_Spatial_Correlations.png');
pdfPath=fullfile(outDir,'Figure_4_Spatial_Correlations.pdf');
grayPath=fullfile(outDir,'Figure_4_Spatial_Correlations_Grayscale_QC.png');
exportgraphics(fig,pngPath,'Resolution',600,'BackgroundColor','white');
% Raster PDF avoids an unwieldy vector object from GSHHS coastline.
exportgraphics(fig,pdfPath,'ContentType','image','Resolution',600, ...
    'BackgroundColor','white');
for k=1:3, colormap(mapAxes(k),cmapGray); end
drawnow;
exportgraphics(fig,grayPath,'Resolution',300,'BackgroundColor','white');
for k=1:3, colormap(mapAxes(k),cmap); end

%% 11. Save reproducibility metadata and visual QC
Q=table(names',[D.n]',[D.nSig]',[D.nPooled]',[D.nDots]', ...
    [D.medianR]',boxes(:,1),boxes(:,2),boxes(:,3),boxes(:,4), ...
    'VariableNames',{'Region','Valid_grid_count', ...
    'Within_region_FDR_005_count','Pooled_FDR_005_count', ...
    'Displayed_significant_dots','Median_Pearson_r', ...
    'Lon_min','Lon_max','Lat_min','Lat_max'});
writetable(Q,fullfile(outDir,'Figure_4_Visual_QC.csv'));

fid=fopen(fullfile(outDir,'Figure_4_Methods_Metadata.txt'),'w');
assert(fid~=-1,'Unable to write metadata.');
fprintf(fid,'FIGURE 4 | CLEAN LATITUDES / HIGHER-CONTRAST COLOR\n');
fprintf(fid,'Data: %s\nSummary: %s\n',fMat,fCsv);
fprintf(fid,'M_Map Mercator + GSHHS high-resolution coastline.\n');
fprintf(fid,'Exact CHIRPS Figure 1 coordinate boxes, no context expansion.\n');
fprintf(fid,'M_Map latitude tickstyle=dd with exact custom degree-S labels.\n');
fprintf(fid,'Colorbar: true r values; zero-centered [-0.4,+0.4].\n');
fprintf(fid,'Contrast-enhanced diverging RGB stops at -0.2,-0.1,0,0.1,0.2.\n');
fprintf(fid,'No changes to r maps, grid masks, p values, or qFDR.\n');
fprintf(fid,'Flores=110/1158; Sumba=0/565; Timor=0/1088 within-region q<0.05.\n');
fprintf(fid,'Pooled BH-FDR (2811 grids): 0 significant.\n');
fprintf(fid,'All 110 Flores grid centers displayed; no spatial interpolation.\n');
fprintf(fid,'Colored data clipped to original valid CHIRPS land masks.\n');
fprintf(fid,'PDF uses high-resolution raster to avoid GSHHS vector warnings.\n');
fclose(fid);

fprintf('\n===== FIGURE 4 COMPLETE =====\n');
fprintf('Within-region dots: [%d %d %d]; pooled: %d / %d\n', ...
    [D.nDots],sum([D.nPooled]),sum([D.n]));
fprintf('PNG: %s\nPDF: %s\nGrayscale QC: %s\n', ...
    pngPath,pdfPath,grayPath);
fprintf('Latitude labels: degrees South, no minutes notation.\n');
