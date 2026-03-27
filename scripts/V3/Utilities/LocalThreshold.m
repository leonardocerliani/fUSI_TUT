function newPDI = LocalThreshold(PDI,nwin,nstd)

% nwin: Sliding window length in second, defalut is ±5 sec
% nstd: Threshold for outline as n times of standard deviation, defalut is
% 3 std

if nargin < 2
    nwin = 5;
end

if nargin < 3
    nstd = 3;
end

newPDI = PDI;

% process head motion information
headMotionX=detrend(PDI.gsensorInfo.x);
headMotionY=detrend(PDI.gsensorInfo.y);
headMotionZ=detrend(PDI.gsensorInfo.z);

combineMotion = sqrt(headMotionX.^2 + headMotionY.^2 + headMotionZ.^2);
combineMotionz = zscore(combineMotion);

outlierStd = 3;
outlierInd = combineMotionz > outlierStd;
[~,PDIoutlier] = min(pdist2(PDI.time,PDI.gsensorInfo.time(outlierInd)));

strlen = 0;
for i = 1:size(PDI.PDI,1)
    for j = 1:size(PDI.PDI,2)
        s = ['Thresholding progress: ' num2str(i) '/' num2str(size(PDI.PDI,1)) ', ' num2str(j) '/' num2str(size(PDI.PDI,2))];
        strlentmp = fprintf([repmat(sprintf('\b'),[1 strlen]) '%s\n'], s);
        strlen = strlentmp - strlen;
        
        voxelSignal = squeeze(PDI.PDI(i,j,:));
        voxelSignalMask = ones(size(voxelSignal));
        for t = 1:numel(voxelSignal)
            winTimeInd = (PDI.time>=PDI.time(t)-nwin & PDI.time<=PDI.time(t)+nwin);
            s = voxelSignal(winTimeInd);
            si = voxelSignal(t)/median(s,'omitnan');
            s=s./median(s,'omitnan');
            sigma=sqrt(mean((s(:)-1).^2));
            if si > 1+nstd*sigma || si < 1-nstd*sigma
                voxelSignalMask(t) = 0;
            end
        end
        voxelSignalMask(unique(PDIoutlier)) = 0;
        timeAccepted=find(voxelSignalMask);
        DataAccepted= voxelSignal(timeAccepted);
        DataInterp= interp1(timeAccepted,DataAccepted,1:numel(voxelSignal),'linear','extrap');
        newPDI.PDI(i,j,:) = DataInterp;
    end
end

end


