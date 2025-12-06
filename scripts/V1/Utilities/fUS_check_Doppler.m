% script to check if fUS acquisition was successfull.
% To be used after: fUS_L22_14_continuous_live.m
thispath = strrep(mfilename('fullpath'),mfilename,'');
addpath(genpath([thispath 'verasonics_utilities']))
% function fUS_check_Doppler
datafolder = uigetdir(['\\vs03\VS03-SBL-4\'], 'Please select the raw fUSI data folder');

% search for all avi files in the folder and subfolders
[folder,file,list] = findfolderfile(datafolder,'L22-14_PlaneWave_FUSI_data.mat');

for ifile = 1:size(file,1)

    filepath = file{ifile,1};
    filename = file{ifile,2};

        % load scan parameters
    load([filepath filesep filename])
    
    % skip converted data folder
    if exist([filepath filesep 'fUS_block_PDI_float.bin'],'file')
        fprintf('Converted PDI data exist, loading PDI data... \n')
        fid = fopen([filepath filesep 'fUS_block_PDI_float.bin'], 'r');
        rawPDI = fread(fid,inf,'single');
        fclose(fid);
        if Pm.numBlocks == numel(rawPDI)/BFConfig.Nx/BFConfig.Nz
            continue
        else
            warning(['Incorrectly converted PDI data at:' filepath '\n Trying to convert again...'])
        end
    end

    nblocks = Pm.numBlocks;
    datanamepat = 'fUS_block_IQ_%03i_float.bin';
    datatype = 'single';

    USE_DOPDATA = 0;
    LOAD_ALL_IQ = 0;
    IQ_all = [];

    if isfile(fullfile(filepath, 'DopplerResult.mat'))
        load(fullfile(filepath, 'DopplerResult.mat'))
    else
        % initialize DopData
        Dop = zeros(BFConfig.Nz, BFConfig.Nx, nblocks, 'single');
        ens_size = [BFConfig.Nz, BFConfig.Nx, BFConfig.NFrames];

        fprintf('Loading IQ and computing SVD of recorded blocks\n');
        for kb = 1:nblocks
            if mod(kb, 10) == 0
                fprintf('Reading and svd block % 4i of % 4i\n', kb, Pm.numBlocks)
            end
            dataname = sprintf(datanamepat, kb);
            [IQ, fileFound] = readBinFile(fullfile(filepath, dataname), ens_size, datatype, 1);
            if ~fileFound
                fprintf('ERROR: Could not find all blocks.\n')
                break;
            end

            % and compute SVD
            BFConfig.svalsToKeep = round(SVDINFO.start):round(SVDINFO.end);
            Dop(:, :, kb) = dopplerSVDfilter(IQ, BFConfig.svalsToKeep);
            % Dop(:,:,kb) = dopplerSVDfilter2(IQ);

            if LOAD_ALL_IQ
                IQ_all = cat(3, IQ_all, IQ);
            end
        end
        DopData{1} = Dop;
    end

    % save to save folder
    dop_fname = 'fUS_block_PDI_float.bin';
    dop_fpath = fullfile(filepath, dop_fname);
    writeBinFile(dop_fpath , DopData{1}, 'float', false);

end

return
% load('N:\tnw\IST\AK\hpc\rwaasdorp1\experimental_data\fus_assignment\fUS_dataset_AP3232.mat')
% load('N:\tnw\IST\AK\hpc\rwaasdorp1\experimental_data\fus_assignment\UF.mat')
% Dop = Doppler_frames;
% tv = 1:size(Dop,3);


%% Processing  of Doppler signal variations versus baseline
nframes_baseline = 20;
Dop_mean = imfilter(Dop, ones(3) / 9);
Dop_baseline = imfilter(mean(Dop_mean(:, :, 1:nframes_baseline), 3), ones(3) / 9);
Dop_norm = Dop_mean - Dop_baseline;
Dop_norm = Dop_norm ./ Dop_baseline;

tv = (1:size(Dop_norm, 3)) ./ Pm.blockRate;
if exist('VSTIM', 'var')
    stimBaseline = VSTIM.Baseline; % s
    stimOnDuration = VSTIM.OnDuration; % s
    stimBlockDuration = VSTIM.BlockDuration; % s
else
    stimBaseline =  0; % s
    stimOnDuration = 15; % s
    stimBlockDuration = 60; % s
end
offset = 0;
Vstim = generateVstim(tv, stimBaseline+offset, stimBlockDuration, stimOnDuration);

% correlation
R = zeros(size(mean(Dop_norm, 3)));
for x = 1:size(Dop_norm, 2)
    for z = 1:size(Dop_norm, 1)
        PwDn = squeeze(Dop_norm(z, x, :))';
        R(z, x) = sum((PwDn .* Vstim)) / (sqrt(sum(PwDn.^2)) * sqrt(sum(Vstim.^2)));
    end
end
% R = sum(Dop_norm .* reshape(Vstim,1,1,[]),3) ./ (sqrt(sum(Dop_norm.^2,3)) * sqrt(sum(Vstim.^2)));

Rc = R; Rc(Rc < 0.5) = 0;
Rc = ones(size(R));
% plot trace
plotDopTrace(tv, Dop, Dop_norm, Vstim, BFConfig, Rc);

figure(99); clf;
imagesc(BFConfig.xax * 1e3, BFConfig.zax * 1e3, R);
colorbar;
daspect([1 1 1])
caxis([0.2 0.7])

return
%% and plot
figure(44); clf;
sliceViewer(nthroot(Dop, 2), 'Colormap', hot, 'ScaleFactors', 2 * [2 1 1])

%%
bmodes = iq2bmode(IQ, 50);
figure(44); clf;
imagesc(bmodes(:, :, 1));
colormap gray
for k = 1:size(bmodes, 3)

    imagesc(bmodes(:, :, k))
    title(num2str(k))
    drawnow
end

%% Function to create visual stim signal
function s = generateVstim(t, dur_baseline, dur_block, dur_on)
% s = generateVstim(t, dur_baseline, dur_block, dur_on)
% t is time vector, dur_baseline is duration of baseline, dur_block is
% duration of block, and dur_on is duration of stimulus on within a block
%
s = zeros(size(t));
s(t < dur_baseline) = 0;
k = 0;
while k * dur_block + dur_baseline < t(end)
    s(t >= dur_baseline + k * dur_block & ...
        t < dur_baseline + dur_on + k * dur_block) = 1;
    k = k + 1;
end
end

function plotDopTrace(tv, Dop, Dop_norm, Vstim, BFConfig, Rc)

nth = 2;
roi_size = 2;
f = figure(51); clf;
f.Position = [200 200 600 700];
f.KeyReleaseFcn = @keyInput;

xax = BFConfig.xax * 1e3;
zax = BFConfig.zax * 1e3;

x = []; z = [];
xi = round(numel(xax) / 2) + (-roi_size:roi_size);
zi = round(numel(zax) / 2) + (-roi_size:roi_size);

ax(1) = subplot(3, 1, [1 2]);
s_dop = imagesc(xax, zax, nthroot(Dop(:, :, 1), nth));
hold(ax(1), 'on');
b = scatter(ax(1), xax(median(xi)), zax(median(zi)), 'g', 'filled');
lb = plot(ax(1), xax(xi([1 end end 1 1])), zax(zi([1 1 end end 1])), 'g');

daspect([1 1 1])
colormap(ax(1), hot);
set(s_dop, 'ButtonDownFcn', @setROIPos);

ax(2) = subplot(313);
lt = plot(tv, getDopTrace(), 'linewidth',1);
ylabel('fUS Signal change (%)')
ylim(ax(2), [-30 30])
yyaxis right
plot(tv, Vstim,'linewidth',2);

    function setROIPos(~, event)
        z = event.IntersectionPoint(2);
        x = event.IntersectionPoint(1);
        updatePlot();

    end
    function updatePlot()
        xi = find(x < xax, 1) + (-roi_size:roi_size);
        zi = find(z < zax, 1) + (-roi_size:roi_size);
        b.XData = xax(median(xi));
        b.YData = zax(median(zi));
        lb.XData = xax(xi([1 end end 1 1]));
        lb.YData = zax(zi([1 1 end end 1]));
        lt.YData = getDopTrace();
        s_dop.CData = nthroot(mean(Dop, 3), nth);
    end

    function trace = getDopTrace()
        trace = squeeze(mean(Dop_norm(zi, xi, :) .* Rc(zi, xi), [1 2])) * 100; % in %
    end

    function keyInput(src, event)
        req_update = 0;
        switch event.Character
            case '+'
                roi_size = roi_size + 1;
                roi_size = min(roi_size, 10);
                req_update = 1;
            case '-'
                roi_size = roi_size - 1;
                roi_size = max(roi_size, 1);
                req_update = 1;
            case 't'
                nth = nth + 1;
                req_update = 1;
            case 'r'
                nth = nth - 1;
                nth = max(nth, 1);
                req_update = 1;
            case 'a'
                [];
            otherwise
                return
        end
        if req_update
            updatePlot();
        end
    end

end

% function [signal_extracted, Mask] = extractSignal_AK(t, Dop, nDop, UF, Xscale, Yscale)
% %EXTRACTSIGNAL Summary of this function goes here
% [nz, nx, nt] = size(Dop);
% W = nthroot(mean(Dop,3),10);
% W = (W - min(W(:)))./(max(W(:))-min(W(:)));
%
% figure(101), colormap hot(512)
% imagesc(Xscale,Yscale, W);
% axis image, xlabel('[mm]'), ylabel('[mm]'), title('Vascular Anatomy')
% Mask = roipoly();
%
% figure(102)
% % imagesc(Xscale,Yscale, imoverlay(cat(3,W,W,W), Mask));
% imagesc(Xscale,Yscale, cat(3,W,W,W));
% hold all, contour(Xscale,Yscale, Mask,1, 'LineColor', 'y')
% axis image, xlabel('[mm]'), ylabel('[mm]'), title('Selected ROI')
%
% signal_extracted = nDop(repmat(Mask, [1 1 nt]));
% signal_extracted = reshape(signal_extracted, [sum(Mask(:)) nt]);
%
% signal_extracted = squeeze(mean(signal_extracted));
% figure(103), plot(t, 100*signal_extracted); xlabel('time [s]'); ylabel('% fUS signal change')
% title('fUS signal in selected ROI')
% set(gca,'FontSize',13), box off
% end

% end
