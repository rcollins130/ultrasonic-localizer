%% LAB 2 - ULTRASONICS

% Objectives:
% 1) Measure the directivity of the ultrasonic sensor.
% 2) Measure the range resolution of the ultrasonic sensor. 
% 3) Localize targets through an image formation process. 

%% SECTION 1 - INITIALIZATION
clear; clc; close all;
mkdir 'plots';

%%% Get metadata
sensor_id = 1;
data = ParseDataSonicLink2('directivity_0cm', sensor_id);
fc = data.fc; % ultrasonic sensor frequency
thresholds = data.threshold_levels; % thresholds in SonicLink software
Fs = data.Fs; % sampling rate of the resampled passband signal

%%% Visualize the first measurement
i = 1; % only plot the first measurement
figure;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 100 1500 500]);

subplot(1, 3, 1);
hold on;
plot(data.I(i, :), 'DisplayName', 'I');
plot(data.Q(i, :), 'DisplayName', 'Q');
title('IQ data');
hold off;
legend();

subplot(1, 3, 2);
hold on;
plot(data.envelope(i, :), 'DisplayName', 'A-scan');
title('A-scan');
% plot multithresholds
multithresholds = zeros(size(data.envelope, 2), 1);
for j = 1:length(thresholds)
    start = data.threshold_start_samples(j) + 1;
    if j < length(thresholds)
        stop = data.threshold_start_samples(j+1) + 1;
    else
        stop = size(data.envelope, 2);
    end
    multithresholds(start:stop) = thresholds(j);
end
plot(multithresholds, 'DisplayName', 'Thresholds');
hold off;
legend();

subplot(1, 3, 3);
plot(data.pb(i, :));
title('Resampled passband signal');

sgtitle(sprintf('Visualization of CH201 ultrasonic data'));
saveas(gcf, 'plots/visualization.png');


%% SECTION 2 - DIRECTIVITY

range_cm = 50;
offsets_cm = 0:10:100;
angles = 180/pi*atan((offsets_cm-50)/range_cm);

amplitude = zeros(1,length(angles));
for i = 1:length(angles)
    % File prefix should be directivity_Xcm (X being lateral offset in cm)
    file_prefix = sprintf('directivity_%dcm', offsets_cm(i));
    sensor_id = 1;
    data = ParseDataSonicLink2(file_prefix, sensor_id);
    range = mean(data.ranges);
    amplitude(i) = mean(data.intensities) .* range^2;
end


figure;
set(gcf, 'Color', 'w');
polarplot(angles*pi/180,20*log10(amplitude./max(amplitude)),'o-','linewidth',2,'markersize',5)
set(gca,'Fontsize',16)
rlim([-30 0])
thetalim([-90 90])
pax = gca;
pax.ThetaZeroLocation = 'Top';
saveas(gcf, 'plots/directivity.png');


%% SECTION 3 - RANGE RESOLUTION - A-SCAN
clc 

file_prefix = 'resolution';
sensor_id = 1;
data = ParseDataSonicLink2(file_prefix, sensor_id);
data_pb = data.pb;
Fs = data.Fs;

% Define time vector
t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;

% Find Two Target Peaks
env = abs(hilbert(data_pb));
start_ind = round(0.2/343*Fs);
[pks,locs] = findpeaks(env(start_ind:end),'MinPeakHeight',0.7*max(env),'Npeaks',2);

% Display Range Resolution
range_res = (locs(2)-locs(1))/Fs*343/2;
fprintf('Range Resolution: %g cm \n', round(range_res*100,1))
BW = 343/(2*range_res);
fprintf('Estimated Sensor Bandwidth: %g kHz \n',round(BW*1e-3,1))

% Plot Ultrasonic Measurment
figure;
set(gcf, 'Color', 'w');
plot(t*1e3,data_pb./max(abs(data_pb)),'linewidth',2)
set(gca, 'fontsize', 16)
grid on; box on;
title('Captured Ultrasonic Data')
xlabel('Time (ms)')
ylabel('Normalized Amplitude')
saveas(gcf, 'plots/resolution.png');

%% SECTION 4 - LOCALIZATION w/ IMAGE FORMATION

file_prefix = 'localization';
N = 3; % Number of Sensors
receiver_locs = [-0.2 0 0.2];
Im = zeros(400,400,N); % reconstructed image stack

figure;
set(gcf, 'Color', 'w');
hold on;
grid on; box on;
set(gca, 'fontsize', 16);
for ri = 1:N
    sensor_id = ri - 1;
    data = ParseDataSonicLink2(file_prefix, sensor_id);
    data_pb = data.pb;
    Fs = data.Fs;
    
    % Define time vector
    t = 0:1/Fs:size(data_pb,2)/Fs - 1/Fs;

    % Plot Sensor Measurements
    subplot(3,1,ri)
    plot(t*1e3,data_pb(1:length(t)))
    xlim([0 t(end)*1e3])
    xlabel('Time (ms)')
    ylabel('Amplitude (a.u.)')
    titl = sprintf('Sensor %d',ri-1);
    title(titl)

    % Backprojection of Each Measurement Individually
    Im(:,:,ri) = BackProj(hilbert(data_pb),receiver_locs(ri),receiver_locs(ri),343,Fs,0.75,0.75); 

end
%saveas(gcf, 'plots/localization multisensor data.png');

% Image Parameters
Nx = 400;
dx = 0.75/Nx;

% Display Backprojected Images
figure;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 100 1200 500]);
for ri = 1:N
    subplot(1,N,ri)
    imagesc(abs(Im(:,:,ri)))
    axis image;
    xticks([1 xticks])
    yticks([1 yticks])
    yticklabels(floor(yticks*dx*100))
    xticklabels(ceil(abs(xticks-Nx/2)*dx*100))
    if ri == 1
        ylabel('Z(cm)')
    end
    xlabel('X (cm)')
    titl = sprintf('Sensor %d',ri-1);
    title(titl)
end
%saveas(gcf, 'plots/localization backprojections.png');

% Combine image stack into single reconstructed image
Im_final = squeeze(sum(abs(Im),3));

% Display Combined Backprojected Image
figure;
set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 100 500 500]);
imagesc(abs(Im_final).^2)
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

