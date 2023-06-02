function [scaledIQ] = preprocess_ascan( ...
    AscanData, ...
    numTargets ...
    )
%PREPROCESS_ASCAN Clean up IQ Data 
%   Function for cleaning up CH201 IQ data by isolating & normalizing 
%   target peaks.
%   
%   INPUTS:
%   AscanData: Raw 4D IQ data from GetAscanDataFromCH201
%   params: Parameters from GetAscanDataFromCH201
%   numTargets: The number of expected targets.

%% Setup
% Function constants
%   move to parameters if need be
self_interference_region = 1:20;
roi_thold_mean_frac = 0;

% Identify sizes from raw data
numDevices = size(AscanData, 1);
numMeasures = size(AscanData, 2);
numSamples = size(AscanData, 4);

%% Region of Interest Identification
% Compute mean AScan across all measures
deviceAscan = squeeze(mean( ...
    abs(AscanData(:,:,1,:)+1j*AscanData(:,:,2,:)), ...
    2 ...
    ))';

% Itentify peaks in mean AScan
ascan_diff = diff(deviceAscan,1,1);
peaks = ascan_diff(1:end-1,:) > 0 & ascan_diff(2:end,:) < 0;
peaks = [false(1,numDevices); peaks; false(1,numDevices)];

% mask out self interference
peaks(self_interference_region, :) = false;

% mask out peaks below mean value
ascan_means = mean(deviceAscan);
peaks = peaks & deviceAscan > ascan_means;

% identify regions of interest around peaks
% [target, [leftbound rightbound], device]
ascan_rois = zeros(numTargets, 2, numDevices);
device_maxs = zeros(numDevices, 1);

for ii_dev=1:numDevices
    % mapping of peak indicies to ascan indicies
    % (ascan index) = pidx2aidx(peak index);
    pidx2aidx = find(peaks(:,ii_dev));

    % identify bounds of each peak
    device_rois = zeros(size(pidx2aidx, 1),2);
    for pidx = 1:size(pidx2aidx)
        aidx = pidx2aidx(pidx);
        thold = (deviceAscan(aidx) - ascan_means(ii_dev)) * roi_thold_mean_frac+ ascan_means(ii_dev);
        
        device_rois(pidx, 1) = ...
            find(deviceAscan(1:aidx, ii_dev) < thold, 1, 'last');
        device_rois(pidx, 2) = aidx -1 + ...
            find(deviceAscan(aidx:end, ii_dev) < thold, 1, 'first');
    end

    % merge overlapping peaks
    %   TODO: implement this for "bouncing" behavior
    merged_rois = device_rois;

    % sort ROI by maximum
    roi_maxs = zeros(size(merged_rois, 1),1);
    for ii_roi = 1:size(roi_maxs, 1)
        roi_maxs(ii_roi) = max(deviceAscan( ...
            merged_rois(ii_roi, 1):merged_rois(ii_roi, 2),...
            ii_dev ...
            ));
    end
    [~, roi_order] = sort(roi_maxs, 'descend');
    sorted_rois = merged_rois(roi_order, :);

    % output best rois and maximum value
    ascan_rois(:,:, ii_dev) = sorted_rois(1:numTargets,:);
    device_maxs(ii_dev) = roi_maxs(roi_order(1));
end

%% Mask and Scale IQ Data
scaledIQ = zeros(size(AscanData));

idx=1:numSamples;
for ii_dev = 1:numDevices
    % initialize mask for this device
    device_mask = zeros(numSamples,1);

    % combine 
    for ii_targ = 1:numTargets
        % generate mask for this target
        mask = double( ...
            (idx)>ascan_rois(ii_targ,1,ii_dev) & ...
            (idx)<ascan_rois(ii_targ,2,ii_dev) ...
            )';
        
        % apply mask to Ascan to determine scaling
        vals = deviceAscan(:,ii_dev) .* mask;
        scaled_mask = mask * (device_maxs(ii_dev) ./ max(vals));

        % add scaled ROI mask to device mask
        device_mask = device_mask + scaled_mask;
    end
    
    device_mask = repmat(reshape(device_mask, 1, 1, numSamples),numMeasures, 2);
    scaledIQ(ii_dev, :,:,:) = squeeze(AscanData(ii_dev,:,:,:)) .* device_mask;
end


end

