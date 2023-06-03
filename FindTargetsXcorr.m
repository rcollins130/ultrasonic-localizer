function [points, targ_center, heatmap] = FindTargetsXcorr(combined_Im,target_pts)
%FINDTARGETSCONV Find targets using a cross-correlation method

% create kernel
% TODO: use a disk kernel instead of square?
% note this method makes kernal centered about 0,0 target pt, not efficient
padding=5;
zsize = max(abs(target_pts(:,2))+padding)*2 + 1;
xsize = max(abs(target_pts(:,1))+padding)*2 + 1;
kernel = zeros([zsize,xsize]);

for ii_targ = 1:size(target_pts,1)
    cent = [
        ceil(zsize/2)+target_pts(ii_targ,2);
        ceil(xsize/2)+target_pts(ii_targ,1)];

    kernel( ...
        cent(1)-padding:cent(1)+padding, ...
        cent(2)-padding:cent(2)+padding) = 1;
end
offset = [ceil(xsize/2), ceil(zsize/2)];

% cross-correlate with combined image
heatmap = xcorr2(combined_Im, kernel);

[~, I] = max(heatmap,[], 'all');
[z_peak,x_peak] = ind2sub(size(heatmap),I);
targ_center = [x_peak-xsize,z_peak-zsize] + offset;

points = targ_center + target_pts;

% figure(4)
% subplot(1,4,1)
% imagesc(kernel)
% axis equal
% 
% subplot(1,4,2)
% imagesc(heatmap); hold on;
% plot(x_peak, z_peak, 'go'); hold off;
% 
% subplot(1,4,3)
% hm_trim = heatmap(zsize:end, xsize:end);
% imagesc(hm_trim); hold on;
% plot(targ_center(1), targ_center(2), 'go'); hold off;
% 
% subplot(1,4,4)
% imagesc(combined_Im); hold on;
% plot(targ_center(1),targ_center(2), 'go')
% plot(points(:,1), points(:,2),'ro')
% hold off;

end

