%%%
% ULTRASONIC LOCALIZER
% EE292Q FINAL PROJECT SPRING 2023
% 


%% SETUP & PARAMETERS
clear; close all;

% physical parameters
c = 343; % speed of sound, m
% sensor_locs = [-0.07 0 0.07]; % relative sensor x-locations, m
% sensor_locs = [0.12 0 -0.12]; % relative sensor x-locations, m
sensor_locs = [-.15, -.05, .05, .15];
route = [20 0;20 0;20 0;0 -20;-20 0;-20 0;-20 0;0 -20;20 0;20 0;20 0];
estimate = [0,0,0,0]';
P = [1000,0,0,0;0,1000,0,0;0,0,1000,0;0,0,0,1000];
target_locs = [0, 0;
               -0.32, 0.32]; % target [x,z] locations, m
% target_locs = [0, 0;
%                -0.225, 0.1125]; % target [x,z] locations, m

numTargets = size(target_locs, 1); % number of targets

% capture parameters
% file data parameters
data_from_file = 0; % if true, load data from directory instead of serial
input_directory = "test_data/20230604_190328";

data_to_file = 0; % if true, output captured data to directory
output_directory = "test_data";
filefmt = "yyyyMMdd_HHmmssSSS";
dirfmt = "yyyyMMdd_HHmmss";

if data_to_file && ~ data_from_file
    output_directory = fullfile(output_directory, string(datetime,dirfmt));
    mkdir(output_directory)
end

% serial parameters
% serial_port = "COM3";
serial_port = "COM3";
baud = 1000000; % baud rate
numMeasures = 3; % captures per sensor
numDevices = length(sensor_locs); % number of sensors
distMeasure = 2; % maximum distance measurement, matches firmware

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
width = widthcm/(100*dx);
height = heightcm/(100*dx);
%widthcm = 600*100*dx;

targetTruthPosCm = [8 138; -3.42 163];
targetTruthPos = targetTruthPosCm./(dx*100);
targetTruthPos(:,1) = targetTruthPos(:,1) + width/2;
sensorPosCmInit = [-30 75];

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
subplot(2,1,1)
fig2l1 = plot(d,zeros(size(d,2),numDevices),'LineStyle','-');
% set(gca, 'ColorOrderIndex', 1)
subplot(2,1,2)
fig2l2 = plot(d,zeros(size(d,2),numDevices),'LineStyle','-','LineWidth',2);
title('Sensor A-Scan')
xlabel('Distance, m')


fig3 = figure(3); hold on;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 150 500 600]);
scene = zeros(height,width);
imagesc(scene);
fig3l1 = plot(targetTruthPos(:,1), targetTruthPos(:,2), ...
    'ro','MarkerFaceColor','r','MarkerSize',5, ...
    'DisplayName','Targets');
% fig3l2 = plot(0,0,'gs','DisplayName', 'Sensors');
fig3l2 = rectangle('Position', [sensorPosCmInit(1)+widthcm/2-7 sensorPosCmInit(2)-2 14 4]./(dx*100),'FaceColor',[1 1 1]);
fig3l3 = plot((sensorPosCmInit(1)+widthcm/2)/(dx*100), sensorPosCmInit(2)/(dx*100), '*');
tempPosPrev = sensorPosCmInit;
for idx = 1:size(route,1)
    tempPos(1) = tempPosPrev(1) + route(idx,1);
    tempPos(2) = tempPosPrev(2) + route(idx,2);
    hold on
    line(([tempPosPrev(1) tempPos(1)]+widthcm/2)./(dx*100), [tempPosPrev(2) tempPos(2)]/(dx*100));
    hold off
    tempPosPrev = tempPos;
end
    

fig3l4 = text(0,0, sprintf("init"), ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','top', ...
    'FontSize',14, ...
    'FontWeight','bold', ...
    'Color','w');
axis image;
set(gca,'fontsize',16)
title('Scene')
xlabel('X (cm)')
ylabel('Z(cm)')
xticks([1 xticks])
yticks([1 yticks])
yticklabels(floor(yticks*dx*100))
xticklabels(ceil(abs(xticks-width/2)*dx*100))

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
    ppIQ = AscanData;
    % Backpropagate to create image
    Im = zeros(400, 400, numDevices);
    for ii_dev = 1:numDevices
        % upconvert back to sample rate
        [data_pb, Fs] = upconv( ...
            squeeze(ppIQ(ii_dev,:,1,:)), ... % I
            squeeze(ppIQ(ii_dev,:,2,:)), ... % Q
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

    % itentify targets by xcorr method
    numFound = 2;
    [points, ~, heatmap] = FindTargetsXcorr(combined_Im, tt_pos_idx);
    
    % Identify targets in backpropgatation image
    %[numFound, points] = FindTargets(numTargets, combined_Im);

    
    fig1img1.CData = combined_Im;
    fig1tp1.XData = points(:,1);
    fig1tp1.YData = points(:,2);

    % Self-localize
    if numFound == numTargets
        points(:,1) = points(:,1) + (width-Nx)/2;
        [x,z] = calcSenorsPos(targetTruthPos, points);
        sensorPosMeasureCm = [x*1.3,z].*(dx*100);
%         sensorPosCm = sensorPosMeasureCm;
        %apply kalman filter
        [estimate,P] = kalman(estimate, P, sensorPosMeasureCm');
        sensorPosCm = [estimate(1),estimate(2)];
        figure(fig3); hold on;
        plot((sensorPosCm(1)+widthcm/2)/(dx*100),sensorPosCm(2)/(dx*100));
%         fig3l3.XData = (sensorPosCm(1)+widthcm/2)/(dx*100);
%         fig3l3.YData = sensorPosCm(2)/(dx*100);
        hold off;
        line(([tempPosPrev(1) tempPos(1)]+widthcm/2)./(dx*100), [tempPosPrev(2) tempPos(2)]/(dx*100));
        fig3l2.Position = [sensorPosCm(1)+widthcm/2-7 sensorPosCm(2)-2 14 4]./(dx*100);
        fig3l4.Position = [(sensorPosCm(1)+widthcm/2)./(dx*100), sensorPosCm(2)./(dx*100)-2];
        fig3l4.String = sprintf("(%0.2f, %0.2f)", sensorPosCm);
    end
    % Update Plots

    for lidx=1:length(fig2l1)
        fig2l1(lidx).YData = deviceAscan(:,lidx);
        fig2l2(lidx).YData = scaledAscan(:,lidx);
    end

    if data_to_file && ~ data_from_file
        save(fullfile(output_directory, string(datetime, filefmt)),'AscanData','params')
    end
    pause(0.25)

end

%% CLEANUP 
clear s
