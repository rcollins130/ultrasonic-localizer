%%%
% ULTRASONIC LOCALIZER
% EE292Q FINAL PROJECT SPRING 2023
% 


%% SETUP & PARAMETERS
clear; close all;

% CAPTUTRE OPTIONS
data_from_file = 1; % if true, load data from directory instead of serial
data_to_file = 1; % if true, output captured data to directory
use_preprocess = 0; % if true, localized based on preprocessed IQ data
use_xcorr = 1; % if true, localize using xcorr method

use_kalman = 0;

% physical parameters
c = 343; % speed of sound, m/s
sensor_locs = [-.15, -.05, .05, .15]; % relative sensor x-locations, m
%sensorPosCmInit = [-30 75]; % initial sensor location in cm
sensorPosCmInit = [0 0]; % initial sensor location in cm

% route of sensor, in cm
route = [
    20 0;
    20 0;
    20 0;
    0 -20;
    -20 0;
    -20 0;
    -20 0;
    0 -20;
    20 0;
    20 0;
    20 0
    ];
estimate = [0,0,0,0]';
P = [
    1000,0,0,0;
    0,1000,0,0;
    0,0,1000,0;
    0,0,0,1000];

truthPoints = [
    -20    30
    20    30
    20    60
   -20    60
   -20    90
    20    90
    20   120
   -20   120];

% targetTruthPosCm = [8 138; -3.42 163];
targetTruthPosCm = [8 138; -4 163];
targetDiaCm = 7.5;

numTargets = size(targetTruthPosCm, 1); % number of targets

% capture parameters
% file data parameters
input_directory = "test_data/20230605_153646";

output_directory = "test_data";
filefmt = "yyyyMMdd_HHmmssSSS";
dirfmt = "yyyyMMdd_HHmmss";

if data_to_file && ~data_from_file
    output_directory = fullfile(output_directory, string(datetime,dirfmt));
    mkdir(output_directory)
end

% serial parameters
if ismac
    serial_port = "/dev/tty.usbmodem2102";
else
    serial_port = "COM3";
end
baud = 1000000; % baud rate
numMeasures = 5; % captures per sensor
numDevices = length(sensor_locs); % number of sensors
distMeasure = 2; % maximum distance measurement, matches firmware, m

% plotting parameters
%   these are also defined in some functions, but here because I'm lazy
% backprop image parameters
Nx = 400;
backprop_grid_size = 2;
dx = backprop_grid_size/Nx;

% a scan plot parameters
d = (1:distMeasure*60)/60;

% localization plot params
widthcm = 100;
heightcm = 200;

% get truth target positions in relative plot grid space, for 
%   localization kernel
tt_pos(1,:) = [0, 0];
tt_pos(2,:) = targetTruthPosCm(2,:) - targetTruthPosCm(1,:);
tt_pos_idx = floor(tt_pos / (100 *dx));

%% INITIALIZE SENSOR
if ~data_from_file
    s = serialport(serial_port, baud);
end

%% INITIALIZE PLOTS
% Target Image
fig1 = figure(1);
set(gcf, 'Position', [848   704   560   420]);

fig1img1 = imagesc(zeros(Nx,Nx)); hold on;
fig1tp1 = plot( ...
    zeros(numTargets,1), ...
    zeros(numTargets,1), ...
    'ro','MarkerSize',10,'LineWidth',3 ...
    );
title('Target Image')
xlabel('X (cm)')
ylabel('Z(cm)')
xticks([1 xticks])
yticks([1 yticks])
yticklabels(floor(yticks*dx*100))
xticklabels(ceil(abs(xticks-Nx/2)*dx*100))
set(gca,'YDir','normal')

% A-Scan
fig2 = figure(2); hold on;
set(gcf, 'Position', [847   158   560   420]);

subplot(2,1,1)
fig2l1 = plot(d,zeros(size(d,2),numDevices),'LineStyle','-');
% set(gca, 'ColorOrderIndex', 1)
subplot(2,1,2)
fig2l2 = plot(d,zeros(size(d,2),numDevices),'LineStyle','-','LineWidth',2);
title('Sensor A-Scan')
xlabel('Distance, m')

% Localization
fig3 = figure(3); hold on;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [55   142   760   980]);
% scene = zeros(height,width);
% imagesc(scene);

fig3l1 = plot(targetTruthPosCm(:,1), targetTruthPosCm(:,2), ...
    'ro','MarkerFaceColor','r','MarkerSize',5, ...
    'DisplayName','Targets');

plot(truthPoints(:,1), truthPoints(:,2),'k');

fig3l2 = rectangle('Position', [sensorPosCmInit(1)-7 sensorPosCmInit(2)-2 14 4],'FaceColor','r');
fig3l3 = plot((sensorPosCmInit(1)), sensorPosCmInit(2), 'bo');
% tempPosPrev = sensorPosCmInit;
% for idx = 1:size(route,1)
%     tempPos(1) = tempPosPrev(1) + route(idx,1);
%     tempPos(2) = tempPosPrev(2) + route(idx,2);
%     hold on
%     line(([tempPosPrev(1) tempPos(1)]), [tempPosPrev(2) tempPos(2)]);
%     hold off
%     tempPosPrev = tempPos;
% end

fig3l4 = text(0,0, sprintf("init"), ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','top', ...
    'FontSize',20, ...
    'FontWeight','bold', ...
    'Color','k');
axis image;
set(gca,'fontsize',16)
title('Scene')
xlabel('X (cm)')
ylabel('Z(cm)')

ylim([0,heightcm]);
xlim([-widthcm/2, widthcm/2]);
lastPos = [nan, nan];

%% LOCALIZATION LOOP
N = 10000000;
for ii = 1:N
    % Capture Ultrasonic Data
    %   AscanData:
    % [device, measurement, [I,Q], samples]
    %   Params:
    % [port, range, amp, samples, op_freq, bandwidth]

    if data_from_file
        [AscanData, params] = GetAscanDataFromFile(input_directory, ii);
    else
        [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
    end
    
    AscanData = AscanData(:,:,:,1:distMeasure*60);

    % Preprocess IQ Data
    [ppIQ, scaledAscan, deviceAscan] = preprocess_IQ(AscanData, numTargets);
    if use_preprocess
        IQ_data = ppIQ;
    else
        IQ_data = AscanData;
    end

    % Backpropagate to create image
    Im = zeros(400, 400, numDevices);
    for ii_dev = 1:numDevices
        % upconvert back to sample rate
        [data_pb, Fs] = upconv( ...
            squeeze(IQ_data(ii_dev,:,1,:)), ... % I
            squeeze(IQ_data(ii_dev,:,2,:)), ... % Q
            params(ii_dev,1,5)); % fs
        
        % define time vector
        t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;
        
        % backprojection
        Im(:,:,ii_dev) = BackProj( ...
            hilbert(data_pb), ... % analytic signal of time series data
            sensor_locs(ii_dev), ... % receiver location(s)
            sensor_locs(ii_dev), ... % source location(s)
            c, ... % speed of sound
            Fs, ... % ?
            backprop_grid_size, ... % x, m
            backprop_grid_size, ... % z, m
            Nx ...
            );
    end
    % merge backprop images
    combined_Im = squeeze(sum(abs(Im),3)).^2;
    
    if use_xcorr
        % itentify targets by xcorr method
        numFound = 2;
        [points, ~, heatmap] = FindTargetsXcorr(combined_Im, tt_pos_idx);
    else
        % Identify targets in backpropgatation image
        [numFound, points] = FindTargets(numTargets, combined_Im);
    end

    % update point plots
    fig1img1.CData = combined_Im;
    fig1tp1.XData = points(:,1);
    fig1tp1.YData = points(:,2);
    
    % convert to cm
    points(:,1) = points(:,1) - Nx/2;
    points = points * (100*dx);

    % correct for diameter of target
    pnorm = points ./ vecnorm(points,2,2);
    points = points + pnorm * targetDiaCm/2;    

    % Self-localize
    if numFound == numTargets
        % convert target x-points into localization plot grid space
        [x,z] = calcSenorsPos(targetTruthPosCm, points);
        sensorPosMeasureCm = [x,z];

        %apply kalman filter
        if use_kalman
            [estimate,P] = kalman(estimate, P, sensorPosMeasureCm');
            sensorPosCm = [estimate(1), estimate(2)];
        else
            sensorPosCm = sensorPosMeasureCm;
        end

%         figure(fig3); hold on;
%         % plot((sensorPosCm(1)+widthcm/2)/(dx*100),sensorPosCm(2)/(dx*100));
% %         fig3l3.XData = (sensorPosCm(1)+widthcm/2)/(dx*100);
% %         fig3l3.YData = sensorPosCm(2)/(dx*100);
%         hold off;
        % line(([tempPosPrev(1) tempPos(1)]+widthcm/2)./(dx*100), [tempPosPrev(2) tempPos(2)]/(dx*100));
        if ~any(isnan(lastPos))
            plot([lastPos(1),  sensorPosCm(1)], [lastPos(2), sensorPosCm(2)],'b');
        end
        fig3l3.XData = sensorPosCm(1);
        fig3l3.YData = sensorPosCm(2);
        fig3l2.Position = [sensorPosCm(1)-7 sensorPosCm(2)-2 14 4];
        fig3l4.Position = [sensorPosCm(1), sensorPosCm(2)-2];
        fig3l4.String = sprintf("(%0.1f, %0.1f)", sensorPosCm);

        lastPos = sensorPosCm;
    end
    % Update Plots

    for lidx=1:length(fig2l1)
        fig2l1(lidx).YData = deviceAscan(:,lidx);
        fig2l2(lidx).YData = scaledAscan(:,lidx);
    end

    if data_to_file && ~ data_from_file
        save(fullfile(output_directory, string(datetime, filefmt)),'AscanData','params')
    end
    pause(0.01)

end

%% CLEANUP 
clear s
