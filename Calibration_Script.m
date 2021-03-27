clear
clc
close

filename = "calibration_3";
fs=1000;
record_time=25;

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

n = [1:1:length(data)]; % generate sample number vector

% plot voltage vs. sample and save

plot(n,data);
xlabel("Sample Number)");
ylabel("Voltage (V)");  
saveas(gcf,filename,"fig");

fprintf("specify calibration intervals by sample number and identify the calibration masses used in grams in the following format:\n\n")

intervals = input("[[interval 1 starting sample, interval 1 ending sample, mass];[interval 2 starting sample, interval 2 ending sample, mass]]\n\n");

% calculate force and average voltage over each calibration interval

for i=1:length(intervals)
    average_voltage(i) = mean(data(intervals(i,1):intervals(i,2)));
    force(i) = intervals(i,3)*9.8/1000;
end

coefficients = polyfit(force,average_voltage,1);
y_trendline = polyval(coefficients,force);

% produce calibration plot and save

plot(force,average_voltage,"b*");
hold on
plot(force,y_trendline);
hold off
xlabel("Force (N)")
ylabel("Voltage (V)")
title("Calibration Plot")
saveas(gcf,filename+"_cal","fig");

fprintf("\nstatic sensitivity: %f V/N\n", coefficients(1))

save(filename);