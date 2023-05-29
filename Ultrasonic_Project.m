%% EE 292Q - Ultrasonic Project
% Group members: ADD YOUR NAMES HERE

clear; clc; close all;

% Before running this code, make sure you have flashed the HelloChirp
% firmware to the ultrasonic board. Also note that you will need to reflash
% the default firmware if you want to use SonicLink again.

%% Connect to board
% Open serial port. Change COM5 to whichever COM port your board is using.
s = serialport("COM3", 1000000);

%%
numMeasures = 1; % how many captures to do
numDevices = 1; % how many sensors are plugged in
distMeasure = 1;
[AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
sensorAscan = squeeze(abs(AscanData(:,1,1,:)+1j*AscanData(:,1,2,:)))';
plot(sensorAscan);

%% Musical Instrument
% AscanData = (numDevices, numMeasures, numSamples);
% params = (numDevices, numMeasures, 6);
% param reported as (Sensor #, Range in mm,  Amp, Samples, Op_freq Hz, Bandwidth Hz)

% Include any setup code you want to run before the loop here.
%% SECTION 4 - LOCALIZATION w/ IMAGE FORMATION

file_prefix = 'localization';
receiver_locs = [0 -0.07 0.07];
numMeasures = 10; % how many captures to do
numDevices = 3; % how many sensors are plugged in
distMeasure = 2;
numTargets = 1;
Im = zeros(400,400,numDevices); % reconstructed image stack
%[AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
%save("10Avg,7cm Spaceing,2m_max,2target-dif,take2", "AscanData", "params");
figure;
set(gcf, 'Color', 'w');
hold on;
grid on; box on;
set(gca, 'fontsize', 16);

for idx = 1:numDevices
    
    [data_pb, Fs] = upconv(squeeze(AscanData(idx,:,1,:)), squeeze(AscanData(idx,:,2 ...
        ,:)), params(idx,1,5));
    %data = ParseDataSonicLink2(file_prefix, sensor_id);
    %data_pb = data.pb;
    %Fs = data.Fs;
    %data_pb(ai,:) = data_I_up.*cos(2*pi*fc*t) - data_Q_up.*sin(2*pi*fc*t);
    % Define time vector
    t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;
    
    % Plot Sensor Measurements
    subplot(3,1,idx)
    plot(t*1e3,data_pb(1:length(t)))
    xlim([0 t(end)*1e3])
    xlabel('Time (ms)')
    ylabel('Amplitude (a.u.)')
    titl = sprintf('Sensor %d',idx-1);
    title(titl)

    % Backprojection of Each Measurement Individually
    Im(:,:,idx) = BackProj(hilbert(data_pb),receiver_locs(idx),receiver_locs(idx),343,Fs,1.5,1.5); 

end
%saveas(gcf, 'plots/localization multisensor data.png');

% Image Parameters
Nx = 400;
dx = 1.5/Nx;

% Display Backprojected Images
% figure;
% set(gcf, 'Color', 'w');
% set(gcf, 'Position', [100 100 1200 500]);
% for ri = 1:numDevices
%     subplot(1,numDevices,ri)
%     imagesc(abs(Im(:,:,ri)))
%     axis image;
%     xticks([1 xticks])
%     yticks([1 yticks])
%     yticklabels(floor(yticks*dx*100))
%     xticklabels(ceil(abs(xticks-Nx/2)*dx*100))
%     if ri == 1
%         ylabel('Z(cm)')
%     end
%     xlabel('X (cm)')
%     titl = sprintf('Sensor %d',ri-1);
%     title(titl)
% end
%saveas(gcf, 'plots/localization backprojections.png');

% Combine image stack into single reconstructed image
Im_final = abs(squeeze(sum(abs(Im),3))).^2;
points = FindTargets(numTargets, Im_final);

% Display Combined Backprojected Image
figure;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 100 500 500]);
imagesc(abs(Im_final).^2)
hold on;
plot(points(:,1), points(:,2), 'r*');
hold off;
axis image;
set(gca,'fontsize',16)
title('Combined Backprojection')
xlabel('X (cm)')
ylabel('Z(cm)')
xticks([1 xticks])
yticks([1 yticks])
yticklabels(floor(yticks*dx*100))
xticklabels(ceil(abs(xticks-Nx/2)*dx*100))
%saveas(gcf, 'plots/localization combined backprojection.png');
%% real time a scan %%
numMeasures = 1; % how many captures to do
numDevices = 3; % how many sensors are plugged in
distMeasure = 2;
figure(1);
flush(s); % flush serial buffer so we don't read old buffered data
while true % infinite loop, hit the Stop button in Matlab to get out of it
    [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
    sensorAscan = squeeze(abs(AscanData(:,1,1,:)+1j*AscanData(:,1,2,:)))';
    plot(sensorAscan);

    %%% YOUR CODE HERE %%%
    
    %%% END OF YOUR CODE %%%
end

%% close serial port
clear s