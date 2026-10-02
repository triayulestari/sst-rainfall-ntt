%% ============================================================
% FIGURE 5 FINAL
% Climate-Mode Sensitivity of Seasonal SST-Rainfall Correlations
%
% Run from:
% Data\7-Climate-Mode-Sensitivity
%
% Final values from the climate-mode sensitivity analysis.
%
% Rows:
% 1 = Flores
% 2 = Sumba
% 3 = Timor
%
% Columns:
% DJF MAM JJA SON
%
% No panel labels (a), (b) are added.
% Add them manually later for consistency with other figures.
%% ============================================================

clear;
clc;
close all;

%% ============================================================
% 1. FINAL PARTIAL-CORRELATION VALUES
%% ============================================================

% After controlling Niño 3.4
r_nino = [ ...
     0.079  -0.193   0.835   0.418; ...
     0.110  -0.340   0.821   0.160; ...
     0.243  -0.335   0.741   0.746];

% After controlling DMI
r_dmi = [ ...
    -0.527   0.207   0.698   0.016; ...
    -0.371  -0.123   0.665  -0.129; ...
    -0.149   0.170   0.655   0.467];


%% ============================================================
% 2. FDR STATUS
%
% No partial correlation retained q_FDR < 0.05.
%
% Suggestive Niño-controlled relationships:
% Flores JJA
% Sumba JJA
% Timor JJA
% Timor SON
%
% DMI-controlled:
% none retained at q_FDR < 0.10
%% ============================================================

suggestive_nino = false(3,4);

suggestive_nino(1,3) = true;   % Flores JJA
suggestive_nino(2,3) = true;   % Sumba JJA
suggestive_nino(3,3) = true;   % Timor JJA
suggestive_nino(3,4) = true;   % Timor SON

suggestive_dmi = false(3,4);

dagger_symbol = char(8224);     % †


%% ============================================================
% 3. LABELS
%% ============================================================

region_names = {'Flores','Sumba','Timor'};
season_names = {'DJF','MAM','JJA','SON'};

font_name = 'Arial';
font_size = 10;


%% ============================================================
% 4. BLUE-WHITE-RED COLORMAP
%% ============================================================

nC = 256;
nHalf = nC/2;

bluePart = [ ...
    linspace(0.16,1.00,nHalf)', ...
    linspace(0.36,1.00,nHalf)', ...
    linspace(0.68,1.00,nHalf)'];

redPart = [ ...
    linspace(1.00,0.78,nHalf)', ...
    linspace(1.00,0.12,nHalf)', ...
    linspace(1.00,0.12,nHalf)'];

cmap = [bluePart; redPart];


%% ============================================================
% 5. CREATE SLIM FIGURE
%% ============================================================

fig = figure( ...
    'Color','w', ...
    'Units','pixels', ...
    'Position',[80 140 1450 480]);


% Panel positions
% [left bottom width height]

posNino = [0.075 0.18 0.375 0.70];
posDMI  = [0.505 0.18 0.375 0.70];


%% ============================================================
% 6. PANEL LEFT - NIÑO 3.4 CONTROLLED
%% ============================================================

ax1 = axes('Position',posNino);

imagesc(ax1,r_nino);

caxis(ax1,[-1 1]);
colormap(ax1,cmap);

set(ax1, ...
    'XTick',1:4, ...
    'XTickLabel',season_names, ...
    'YTick',1:3, ...
    'YTickLabel',region_names, ...
    'YDir','reverse', ...
    'TickLength',[0 0], ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8);

xlabel(ax1,'Season');

title(ax1, ...
    '(a) Niño 3.4-controlled', ...
    'FontName',font_name, ...
    'FontSize',12, ...
    'FontWeight','bold');


hold(ax1,'on');


% Cell borders
for xg = 0.5:1:4.5
    plot(ax1,[xg xg],[0.5 3.5], ...
        '-', ...
        'Color',[0.88 0.88 0.88], ...
        'LineWidth',0.7);
end

for yg = 0.5:1:3.5
    plot(ax1,[0.5 4.5],[yg yg], ...
        '-', ...
        'Color',[0.88 0.88 0.88], ...
        'LineWidth',0.7);
end


% Values
for r = 1:3

    for s = 1:4

        rr = r_nino(r,s);

        if suggestive_nino(r,s)
            sigtxt = dagger_symbol;
        else
            sigtxt = '';
        end

        txt = [sprintf('%.2f',rr) sigtxt];

        if abs(rr) >= 0.55
            txt_color = 'w';
        else
            txt_color = 'k';
        end

        text(ax1,s,r,txt, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontName',font_name, ...
            'FontSize',11, ...
            'FontWeight','bold', ...
            'Color',txt_color, ...
            'Interpreter','none');

    end

end

hold(ax1,'off');


%% ============================================================
% 7. PANEL RIGHT - DMI CONTROLLED
%% ============================================================

ax2 = axes('Position',posDMI);

imagesc(ax2,r_dmi);

caxis(ax2,[-1 1]);
colormap(ax2,cmap);

set(ax2, ...
    'XTick',1:4, ...
    'XTickLabel',season_names, ...
    'YTick',1:3, ...
    'YTickLabel',{}, ...
    'YDir','reverse', ...
    'TickLength',[0 0], ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8);

xlabel(ax2,'Season');

title(ax2, ...
    '(b) DMI-controlled', ...
    'FontName',font_name, ...
    'FontSize',12, ...
    'FontWeight','bold');


hold(ax2,'on');


% Cell borders
for xg = 0.5:1:4.5
    plot(ax2,[xg xg],[0.5 3.5], ...
        '-', ...
        'Color',[0.88 0.88 0.88], ...
        'LineWidth',0.7);
end

for yg = 0.5:1:3.5
    plot(ax2,[0.5 4.5],[yg yg], ...
        '-', ...
        'Color',[0.88 0.88 0.88], ...
        'LineWidth',0.7);
end


% Values
for r = 1:3

    for s = 1:4

        rr = r_dmi(r,s);

        if suggestive_dmi(r,s)
            sigtxt = dagger_symbol;
        else
            sigtxt = '';
        end

        txt = [sprintf('%.2f',rr) sigtxt];

        if abs(rr) >= 0.55
            txt_color = 'w';
        else
            txt_color = 'k';
        end

        text(ax2,s,r,txt, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontName',font_name, ...
            'FontSize',11, ...
            'FontWeight','bold', ...
            'Color',txt_color, ...
            'Interpreter','none');

    end

end

hold(ax2,'off');


%% ============================================================
% 8. SHARED COLORBAR
%% ============================================================

cb = colorbar(ax2);

cb.Units = 'normalized';
cb.Position = [0.905 0.18 0.014 0.70];

cb.Label.String = ...
    'Partial correlation coefficient (r)';

cb.Label.FontName = font_name;
cb.Label.FontSize = font_size+1;

cb.FontName = font_name;
cb.FontSize = font_size;

cb.Ticks = -1:0.2:1;


%% ============================================================
% 9. SAVE
%% ============================================================

drawnow;

exportgraphics( ...
    fig, ...
    'Figure5_Climate_Mode_Sensitivity_FINAL.png', ...
    'Resolution',600);

exportgraphics( ...
    fig, ...
    'Figure5_Climate_Mode_Sensitivity_FINAL.pdf', ...
    'ContentType','vector');

fprintf('\n=========================================\n');
fprintf('FINAL FIGURE 5 SAVED\n');
fprintf('=========================================\n');
fprintf('Figure5_Climate_Mode_Sensitivity_FINAL.png\n');
fprintf('Figure5_Climate_Mode_Sensitivity_FINAL.pdf\n');