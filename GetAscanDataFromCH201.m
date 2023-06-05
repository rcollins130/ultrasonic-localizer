function [AscanData, params] = GetAscanDataFromCH201(numDevices, numMeasures, distMeasure, s)
    numSamples = distMeasure*60;
    AscanData = zeros(numDevices, numMeasures, 2, numSamples);
    params = zeros(numDevices, numMeasures, 6);
    %s = serialport("COM3", 1000000);
    flush(s);
    measureIdx = 1;
    while measureIdx <= numMeasures
        input = char(readline(s));
        if length(input) > 11 && strcmp('Outputting', input(1:10))
            for dev = 1:numDevices
                input = char(readline(s));
                paramText = input;
                template = 'Port %d:  Range: %f mm  Amp: %d  Samples: %d  Op_freq: %d  Bandwidth: %d';
                params(dev,measureIdx, :) = sscanf(paramText, template);
                numSamples = params(dev,measureIdx,4);
                idx = 1;
                input = readline(s);
                while idx <= numSamples & input ~= ""
                    IQnum = strsplit(input,',');
                    AscanData(dev, measureIdx, 1, idx) = IQnum(1);
                    AscanData(dev, measureIdx, 2, idx) = IQnum(2);
                    input = readline(s);
                    idx = idx + 1;
                end
                %char(readline(s));
            end
            measureIdx = measureIdx + 1;
        end
    end

    %time = 0:8/params(5):(size(IQdataSet,2)-1)*8/params(5);
    %plot(time*1e3, sqrt(IQdataSet(1,:,1).^2 + IQdataSet(1,:,2).^2))
    %clear s
end