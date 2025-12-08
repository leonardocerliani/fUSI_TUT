%% plot fft for hrf convoled stim
% extract infomation from eventInfo
onsetFrame = round(PDI.eventInfo{1}/PDI.Dim.dt);
durationFrame = ceil(PDI.eventInfo{2}/PDI.Dim.dt);
condMat = PDI.eventInfo{4};
predictor = unique(PDI.eventInfo{4});

stim=zeros(length(PDI.PDI),numel(predictor));
for ip = 1:numel(predictor)
    condInd = find(condMat==predictor(ip));
    for ii = onsetFrame(condInd)'
        stim(ii:ii+durationFrame(condInd(1))-1,ip)=1;
    end
end
    
hrf = hemodynamicResponse(PDI.Dim.dt,[2 16 0.5 1 20 0 16]); % hemodynamic response function (hrf)
X=filter(hrf,1,stim);     

figure()
subplot(2,1,1)
plot(PDI.time,X)
title('HRF convoled stimuli')
xlabel('Time (sec)')
ylabel('Response')

subplot(2,1,2)
L = numel(X);
f = 1/PDI.Dim.dt*(0:(L/2))/L;
Y = fft(X);
P2 = abs(Y/L).^2;
P1HF = P2(1:L/2+1);
f(1) = [];
P1HF(1) = [];
plot(f,P1HF)
xlim([0 1])
title('Frequency response of convoled stimuli')
xlabel('Frequency (Hz)')
ylabel('Amplitude')

%% plot fft for PDI convoled stim
X = squeeze(PDI.PDI(randi(size(PDI.PDI,1)),randi(size(PDI.PDI,2)),:));
L = numel(X);
f = 1/PDI.Dim.dt*(0:(L/2))/L;
Y = fft(X);
P2 = abs(Y/L).^2;
P1HF = P2(1:L/2+1);
f(1) = [];
P1HF(1) = [];
figure();plot(f,P1HF)
xlim([0 1])
ylabel('Amplitude')