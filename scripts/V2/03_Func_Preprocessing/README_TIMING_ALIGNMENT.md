# Timing Alignment for fUSI Data

## Problem

After preprocessing fUSI data, you have:
- **PDI frames**: 3,652 brain images (resampled to 5 Hz)
- **Wheel data**: 40,541 timestamps with wheel speed values
- **Stimulus data**: 10 stimulus events with start/end times

**Question**: How do I know which frame corresponds to which stimulus and wheel speed?

## Solution

Use the `align_timing_to_frames.m` function to create **frame-aligned vectors** where each frame has one corresponding value for both wheel speed and stimulus state.

### Input
- `prepPDI.mat` with mismatched timing arrays

### Output
- `wheelspeed_resampled`: [3652 × 1] - one wheel speed per frame
- `stim_boxcar`: [3652 × 1] - binary vector (1 = stimulus ON, 0 = OFF)

## How It Works

### 1. Wheel Speed Alignment
Uses **linear interpolation** (`interp1`) to resample the high-frequency wheel sensor data (40,541 samples) onto the PDI frame times (3,652 frames):

```matlab
wheelspeed_resampled = interp1(PDI.wheelInfo.time, ...
                               PDI.wheelInfo.wheelspeed, ...
                               PDI.time, 'linear');
```

This gives you the estimated wheel speed at each frame acquisition time.

### 2. Stimulus Alignment
Creates a **binary boxcar** where frames during stimulus presentation are marked as 1:

```matlab
stim_boxcar = zeros(nFrames, 1);
for i = 1:nStimuli
    frames_during_stim = (PDI.time >= stim_start(i)) & (PDI.time <= stim_end(i));
    stim_boxcar(frames_during_stim) = 1;
end
```

## Usage

### Basic Usage

```matlab
% Interactive mode - prompts for file selection
[wheel, stim] = align_timing_to_frames();

% Or provide path directly
[wheel, stim] = align_timing_to_frames('/path/to/prepPDI.mat');
```

### Analysis Examples

```matlab
% Get aligned vectors
[wheel, stim] = align_timing_to_frames('/path/to/prepPDI.mat');

% Load the data to access additional fields
loaded = load('/path/to/prepPDI.mat');
PDI = loaded.data;  % prepPDI.mat saves as 'data' variable

% Now frame i has:
% - Time: PDI.time(i)
% - Brain data: PDI.PDI(:,:,i)
% - Wheel speed: wheel(i)
% - Stimulus state: stim(i)

% Extract brain data during stimulus
brain_during_stim = PDI.PDI(:, :, stim == 1);

% Find stimulus onset frames
stim_onsets = find(diff([0; stim]) == 1);

% Frames with both stimulus and movement
moving_during_stim = (wheel > threshold) & (stim == 1);
```

## Key Concepts

### Frame Time as Master Reference
After preprocessing, `PDI.time` is the **master timing reference** (uniformly sampled at 5 Hz). All other timing information (wheel, stimulus) gets aligned to these frame times.

### Why This Matches fMRI Analysis
In fMRI:
- Each TR (volume) has one time point
- Behavioral data gets resampled to match TR times
- Stimulus onsets are converted to volume indices

In fUSI with this solution:
- Each frame has one time point → `PDI.time`
- Wheel data gets resampled to match frame times → `wheel`
- Stimulus timing is converted to frame indices → `stim`

## Files

- **`align_timing_to_frames.m`**: Main function for creating aligned vectors
- **`example_align_timing.m`**: Examples and analysis templates
- **`README_TIMING_ALIGNMENT.md`**: This documentation

## Technical Notes

### Linear Interpolation
The wheel speed is interpolated linearly between sensor samples. This assumes wheel speed changes smoothly between measurements, which is reasonable given the high sampling rate (40,541 samples over ~730 seconds ≈ 55 Hz).

### Absolute Value for Wheel Speed
The function automatically takes the absolute value of wheel speed. Negative values in the raw data simply indicate reversed rotation direction, but for most analyses you want the magnitude of wheel movement regardless of direction.

### Stimulus Boxcar
The binary boxcar indicates whether a stimulus is ON at each frame. For more sophisticated analyses, you might want:
- Multiple boxcars for different stimulus types
- Convolution with hemodynamic response function
- Time-since-stimulus-onset vectors

### Edge Effects
If PDI.time extends beyond wheelInfo.time, some interpolated values may be NaN. The function automatically fills these with nearest neighbor values.

## See Also

- `do_preprocessing.m`: Main preprocessing pipeline
- `resamplePDI.m`: Function that resamples PDI data to 5 Hz
- `interp1`: MATLAB's interpolation function
