%% test script for a-scan based localization

%% setup
clear; close all;

numMeasures = 5; % how many captures to do
numDevices = 3; % how many sensors are plugged in
distMeasure = 2;
numTargets = 2;

receiver_locs = [0 -0.07 0.07];
source_locs = [0 -0.07 0.07];


c = 343; % speed of sound, m/s

%% load data
load('/Users/robertcollins/Documents/GitHub/ultrasonic-localizer/Data 5-26/10Avg,7cm Spaceing,2m_max,2target-dif,take2.mat')
numMeasures = size(params,2);
numDevices= size(params,1);

% [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
sensorAscan = squeeze(abs(AscanData(:,1,1,:)+1j*AscanData(:,1,2,:)))';
dist = (1:size(sensorAscan,1)) / 60;
plot(dist, sensorAscan); hold on;

%% find peaks
% find peaks using diff offset. 
raw_diff = diff(sensorAscan,1,1);
peaks = raw_diff(1:end-1,:) > 0 & raw_diff(2:end,:) < 0;
peaks = [false(1,numDevices); peaks; false(1,numDevices)];

% mask out self-interference
peaks(1:20,:) = false;

% mask out peaks below mean
peaks = peaks & sensorAscan > mean(sensorAscan);

% select peaks
peakBounds = zeros(numTargets, 2, numDevices);
for ii_dev=1:numDevices
    % mapping of peak indicies to ascan indicies
    idx_map = find(peaks(:,ii_dev));

    % get half-max width of each peak
    this_peakBounds = zeros(size(idx_map,1),2);
    for ii_peak = 1:size(idx_map,1)
        idx_peak = idx_map(ii_peak);
        thold = sensorAscan(idx_peak) * 0.25;

        this_peakBounds(ii_peak,1) = ...
            find(sensorAscan(1:idx_peak, ii_dev) < thold, 1, 'last');
        this_peakBounds(ii_peak,2) = idx_peak - 1 + ...
            find(sensorAscan(idx_peak:end, ii_dev) < thold, 1, 'first');
    end

    % merge overlapping peaks: TODO

    % sort peaks by magnitude
    [~, peakOrder] = sort(sensorAscan(peaks(:,ii_dev), ii_dev),'descend');
    
    % output max peak bounds
    peakBounds(:,:, ii_dev) = this_peakBounds(1:numTargets, :);
end

% test plotting
if 1 
    for ii_dev=1:numDevices
        for ii_targ=1:numTargets
            set(gca, "ColorOrderIndex", ii_dev)
            ran = peakBounds(ii_targ,1,ii_dev):peakBounds(ii_targ,2,ii_dev);
            plot(dist(ran), sensorAscan(ran,ii_dev),'-','LineWidth',2)
        end
    end
end

%% pick out a scan of each peak
peakSeries = zeros(size(sensorAscan,1),numTargets, numDevices);
%peakSeries = zeros(size(sensorAscan,1),numTargets * numDevices);
for ii_dev = 1:numDevices
    for ii_targ = 1:numTargets
        idx = 1:size(sensorAscan,1);
        mask = (idx)>peakBounds(ii_targ,1,ii_dev) & (idx)<peakBounds(ii_targ,2,ii_dev);
        peakSeries(:,ii_targ, ii_dev) = sensorAscan(:,ii_dev) .* double(mask)';
    end
end
% 
% [c, lags] = xcorr( ...
%     reshape(peakSeries, ...
%     [size(peakSeries,1), prod(size(peakSeries,2:3))] ...
%     ));
% c = reshape(c,[size(c,1),sqrt(size(c,2)), sqrt(size(c,2))]);



% 
% xcorrs = 
% for ii_dev = 1:numDevices
%     for jj_dev = 1:numDevices
%         if ii_dev==jj_dev; continue; end
% 
% 
%     end
% end

%% upconvert
timeseries = [];
testPB = (peakBounds-ones(size(peakBounds))) * 64 + ones(size(peakBounds));
for ii_dev=1:numDevices
    fc = params(ii_dev, 1, 5);
    [data_pb, Fs] = upconv( ...
        squeeze(AscanData(ii_dev, :, 1, :)), ...
        squeeze(AscanData(ii_dev, :, 2, :)), ...
        fc);
    timeseries(:,ii_dev) = data_pb;
end

% get peak series of upconverted
peakTimeSeries = zeros(size(timeseries,1), numTargets, numDevices);
for ii_dev = 1:numDevices
    for ii_targ = 1:numTargets
        idx = 1:size(timeseries,1);
        mask = (idx)>testPB(ii_targ,1,ii_dev) & (idx)<testPB(ii_targ,2,ii_dev);
        peakTimeSeries(:,ii_targ, ii_dev) = timeseries(:,ii_dev) .* double(mask)';
    end
end

% normalize returns against max


% feed into backproj
Im = zeros(400,400,numDevices*numTargets);
for ii_dev = 1:numDevices
    for ii_targ = 1:numTargets
        Im(:,:,sub2ind([numDevices, numTargets],ii_dev, ii_targ)) = BackProj( ...
            hilbert(peakTimeSeries(:,ii_targ, ii_dev)), ...
            receiver_locs(ii_dev), ...
            source_locs(ii_dev), ...
            343, ...
            Fs,... % todo replace with actual val
            1.5, ...
            1.5);
    end
end
figure
imagesc(abs(squeeze(sum(abs(Im),3))).^2);

%% GRAVEYARD

% apply time-based threshold to find peaks
%   where does 60 samples/m come in? 
% 
% raw_diff = diff(sensorAscan(:,1),1);
% peaks = raw_diff(1:end-1) > 0 & raw_diff(2:end) < 0;
% peaks = [false; peaks; false];
% 
% % mask out self-interference
% peaks(1:20) = false;
% peakIdxs = find(peaks);
% 
% % pick out highest N peaks
% [Mi, Ii] = maxk(sensorAscan(peaks,1), numTargets);
% plot(dist(peakIdxs(Ii)), sensorAscan(peakIdxs(Ii),1),'o');
% 

% % find maximum peaks
% peakIdxs = zeros(numTargets, numDevices);
% for ii_dev=1:numDevices
%     idx_map = find(peaks(:,ii_dev));
%     [~, Ii] = maxk(sensorAscan(peaks(:,ii_dev),ii_dev), numTargets,1);
%     peakIdxs(:,ii_dev) = idx_map(Ii);
% end

% TEST: plot 
% if 1
%     set(gca, "ColorOrderIndex", 1)
%     for ii_dev=1:numDevices
%         plot(dist(peakIdxs(:,ii_dev)), sensorAscan(peakIdxs(:,ii_dev),ii_dev), 'o')
%     end
% end

% pick out highest N peaks
% [Mi, Ii] = maxk(sensorAscan(peaks), numTargets,1);
% plot(dist(peakIdxs(Ii)), sensorAscan(peakIdxs(Ii),1),'o');

% identify peaks with diff
% idx = repmat((1:120)',1,3);
% raw_diff = diff(sensorAscan,1);
% peaks = (raw_diff(1:end-1,:) < 0) & (raw_diff(2:end,:) > 0);
% hold on;
% set(gca,"ColorOrderIndex",1)
% plot(idx(peaks), sensorAscan(peaks),'o');

%% threshold code
% set unscaled distance threshold based on power law scaling
% power = 2;
% dist = (1:size(AscanData,4)) / 60;
% thold = dist.^(-power);
% % get maximum of each
% [M,I] = max(sensorAscan,[],1);
% % scale thold to have max peak at 0.5
% level = 0.5;
% thold = thold' * (M./thold(I)) * level;
% % plot tholds
% hold on 
% set(gca,"ColorOrderIndex",1)
% plot(thold, '--');
% ylim([0,1.1*max(M)])

