%Read in data1
[data1,~] = rdmseed('00_LHZ.512.seed');
%Get a vector of the time series
data1vec = cat(1,data1.d);
%Get a vector of the times
data1time = cat(1,data1.t);


%Lets get the sample rate and assume all the data has the same sample rate
datasrate = data1(1,1).SampleRate;
net1 = deblank(data1(1,1).NetworkCode);
sta1 = deblank(data1(1,1).StationIdentifierCode);
loc1 = deblank(data1(1,1).LocationIdentifier);
chan1 = deblank(data1(1,1).ChannelIdentifier);

%Lets get the year and the day along with the other date parameters
year=data1(1,1).RecordStartTimeISO;
hour = year(10:11);
minute = year(13:14);
second = year(16:17);
year=year(1:8);
day=year(6:8);
year=year(1:4);


%Read in data2
[data2,~] = rdmseed('10_LHZ.512.seed');
%Get a vector of the time series for data2
data2vec = cat(1,data2.d);
%Get a vector of the times for data2
data2time = cat(1,data2.t);

%Lets get the info for the second stream
net2 = deblank(data2(1,1).NetworkCode);
sta2 = deblank(data2(1,1).StationIdentifierCode);
loc2 = deblank(data2(1,1).LocationIdentifier);
chan2 = deblank(data2(1,1).ChannelIdentifier);

%Lets not do more with the dates and assume they are the same



[pdata1,fre]=pwelch(data1vec,floor(length(data1vec)/10), ...
    floor(length(data1vec)/20),floor(length(data1vec)/10),datasrate);


[pdata2,fre]=pwelch(data2vec,floor(length(data2vec)/10), ...
    floor(length(data2vec)/20),floor(length(data2vec)/10),datasrate);






%Lets remove a linear trend from both data streams
data1vec = detrend(data1vec);
data2vec = detrend(data2vec);

%Lets do a band-pass filter from 0.1 Hz to 0.01 Hz with 4 poles
h=fdesign.bandpass('N,F3dB',4,0.01,0.1);
%Lets make is a butterworth
d1 = design(h,'butter');
%Lets do a two-pass to make it zero phase
data1vec = filtfilt(d1.sosMatrix,d1.ScaleValues,data1vec);
data2vec = filtfilt(d1.sosMatrix,d1.ScaleValues,data2vec);

%Lets compare a scale ratios between the two
data1to2rat = std(data1vec)/std(data2vec);

%Lets look at the difference between the data streams with the ratio of the
%two removed

resi1to2 = data1vec/data1to2rat - data2vec;

%Lets make a time vector to plot with
tvec = 1:length(data1vec);
tvec = tvec/(60*60*datasrate);


%Now lets plot everything
figure(1);
%Clear the figure
clf;
subplot(2,1,1)
%Plot the first stream scaled as a black line
p1=plot(tvec,data1vec/data1to2rat,'color','k','LineWidth',1);
hold on;
%Plot the second stream as a blue line
p2=plot(tvec,data2vec,'color','b','LineWidth',1);
%Plot the residual as a green line
p3=plot(tvec,resi1to2,'color','g','LineWidth',1);
%Lets limit the x-axis to what we are plotting
xlim([min(tvec) max(tvec)]);
%Lets label the x-axis along with the y-axis
xlabel('Time (hours)','FontSize',16);
ylabel('Output','FontSize',16);
set(gca,'FontSize',16);
%Lets make a legend with the start time
legend([p1 p2 p3],['Scaled ' net1 ' ' sta1 ' ' loc1 ' ' chan1], ...
    ['Raw ' net2 ' ' sta2 ' ' loc2 ' ' chan2],['Residual w/Scale: ' ...
    num2str(roundn(data1to2rat,-2)) ],'FontSize',16);
title([year ' ' day ' ' hour ':' minute ':' second],'FontSize',16);
%Lets plot the spectral ratio
subplot(2,1,2)
p2=semilogx(fre,10*log10(pdata1./pdata2),'color','k','LineWidth',1);
xlabel('Frequency (Hz)','FontSize',16);
ylabel('Power Ratio (dB)','FontSize',16);
xlim([min(fre) max(fre)]);
set(gca,'FontSize',16);
title(['Spectral Ratio: ' net1 ' ' sta1 ' ' loc1 ' ' chan1 ' over' ...
    net2 ' ' sta2 ' ' loc2 ' ' chan2],'FontSize',16);
orient Landscape
print('-djpeg',[net1 sta1 loc1 chan1 'vs' net2 sta2 loc2 chan2 '_' ...
    year day hour minute second '.jpg']);










