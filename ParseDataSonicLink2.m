function data = ParseDataSonicLink2(file_prefix, sensor_id)
%PARSEDATASONICLINK2 Parse data captured by SonicLink 2
%   From the JSON file, extract carrier freq and thresholds.
%   From the TXT file, extract IQ data, ranges, and amplitudes.

json_file = dir(sprintf('%s*.json', file_prefix));
txt_file = dir(sprintf('%s*.txt', file_prefix));

% Read metadata from JSON file
json_data = jsondecode(fileread(fullfile(json_file.folder, json_file.name)));
sensor_metadata = getfield(json_data.sensors, sprintf('x%d', sensor_id)); % metadata for the specified sensor
data.fc = sensor_metadata.op_freq_hz;
data.bandwidth = sensor_metadata.bandwidth;

% Get threshold levels and start samples
data.Nthresholds = length(fieldnames(sensor_metadata.mt_thresholds));
data.threshold_levels = zeros(1, data.Nthresholds);
data.threshold_start_samples = zeros(1, data.Nthresholds);
for i = 1:data.Nthresholds
    threshold = getfield(sensor_metadata.mt_thresholds, sprintf('x%d', i-1));
    data.threshold_levels(i) = threshold.level;
    data.threshold_start_samples(i) = threshold.start_sample;
end

% Read data from TXT file
matrix = readmatrix(fullfile(txt_file.folder, txt_file.name));

% Only keep rows for the specified sensor
sensor_data = [];
flag = 0;
for ri = 1:size(matrix, 1) % ri is row index
    row = matrix(ri, :);
    if row(2) == sensor_id
        if flag == 0
            sensor_data = row;
            flag = 1;
        else
            sensor_data = [sensor_data; row];
        end
    end
end

% Extract target range and intensity
data.ranges = sensor_data(:, 4);
data.intensities = sensor_data(:, 5);

% Extract IQ data
nonIQcols = 7; % first 7 columns are not IQ data. then it's Nt columns of I, then Nt columns of Q.
data.Nsamples = (size(sensor_data, 2) - nonIQcols)/2;
data.I = sensor_data(:, 1+nonIQcols:data.Nsamples+nonIQcols);
data.Q = sensor_data(:, 1+nonIQcols+data.Nsamples:end);

% Get envelope from IQ data
data.envelope = abs(data.I + 1j*data.Q);

% Upconvert iq data to the passband
[data.pb, data.Fs] = upconv(data.I, data.Q, data.fc);

end
