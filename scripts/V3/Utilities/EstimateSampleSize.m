function [idealSmapleSize,powBF] = EstimateSampleSize(meanstd1,meanstd2,sampleSize2Est,NrandomData,Nbootstrap,powThresh)

% Make sure klabhub-bayesFactor toolbox is in your path
installBayesFactor

if nargin < 2
    meanstd2 = [];
end

if nargin < 3
    sampleSize2Est = [10 60];
end

if nargin < 4
    NrandomData = 1000;
end

if nargin < 5
    Nbootstrap = 5000;
end

if nargin < 6
    powThresh = 0.8;
end


rData1 = meanstd1(1) + meanstd1(2).*randn(NrandomData,1);
if ~isempty(meanstd2)
    rData2 = meanstd2(1) + meanstd2(2).*randn(NrandomData,1);
end

powBF = zeros(max(sampleSize2Est),1);
% Bootstrapping to estiamte power by sample size
strlen = 0;
for iss = min(sampleSize2Est):max(sampleSize2Est)
    s = ['Calculating samplesize: ' num2str(iss) '/' num2str(max(sampleSize2Est))];
    strlentmp = fprintf([repmat(sprintf('\b'),[1 strlen]) '%s'], s);
    strlen = strlentmp - strlen;
    Ncon = 0;
    for ibs = 1:Nbootstrap
        if isempty(meanstd2)
            tmpData1 = rData1(randperm(NrandomData,iss));
            [BF10,~] = bf.ttest(tmpData1); % type of test can be changed here
        else
            tmpData1 = rData1(randperm(NrandomData,iss));
            tmpData2 = rData2(randperm(NrandomData,iss));
            [BF10,~] = bf.ttest(tmpData1,tmpData2); % type of test can be changed here
        end
        % Save conclusive iterations
        if BF10<1/3 || BF10>3
            Ncon = Ncon+1;
        end

    end
    powBF(iss) = Ncon/Nbootstrap;
end


idealSmapleSize = find(powBF>=powThresh,1);

plot(powBF,'linewidth',2)
hold on
plot([min(sampleSize2Est),max(sampleSize2Est)],[powThresh powThresh],'--','linewidth',2)
text(idealSmapleSize,powThresh-0.1,['N= ' num2str(idealSmapleSize)])
xlim([min(sampleSize2Est),max(sampleSize2Est)])
xlabel('Sample Size')
ylabel('Estimated Power')

end

