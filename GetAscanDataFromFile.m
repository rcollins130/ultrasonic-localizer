function [AscanData, params] = GetAscanDataFromFile(data_path, idx)

    d = dir(fullfile(data_path,"*.mat"));
    
    fidx = mod(idx-1,size(d,1))+1;
    p = fullfile(d(fidx).folder, d(fidx).name);

    load(p,"AscanData","params")
end

