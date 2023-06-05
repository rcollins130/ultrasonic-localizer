clear
clc
close all

num_obs = 500;
x_true = [1:num_obs;1:num_obs]';
R = [15,0;0,3];
y = mvnrnd(x_true,R,num_obs)';

for k = 50:59:790
    y(:,k:k+4) = [0 0 0 0 0;0 0 0 0 0];
end
%y(:,50) = [0,0];

x = zeros(4,num_obs);
P = zeros(4,4,num_obs);
x(:,1) = [y(1,1);y(2,1);0;0];
P(:,:,1) = [1000,0,0,0;0,1000,0,0;0,0,1000,0;0,0,0,1000];

for i = 2:num_obs
    [x(:,i),P(:,:,i)] = kalman(x(:,i-1),P(:,:,i-1),y(:,i));
end

error = sqrt(sum((x(1:2,:)-x_true').^2));
plot(error)