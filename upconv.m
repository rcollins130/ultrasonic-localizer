function [data_pb_avg,Fs] = upconv(data_I,data_Q,fc)

    K = 64;
    Fs = K*fc/8;
    t = 0:1/Fs:12/343;
    t = t(1:size(data_I,2)*K);
    
    data_pb = zeros(size(data_I,1),length(t));
    for ai = 1:size(data_I,1)
        amp = abs(data_I(ai,:)+1j*data_Q(ai,:));
%         data_I_up = resample(data_I(ai,:),K,1);
%         data_Q_up = resample(data_Q(ai,:),K,1);
%         data_pb(ai,:) = data_I_up.*cos(2*pi*fc*t) - data_Q_up.*sin(2*pi*fc*t);
        data_pb(ai,:) = resample(amp,K,1);
    end
    
    data_pb_avg = mean(data_pb,1);

end

