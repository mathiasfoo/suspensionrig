clear; clc; close all;

%% Load CSV

filePath = 'Test 3.csv';

[pathStr, ~, ~] = fileparts(filePath);
parts = split(pathStr, filesep);
lastWord = parts{end};

T = readtable(filePath);

%% Convert time

T.Time_s = T.Time_ms / 1000;

%% Extract raw signals

y_wheel   = T.Wheel_Plate;
y_chassis = T.Chassis_Plate;
y_road    = T.Road_Plate;

%% Static positions (first 30 samples)

eq_wheel   = mean(y_wheel(1:30));
eq_chassis = mean(y_chassis(1:30));
eq_road    = mean(y_road(1:30));

%% Zero-reference displacement

T.Wheel_Z   = y_wheel   - eq_wheel;
T.Chassis_Z = y_chassis - eq_chassis;
T.Road_Z    = y_road    - eq_road;

%% Frequency sweep processing

uniqueTargets = unique(T.Target_Hz);
uniqueTargets = sort(uniqueTargets);

f_exp = [];
T_chassis_exp = [];
T_wheel_exp = [];
road_amps_exp = [];

for i = 1:length(uniqueTargets)

    target = uniqueTargets(i);

    if target == 0
        continue
    end

    idx = abs(T.Target_Hz - target) < 0.01;
    stepData = T(idx,:);

    if height(stepData) < 200
        continue
    end

    %% Ignore first 2 seconds (settling)

    t_start = stepData.Time_s(1) + 2;

    steadyData = stepData(stepData.Time_s >= t_start,:);

    if height(steadyData) < 50
        continue
    end

    %% Actual frequency

    f_actual = mean(steadyData.Actual_Hz);

    %% Amplitudes from 1st and 99th percentile

    amp_road = ...
        (prctile(steadyData.Road_Z,99) ...
        - prctile(steadyData.Road_Z,1))/2;

    amp_wheel = ...
        (prctile(steadyData.Wheel_Z,99) ...
        - prctile(steadyData.Wheel_Z,1))/2;

    amp_chassis = ...
        (prctile(steadyData.Chassis_Z,99) ...
        - prctile(steadyData.Chassis_Z,1))/2;

    %% Transmissibility (Why do we need to calculate Transmissibility?)

    if amp_road > 0.5

        f_exp(end+1) = f_actual;

        T_wheel_exp(end+1) = amp_wheel / amp_road;

        T_chassis_exp(end+1) = amp_chassis / amp_road;

        road_amps_exp(end+1) = amp_road;

    end

end

fprintf('Processing Complete!\n');

avg_road_amp = mean(road_amps_exp);
avg_road_p2p = 2*avg_road_amp;

fprintf('\n--- ROAD INPUT SUMMARY ---\n');
fprintf('Average Road Amplitude: %.2f mm\n',avg_road_amp);
fprintf('Average Peak-to-Peak: %.2f mm\n',avg_road_p2p);
fprintf('Extracted %d steady-state frequency points.\n\n',length(f_exp));

%% THEORETICAL 2-DOF MODEL

ms = 2.298;
mu = 0.251;
ks = 405.0;
kt = 1795.0;
c = 24.47; % 500 cSt
% c = 32.92; % 800 cSt
% c = 37.24; % 1000 cSt

f_smooth = linspace(0.5,25,500);

w = 2*pi*f_smooth;
s = 1i*w;

detA = (ms*s.^2 + c*s + ks) .* ...
       (mu*s.^2 + c*s + ks + kt) ...
       - (c*s + ks).^2;

Hs = ((c*s + ks).*kt) ./ detA;

Hu = ((ms*s.^2 + c*s + ks).*kt) ./ detA;

T_chassis_theory = abs(Hs);
T_wheel_theory   = abs(Hu);

%% Plot

figure('Position',[100 100 1000 600])

plot(f_smooth,T_chassis_theory,'r-','LineWidth',2)
hold on

plot(f_smooth,T_wheel_theory,'b-','LineWidth',2)

scatter(f_exp,T_chassis_exp,60,'filled',...
    'MarkerFaceColor',[0.86 0.08 0.24])

scatter(f_exp,T_wheel_exp,60,'s','filled',...
    'MarkerFaceColor',[0 0 0.5])

% title(sprintf(['2DOF Quarter-Car Transmissibility: Experimental vs Theoretical\n' ...
%     '%s - Road Peak-to-Peak Displacement: %.1f mm - Damping Coefficient: %.1f Ns/m'],...
%     lastWord,avg_road_p2p,c))

title(sprintf(['FRF: Experimental vs Theoretical\n' ...
    '%s Crank radius: %.1f mm with Damping Coefficient: %.1f Ns/m (500 cSt)'],...
    lastWord,floor(avg_road_p2p/2),c), 'FontSize', 20)

xlabel('Excitation Frequency (Hz)', 'FontSize', 20)
ylabel('Transmissibility, T', 'FontSize', 20)

xlim([0 12])
ylim([0 3])
% ylim([0 max([max(T_chassis_theory) max(T_chassis_exp)])*1.15])

grid on
legend('Chassis Model','Wheel Model', ...
       'Chassis Exp Data','Wheel Exp Data', ...
       'Location','best')
set(gca,'FontSize',20)
%% Save PDF

% pdfFilename = sprintf('%s - p2p %.0fmm.pdf',...
%     lastWord,avg_road_p2p);
% 
% exportgraphics(gcf,pdfFilename,'ContentType','vector');
% 
% fprintf('Saved plot as "%s"\n',pdfFilename);

%% QUANTITATIVE ERROR ANALYSIS

w_exp = 2*pi*f_exp;
s_exp = 1i*w_exp;

detA_exp = (ms*s_exp.^2 + c*s_exp + ks) .* ...
           (mu*s_exp.^2 + c*s_exp + ks + kt) ...
           - (c*s_exp + ks).^2;

Hs_exp = ((c*s_exp + ks).*kt) ./ detA_exp;

Hu_exp = ((ms*s_exp.^2 + c*s_exp + ks).*kt) ./ detA_exp;

T_chassis_theory_exact = abs(Hs_exp);
T_wheel_theory_exact   = abs(Hu_exp);

%% Relative error

E_f_chassis = abs(T_chassis_exp - T_chassis_theory_exact) ...
               ./ T_chassis_theory_exact * 100;

E_f_wheel = abs(T_wheel_exp - T_wheel_theory_exact) ...
               ./ T_wheel_theory_exact * 100;

%% Signed error

Signed_Error_chassis = ...
    ((T_chassis_exp - T_chassis_theory_exact) ...
    ./ T_chassis_theory_exact) * 100;

Signed_Error_wheel = ...
    ((T_wheel_exp - T_wheel_theory_exact) ...
    ./ T_wheel_theory_exact) * 100;

%% Metrics

MAPE_chassis = mean(E_f_chassis);
MAPE_wheel   = mean(E_f_wheel);

Mean_Signed_Error_chassis = mean(Signed_Error_chassis);
Mean_Signed_Error_wheel   = mean(Signed_Error_wheel);

RMSE_chassis = sqrt(mean( ...
    (T_chassis_exp - T_chassis_theory_exact).^2));

RMSE_wheel = sqrt(mean( ...
    (T_wheel_exp - T_wheel_theory_exact).^2));

%% Maximum errors

[Max_Error_chassis, idx_max_chassis] = max(E_f_chassis);
[Max_Error_wheel,   idx_max_wheel]   = max(E_f_wheel);

f_max_error_chassis = f_exp(idx_max_chassis);
f_max_error_wheel   = f_exp(idx_max_wheel);

fprintf('\n=====================================\n');
fprintf(' QUANTITATIVE ERROR ANALYSIS\n');
fprintf('=====================================\n');

fprintf('Chassis MAPE: %.2f %%\n',MAPE_chassis);
fprintf('Wheel MAPE:   %.2f %%\n',MAPE_wheel);

fprintf('-------------------------------------\n');

fprintf('Mean Signed Chassis Error: %.2f %%\n',...
    Mean_Signed_Error_chassis);

fprintf('Mean Signed Wheel Error:   %.2f %%\n',...
    Mean_Signed_Error_wheel);

fprintf('-------------------------------------\n');

fprintf('Chassis RMSE: %.4f\n',RMSE_chassis);
fprintf('Wheel RMSE:   %.4f\n',RMSE_wheel);

fprintf('-------------------------------------\n');

fprintf('Max Chassis Error: %.2f %% at %.2f Hz\n',...
    Max_Error_chassis, f_max_error_chassis);

fprintf('Max Wheel Error: %.2f %% at %.2f Hz\n',...
    Max_Error_wheel, f_max_error_wheel);

fprintf('=====================================\n');