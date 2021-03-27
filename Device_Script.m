clear
clc
close

filename = "test_1";
fs=1000; % sample frequency in Hz
record_time=5; % recording duration
sensitivity = 0.079815; % static sensitivity in V/N
R = 8/1000; % tube radius in meters
rho = 1.225; % air density in kg/m^3

% create a DAQ session with one analog input

s=daq.createSession("ni");
[ch,idx]=s.addAnalogInputChannel("dev1","ai0","Voltage");

ch(1).Range=[-4 4]; % set the voltage range

% set the sampling frequency and recording duration

s.Rate=fs;
s.DurationInSeconds=record_time;

% create a listener to view data during collection 

listen=s.addlistener("DataAvailable",@(s,event) plot(event.TimeStamps,event.Data));

[data,t]=s.startForeground(); % start recording data
data_smoothed = smooth(data, 10); % apply moving-average smoothing to the voltage data

dc_offset = mean(data_smoothed(1:250)); %calculate dc offset from first 250 samples
F = (data_smoothed-dc_offset)/sensitivity; % calculate pressure force in N based on static sensitivity and dc offset

% calculate volumetric flow rate in m^3/s via stagnation pressure

for k=1:length(F)
    
    if (2*pi*R^2*F(k)/rho)<=0
        flow_rate(k) = -sqrt(-2*pi*(R^2)*(F(k))/rho);
    else
        flow_rate(k) = sqrt(2*pi*(R^2)*(F(k))/rho);
    end
end

%numeric integral under flow_rate curve to calculate total volume flowed in m^3

volume(1) = flow_rate(1)/fs;
for k=2:length(flow_rate)
    volume(k) = flow_rate(k)/fs + volume(k-1);
end

n = [1:length(t)];
    
% plot voltage vs. sample
subplot(2,2,1)
plot(n,data_smoothed);
xlabel("Sample");
ylabel("Voltage (V)");
title("Raw Data");

interval = input("Select data range\n");

% plot force vs. time
subplot(2,2,2)
plot(t(interval(1):interval(2)),F(interval(1):interval(2)));
xlabel("Time (s)");
ylabel("Force (N)");
title("Force");

% plot flow rate vs. time
subplot(2,2,3)
plot(t(interval(1):interval(2)),flow_rate(interval(1):interval(2)));
xlabel("Time (s)");
ylabel("Flow Rate (m^3/s)");
title("Flow Rate");

% plot volume flowed
subplot(2,2,4)
plot(t(interval(1):interval(2)),volume(interval(1):interval(2)));
xlabel("Time (s)");
ylabel("Volume (m^3)");
title("Volume");

fprintf("\nmax force: %f m^3\naverage force: %f m^3\n", max(F(interval(1):interval(2))), mean(F(interval(1):interval(2))))
fprintf("max flow rate: %f m^3/s\naverage flow rate: %f m^3/s\n", max(flow_rate(interval(1):interval(2))), mean(flow_rate(interval(1):interval(2))))
fprintf("total volume: %f m^3\n", max(volume(interval(1):interval(2))))

saveas(gcf,filename,"fig");
save(filename);