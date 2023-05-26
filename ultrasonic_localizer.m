%%%
% ULTRASONIC LOCALIZER
% EE292Q FINAL PROJECT SPRING 2023
% 
%

%% SETUP & PARAMETERS
clear; close all;

serial_port = "/dev/tty.usbmodem102";
baud = 1000000;

file_prefix = 'localization';
receiver_locs = [-0.07 0 0.07]; % receiver locations, m
numMeasures = 5; % captures per sensor
numDevices = 3; % number of sensors
distMeasure = 2; % maximum distance measurement, matches firmware

%% SENSOR SETUP
% Connect to board
s = serialport(serial_port, baud);
figure(1)

%% LOCALIZATION LOOP
while 1
    % capture sensor data
    [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);

    % localize targets
    [rel_locs] = localizeTargets(AscanData, params, receiver_locs);

    % % capture sensor data
    % [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
    % 
    % Im = zeros(400,400,numDevices); % reconstructed image stack
    % for idx=1:numDevices
    %     % upconvert to time series
    %     [data_pb, Fs] = upconv(squeeze(AscanData(idx,:,1,:)), squeeze(AscanData(idx,:,2,:)), params(idx,1,5));
    %     % define time vector
    %     t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;
    %     % compute backprojection
    %     Im(:,:,idx) = BackProj( ...
    %         hilbert(data_pb), ...
    %         receiver_locs(idx), ...
    %         receiver_locs(idx), ...
    %         343,Fs,1.5,1.5 ...
    %         ); 
    %     subplot(2,3,idx+3)
    %     imagesc(abs(Im(:,:,idx)).^2);
    % end
    % 
    % % Image Parameters
    % Nx = 400;
    % dx = 1.5/Nx;
    % 
    % % Stack image
    % Im_final = squeeze(sum(abs(Im),3));
    % subplot(2,3,1:3)
    % imagesc(abs(Im_final).^2)
    % axis image;
    % set(gca,'fontsize',16)
    % title('Combined Backprojection')
    % xlabel('X (cm)')
    % ylabel('Z(cm)')
    % xticks([1 xticks])
    % yticks([1 yticks])
    % yticklabels(floor(yticks*dx*100))
    % xticklabels(ceil(abs(xticks-Nx/2)*dx*100))
    % 
    % pause(0.01)
end



%% CLEANUP
clear s
