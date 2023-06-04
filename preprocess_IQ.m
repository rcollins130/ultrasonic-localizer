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

take_first = 1;

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
troughs(self_interference_region, :) = false;

% mask out peaks below 125% mean value
ascan_means = mean(deviceAscan);
peaks = peaks & deviceAscan > 1.25*ascan_means;

% identify regions of interest around peaks
% [target, [leftbound rightbound], device]
ascan_rois = zeros(numTargets, 2, numDevices);
device_maxs = zeros(numDevices, 1);
for ii_dev=1:numDevices
    % mapping of peak indicies to ascan indicies
    % (ascan index) = pidx2aidx(peak index);
    pidx2aidx = find(peaks(:,ii_dev));
    % get sorted list of peak indicies
    [peak_vals, pidx_sorted] = sort(deviceAscan(peaks(:,ii_dev),ii_dev),'descend');

    % identify bounds of the peak roi, both peak-trough and peak-mean
    % device_rois = zeros(size(pidx2aidx, 1),2);
    pm_rois = zeros(size(pidx2aidx, 1),2);
    pt_rois = zeros(size(pidx2aidx, 1),2);
    for pidx = 1:size(pidx2aidx)
        % A-Scan Index of peak
        aidx = pidx2aidx(pidx);
        % peak-trough rois
        lt = find(troughs(1:aidx, ii_dev), 1, 'last');
        rt = aidx - 1 + find(troughs(aidx:end, ii_dev), 1, 'first');
        if isempty(lt)
            lt = 1;
        end
        if isempty(rt)
            rt = size(troughs,1);
        end
        pt_rois(pidx,1) = lt;
        pt_rois(pidx, 2) = rt;
        
        % peak-mean rois
        thold = (deviceAscan(aidx) - ascan_means(ii_dev)) * roi_thold_mean_frac + ascan_means(ii_dev);
        pm_rois(pidx, 1) = ...
            find(deviceAscan(1:aidx, ii_dev) < thold, 1, 'last');
        pm_rois(pidx, 2) = aidx - 1 + ...
            find(deviceAscan(aidx:end, ii_dev) < thold, 1, 'first');
    end

    % merge overlapping rois and sort
    merged_rois = zeros(size(pm_rois));
    % merged_rois_pidx = zeros(size(merged_rois,1),1);
    ii_mroi = 1;

    % roi indexing
    if take_first
        peak_indicies = 1:size(pidx2aidx);
    else
        peak_indicies = pidx_sorted;
    end

    % loop thru each peak, largest to smallest
    for ii_peak = 1:length(peak_indicies)
        ii_roi = peak_indicies(ii_peak);
        this_pt_roi = pt_rois(ii_roi, :);
        this_pm_roi = pm_rois(ii_roi, :);

        % for now, just taking the pt rois
        if ii_mroi == 1
            merged_rois(ii_mroi,:) = this_pt_roi;
            % merged_rois_pidx(ii_mroi) = ii_roi;
            ii_mroi = ii_mroi + 1;
        else
            overlap = false;
            for jj_mroi = 1:ii_mroi-1
                that_roi = merged_rois(jj_mroi,:);
                if this_pm_roi(1) < that_roi(2) && this_pm_roi(2) > that_roi(1)
                    overlap = true;
                end
            end
            if ~overlap
                merged_rois(ii_mroi,:) = this_pt_roi;
                % merged_rois_pidx(ii_mroi) = ii_roi;
                ii_mroi = ii_mroi + 1;
            end
        end
    end
    
    % trim merged rois
    % merged_rois = merged_rois(all(merged_rois ~= 0,2), :);
    
    % output best N rois and maximum device value (for scaling)
    num_rois = min(numTargets,size(merged_rois,1));
    ascan_rois(1:num_rois,:, ii_dev) = merged_rois(1:num_rois,:);
    device_maxs(ii_dev) = peak_vals(1);
end

%% Mask and Scale Outputs
scaledIQ = zeros(size(rawIQ));
scaledAscan = zeros(size(deviceAscan));

idx=1:numSamples;
for ii_dev = 1:numDevices
    % initialize empty mask for this device
    device_mask = zeros(numSamples,1);

    % combine masks from each non-zero ROI, scaled by max val
    for ii_roi = 1:sum(ascan_rois(:,1,ii_dev) ~=0)
        % generate mask for this target
        mask = double( ...
            (idx)>ascan_rois(ii_roi,1,ii_dev) & ...
            (idx)<ascan_rois(ii_roi,2,ii_dev) ...
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
    scaledAscan(:,ii_dev) = deviceAscan(:,ii_dev) .* device_mask;
end

end

