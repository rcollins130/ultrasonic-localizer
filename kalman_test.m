clear
clc
close all
%num_obs = 500;
x_true = [1:5:100,ones(1,100)*100,100:-2:1,ones(1,20),1:100;ones(1,20),1:2:100,100*ones(1,100),100:5:199,ones(1,100)*199];
%x_true = [1:num_obs;1:num_obs];
%x_true = [6*cos(2*pi/num_obs:2*pi/num_obs:2*pi);6*sin(2*pi/num_obs:2*pi/num_obs:2*pi)];
%x_true = [6*sin(2*pi/num_obs:2*pi/num_obs:2*pi);6*sin(2*pi/num_obs:2*pi/num_obs:2*pi)];
%x_true = [ones(1,num_obs);ones(1,num_obs)];
num_obs = length(x_true);
R = [15,0;0,3];
y = mvnrnd(x_true',R,num_obs)';

for k = 50:59:num_obs
    y(:,k:k+4) = [0 0 0 0 0;0 0 0 0 0];
end
%y(:,50) = [0,0];

x = zeros(4,num_obs);
P = zeros(4,4,num_obs);
x(:,1) = [y(1,1);y(2,1);0;0];
P(:,:,1) = [1000,0,0,0;0,1000,0,0;0,0,1000,0;0,0,0,1000];

%Uncomment All to see real-time estimation
for i = 2:num_obs
    %clf
    %subplot(2,1,1)
    %title("Position")
    %hold on
    %plot(x_true(1,1:i),x_true(2,1:i),'LineWidth',8)
    %plot(y(1,1:i),y(2,1:i))
    %legend("True X","Measured X","Estimated X")
    [x(:,i),P(:,:,i)] = kalman(x(:,i-1),P(:,:,i-1),y(:,i));
    %plot(x(1,1:i),x(2,1:i))
    %plot(x_true(1,:),x_true(2,:))

    %subplot(2,1,2)
    %title("Error")
    %hold on
    x_error = sqrt(sum((x(1:2,1:i)-x_true(:,1:i)).^2));
    %plot(x_error)
    y_error = sqrt(sum((y(1:2,1:i)-x_true(:,1:i)).^2));
    %plot(y_error)

    %getframe();
end

figure()
subplot(3,1,1)
hold on
plot(x_true(1,:),x_true(2,:),'LineWidth',4)
plot(y(1,:),y(2,:))
plot(x(1,:),x(2,:))
legend("True X","Measured X","Estimated X")
title("Position")

t = 1:num_obs;
velox = [0 x_true(1,2:end)-x_true(1,1:end-1)];
veloy = [0 x_true(2,2:end)-x_true(2,1:end-1)];
velonorm = sqrt(velox.^2 + veloy.^2);
est_velonorm = sqrt(x(3,:).^2 + x(4,:).^2);
subplot(3,1,2)
hold on
plot(t,velox)
plot(t,x(3,:))
title("X-Velocity")
legend("True Velocity","Estimated Velocity")
xlabel("Time")

subplot(3,1,3)
hold on
plot(t,veloy)
plot(t,x(4,:))
%plot(x(3,:),x(4,:));
legend("True Velocity","Estimated Velocity")
title("Y-Velocity")
xlabel("Time")

figure()
subplot(3,1,1)
hold on
x_error = sqrt(sum((x(1:2,:)-x_true).^2));
plot(t,x_error)
y_error = sqrt(sum((y(1:2,:)-x_true).^2));
plot(t,y_error)
legend("Estimation Error","Measurement Error")
title("Position Error")
xlabel("Time")
ylabel("||x-x_{true}||")

subplot(3,1,2)
hold on
plot(t,x(3,:)-velox)
plot(zeros(num_obs),'bl')
title("X-Velocity Error")
xlabel("Time")
ylabel("x-x_{true}")

subplot(3,1,3)
hold on
plot(t,x(4,:)-veloy)
plot(zeros(num_obs),'bl')
title("Y-Velocity Error")
xlabel("Time")
ylabel("x-x_{true}")

