
datafolder = uigetdir(['\\vs03\VS03-SBL-4\fUSI'], 'Please select data folder containing videos.');

% search for all avi files in the folder and subfolders
[folder,file,list] = findfolderfile(datafolder,'avi');

% read camera data

for ifile = 1:size(file,1)
    
    filepath = file{ifile,1};
    filename = file{ifile,2};
    
    % skip marked video
    if strncmp(filename,'x-',2)
        continue
    end
    
    try
        % read video data
        disp(['Checking: ' filepath filesep filename])
        camData = VideoReader([filepath filesep filename]);
        
        % read video logfile
        camLog = importdata([filepath filesep 'camera_log_' filename(1:end-3) 'txt']);
        
        % read video TTL
        
        TTLfile = dir([filepath filesep 'TTL*']);
        TTLdata = readmatrix([TTLfile.folder filesep TTLfile.name]);
        
        allcamTTL = find(diff(TTLdata(:,8))==1);
        allcamTime = TTLdata(allcamTTL,1);
        startTimeCam = TTLdata(allcamTTL(1),1);
        
        NIDAQinfo = importdata([TTLfile.folder filesep 'NIDAQ.csv']);
        initTimeStamp = str2num(NIDAQinfo{2}(1:17));
        
        Cstart = textscan(camLog{2}, '%f %c');
        Cclose = textscan(camLog{3}, '%f %c');
        camStartTime = startTimeCam + Cstart{1} - initTimeStamp;
        camCloseTime = startTimeCam + Cclose{1} - initTimeStamp;
        
        camTime = allcamTime(allcamTime>= camStartTime & allcamTime<= camCloseTime);
        
        ['Num frames:' num2str(camData.NumFrames) ', Num TTLs:' num2str(numel(camTime))];
        
        if abs(camData.NumFrames-numel(camTime)) > 24
            fprintf('Number of frames lost larger than 24, video file will be marked with x- \n')
            movefile([filepath filesep filename],[filepath filesep 'x-' filename],'f');
        elseif camData.NumFrames > numel(camTime)
            extraTimeInd = find(allcamTime>max(camTime),camData.NumFrames-numel(camTime));
            camTime = cat(1,camTime,allcamTime(extraTimeInd));
            camTime = camTime - startTimeCam;
            dlmwrite([filepath filesep filename(1:end-4) '_time.csv'],camTime,'delimiter',',','precision','%.3f')
        elseif camData.NumFrames <= numel(camTime)
            camTime = camTime(1:camData.NumFrames);
            camTime = camTime - startTimeCam;
            dlmwrite([filepath filesep filename(1:end-4) '_time.csv'],camTime,'delimiter',',','precision','%.3f')
        end
        
    catch ME
        warning(ME.message)
    end
end

fprintf('Video frames check is done! \n')