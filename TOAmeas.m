function TOA = TOAmeas(data,thresholds,Fs)

    data = abs(hilbert(data));

    % Define thresholds and transition indices
    indices = [26,39,56,79,89];
    inds_pb = indices*64;
    inds_pb = [1 inds_pb];
  
    % Threshold data
    data_thresh = data;
    for i = 1:length(inds_pb)-1
        if inds_pb(i+1)<length(data)
            for j = inds_pb(i):inds_pb(i+1)
                if data_thresh(j)<thresholds(i)
                    data_thresh(j) = 0;
                end
            end
        end
    end


    % Find first peak
   [pk,loc] = findpeaks(data_thresh,'NPeaks',1);

   % Find index at half peak
   ind_TOA = find(data(1:loc)<pk/2,1,'last');

   % Find Time-of-arrival
   TOA = 1e3*ind_TOA/Fs;
   
end