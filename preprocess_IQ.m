function [scaledIQ, scaledAscan, deviceAscan] = preprocess_IQ( ...
    rawIQ, ...
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
self_interference_region = 1:10;
roi_thold_mean_frac = 0;

exclude_overlaps = 1;

% Identify sizes from raw data
numDevices = size(rawIQ, 1);
numMeasures = size(rawIQ, 2);
numSamples = size(rawIQ, 4);

%% Region of Interest Identification
% Compute mean AScan across all measures
deviceAscan = squeeze(mean( ...
    abs(rawIQ(:,:,1,:)+1j*rawIQ(:,:,2,:)), ...
    2 ...
    ))';

% Itentify peaks & troughs in mean AScan
ascan_diff = diff(deviceAscan,1,1);
peaks = ascan_diff(1:end-1,:) > 0 & ascan_diff(2:end,:) < 0;
troughs = ascan_diff(1:end-1,:) < 0 & ascan_diff(2:end,:) > 0;
peaks = [false(1,numDevices); peaks; false(1,numDevices)];
troughs = [false(1,numDevices); troughs; false(1,numDevices)];

% mask out self interference
peaks(self_interference_region, :) = false;
troughs(self_interference_region, :) = troughs;

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

    % identify bounds of the peak roi
    device_rois = zeros(size(pidx2aidx, 1),2);
    for pidx = 1:size(pidx2aidx)
        aidx = pidx2aidx(pidx);
        thold = (deviceAscan(aidx) - ascan_means(ii_dev)) * roi_thold_mean_frac+ ascan_means(ii_dev);
        
        device_rois(pidx, 1) = ...
            find(deviceAscan(1:aidx, ii_dev) < thold, 1, 'last');
        device_rois(pidx, 2) = aidx -1 + ...
            find(deviceAscan(aidx:end, ii_dev) < thold, 1, 'first');
    end

    % merge overlapping rois 
    merged_rois = zeros(size(device_rois));
    merged_rois_pidx = zeros(size(merged_rois,1),1);
    ii_mroi = 1;
    for ii_roi = 1:size(pidx2aidx)
        this_roi = device_rois(ii_roi, :);
        if ii_mroi == 1
            merged_rois(ii_mroi,:) = this_roi;
            merged_rois_pidx(ii_mroi) = ii_roi;
        else
            overlap = false;
            for jj_mroi = 1:ii_mroi-1
                that_roi = merged_rois(jj_mroi,:);
                if this_roi(1) < that_roi(2) && this_roi(2) > that_roi(1)
                    overlap = true;

                end
            end
            if ~overlap
                merged_rois(ii_mroi,:) = this_roi;
                merged_rois_pidx(ii_mroi) = ii_roi;
            end
        end
        ii_mroi = ii_mroi + 1;
    end
    
    % trim merged rois
    merged_rois = merged_rois(all(merged_rois ~= 0,2), :);
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
    num_rois = min(numTargets,size(sorted_rois,1));
    ascan_rois(1:num_rois,:, ii_dev) = sorted_rois(1:num_rois,:);
    device_maxs(ii_dev) = roi_maxs(roi_order(1));
end

%% Mask and Scale Outputs
scaledIQ = zeros(size(rawIQ));
scaledAscan = zeros(size(deviceAscan));

idx=1:numSamples;
for ii_dev = 1:numDevices
    % initialize empty mask for this device
    device_mask = zeros(numSamples,1);

    % combine masks from each ROI, scaled by max val
    for ii_targ = 1:numTargets
        % generate mask for this target
        mask = double( ...
            (idx)>ascan_rois(ii_targ,1,ii_dev) & ...
            (idx)<ascan_rois(ii_targ,2,ii_dev) ...
            )';
        
        % apply mask to AScan to determine scaling
        vals = deviceAscan(:,ii_dev) .* mask;
        scaled_mask = mask * (device_maxs(ii_dev) ./ max(vals));

        % add scaled ROI mask to device mask
        device_mask = device_mask + scaled_mask;
    end
    
    % apply mask to IQ data
    IQ_mask = repmat(reshape(device_mask, 1, 1, numSamples),numMeasures, 2);
    scaledIQ(ii_dev, :,:,:) = squeeze(rawIQ(ii_dev,:,:,:)) .* IQ_mask;

    % apply mask to Ascan
    % Ascan_mask = 
    scaledAscan(:,ii_dev) = deviceAscan(:,ii_dev) .* device_mask;
end

end

