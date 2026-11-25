clc
clear all
close all

% Read pull down test for 500cst.
for i = 1:10
    data = readtable(sprintf('%d.csv',i));

    if i == 1
        time = data.Time_ms;
        Y = zeros(length(time),10);
    end
    output = data.Chassis_Position_mm;
    Y(:,i) = output;
    % Extract quantities
    maxOutput(i)   = max(output);
    firstOutput(i) = output(1);
    finalOutput(i) = output(end);

    del(i) = log(abs(firstOutput(i) - finalOutput(i))/abs(maxOutput(i) - finalOutput(i)));
    damp_ratio(i) = del(i)./sqrt(pi^2 + del(i)^2);
end

% Statistics
yMean = mean(Y,2);
yMin = min(Y,[],2);
yMax = max(Y,[],2);

% Plot
figure(1)
set(gcf,'Position',[100 100 1400 600])
subplot(1,2,1)
hold on;

% Shaded min-max region
fill([time; flipud(time)], ...
     [yMin; flipud(yMax)], ...
     [0.7 0.7 1], ...
     'FaceAlpha',0.3, ...
     'EdgeColor','none');

% Mean line
plot(time, yMean, ...
    'b--', ...
    'LineWidth',2);
set(gca,'FontSize',14)

xlabel('Time (s)', 'FontSize', 14);
ylabel('Chassis plate position (mm)', 'FontSize', 14);
title('Free decay responses for 500 cSt', 'FontSize', 14);
grid on;
box on
legend('Min-Max Range','Mean');

subplot(1,2,2)
axis off
axTop = axes('Position',[0.60 0.55 0.30 0.30]);
scatter(1:length(damp_ratio),damp_ratio,'filled')
hold on
yline(mean(damp_ratio), 'r-', 'LineWidth', 2)
set(gca,'FontSize',14)
xlabel('Experiment number', 'FontSize', 14)
ylabel('Damping ratio, \zeta', 'FontSize', 14)
xticks(1:10)
xlim([0 11])
ylim([0.35 0.45])
title(sprintf('Mean = %.3f', mean(damp_ratio)), 'FontSize', 14)
grid on
box on

axBottom = axes('Position',[0.60 0.15 0.30 0.25]);
boxplot(damp_ratio)
set(gca,'FontSize',14)
ylim([0.35 0.45])
xlabel('500 cSt', 'FontSize', 14)
ylabel('Damping ratio, \zeta', 'FontSize', 14)
grid on
box on



