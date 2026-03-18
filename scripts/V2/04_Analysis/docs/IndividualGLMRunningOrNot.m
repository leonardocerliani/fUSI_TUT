%% Individual GLM with running and without running (Visual test)
% clear;
[subDataPath,subAnatPath,resultPath] = Datapath('VisualTest'); % load the paths to all data

resultFolder = 'GLMPrepRunningOrNot';

tic;
warning off
for isub =  1:numel(subDataPath)
    % load PDI data
    tmp = load([subDataPath{isub} filesep 'functional' filesep 'prepPDI.mat']);
    n = fieldnames(tmp);
    PDI = tmp.(n{1});
    PDI.savepath = subDataPath{isub};

    % create result folder if there is none
    if ~exist([resultPath filesep resultFolder],'file')
        mkdir([resultPath filesep resultFolder])
    end

    % Separate running and no running condition
    runningTrialIndex = [];
    for itrl = 1:numel(PDI.stimInfo.stimCond)
        trialRunning = PDI.wheelInfo.wheelspeed(PDI.wheelInfo.time>=PDI.stimInfo.startTime(itrl)&...
            PDI.wheelInfo.time<=PDI.stimInfo.endTime(itrl));
        timeDev = mean(diff(PDI.wheelInfo.time));
        CC = bwconncomp(abs(trialRunning) >35); % speed above 2cm/s
        CCsize = cellfun(@(x) numel(x), CC.PixelIdxList);
        if any(CCsize>0.2/timeDev) % time last more than 200ms
            runningTrialIndex = [runningTrialIndex,itrl];
        end
    end
    PDI.stimInfo.stimCond(runningTrialIndex) = ...
        strrep(PDI.stimInfo.stimCond(runningTrialIndex),PDI.stimInfo.stimCond{1},'visualRunning');


    disp(['ses' num2str(isub) ',RunningTrials' num2str(numel(runningTrialIndex)) '/' num2str(itrl)])
    
    % skip sessions that contain only running or only stationary trials
    if numel(runningTrialIndex) <= 0 | numel(runningTrialIndex) >= itrl
        continue
        PDI.stimInfo.stimCond(end) = ...
            strrep(PDI.stimInfo.stimCond(end),PDI.stimInfo.stimCond{1},'visual');
    end


    %% construct desgin matrix for all events
    % extract infomation from eventInfo
    [~,onsetFrame]= arrayfun(@(x)(min(abs(x-PDI.time))), PDI.stimInfo.startTime, 'UniformOutput', true);
    [~,offsetFrame]= arrayfun(@(x)(min(abs(x-PDI.time))), PDI.stimInfo.endTime, 'UniformOutput', true);
    condMat = deblank(PDI.stimInfo.stimCond);
    condMat = strrep(condMat,'.','');
    condMat = strrep(condMat,' ','');
    predictor = unique(condMat);

    stim=zeros(size(PDI.PDI,3),numel(predictor));
    stimIgnore=zeros(size(PDI.PDI,3),numel(predictor));
    for ip = 1:numel(predictor)
        condInd = find(strcmp(condMat,predictor(ip)));
        tmpOnset = onsetFrame(condInd);
        tmpOffset = offsetFrame(condInd);
        for ii = 1:numel(tmpOnset)
            stim(tmpOnset(ii):tmpOffset(ii),ip)=1;
            stimIgnore(tmpOnset(ii):tmpOnset(ii),ip)=1;
        end
    end
    stim = stim(1:size(PDI.PDI,3),:);
    stimIgnore = stimIgnore(1:size(PDI.PDI,3),:);


    % stimulation is the convolution of HRF and boxcar function
    hrf = hemodynamicResponse(mean(diff(PDI.time)),[2.4 8 0.8 0.9 6 0 16]); % hemodynamic response function (hrf)
    X=filter(hrf,1,stim);                % filter the activity by the hrf (convolution)

    % generate GLM formula
    glmresult = struct;
    glmresult.varName{1} = 'Visual';
    glmresult.varName{2} = 'VisualRunning';

    % add absolute running speed convolved with HRF
    wheelSpeed  = fillmissing(abs(interp1(PDI.wheelInfo.time,PDI.wheelInfo.wheelspeed,PDI.time)),'nearest');
    wheelSpeedConv = filter(hrf,1,wheelSpeed);
    wheelSpeedSmooth = smoothdata(wheelSpeed,'gaussian',10);
    X(:,3) = wheelSpeedSmooth;
    glmresult.varName{3} = 'SmoothRunning';
    X(:,4) = wheelSpeedConv;
    glmresult.varName{4} = 'ConvRunning';
    X(:,5) = wheelSpeedConv'.*sum(X(:,[1,2]),2);
    glmresult.varName{5} = 'VisualRunningInteraction';

    glmresult.X = X;
    glmresult.corrMat = corr(X,'rows','pairwise');


%% fit different GLM
    [nx,ny,~]=size(PDI.PDI);
    strlen = 0;
    n =1;
    for ix=1:nx
        for iy=1:ny
            s = ['Calculating GLM: ' num2str(ceil(n/nx/ny*100)) '%'];
            strlentmp = fprintf([repmat(sprintf('\b'),[1 strlen]) '%s'], s);
            strlen = strlentmp - strlen;
            n = n+1;
            Y=squeeze(PDI.PDI(ix,iy,:));

            % process running speed
            wheelSpeed = X(:,3);
            wheelSpeed(wheelSpeed<35) = 0;
            wheelSpeedConv = filter(hrf,1,wheelSpeed);

            mdlAll = fitglm([sum(X(:,[1,2]),2),X(:,3:end)],Y);
            SSVisual = sum((mdlAll.Coefficients.Estimate(2)*sum(X(:,[1,2]),2)-mean(mdlAll.Coefficients.Estimate(2)*sum(X(:,[1,2]),2))).^2);
            glmresult.AllvisualPartialETA2(ix,iy,:) = SSVisual/(SSVisual+mdlAll.SSE);


            mdlAllReduce = fitglm(sum(X(:,[1,2]),2),Y);
            SSRunVisual = sum((mdlAllReduce.Coefficients.Estimate(2)*sum(X(:,[1,2]),2)-mean(mdlAllReduce.Coefficients.Estimate(2)*sum(X(:,[1,2]),2))).^2);
            glmresult.AllVisualReduceETA2(ix,iy,:) = (SSRunVisual)/(SSRunVisual+mdlAllReduce.SSE);

            mdlSteady = fitglm(X(:,1),Y,'Exclude',wheelSpeedConv>0);
            SSsteadyVisual = sum((mdlSteady.Coefficients.Estimate(2)*X(wheelSpeedConv==0,1)-mean(mdlSteady.Coefficients.Estimate(2)*X(wheelSpeedConv==0,1))).^2);
            glmresult.SteadyVisualETA2(ix,iy,:) = SSsteadyVisual/(SSsteadyVisual+mdlSteady.SSE);
            glmresult.SteadyVisualMask = wheelSpeedConv>0;

            corrReduce = corr(sum(X(:,[1,2]),2),Y);
            glmresult.AllVisualReduceCorr(ix,iy,:) = corrReduce;

            corrSteady = corr(X(wheelSpeedConv<=0,1),Y(wheelSpeedConv<=0));
            glmresult.SteadyVisualCorr(ix,iy,:) = corrSteady;

        end
    end
    fprintf('\n');

    parsave([resultPath filesep resultFolder filesep 'GLMSes' num2str(isub)],glmresult)


end
warning on
toc

