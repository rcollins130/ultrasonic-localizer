function Im = BackProj(data,receiver_locs,source_locs,c,Fs,sizeX,sizeZ)
    % Define Imaging Geometry
    X = linspace(-sizeX/2,sizeX/2,400);
    Z = linspace(0,sizeZ, 400);
    [X,Z] = meshgrid(X,Z);

    % Define Time Delays
    TimeDelays = zeros(400,400,length(receiver_locs));
    for i = 1:length(receiver_locs)
        for j = 1:length(source_locs)
            TimeDelays(:,:,i,j) = sqrt((X-receiver_locs(i)).^2+Z.^2)/c + sqrt((X-source_locs(j)).^2+Z.^2)/c;
        end
    end
    
    % Backprojection into Image Domain
    Im = zeros(size(X,1),size(Z,1));
    for i = 1:length(receiver_locs)
        for j = 1:length(source_locs)
            for xi = 1:size(X,1)
                for zi = 1:size(Z,1)
                    Im(zi,xi) = Im(zi,xi)+data(ceil(TimeDelays(zi,xi,i,j)*Fs));
                end
            end
        end
    end

end

