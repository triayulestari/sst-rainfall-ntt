%% ============================================================
% FIGURE 4 FINAL - REVISED LAYOUT
% Spatial Heterogeneity of SST-Rainfall Relationships
%
% Run from:
% Data\5-Spatial-Correlation
%
% Required file:
% spatial_correlation_results.mat
%
% No panel labels or region names are added.
% Add (a)-(d) and Flores/Sumba/Timor manually later.
%% ============================================================

clear;
clc;
close all;

%% ============================================================
% 1. LOAD FINAL SPATIAL RESULTS
%% ============================================================

result_file = 'spatial_correlation_results.mat';

if ~isfile(result_file)
    error(['File ', result_file, ...
        ' tidak ditemukan di folder 5-Spatial-Correlation.']);
end

S = load(result_file);

fprintf('Loaded: %s\n', result_file);

%% ============================================================
% 2. CHECK REQUIRED VARIABLES
%% ============================================================

required_vars = { ...
    'lon_F','lat_F','r_map_F','mask_F','q_region_map_F', ...
    'lon_S','lat_S','r_map_S','mask_S','q_region_map_S', ...
    'lon_T','lat_T','r_map_T','mask_T','q_region_map_T'};

for i = 1:length(required_vars)

    if ~isfield(S,required_vars{i})

        fprintf('\nVariables found:\n');
        disp(fieldnames(S));

        error(['Variable ',required_vars{i}, ...
            ' tidak ditemukan dalam file MAT.']);
    end

end

%% ============================================================
% 3. READ VARIABLES
%% ============================================================

lon_F = S.lon_F(:);
lat_F = S.lat_F(:);

lon_S = S.lon_S(:);
lat_S = S.lat_S(:);

lon_T = S.lon_T(:);
lat_T = S.lat_T(:);

rF = S.r_map_F;
rS = S.r_map_S;
rT = S.r_map_T;

maskF = logical(S.mask_F);
maskS = logical(S.mask_S);
maskT = logical(S.mask_T);

qF = S.q_region_map_F;
qS = S.q_region_map_S;
qT = S.q_region_map_T;

%% ============================================================
% 4. STANDARDIZE MATRIX ORIENTATION
% Required orientation:
% [latitude x longitude]
%% ============================================================

% ---------- Flores ----------
target_F = [length(lat_F) length(lon_F)];

if isequal(size(rF),target_F)
    rFp = rF;
elseif isequal(size(rF),fliplr(target_F))
    rFp = rF';
else
    error('Unexpected size for r_map_F.');
end

if isequal(size(maskF),target_F)
    maskFp = maskF;
elseif isequal(size(maskF),fliplr(target_F))
    maskFp = maskF';
else
    error('Unexpected size for mask_F.');
end

if isequal(size(qF),target_F)
    qFp = qF;
elseif isequal(size(qF),fliplr(target_F))
    qFp = qF';
else
    error('Unexpected size for q_region_map_F.');
end


% ---------- Sumba ----------
target_S = [length(lat_S) length(lon_S)];

if isequal(size(rS),target_S)
    rSp = rS;
elseif isequal(size(rS),fliplr(target_S))
    rSp = rS';
else
    error('Unexpected size for r_map_S.');
end

if isequal(size(maskS),target_S)
    maskSp = maskS;
elseif isequal(size(maskS),fliplr(target_S))
    maskSp = maskS';
else
    error('Unexpected size for mask_S.');
end

if isequal(size(qS),target_S)
    qSp = qS;
elseif isequal(size(qS),fliplr(target_S))
    qSp = qS';
else
    error('Unexpected size for q_region_map_S.');
end


% ---------- Timor ----------
target_T = [length(lat_T) length(lon_T)];

if isequal(size(rT),target_T)
    rTp = rT;
elseif isequal(size(rT),fliplr(target_T))
    rTp = rT';
else
    error('Unexpected size for r_map_T.');
end

if isequal(size(maskT),target_T)
    maskTp = maskT;
elseif isequal(size(maskT),fliplr(target_T))
    maskTp = maskT';
else
    error('Unexpected size for mask_T.');
end

if isequal(size(qT),target_T)
    qTp = qT;
elseif isequal(size(qT),fliplr(target_T))
    qTp = qT';
else
    error('Unexpected size for q_region_map_T.');
end

%% ============================================================
% 5. APPLY MASK
%% ============================================================

rFp(~maskFp) = NaN;
rSp(~maskSp) = NaN;
rTp(~maskTp) = NaN;

qFp(~maskFp) = NaN;
qSp(~maskSp) = NaN;
qTp(~maskTp) = NaN;

%% ============================================================
% 6. COORDINATE MATRICES
%% ============================================================

[LON_F,LAT_F] = meshgrid(lon_F,lat_F);
[LON_S,LAT_S] = meshgrid(lon_S,lat_S);
[LON_T,LAT_T] = meshgrid(lon_T,lat_T);

%% ============================================================
% 7. DATA FOR BOXPLOT
%% ============================================================

vals_F = rFp(maskFp & isfinite(rFp));
vals_S = rSp(maskSp & isfinite(rSp));
vals_T = rTp(maskTp & isfinite(rTp));

vals_F = vals_F(:);
vals_S = vals_S(:);
vals_T = vals_T(:);

fprintf('\n=========================================\n');
fprintf('VALID GRID COUNTS\n');
fprintf('=========================================\n');
fprintf('Flores = %d\n',length(vals_F));
fprintf('Sumba  = %d\n',length(vals_S));
fprintf('Timor  = %d\n',length(vals_T));

%% ============================================================
% 8. PLOT SETTINGS
%% ============================================================

font_name = 'Arial';
font_size = 10;

corr_lim = [-0.4 0.4];

%% ============================================================
% 9. BLUE-WHITE-RED COLORMAP
%% ============================================================

nC = 256;
nHalf = nC/2;

bluePart = [ ...
    linspace(0.10,1.00,nHalf)', ...
    linspace(0.28,1.00,nHalf)', ...
    linspace(0.65,1.00,nHalf)'];

redPart = [ ...
    linspace(1.00,0.75,nHalf)', ...
    linspace(1.00,0.10,nHalf)', ...
    linspace(1.00,0.10,nHalf)'];

cmap = [bluePart; redPart];

%% ============================================================
% 10. CREATE FIGURE
%% ============================================================

fig = figure( ...
    'Color','w', ...
    'Units','pixels', ...
    'Position',[50 90 1950 650]);

%% ============================================================
% 11. FINAL PANEL POSITIONS
%
% Maps remain dominant.
% Boxplot is shorter and centered vertically.
%% ============================================================

pos_F = [0.050 0.565 0.555 0.365];

pos_S = [0.050 0.115 0.270 0.325];

pos_T = [0.350 0.115 0.270 0.325];

pos_Box = [0.755 0.235 0.195 0.575];

%% ============================================================
% 12. FLORES MAP
%% ============================================================

axF = axes('Position',pos_F);
hold(axF,'on');

hF = pcolor(axF,LON_F,LAT_F,rFp);
set(hF,'EdgeColor','none');

shading(axF,'flat');
caxis(axF,corr_lim);
colormap(axF,cmap);

contour(axF, ...
    LON_F,LAT_F,double(maskFp), ...
    [0.5 0.5], ...
    'k-', ...
    'LineWidth',0.8);

sigF = maskFp & isfinite(qFp) & qFp < 0.05;

scatter(axF, ...
    LON_F(sigF), ...
    LAT_F(sigF), ...
    7, ...
    'k', ...
    'filled');

xlim(axF,[min(lon_F) max(lon_F)]);
ylim(axF,[min(lat_F) max(lat_F)]);

ylabel(axF,'Latitude (°)');

grid(axF,'on');
box(axF,'on');

set(axF, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(axF,'off');

%% ============================================================
% 13. SUMBA MAP
%% ============================================================

axS = axes('Position',pos_S);
hold(axS,'on');

hS = pcolor(axS,LON_S,LAT_S,rSp);
set(hS,'EdgeColor','none');

shading(axS,'flat');
caxis(axS,corr_lim);
colormap(axS,cmap);

contour(axS, ...
    LON_S,LAT_S,double(maskSp), ...
    [0.5 0.5], ...
    'k-', ...
    'LineWidth',0.8);

sigS = maskSp & isfinite(qSp) & qSp < 0.05;

scatter(axS, ...
    LON_S(sigS), ...
    LAT_S(sigS), ...
    7, ...
    'k', ...
    'filled');

xlim(axS,[min(lon_S) max(lon_S)]);
ylim(axS,[min(lat_S) max(lat_S)]);

xlabel(axS,'Longitude (°E)');
ylabel(axS,'Latitude (°)');

grid(axS,'on');
box(axS,'on');

set(axS, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(axS,'off');

%% ============================================================
% 14. TIMOR MAP
%% ============================================================

axT = axes('Position',pos_T);
hold(axT,'on');

hT = pcolor(axT,LON_T,LAT_T,rTp);
set(hT,'EdgeColor','none');

shading(axT,'flat');
caxis(axT,corr_lim);
colormap(axT,cmap);

contour(axT, ...
    LON_T,LAT_T,double(maskTp), ...
    [0.5 0.5], ...
    'k-', ...
    'LineWidth',0.8);

sigT = maskTp & isfinite(qTp) & qTp < 0.05;

scatter(axT, ...
    LON_T(sigT), ...
    LAT_T(sigT), ...
    7, ...
    'k', ...
    'filled');

xlim(axT,[min(lon_T) max(lon_T)]);
ylim(axT,[min(lat_T) max(lat_T)]);

xlabel(axT,'Longitude (°E)');

% IMPORTANT:
% no ylabel here to avoid overlap with Sumba panel

grid(axT,'on');
box(axT,'on');

set(axT, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(axT,'off');

%% ============================================================
% 15. SHARED COLORBAR
%% ============================================================

cb = colorbar(axF);

cb.Units = 'normalized';

cb.Position = [0.645 0.285 0.014 0.455];

cb.Label.String = ...
    'Pearson correlation coefficient (r)';

cb.Label.FontName = font_name;
cb.Label.FontSize = font_size+1;

cb.FontName = font_name;
cb.FontSize = font_size;

cb.Ticks = -0.4:0.1:0.4;

%% ============================================================
% 16. FDR NOTE
%% ============================================================

annotation(fig, ...
    'textbox', ...
    [0.638 0.145 0.095 0.075], ...
    'String',{ ...
        '•  Within-region', ...
        '   FDR q < 0.05'}, ...
    'EdgeColor','none', ...
    'FontName',font_name, ...
    'FontSize',9, ...
    'FitBoxToText','on');

%% ============================================================
% 17. BOXPLOT
%% ============================================================

axB = axes('Position',pos_Box);

all_r = [ ...
    vals_F;
    vals_S;
    vals_T];

group_id = [ ...
    ones(length(vals_F),1);
    2*ones(length(vals_S),1);
    3*ones(length(vals_T),1)];

boxplot(axB, ...
    all_r, ...
    group_id, ...
    'Labels',{'Flores','Sumba','Timor'}, ...
    'Colors','k', ...
    'Whisker',1.5, ...
    'Symbol','');

hold(axB,'on');

yline(axB, ...
    0, ...
    '--', ...
    'Color',[0.40 0.40 0.40], ...
    'LineWidth',0.8);

%% sample sizes
text(axB,1,-0.148, ...
    sprintf('n = %d',length(vals_F)), ...
    'HorizontalAlignment','center', ...
    'FontName',font_name, ...
    'FontSize',8);

text(axB,2,-0.148, ...
    sprintf('n = %d',length(vals_S)), ...
    'HorizontalAlignment','center', ...
    'FontName',font_name, ...
    'FontSize',8);

text(axB,3,-0.148, ...
    sprintf('n = %d',length(vals_T)), ...
    'HorizontalAlignment','center', ...
    'FontName',font_name, ...
    'FontSize',8);

% tighter vertical range
ylim(axB,[-0.16 0.40]);

yticks(axB,-0.1:0.1:0.4);

ylabel(axB,'Pearson correlation coefficient (r)');
xlabel(axB,'Region');

grid(axB,'on');
box(axB,'on');

set(axB, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

%% style boxplot
boxes = findobj(axB,'Tag','Box');
set(boxes,'LineWidth',1.3);

medians = findobj(axB,'Tag','Median');
set(medians,'LineWidth',1.8);

whiskers = findobj(axB,'Tag','Whisker');
set(whiskers,'LineWidth',0.8,'LineStyle',':');

caps = findobj(axB,'Tag','Cap');
set(caps,'LineWidth',0.8);

hold(axB,'off');

%% ============================================================
% 18. SAVE SUMMARY TABLE
%% ============================================================

Region = {'Flores';'Sumba';'Timor'};

N = [ ...
    length(vals_F);
    length(vals_S);
    length(vals_T)];

Minimum = [ ...
    min(vals_F);
    min(vals_S);
    min(vals_T)];

Q1 = [ ...
    prctile(vals_F,25);
    prctile(vals_S,25);
    prctile(vals_T,25)];

Median = [ ...
    median(vals_F);
    median(vals_S);
    median(vals_T)];

Q3 = [ ...
    prctile(vals_F,75);
    prctile(vals_S,75);
    prctile(vals_T,75)];

IQR = Q3-Q1;

Mean = [ ...
    mean(vals_F);
    mean(vals_S);
    mean(vals_T)];

SD = [ ...
    std(vals_F);
    std(vals_S);
    std(vals_T)];

Maximum = [ ...
    max(vals_F);
    max(vals_S);
    max(vals_T)];

SummaryTable = table( ...
    Region,N,Minimum,Q1,Median,Q3,IQR,Mean,SD,Maximum);

writetable( ...
    SummaryTable, ...
    'spatial_correlation_distribution_summary.csv');

%% ============================================================
% 19. SAVE FIGURE
%% ============================================================

drawnow;

exportgraphics( ...
    fig, ...
    'Figure4_Spatial_Heterogeneity_FINAL_rev2.png', ...
    'Resolution',600);

exportgraphics( ...
    fig, ...
    'Figure4_Spatial_Heterogeneity_FINAL_rev2.pdf', ...
    'ContentType','vector');

fprintf('\n=========================================\n');
fprintf('FINAL FIGURE 4 SAVED\n');
fprintf('=========================================\n');
fprintf('Figure4_Spatial_Heterogeneity_FINAL_rev2.png\n');
fprintf('Figure4_Spatial_Heterogeneity_FINAL_rev2.pdf\n');