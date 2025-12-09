%% Preprocessing optimization 

[subDataPath,subAnatPath,~] = Datapath_DEV('VisualTest'); % load the paths to all data

load allen_brain_atlas.mat

% here there was a for like for isub = 1:numel(subDataPath) until parsave
isub=1;

%% For some reason the savepath is reassigned for both anat and func
%  for the moment I will keep it although I don't see the reason

% load functional scan
load([subDataPath{isub} filesep 'PDI.mat']);
PDI.savepath = subDataPath{isub};

% load anatomical scan
load([subAnatPath{isub} filesep 'anatomic.mat'])
load([subAnatPath{isub} filesep 'Transformation.mat']) %transf. matrix 
anatomic.savepath = subAnatPath{isub}; %set storage path



%% Create a mask from the Allen atlas to retain only nnz voxels in the functional slice
%  This is necessary because although we made sure that our fn slice
%  correspond to a specific slice in the Allen atlas, we still want to
%  exclude the voxels outside of the brain. For that, we take the atlas
%  in the sub(ject) space and we retain only the voxels where nonzero
%  voxels in the Region data of the atlas are present.
% 
%  Note: for some reason the X and Z dimensions in the anatomic.funcSlice
%  are half of those in the anatomic / subAtlas. Why so?

% Take Allen atlas in subject space
subAtlas=Atlas2Individual(atlas,anatomic,Transf); 
% Select the retained functional slice from the anatomic. The slice
% number is the last element of anatomic.funcSlice.
subRegions = subAtlas.Region.Data(:,:,anatomic.funcSlice(3));

% Create the binary mask
bmask = double(subRegions > 1);

% Dilate the mask
dilatation_radius = 2;
se = strel('disk', dilatation_radius);
bmask = imdilate(bmask, se);

% Store it in PDI
PDI.bmask = bmask;
% PDI.PDI = bsxfun(@times,PDI.PDI,bmask);




% Display the slice on the subAtlas
figure('Position', [100 100 1200 900]);
t = tiledlayout(5,4, 'Padding', 'compact', 'TileSpacing', 'compact');

numSlices = size(subAtlas.Region.Data,3);
sliceIdx = 1:numSlices;  % slices to display
overlaySlice = anatomic.funcSlice(3); % slice where mask applies


for i = 1:numSlices
    ax = nexttile;
    
    % Display anatomical slice
    imagesc(subAtlas.Region.Data(:,:,sliceIdx(i)));
    colormap(ax, gray);
    axis(ax, 'square');
    hold(ax, 'on');
    
    % Overlay mask only if this is the functional slice
    if sliceIdx(i) == overlaySlice
        % create a red RGB overlay from the binary mask
        redMask = cat(3, bmask, zeros(size(bmask)), zeros(size(bmask))); 
        h = imshow(redMask, 'XData', [1 size(redMask,2)], 'YData', [1 size(redMask,1)]);
        set(h, 'AlphaData', bmask * 0.3);
        axis(ax, 'square');
    end
    
    title(ax, ['Slice ' num2str(sliceIdx(i))]);
end

sgtitle('Subject Anatomy with Brain Mask Overlay');





%% Rigid in-plane motion correction

ref = median(PDI.PDI,3); % median image from the functionl run

[nY, nX, nFrames] = size(PDI.PDI);
cPDI = zeros(nY, nX, nFrames, 'like', PDI.PDI); % preallocation for speed

h = waitbar(0,'Performing motion correction...');

for k = 1:nFrames
    tform = imregcorr(PDI.PDI(:,:,k), ref, 'translation');
    cPDI(:,:,k) = imwarp(PDI.PDI(:,:,k), tform, 'OutputView', imref2d(size(ref)));
    
    % update waitbar
    step = 100;
    if mod(k,step)==0 || k==nFrames  % update every 10 frames to avoid slowdown
        waitbar(k/nFrames, h, sprintf('Correcting frame %d of %d', k, nFrames));
    end
end

close(h); % close progress bar when done


%% Voxelwise outlier rejection/interpolation 
std_threshold = 5;
PDI.voxelFrameRjection.std = std_threshold;
PDI.voxelFrameRjection.interpMethod = 'linear';
zG     = abs(zscore(cPDI,0,3));
maskG  = zG > PDI.voxelFrameRjection.std;  % 5-σ threshold
cPDI(maskG) = NaN;                         % flag as → NaN
crPDI = PDI;
crPDI.PDI = fillmissingTime(cPDI,PDI.voxelFrameRjection.interpMethod);
PDI.voxelFrameRjection.ratio = sum(maskG(:))/numel(crPDI.PDI );



%% Convert to percent-signal change (for GLM) 
n_Frames = size(PDI.PDI,3);
mu   = repmat(mean(crPDI.PDI,3),1,1,n_Frames);
PDI.PDI   = (crPDI.PDI-mu)./mu.*100;


% Convert to zscore (for ISC analysis)
% PDI.PDI = zscore(PDI.PDI,0,3);


%% Resample data to 5Hz 
resampling_rate = 5;
PDI = resamplePDI(PDI,resampling_rate);


%% Temporal highpass filtering 
cutoff_in_seconds = 500;
PDI.PDI = DCThighpass(PDI.PDI,5,cutoff_in_seconds);


%% Spatial smoothing 
PDI.spatialSigma = 1; % gaussian kernel with 1 sd (FWHM = 2.355 * σ)
n_Frames = size(PDI.PDI,3);
for ii = 1:n_Frames
    PDI.PDI(:,:,ii) = imgaussfilt(squeeze(PDI.PDI(:,:,ii)),PDI.spatialSigma);%Reduce noise and smooth the function
end


%% Save the preprocessed data

% now I simply save in the original data_analysis dir
parsave([subDataPath{isub} filesep 'prepPDI.mat'],PDI);

















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    Alternative preprocessing below
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

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
