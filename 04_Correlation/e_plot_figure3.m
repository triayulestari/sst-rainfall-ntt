%% ============================================================
% FINAL PLOT - FIGURE 3 (REVISED LAYOUT)
% Folder: 4-Correlation
%
% Required file:
%   Figure3_final_results.mat
%
% Expected variables:
%   lags        : 1 x nLag
%   r_lag       : 3 x nLag   (Flores, Sumba, Timor)
%   q_lag       : 3 x nLag
%   r_season    : 3 x 4      (Flores, Sumba, Timor) x (DJF,MAM,JJA,SON)
%   q_season    : 3 x 4
%% ============================================================

clear; clc; close all;

%% ============================================================
% 1. LOAD DATA
%% ============================================================
result_file = 'Figure3_final_results.mat';

if ~isfile(result_file)
    error('File %s tidak ditemukan di folder 4-Correlation.', result_file);
end

load(result_file);
fprintf('Loaded: %s\n', result_file);

%% ============================================================
% 2. SETTINGS
%% ============================================================
region_names = {'Flores','Sumba','Timor'};
season_names = {'DJF','MAM','JJA','SON'};

% warna konsisten
cFlores = [0.0000 0.4470 0.7410];
cSumba  = [0.8500 0.3250 0.0980];
cTimor  = [0.9290 0.6940 0.1250];
region_colors = [cFlores; cSumba; cTimor];

markers = {'o','s','^'};

font_name = 'Arial';
font_size = 10;
dagger_symbol = char(8224);   % †

%% ============================================================
% 3. FIGURE CANVAS
% Lag panel dibuat lebih slim
% Heatmap dibuat lebih lebar
%% ============================================================
fig = figure('Color','w','Units','pixels','Position',[70 120 1820 470]);

% layout baru
posLag  = [0.055 0.16 0.41 0.77];
posHeat = [0.52  0.16 0.40 0.77];
%% ============================================================
% 4. PANEL (a): LAGGED CORRELATION
%% ============================================================
ax1 = axes('Position',posLag);
hold(ax1,'on');

for r = 1:3
    plot(ax1, lags, r_lag(r,:), ...
        '-', ...
        'Color', region_colors(r,:), ...
        'LineWidth', 1.8, ...
        'Marker', markers{r}, ...
        'MarkerSize', 7, ...
        'MarkerFaceColor', 'none');
end

% reference lines
yline(ax1,0,'--','Color',[0.45 0.45 0.45],'LineWidth',0.9,'HandleVisibility','off');
xline(ax1,0,':','Color',[0.55 0.55 0.55],'LineWidth',0.9,'HandleVisibility','off');

% significance markers
for r = 1:3
    for j = 1:length(lags)

        rr = r_lag(r,j);
        qq = q_lag(r,j);

        if ~isfinite(rr) || ~isfinite(qq)
            continue
        end

        if rr >= 0
            ytxt = rr + 0.03;
        else
            ytxt = rr - 0.03;
        end

        if qq < 0.05
            text(ax1, lags(j), ytxt, '*', ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
                'Color','k', ...
                'Interpreter','none');
        elseif qq < 0.10
            text(ax1, lags(j), ytxt, dagger_symbol, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
                'Color','k', ...
                'Interpreter','none');
        end
    end
end

xlim(ax1,[-6 6]);
ylim(ax1,[-0.4 0.4]);
xticks(ax1,-6:1:6);
yticks(ax1,-0.4:0.1:0.4);

xlabel(ax1,'Lag (months)','FontName',font_name,'FontSize',font_size+1);
ylabel(ax1,'Pearson correlation coefficient (r)','FontName',font_name,'FontSize',font_size+1);

% teks arah
text(ax1,-5.7,-0.36,'Rainfall leads SST', ...
    'FontName',font_name,'FontSize',9, ...
    'FontAngle','italic','Color',[0.35 0.35 0.35]);

text(ax1,4.1,-0.36,'SST leads rainfall', ...
    'FontName',font_name,'FontSize',9, ...
    'FontAngle','italic','Color',[0.35 0.35 0.35]);

% legend digeser agak ke tengah supaya pojok kiri atas kosong untuk (a)
lgd = legend(ax1, region_names, ...
    'Box','off', ...
    'FontName',font_name, ...
    'FontSize',10);

lgd.Units = 'normalized';
lgd.Position = [0.115 0.73 0.11 0.16];  
% kalau masih ingin sedikit lebih ke kanan, ubah angka pertama jadi 0.12 atau 0.125

grid(ax1,'on');
box(ax1,'on');

set(ax1, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.9, ...
    'Layer','top');

hold(ax1,'off');

%% ============================================================
% 5. PANEL (b): HEATMAP
%% ============================================================
ax2 = axes('Position',posHeat);

imagesc(ax2, r_season);
caxis(ax2,[-1 1]);

set(ax2, ...
    'XTick',1:4, ...
    'XTickLabel',season_names, ...
    'YTick',1:3, ...
    'YTickLabel',region_names, ...
    'YDir','reverse', ...   % supaya Flores di atas
    'TickLength',[0 0], ...
    'FontName',font_name, ...
    'FontSize',font_size+1, ...
    'LineWidth',0.9);

xlabel(ax2,'Season','FontName',font_name,'FontSize',font_size+2);
ylabel(ax2,'Region','FontName',font_name,'FontSize',font_size+2);

% blue-white-red colormap
nC = 256;
nHalf = nC/2;

bluePart = [ ...
    linspace(0.16,1.00,nHalf)', ...
    linspace(0.36,1.00,nHalf)', ...
    linspace(0.68,1.00,nHalf)'];

redPart = [ ...
    linspace(1.00,0.85,nHalf)', ...
    linspace(1.00,0.12,nHalf)', ...
    linspace(1.00,0.12,nHalf)'];

cmap = [bluePart; redPart];
colormap(ax2,cmap);

hold(ax2,'on');

% cell borders
for xg = 0.5:1:4.5
    plot(ax2,[xg xg],[0.5 3.5],'-','Color',[0.88 0.88 0.88],'LineWidth',0.8);
end

for yg = 0.5:1:3.5
    plot(ax2,[0.5 4.5],[yg yg],'-','Color',[0.88 0.88 0.88],'LineWidth',0.8);
end

% write values
for r = 1:3
    for s = 1:4

        rr = r_season(r,s);
        qq = q_season(r,s);

        if qq < 0.05
            sig_symbol = '*';
        elseif qq < 0.10
            sig_symbol = dagger_symbol;
        else
            sig_symbol = '';
        end

        txt = [sprintf('%.2f',rr) sig_symbol];

        if abs(rr) >= 0.55
            txt_color = 'w';
        else
            txt_color = 'k';
        end

        text(ax2, s, r, txt, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontName',font_name, ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'Color',txt_color, ...
            'Interpreter','none');
    end
end

hold(ax2,'off');

%% ============================================================
% 6. COLORBAR
%% ============================================================
cb = colorbar(ax2);
cb.Units = 'normalized';
cb.Position = [0.94 0.16 0.014 0.77];
cb.Label.String = 'Pearson correlation coefficient (r)';
cb.Label.FontName = font_name;
cb.Label.FontSize = font_size+2;
cb.FontName = font_name;
cb.FontSize = font_size;

ticks = -1:0.2:1;
cb.Ticks = ticks;
cb.TickLabels = arrayfun(@(x) sprintf('%g',x), ticks, 'UniformOutput', false);

%% ============================================================
% 7. SAVE
%% ============================================================
exportgraphics(fig,'Figure3_Temporal_Seasonal_FINAL_rev2.png','Resolution',600);
exportgraphics(fig,'Figure3_Temporal_Seasonal_FINAL_rev2.pdf','ContentType','vector');

fprintf('\n========================================\n');
fprintf('Figure 3 revised final saved:\n');
fprintf('1. Figure3_Temporal_Seasonal_FINAL_rev2.png\n');
fprintf('2. Figure3_Temporal_Seasonal_FINAL_rev2.pdf\n');
fprintf('========================================\n');