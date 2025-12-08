%% Preprocessing optimization 
clear;clc;
[subDataPath,subAnatPath,~] = Datapath('ShockTest'); % load the paths to all data

load allen_brain_atlas.mat
for isub = 1:numel(subDataPath)
    % load functional scan
    tmp = load([subDataPath{isub} filesep 'Functional' filesep 'PDI.mat']);
    n = fieldnames(tmp);
    PDI = tmp.(n{1});
    PDI.savepath = subDataPath{isub};

    % load anatomical scan
    load([subAnatPath{isub} filesep 'anatomic.mat'])
    load([subAnatPath{isub} filesep 'Transformation.mat']) %transf. matrix 
    anatomic.savepath = subAnatPath{isub}; %set storage path

    % Create the brain mask ------------------------------------------------------
    subAtlas=Atlas2Individual(atlas,anatomic,Transf);
    subRegions = subAtlas.Region.Data(:,:,anatomic.funcSlice(3));
    bmask = double(subRegions);
    bmask(bmask<=1) = 0;
    bmask(bmask>0) = 1;
    se = strel('disk', 2); % Structuring element, radius 2
    bmask = imdilate(bmask, se); % 
    PDI.bmask = bmask;
    % PDI.PDI = bsxfun(@times,PDI.PDI,bmask);

    % Rigid in-plane motion correction ------------------------------------------
    ref = median(PDI.PDI,3);% median-run reference
    cPDI = [];
    [opt,met] = imregconfig('monomodal');
    for k = 1:size(PDI.PDI,3)
        tform        = imregcorr(PDI.PDI(:,:,k),ref,'translation');
        cPDI(:,:,k)    = imwarp(PDI.PDI(:,:,k),tform,'OutputView',imref2d(size(ref)));
    end

    % Voxel wise outlier rejection/interpolation --------------------------------------
    PDI.voxelFrameRjection.std = 5;
    PDI.voxelFrameRjection.interpMethod = 'linear';
    zG     = abs(zscore(cPDI,0,3));
    maskG  = zG > PDI.voxelFrameRjection.std;                          % 5-σ threshold
    cPDI(maskG) = NaN;                         % flag as → NaN
    crPDI = PDI;
    crPDI.PDI = fillmissingTime(cPDI,PDI.voxelFrameRjection.interpMethod);
    PDI.voxelFrameRjection.ratio = sum(maskG(:))/numel(crPDI.PDI );

    % Convert to percent-signal change (for GLM) --------------------------
    mu   = repmat(mean(crPDI.PDI,3),1,1,size(PDI.PDI,3));
    PDI.PDI   = (crPDI.PDI-mu)./mu.*100;
    % Convert to zscore (for ISC analysis) --------------------------
    % PDI.PDI = zscore(PDI.PDI,0,3);

    % Resample data to 5Hz -------------------------------------------------
    PDI = resamplePDI(PDI,5);

    % Temporal highpass filtering ------------------------------------------
    PDI.PDI = DCThighpass(PDI.PDI,5,500);

    % Spatial smoothing -------------------------------------------------------
    PDI.spatialSigma = 1; % gaussian kernel with 1 sd (FWHM = 2.355 * σ)
    for ii = 1:size(PDI.PDI,3)
        PDI.PDI(:,:,ii) = imgaussfilt(squeeze(PDI.PDI(:,:,ii)),PDI.spatialSigma);%Reduce noise and smooth the function
    end
    
    % Save the preprocessed data ---------------------------------------------
    parsave([subDataPath{isub} filesep 'Functional' filesep 'prepPDI.mat'],PDI);

end

    

%% Preprocessing (Sliding window outlier removal in each voxel)
clear;
[subDataPath,~] = Datapath('SS'); % load the paths to all data

tic;
% strlen = 0;
for isub = 1:numel(subDataPath) %for each test run load data

    % s = ['Calculating session: ' num2str(isub) '/' num2str(numel(subDataPath))];
    % strlentmp = fprintf([repmat(sprintf('\b'),[1 strlen]) '%s\n'], s);
    % strlen = strlentmp - strlen;

    % load raw functional data from Rawdata2MATnew
%     tmp = load([subDataPath{isub} filesep 'Functional' filesep 'PDI.mat']);
%     n = fieldnames(tmp);
%     PDI = tmp.(n{1});
%     PDI.savepath = subDataPath{isub};
%     PDI = LocalThreshold(PDI);

    % save thresholded data
%     parsave([subDataPath{isub} filesep 'Functional' filesep 'LTPDI.mat'],PDI);

    % load thresholded data
    tmp = load([subDataPath{isub} filesep 'functional' filesep 'LTPDI.mat']);
    n = fieldnames(tmp);
    PDI = tmp.(n{1});
    PDI.savepath = subDataPath{isub};
    
    RSPDI = resamplePDI(PDI,5);
    DTPDI = PDIfilter(RSPDI,'highpass'); %detrend substracts trends from each column
    
    % Spatial smooting
    DTPDI.sigma = 1; % gaussian kernel with 1 sd (FWHM = 2.355 * σ)
    for ii = 1:size(DTPDI.PDI,3)
        DTPDI.PDI(:,:,ii) = imgaussfilt(squeeze(DTPDI.PDI(:,:,ii)),DTPDI.sigma);%Reduce noise and smooth the function
    end

    % data normalization across time
    DTPDI.PDI = zscore(DTPDI.PDI,0,3);

    parsave([subDataPath{isub} filesep 'Functional' filesep 'preprocPDI.mat'],DTPDI);

end
toc
