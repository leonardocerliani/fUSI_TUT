function PDI = PDIfilter(PDI, filttype)
% PDIFILTER Applies specified filters to PDI data.
%
%   PDI = PDIFILTER(PDI, filttype)
%
%   Inputs:
%       PDI      - A structure containing PDI data and associated information.
%                  PDI.PDI should have dimensions:
%                      - x * time (1D data)
%                      - x * y * time (2D data)
%                      - x * y * z * time (3D data)
%       filttype - (Optional) Type of filter to apply. Options:
%                   'detrend'  - Remove linear trend from the data (default).
%                   'highpass' - Apply a high-pass Butterworth filter.
%                   'lowpass'  - Apply a low-pass Butterworth filter.
%
%   Outputs:
%       PDI      - The input PDI structure with the filtered PDI data.
%
%   Description:
%       This function processes the PDI data by applying the specified filter
%       type. It supports detrending, high-pass filtering, and low-pass filtering.
%
%   Example:
%       filteredPDI = PDIfilter(PDI, 'highpass');

%% Input Handling

% Set default filter type to 'detrend' if not provided
if nargin < 2 || isempty(filttype)
    filttype = 'detrend';
end

%% Initialize Filtered Data

% Initialize a matrix to store filtered PDI data with the same size as original
filterPDI = zeros(size(PDI.PDI));

%% Apply Specified Filter

switch lower(filttype)
    case 'detrend'
        % -------------------------------
        % Detrend Filter
        % -------------------------------
        PDI.filter.type = 'detrend';
        PDI.filter.frequency = 0;
        PDI.filter.order = 0;
        fprintf('Applying detrend filter...\n');
        numRows = size(PDI.PDI, 1);
        for ix = 1:numRows
            % Extract the time series for the current row
            timeSeries = squeeze(PDI.PDI(ix, :, :))';

            % Detrend the time series and store it back
            filterPDI(ix, :, :) = detrend(timeSeries)';
        end

    case 'highpass'
        % -------------------------------
        % High-Pass Butterworth Filter
        % -------------------------------
        PDI.filter.type = 'high';
        PDI.filter.frequency = 0.005;
        PDI.filter.order = 3;
        fprintf('Applying high-pass Butterworth filter...\n');
        filterPDI = applyButterworthFilter(PDI, PDI.filter.type, PDI.filter.frequency,PDI.filter.order);
    case 'lowpass'
        % -------------------------------
        % Low-Pass Butterworth Filter
        % -------------------------------
        PDI.filter.type = 'low';
        PDI.filter.frequency = 2.5;
        PDI.filter.order = 3;
        fprintf('Applying low-pass Butterworth filter...\n');
        filterPDI = applyButterworthFilter(PDI, PDI.filter.type, PDI.filter.frequency,PDI.filter.order);
    otherwise
        error('Unknown filter type: %s. Available options are ''detrend'', ''highpass'', and ''lowpass''.', filttype);
end

%% Update PDI Structure

% Assign the filtered data back to the PDI structure
PDI.PDI = filterPDI;

fprintf('Filtering complete.\n');
end

function filterPDI = applyButterworthFilter(PDI, filterType, cutoffFreq,N)
% APPLYBUTTERWORTHFILTER Applies a Butterworth filter to PDI data.
%
%   filterPDI = APPLYBUTTERWORTHFILTER(PDI, filterType, cutoffFreq)
%
%   Inputs:
%       PDI        - The PDI structure containing the data to filter.
%       filterType - Type of Butterworth filter ('high' or 'low').
%       cutoffFreq - Cutoff frequency in Hz.
%
%   Outputs:
%       filterPDI  - The filtered PDI data.

% Calculate sampling parameters
TR = mean(diff(PDI.time));      % Repetition time in seconds
Fs = 1 / TR;                    % Sampling frequency in Hz

% Normalize the cutoff frequency (0 < Wn < 1)
Wn = cutoffFreq / (Fs / 2);

% Design the Butterworth filter
[b, a] = butter(N, Wn, filterType);

% Initialize the filtered data matrix
filterPDI = zeros(size(PDI.PDI));

% Determine the number of rows and columns (if applicable)
numRows = size(PDI.PDI, 1);
numCols = size(PDI.PDI, 2);

% Initialize progress tracking
strlen = 0;
totalRows = numRows;

% Loop through each spatial location and apply the filter
for ix = 1:numRows
    % Display progress
    progressStr = sprintf('Filtering progress: %d/%d', ix, totalRows);
    fprintf([repmat('\b', 1, strlen), '%s'], progressStr);
    strlen = length(progressStr);

    for iy = 1:numCols
        % Extract the time series for the current location
        timeSeries = squeeze(PDI.PDI(ix, iy, :));

        % Determine padding size based on cutoff frequency
        paddingSizeTRs = round((1 / cutoffFreq) / (2 * TR));
        prePad = repmat(timeSeries(1), paddingSizeTRs, 1);
        postPad = repmat(timeSeries(end), paddingSizeTRs, 1);
        paddedTimeSeries = [prePad; timeSeries; postPad];

        % Apply zero-phase Butterworth filter using filtfilt
        filteredPaddedTimeSeries = filtfilt(b, a, paddedTimeSeries);

        % Remove padding to retain original length
        filterPDI(ix, iy, :) = filteredPaddedTimeSeries(paddingSizeTRs + 1:end - paddingSizeTRs);
    end
end
fprintf('\n'); % Move to the next line after progress is complete
end
