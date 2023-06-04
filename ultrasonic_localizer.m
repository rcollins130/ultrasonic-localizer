%%%
% ULTRASONIC LOCALIZER
% EE292Q FINAL PROJECT SPRING 2023
% 


%% SETUP & PARAMETERS
clear; close all;

% physical parameters
c = 343; % speed of sound, m
sensor_locs = [-0.07 0 0.07]; % relative sensor x-locations, m
target_locs = [0, 0;
               -0.225, 0.225]; % target [x,z] locations, m

% test values for canned data
% test_rel = [25   -52]*0.00375; % test value for relative target offset
% target_locs = [0,0; test_rel];
% 
numTargets = size(target_locs, 1); % number of targets

% capture parameters
% file data parameters
data_from_file = 0; % if true, load data from directory instead of serial
input_directory = "test_data/Data 5-26/2targ";

% data_to_file = 0; % if true, output captured data to directory (not implemented)
% output_directory = "test_data";

% serial parameters
serial_port = "/dev/tty.usbmodem2102";
baud = 1000000; % baud rate
numMeasures = 5; % captures per sensor
numDevices = 3; % number of sensors
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

% A-Scan
fig2 = figure(2); hold on;
fig2l1 = plot(d,zeros(size(d,2),numDevices),'LineStyle','--');
set(gca, 'ColorOrderIndex', 1)
fig2l2 = plot(d,zeros(size(d,2),numDevices),'LineStyle','-');
title('Sensor A-Scan')
xlabel('Distance, m')

% Self localization
fig3 = figure(3); hold on;
fig3l1 = plot(target_locs(:,1), target_locs(:,2), ...
    'ro','MarkerFaceColor','r','MarkerSize',5, ...
    'DisplayName','Targets');
fig3l2 = plot(0,0,'gs','DisplayName', 'Sensors');
xlabel('X, m');
ylabel('Z, m');
xlim([-distMeasure, distMeasure])
ylim([-distMeasure, distMeasure])
title('Self Localization, m');

%% LOCALIZATION LOOP
N = 100000000;
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

    % Preprocess IQ Data
    [ppIQ, scaledAscan, deviceAscan] = preprocess_IQ(AscanData, numTargets);

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
    [points, heatmap] = FindTargetsXcorr(combined_Im, floor(target_locs/dx));
    
    % Identify targets in backpropgatation image
    % points2 = FindTargets(numTargets, combined_Im);
    
    % Self-localize
    [x,z] = calcSenorsPos(target_locs, points);

    % Update Plots
    fig1img1.CData = combined_Im;
    fig1tp1.XData = points(:,1);
    fig1tp1.YData = points(:,2);

    for lidx=1:length(fig2l1)
        fig2l1(lidx).YData = deviceAscan(:,lidx);
        fig2l2(lidx).YData = scaledAscan(:,lidx);
    end
    
    fig3l2.XData = x*dx;
    fig3l2.YData = z*dx;

    pause(0.01)
end

%% CLEANUP 
clear s
