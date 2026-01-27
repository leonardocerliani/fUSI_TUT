function behavioral = detect_and_load_behavioral(datapath, nidaqLog)
    % DETECT_AND_LOAD_BEHAVIORAL Auto-detect and load behavioral data
    %
    %   behavioral = detect_and_load_behavioral(datapath, nidaqLog)
    
    behavioral = struct();
    
    % Running wheel
    wheelFile = fullfile(datapath, 'RunningWheel.csv');
    if exist(wheelFile, 'file')
        wheelInfo = readtable(wheelFile);
        wheelInfo.time = wheelInfo.time - nidaqLog.time(1);
        behavioral.wheelInfo = wheelInfo;
        
        fprintf('  ✓ Running wheel: RunningWheel.csv\n');
        fprintf('    → %d time points, speed range: %.1f-%.1f cm/s\n', ...
            height(wheelInfo), min(wheelInfo.wheelspeed), max(wheelInfo.wheelspeed));
    else
        behavioral.wheelInfo = [];
        fprintf('  ✗ Running wheel: Not found\n');
    end
    
    % G-sensor
    gsensorFile = fullfile(datapath, 'GSensor.csv');
    if exist(gsensorFile, 'file')
        gsensorInfo = readtable(gsensorFile);
        gsensorInfo.time = gsensorInfo.time - nidaqLog.time(1);
        if ismember('samplenum', gsensorInfo.Properties.VariableNames)
            gsensorInfo.samplenum = [];
        end
        behavioral.gsensorInfo = gsensorInfo;
        
        fprintf('  ✓ G-sensor: GSensor.csv\n');
        fprintf('    → %d time points, 3-axis acceleration\n', height(gsensorInfo));
    else
        behavioral.gsensorInfo = [];
        fprintf('  ✗ G-sensor: Not found\n');
    end
    
    % Pupil camera
    pupilFile = fullfile(datapath, 'flir_camera_time.csv');
    if exist(pupilFile, 'file')
        pupilTime = readmatrix(pupilFile);
        pupilTime = pupilTime - nidaqLog.time(1);
        behavioral.pupil.pupilTime = pupilTime;
        
        fprintf('  ✓ Pupil camera: flir_camera_time.csv\n');
        fprintf('    → %d time points\n', length(pupilTime));
    else
        behavioral.pupil.pupilTime = [];
        fprintf('  ✗ Pupil camera: Not found\n');
    end
end
