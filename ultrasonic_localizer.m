%%%
% ULTRASONIC LOCALIZER
% EE292Q FINAL PROJECT SPRING 2023
% 

%% SETUP & PARAMETERS
clear; %close all;

serial_port = "/dev/tty.usbmodem102";
baud = 1000000;

file_prefix = 'localization';
receiver_locs = [-0.07 0 0.07]; % receiver locations, m
numMeasures = 5; % captures per sensor
numDevices = 3; % number of sensors
numTargets = 2;
distMeasure = 2; % maximum distance measurement, matches firmware

datafromfile = 1;


%% INPUT DATA
if datafromfile
load('/Users/robertcollins/Documents/GitHub/ultrasonic-localizer/Data 5-26/10Avg,7cm Spaceing,2m_max,2target,take3.mat')
else
    % Connect to board
    s = serialport(serial_port, baud);
    [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
    clear s
end

%% LOCALIZATION LOOP

% preprocess AscanData
[ppAscanData] = preprocess_ascan(AscanData, numTargets);

ppIm = zeros(400,400,numDevices); % reconstructed image stack
Im = zeros(400,400,numDevices); % reconstructed image stack
for ii_dev=1:numDevices
    % upconvert to time series
    [data_pb, Fs] = upconv(squeeze(ppAscanData(ii_dev,:,1,:)), squeeze(ppAscanData(ii_dev,:,2,:)), params(ii_dev,1,5));
    % define time vector
    t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;
    % compute backprojection
    ppIm(:,:,ii_dev) = BackProj( ...
        hilbert(data_pb), ...
        receiver_locs(ii_dev), ...
        receiver_locs(ii_dev), ...
        343,Fs,1.5,1.5 ...
        );

    % upconvert to time series
    [data_pb, Fs] = upconv(squeeze(AscanData(ii_dev,:,1,:)), squeeze(AscanData(ii_dev,:,2,:)), params(ii_dev,1,5));
    % define time vector
    t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;
    % compute backprojection
    Im(:,:,ii_dev) = BackProj( ...
        hilbert(data_pb), ...
        receiver_locs(ii_dev), ...
        receiver_locs(ii_dev), ...
        343,Fs,1.5,1.5 ...
        );
end

% Image Parameters
Nx = 400;
dx = 1.5/Nx;

% Stack image
figure(1)
subplot(1,2,1)
Im_final = squeeze(sum(abs(Im),3));
imagesc(abs(Im_final).^2)
axis image;
title('Original Backprojection')
xlabel('X (cm)')
ylabel('Z(cm)')
xticks([1 xticks])
yticks([1 yticks])
yticklabels(floor(yticks*dx*100))
xticklabels(ceil(abs(xticks-Nx/2)*dx*100))

subplot(1,2,2)
ppIm_final = squeeze(sum(abs(ppIm),3));
imagesc(abs(ppIm_final).^2)
axis image;
title('Preprocessed Backprojection')
xlabel('X (cm)')
ylabel('Z(cm)')
xticks([1 xticks])
yticks([1 yticks])
yticklabels(floor(yticks*dx*100))
xticklabels(ceil(abs(xticks-Nx/2)*dx*100))
