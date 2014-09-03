%Read in data1
[data1,~] = rdmseed('10_LH1.512.seed');
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


%Here we convert to degC using a pre-amp of 20 and digitizer gain of
%2^26/40
data1vec = data1vec*(40/(2^26))*0.01/20;

%Here we do a 100 point moving average to smooth the data
b=zeros(1,100)+1/100;
a=1;
data1vec = filtfilt(b,a,data1vec);

%Lets make a time vector to plot with
tvec = 1:length(data1vec);
tvec = tvec/(60*60*datasrate);

%Here we define a cosine function we want to fit
fit = @(b) b(1) + b(2)*cos(2*pi*tvec/b(3) + 2*pi*b(4));

%Here is the residual using the data vector
resi = @(b) sum((fit(b)-data1vec').^2);


%Here we get our git for our parameters
results = fminsearch(resi,[0.0016 1*10^-7 27 1]);


%Now lets plot everything
figure(1);
%Clear the figure
clf;
%Plot the first stream scaled as a black line
p1=plot(tvec,data1vec,'color','k','LineWidth',1);
hold on;
%Here we plot the fit of our cosine function
p2=plot(tvec,fit(results),'color',[.5 .5 .5],'LineWidth',1);
%Lets limit the x-axis to what we are plotting
xlim([min(tvec) max(tvec)]);
%Lets label the x-axis along with the y-axis
xlabel('Time (hours)','FontSize',16);
ylabel('Output','FontSize',16);
set(gca,'FontSize',16);
%Lets make a legend with the start time and the fit of the cosine function
legend([p1 p2],[net1 ' ' sta1 ' ' loc1 ' ' chan1], ...
    ['Fit: ' num2str(roundn(results(1),-4)) '+' ...
    num2str(roundn(results(2),-8)) '*cos(' ...
    '2*pi/' num2str(roundn(results(3),-8)) '+2*pi*' ...
    num2str(roundn(results(4),-8)) ')'], ...
    'FontSize',16);
title([year ' ' day ' ' hour ':' minute ':' second],'FontSize',16);
orient Landscape
print('-djpeg',[net1 sta1 loc1 chan1 '_' ...
    year day hour minute second '.jpg']);