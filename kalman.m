function [x,P] = kalman(x_old,P_old,y)

    R = [15,0;0,3];
    A = [1,0,1,0;0,1,0,1;0,0,1,0;0,0,0,1];
    H = [1,0,0,0;0,1,0,0];

    xp = A*x_old;
    Pp = A*P_old*A';
    K = (Pp*H')/(H*Pp*H'+R);
    x_new = xp + K * (y-H*xp);
    P_new = Pp - K*H*Pp;

    if mvncdf(x_new,xp,Pp) < 0.05
        x = x_old;
        P = P_old;
    else
        x = x_new;
        P = P_new;
    end
end

% Add this to code to use
% x = zeros(4,num_obs);
% P = zeros(4,4,num_obs);
% x(:,1) = [y(1,1);y(2,1);0;0];
% P(:,:,1) = [1000,0,0,0;0,1000,0,0;0,0,1000,0;0,0,0,1000];
% 
% for i = 2:num_obs
%     [x(:,i),P(:,:,i)] = kalman(x(:,i-1),P(:,:,i-1),y(:,i));
% end