clear
clc
close all

num_obs = 500;
%x_true = [1:100,ones(1,100)*100,100:-1:1,ones(1,100),1:100;ones(1,100),1:100,100*ones(1,100),100:199,ones(1,100)*199];
%x_true = [1:num_obs;1:num_obs];
x_true = [6*cos(2*pi/500:2*pi/500:2*pi);6*sin(2*pi/500:2*pi/500:2*pi)];
R = [15,0;0,3];
y = mvnrnd(x_true',R,num_obs)';

for k = 50:59:500
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

figure()
hold on
x_error = sqrt(sum((x(1:2,:)-x_true).^2));
plot(x_error)
y_error = sqrt(sum((y(1:2,:)-x_true).^2));
plot(y_error)
legend("Estimation Error","Measurement Error")

figure()
hold on
plot(x_true(1,:),x_true(2,:))
plot(y(1,:),y(2,:))
plot(x(1,:),x(2,:))
legend("True X","Measured X","Estimated X")