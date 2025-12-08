function PDI = build_pdi_structure(pdiData, pdiTime, scanParams, stimInfo, behavioral, savepath)
    % BUILD_PDI_STRUCTURE Assemble final PDI structure
    %
    %   PDI = build_pdi_structure(pdiData, pdiTime, scanParams, stimInfo, behavioral, savepath)
    
    PDI = struct();
    
    % Store dimensions
    PDI.Dim.nx = scanParams.Nx;
    PDI.Dim.nz = scanParams.Nz;
    PDI.Dim.dx = scanParams.ScaleX;
    PDI.Dim.dz = scanParams.ScaleZ;
    PDI.Dim.nt = length(pdiTime);
    PDI.Dim.dt = scanParams.dt;
    
    % Store PDI data
    PDI.PDI = pdiData;
    
    % Store timestamps
    PDI.time = pdiTime;
    
    % Store stimulation info
    if ~isempty(stimInfo)
        PDI.stimInfo = stimInfo;
    else
        PDI.stimInfo = table();
    end
    
    % Store behavioral data
    PDI.pupil.pupilTime = behavioral.pupil.pupilTime;
    PDI.wheelInfo = behavioral.wheelInfo;
    PDI.gsensorInfo = behavioral.gsensorInfo;
    
    % Store save path
    PDI.savepath = savepath;
end
