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

%% IMAGE FORMATION

receiver_locs = [0 -0.07 0.07];
numMeasures = 5; % how many captures to do
numDevices = 3; % how many sensors are plugged in
distMeasure = 2;
numTargets = 2;

[Im_final, points] = TakeMeasurement(numMeasures, numTargets, s);
% Image Parameters
Nx = 400;
dx = 1.5/Nx;
% Display Combined Backprojected Image
figure;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 100 500 500]);
imagesc(abs(Im_final).^2);
%imagesc(Im_final);
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
%% LOCALIZATION
width = 600;
height = 700;
widthcm = 600*100*dx;

targetTruthPosCm = [8 138; -3.42 163];
targetTruthPos = targetTruthPosCm./(dx*100);
targetTruthPos(:,1) = targetTruthPos(:,1) + width/2;

targets = points;
targets(:,1) = targets(:,1) + (width-Nx)/2;
%targets(:,2) = targets(:,2) + 75./(dx*100);
%estimated sensor position in cm
%sensorPos = [0 75];
[x,z] = calcSenorsPos(targetTruthPos, targets);
sensorPos = [x,z].*(dx*100);

figure;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 150 500 600]);
scene = zeros(height,width);
imagesc(scene);
hold on;
plot(targetTruthPos(:,1), targetTruthPos(:,2), 'r*');
rectangle('Position', [sensorPos(1)+widthcm/2-7 sensorPos(2)-2 14 4]./(dx*100))
hold off;
axis image;
set(gca,'fontsize',16)
title('Scene')
xlabel('X (cm)')
ylabel('Z(cm)')
xticks([1 xticks])
yticks([1 yticks])
yticklabels(floor(yticks*dx*100))
xticklabels(ceil(abs(xticks-width/2)*dx*100))


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