function [Im_final,points] = TakeMeasurement(numMeasures, numTargets, s)
    receiver_locs = [0 -0.07 0.07];
%     numMeasures = 5; % how many captures to do
    numDevices = 3; % how many sensors are plugged in
    distMeasure = 2;
%     numTargets = 2;
    Im = zeros(400,400,numDevices); % reconstructed image stack
    [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s);
    
    for idx = 1:numDevices
        [data_pb, Fs] = upconv(squeeze(AscanData(idx,:,1,:)), squeeze(AscanData(idx,:,2 ...
            ,:)), params(idx,1,5));

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
    
    % Combine image stack into single reconstructed image
    Im_final = abs(squeeze(sum(abs(Im),3))).^2;
    %Im_final = abs(Im_final).^2
    points = FindTargets(numTargets, Im_final);
end

