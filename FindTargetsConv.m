function [points, heatmap] = FindTargetsConv(combined_Im,target_pts)
%FINDTARGETSCONV Find targets using a convolution-based method

% create convolution kernel
%   not most efficient, maybe redo?
zsize = max(abs(target_pts(:,2)))*2 + 1;
xsize = max(abs(target_pts(:,1)))*2 + 1;
kernel = zeros([zsize,xsize]);

for ii_targ = 1:size(target_pts,1)
    kernel( ...
        ceil(zsize/2)+target_pts(ii_targ,2), ...
        ceil(xsize/2)+target_pts(ii_targ,1)) = 1;
end

% convolve with combined image
heatmap = conv2(combined_Im, kernel,'same');

[~, I] = max(heatmap,[], 'all');
[row,col] = ind2sub(size(heatmap),I);
targ_center = [row,col];

points = targ_center + target_pts;

end

