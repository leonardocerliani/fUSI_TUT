function PDI = RAW_2_MAT(datapath,savepath)
% RAWDATA2MATNEW Converts raw functional and structural ultrasound imaging data to MAT format.
%
%   PDI = RAW_2_MAT(datapath,savepath)
%
%   Inputs:
%       datapath - (Optional) Path to the raw data directory. If not provided,
%                  a directory selection dialog will appear.
%       savepath - (Optional) Path to save the processed MAT file. If not provided,
%                  it will be generated based on the datapath.
%
%   Outputs:
%       PDI - A structure containing processed PDI data and related information.
%
%   Description:
%       This function reads raw ultrasound imaging data, scan parameters,
%       TTL timing information, and various stimulation event data. It
%       processes and aligns the data, then saves the results in a MAT file.
%
%   Dependencies:
%       - LagAnalysisFusi (function for lag analysis)
%
%   Example:
%       PDI = Rawdata2MATnew('/path/to/datapath', '/path/to/savepath');


% Input Handling and Path Setup

% Select data directory if not provided
if nargin < 1 || isempty(datapath)
    datapath = uigetdir('Please select the functional scan to analyze.');
    if datapath == 0
        error('Data path selection canceled by user.');
    end
end

% Generate save path if not provided
if nargin < 2 || isempty(savepath)
    tmpInd1 = strfind(datapath, 'Data_collection');
    if isempty(tmpInd1)
        error('The datapath does not contain ''Data_collection''.');
    end
    tmpInd2 = tmpInd1 + length('Data_collection');
    savepath = fullfile(datapath(1:tmpInd1-1), 'Data_analysis', datapath(tmpInd2:end));
end




% %% ONLY FOR MANUAL CELL EVALUATION
% 
% % Select data directory if not provided
% if ~exist('datapath','var') || isempty(datapath)
%     datapath = uigetdir('.', 'Select the run directory.');
%     if datapath == 0
%         error('Data path selection canceled by user.');
%     end
% end
% 
% % Generate save path if not provided
% if ~exist('savepath','var') || isempty(savepath)
%     tmpInd1 = strfind(datapath, 'Data_collection');
%     if isempty(tmpInd1)
%         error('The datapath does not contain ''Data_collection''.');
%     end
%     tmpInd2 = tmpInd1 + length('Data_collection');
%     savepath = fullfile(datapath(1:tmpInd1-1), 'Data_analysis', datapath(tmpInd2:end));
% end




%% Locate FUSI Data Directory

D = dir(fullfile(datapath, 'FUSI_data*'));
if isempty(D)
    error('No FUSI_data* directory found in the specified datapath.');
end
fusDatapath = fullfile(D(1).folder, D(1).name);


    
%% Load scan parameters
scanParamFiles = {'post_L22-14_PlaneWave_FUSI_data.mat', ...
                  'L22-14_PlaneWave_FUSI_data.mat'};
BFConfig = [];

for i = 1:length(scanParamFiles)
    scanParamPath = fullfile(fusDatapath, scanParamFiles{i});
    if exist(scanParamPath, 'file')
        fprintf('Loading scan parameters from %s.\n', scanParamFiles{i});
        S = load(scanParamPath, 'BFConfig');
        BFConfig = S.BFConfig;
        break;
    end
end

if isempty(BFConfig)
    error('No scan parameter file found. Please check the fusDatapath.');
end


%% Read Raw PDI Data
pdiFile = fullfile(fusDatapath, 'fUS_block_PDI_float.bin');

if exist(pdiFile, 'file')
    fprintf('Loading PDI data from %s.\n', 'fUS_block_PDI_float.bin');
    fid = fopen(pdiFile, 'r');
    rawPDI = fread(fid, inf, 'single');
    fclose(fid);
else
    error('No PDI data found. Please convert IQ data to PDI first.');
end


%% Read TTL Timing Information

ttlFiles = dir(fullfile(datapath, 'TTL*.csv'));

if ~isempty(ttlFiles)
    fprintf('Loading TTL data from %s.\n', ttlFiles(1).name);
    TTLinfo = readmatrix(fullfile(ttlFiles(1).folder, ttlFiles(1).name));
else
    error('No TTL recording found. Please check the datapath.');
end

% plot the TTLinfo
fun_plot.plotTTL(TTLinfo)


%% Read NIDAQ Logfile

nidaqFiles = {'NIDAQ.csv', 'DAQ.csv'};

NIDAQInfo = [];

for i = 1:length(nidaqFiles)
    nidaqPath = fullfile(datapath, nidaqFiles{i});
    if exist(nidaqPath, 'file')
        fprintf('Loading NIDAQ logfile from %s.\n', nidaqFiles{i});
        NIDAQInfo = readtable(nidaqPath);
        break;
    end
end

if isempty(NIDAQInfo)
    error('No NIDAQ logfile found. Please check the datapath.');
end


%% Initialize PDI Structure

PDI = struct;
PDI.Dim.nx = BFConfig.Nx;
PDI.Dim.nz = BFConfig.Nz;
PDI.Dim.dx = BFConfig.ScaleX;
PDI.Dim.dz = BFConfig.ScaleZ;
PDI.Dim.nt = numel(rawPDI) / (BFConfig.Nx * BFConfig.Nz);

% Reshape raw PDI data into [nz, nx, nt]
pdi = reshape(rawPDI, [PDI.Dim.nz, PDI.Dim.nx, PDI.Dim.nt]);
clear rawPDI;

% % Show movie
% fun_plot.pdi_movie(PDI, pdi)


%% Realign Events Using TTL Information

PDITTL = find(diff(TTLinfo(:,3)) < 0);
numPDITTL = numel(PDITTL);
numPDIframes = size(pdi, 3);

if numPDITTL < numPDIframes
    pdi(:, :, numPDITTL+1:end) = [];    % too many frames → cut off extras
elseif numPDITTL > numPDIframes
    PDITTL(numPDIframes+1:end) = [];    % too many events → cut off extras
end




%% Correct for Lagged PDI and Interpolate

try
    [T_pdi_intended, timeTagsSec] = LagAnalysisFusi(fusDatapath);

    frameInterval = mode(diff(timeTagsSec));
    blockDuration = ceil(1 / frameInterval);
    acceptIndex = true(size(timeTagsSec));

    % Validate block intervals
    for it = 1:numel(timeTagsSec)-blockDuration
        rangeInterval = range(diff(timeTagsSec(it:it+blockDuration)));
        if rangeInterval > 0.01
            acceptIndex(it) = false;
        end
    end
    for it = numel(timeTagsSec)-blockDuration:numel(timeTagsSec)
        rangeInterval = range(diff(timeTagsSec(it-blockDuration:it)));
        if rangeInterval > 0.01
            acceptIndex(it) = false;
        end
    end

    PDItime = TTLinfo(PDITTL(1), 1) + timeTagsSec(acceptIndex);
    pdi = pdi(:, :, acceptIndex);
catch
    % If no IQ data exists
    PDItime = TTLinfo(PDITTL, 1);
    blockDuration = mode(diff(PDItime));
end


%%  Adjust PDItime
%   Align PDI timestamps with TTL acquisition and clean data

% Shift PDItime forward by the mean frame interval
% This accounts for the fact that the TTL mark indicates the start of acquisition
PDItime = PDItime + mean(diff(PDItime));

% Find the first rising edge in TTL channel 6 (AdjustPDItime)
% diff > 0 detects transitions from 0 → 1
% initTTL = find(diff(TTLinfo(:,6)) > 0); % returns many, causes the following to break
initTTL = find(diff(TTLinfo(:,6)) > 0, 1, 'first');  % first rising edge only÷

% If channel 6 has no rising edge, try channel 5 (ShockTailStim)
if isempty(initTTL)
    initTTL = find(diff(TTLinfo(:,5)) > 0);
end

% Remove all TTL entries before the first acquisition event
TTLinfo(1:initTTL-1, :) = [];

% Shift PDItime and TTLinfo(:,1) so that the first acquisition starts at time 0
PDItime = PDItime - TTLinfo(1,1);
TTLinfo(:,1) = TTLinfo(:,1) - TTLinfo(1,1);

% Identify PDI frames that occur at non-negative times
validFrames = PDItime >= 0;

% Remove frames with negative time from PDI data and timestamps
pdi(:, :, ~validFrames) = [];
PDItime(~validFrames) = [];

% Store the cleaned timestamps and frame interval in the PDI structure
PDI.time = PDItime;       % aligned frame times
PDI.Dim.dt = blockDuration; % average frame interval



%% -------------- Read experiment event information -------------


%% -------------- Shock stimulation -----------------------------
% Check if shock stimulation file exists in the data folder
if exist([datapath filesep 'ShockStimulation.csv'],'file')
    fprintf('Shock stimulation found. \n')

    % Read stimulation metadata (type of shock: tail/left/right)
    stimInfo = readtable([datapath filesep 'ShockStimulation.csv']);

    % ---- Case 1: Tail stimulation ----
    if strcmp(stimInfo.type{2},'tail')

        % Extract start times: falling edges (<0) in TTL channel 5
        % (ShockTailStim) or 12 (Shock)
        startTime = TTLinfo(diff(TTLinfo(:,5))<0 | diff(TTLinfo(:,12))<0,1);

        % Extract end times: rising edges (>0) in TTL channel 5
        % (ShockTailStim) or 12 (Shock)
        endTime   = TTLinfo(diff(TTLinfo(:,5))>0 | diff(TTLinfo(:,12))>0,1);

        % Remove very short events (<0.1s duration)
        ind2rem = endTime - startTime < 0.1;
        startTime(startTime < 0.1 | ind2rem) = [];
        endTime(endTime < 0.1   | ind2rem)   = [];

        % Load shock intensity + behavioral ratings (Excel file)
        shockInfo = readtable([datapath filesep 'shockIntensities_and_perceivedSqueaks.xlsx']);

        % Build stimInfo table:
        %   - stimCond: condition (tail shock)
        %   - startTime, endTime: from TTL detection
        %   - other columns: shock intensity and squeak ratings
        PDI.stimInfo = addvars(shockInfo, stimInfo.type(2:end), ...
                               'Before',1,'NewVariableNames','stimCond');
        PDI.stimInfo = addvars(PDI.stimInfo, startTime, ...
                               'Before',2,'NewVariableNames','startTime');
        PDI.stimInfo = addvars(PDI.stimInfo, endTime, ...
                               'Before',3,'NewVariableNames','endTime');

        % Rename condition label
        PDI.stimInfo.stimCond = strrep(PDI.stimInfo.stimCond,'tail','shock_tail');

    % ---- Case 2: Left/Right shocks ----
    else
        % Extract start/end times from TTL channel 4 or 12
        PDI.stimInfo.startTime = TTLinfo(diff(TTLinfo(:,4))<0 | diff(TTLinfo(:,12))<0, 1);
        PDI.stimInfo.endTime   = TTLinfo(diff(TTLinfo(:,4))>0 | diff(TTLinfo(:,12))>0, 1);

        % Copy stimulation type directly
        PDI.stimInfo.stimCond = stimInfo.type;

        % Standardize condition labels:
        %   "left"  → "shockOBS" (observed shock)
        %   "right" → "shockCTL" (control shock)
        PDI.stimInfo.stimCond = strrep(PDI.stimInfo.stimCond,'left','shockOBS');
        PDI.stimInfo.stimCond = strrep(PDI.stimInfo.stimCond,'right','shockCTL');
    end
end



%% -------------- Visual stimulation -----------------------------
% Check if visual stimulation file exists
if exist([datapath filesep 'VisualStimulation.csv'],'file')
    fprintf('Visual stimulation found. \n')

    % Read metadata about visual stimulation
    stimInfo = readtable([datapath filesep 'VisualStimulation.csv']);

    % Detect start and end times of visual stimuli:
    %   - start = rising edge in TTL channel 10 (diff > 0)
    %   - end   = falling edge in TTL channel 10 (diff < 0)
    PDI.stimInfo.startTime = TTLinfo(diff(TTLinfo(:,10))>0, 1);
    PDI.stimInfo.endTime   = TTLinfo(diff(TTLinfo(:,10))<0, 1);

    % Compute stimulus duration
    stimDuration = PDI.stimInfo.endTime - PDI.stimInfo.startTime;

    % Remove very short flashes (< 0.01 s), likely noise
    PDI.stimInfo.startTime(stimDuration < 0.01) = [];
    PDI.stimInfo.endTime(stimDuration < 0.01)   = [];

    % Assign condition label "visual" to each stimulus
    PDI.stimInfo.stimCond = repmat({'visual'}, numel(PDI.stimInfo.startTime), 1);

    % ---- Fallback case ----
    % If no TTL-based times are found, fall back to metadata file
    if isempty(PDI.stimInfo.startTime)
        % Adjust stimInfo times relative to start of NIDAQ recording
        stimInfo.time = stimInfo.time - NIDAQInfo.Var1(1);

        % Get start/end times directly from stimInfo table
        PDI.stimInfo.startTime = stimInfo.time(strcmp('stim', stimInfo.stim));
        PDI.stimInfo.endTime   = stimInfo.time(strcmp('black', stimInfo.stim));

        % Label as "visual" condition
        PDI.stimInfo.stimCond = repmat({'visual'}, numel(PDI.stimInfo.startTime), 1);
    end
end





%% -------------- Auditory stimulation -----------------------------
% Check if auditory stimulation file exists
if exist([datapath filesep 'auditoryStimulation.csv'],'file')
    fprintf('Auditory stimulation found. \n')

    % Read metadata about auditory stimulation
    stimInfo = readtable([datapath filesep 'auditoryStimulation.csv']);

    % Detect start and end times of auditory stimuli:
    %   - start = rising edge in TTL channel 11 (diff > 0)
    %   - end   = falling edge in TTL channel 11 (diff < 0)
    PDI.stimInfo.startTime = TTLinfo(diff(TTLinfo(:,11)) > 0, 1);
    PDI.stimInfo.endTime   = TTLinfo(diff(TTLinfo(:,11)) < 0, 1);

    % Assign condition label "CS" (conditioned stimulus) to each stimulus
    PDI.stimInfo.stimCond = repmat({'CS'}, numel(PDI.stimInfo.startTime), 1);

    % ---- Fallback case ----
    % If no TTL-based times are found, fall back to metadata file
    if isempty(PDI.stimInfo.startTime)
        % Adjust stimInfo times relative to start of NIDAQ recording
        stimInfo.time = stimInfo.time - NIDAQInfo.Var1(1);

        % Get start/end times directly from stimInfo table
        PDI.stimInfo.startTime = stimInfo.time(strcmp('audio_start', stimInfo.stim));
        PDI.stimInfo.endTime   = stimInfo.time(strcmp('audio_stop', stimInfo.stim));

        % Label as "CS"
        PDI.stimInfo.stimCond = repmat({'CS'}, numel(PDI.stimInfo.startTime), 1);
    end
end




%% -------------- Flir camera data (pupil) -----------------------------
if exist([datapath filesep 'flir_camera_time.csv'],'file')
    fprintf('Loading pupil camera timestamp. \n')
    pupilCamTime = readmatrix([datapath filesep 'flir_camera_time.csv']);
else
    pupilCamTime = [];
    warning('No video timestamp of flir_camera found!')
end




%% -------------- Wheel data (running speed) -----------------------------
if exist([datapath filesep 'WheelEncoder.csv'],'file')
    fprintf('Running wheel data found. \n')
    wheelInfo = readtable([datapath filesep 'WheelEncoder.csv']);
    wheelInfo.time = wheelInfo.time - NIDAQInfo.Var1(1);
else
    wheelInfo = [];
    warning('No running wheel data found!')
end


%% -------------- gsensor data (headplate motion) -----------------------------
if exist([datapath filesep 'GSensor.csv'],'file')
    fprintf('G sensor data found. \n')
    gsensorInfo = readtable([datapath filesep 'GSensor.csv']);
    gsensorInfo.time = gsensorInfo.time - NIDAQInfo.time(1);
    gsensorInfo.samplenum = [];
else
    gsensorInfo = [];
    warning('No gsensor data found!')
end




%% ---------------- Assign Data to PDI Structure ---------------------

PDI.PDI = pdi;
PDI.pupil.pupilTime = pupilCamTime;
PDI.wheelInfo = wheelInfo;
PDI.gsensorInfo = gsensorInfo;
PDI.savepath = savepath;


%% Save PDI Structure

% Ensure the save directory exists
if ~exist(savepath, 'dir')
    mkdir(savepath);
end

% Save the PDI structure
matFilePath = fullfile(savepath, 'PDI.mat');
save(matFilePath, 'PDI');
fprintf('Data is saved to: %s\n', matFilePath);

% Uncomment below to save in MATLAB v7 format for compatibility with scipy.io.loadmat
% save(fullfile(savepath, 'pyPDI.mat'), '-struct', 'PDI', '-v7');



% end of function
end