function targets = FindTargets(numTargets, Im_final)
    maxAmp = max(Im_final);
    figure;
    imagesc(Im_final);
    numFoundTargets = 0;
    thresh = 2;
    while numFoundTargets ~= numTargets & thresh >= 1
        thresh = thresh - 0.1;
        Im_reduced = Im_final .* double(Im_final>maxAmp/thresh);
        Im_red_binary = Im_reduced>0;
        Im_red_binary = bwlabel(Im_red_binary);
        numFoundTargets = max(Im_red_binary,[],"all","linear");
%         figure;
%         imagesc(Im_red_binary);
    end
    figure;
    imagesc(Im_red_binary);
    points = zeros(numFoundTargets,3);
    for idx = 1:numFoundTargets
        temp = Im_reduced .* double(Im_red_binary==idx);
        [M,I] = max(temp,[],"all","linear");
        [y,x] = ind2sub(size(temp),I);
        points(idx, 1) = x;
        points(idx, 2) = y;
        points(idx, 3) = Im_final(x,y);
    end
    [M,I] = sort(points(:,3));
    I=flip(I);
    targets = zeros(numTargets,2);
    targets = points(I(1:numTargets),:);
    [M,I] = sort(targets(:,2));
    targets = targets(I,:);
end