function targets = FindTargets(numTargets, Im_final)
    maxAmp = max(Im_final);
    Im_reduced = Im_final .* double(Im_final>maxAmp/1.3);
    Im_red_binary = Im_reduced>0;
    Im_red_binary = bwlabel(Im_red_binary);
    
    numFoundTargets = max(Im_red_binary,[],"all","linear");
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
end