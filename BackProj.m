function Im = BackProj(data,receiver_locs,source_locs,c,Fs,sizeX,sizeZ,Nx)
    % Define Imaging Geometry
    X = linspace(-sizeX/2,sizeX/2,Nx);
    Z = linspace(0,sizeZ, Nx);
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
                    idx = ceil(TimeDelays(zi,xi,i,j)*Fs);
                    if idx <= size(data, 2)
                        Im(zi,xi) = Im(zi,xi)+data(idx);
                        
                    end
                    if zi < 30
                        Im(zi,xi) = 0;
                    end
                    % angle = atan2d(xi-200,zi);
                    % if angle > 50 | angle < -50
                    %     Im(zi,xi) = 0;
                    % end
                end
            end
        end
    end
end

