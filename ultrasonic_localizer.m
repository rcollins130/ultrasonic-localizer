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

target_locs = [0, 0;
               -0.32, 0.32]; % target [x,z] locations, m
% target_locs = [0, 0;
%                -0.225, 0.1125]; % target [x,z] locations, m

numTargets = size(target_locs, 1); % number of targets

% capture parameters
% file data parameters
data_from_file = 0; % if true, load data from directory instead of serial
input_directory = "test_data/20230604_150125";

data_to_file = 0; % if true, output captured data to directory
output_directory = "test_data";
filefmt = "yyyyMMdd_HHmmssSSS";
dirfmt = "yyyyMMdd_HHmmss";

if data_to_file && ~ data_from_file
    output_directory = fullfile(output_directory, string(datetime,dirfmt));
    mkdir(output_directory)
end

% serial parameters
serial_port = "COM3";
baud = 1000000; % baud rate
numMeasures = 3; % captures per sensor
numDevices = length(sensor_locs); % number of sensors
distMeasure = 2; % maximum distance measurement, matches firmware

% plotting parameters
%   these are also defined in some functions, but here because I'm lazy
% backprop image parameters
Nx = 400;
dx = 1.5/Nx;

% a scan plot parameters
d = (1:distMeasure*60)/60;

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

% Self localization
% fig3 = figure(3); hold on;
% fig3l1 = plot(target_locs(:,1), target_locs(:,2), ...
%     'ro','MarkerFaceColor','r','MarkerSize',5, ...
%     'DisplayName','Targets');
% fig3l2 = plot(0,0,'gs','DisplayName', 'Sensors');
% xlabel('X, m');
% ylabel('Z, m');
% xlim([-distMeasure, distMeasure])
% ylim([-distMeasure, distMeasure])
% title('Self Localization, m');
width = 600;
height = 700;
widthcm = 600*100*dx;

targetTruthPosCm = [8 138; -3.42 163];
targetTruthPos = targetTruthPosCm./(dx*100);
targetTruthPos(:,1) = targetTruthPos(:,1) + width/2;
sensorPosCm = [0 75];
fig3 = figure(3); hold on;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 150 500 600]);
scene = zeros(height,width);
imagesc(scene);
fig3l1 = plot(targetTruthPos(:,1), targetTruthPos(:,2), ...
    'ro','MarkerFaceColor','r','MarkerSize',5, ...
    'DisplayName','Targets');
% fig3l2 = plot(0,0,'gs','DisplayName', 'Sensors');
fig3l2 = rectangle('Position', [sensorPosCm(1)+widthcm/2-7 sensorPosCm(2)-2 14 4]./(dx*100))
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
    % [device, measurement, [port, range, amp, samples, op_freq, bandwidth]
    if data_from_file
        [AscanData, params] = GetAscanDataFromFile(input_directory, ii);
    else
        [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
    end
    
    AscanData = AscanData(:,:,:,1:distMeasure*60);

    % Preprocess IQ Data
    [ppIQ, scaledAscan, deviceAscan] = preprocess_IQ(AscanData, numTargets);
    %ppIQ = AscanData;
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
            1.5, ... % x, m
            1.5 ... % z, m
            );
    end
    % merge backprop images
    combined_Im = squeeze(sum(abs(Im),3)).^2;
    
    % TODO: need convention on orientation of XZ coords 

    % itentify targets by xcorr method
%     [points, heatmap] = FindTargetsXcorr(combined_Im, floor(target_locs/dx));
    
    % Identify targets in backpropgatation image
    [numFound, points] = FindTargets(numTargets, combined_Im);

    
    fig1img1.CData = combined_Im;
    fig1tp1.XData = points(:,1);
    fig1tp1.YData = points(:,2);

    % Self-localize
    if numFound == numTargets
        points(:,1) = points(:,1) + (width-Nx)/2;
        [x,z] = calcSenorsPos(targetTruthPos, points);
        sensorPosCm = [x,z].*(dx*100);
        fig3l2.Position = [sensorPosCm(1)+widthcm/2-7 sensorPosCm(2)-2 14 4]./(dx*100);
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
