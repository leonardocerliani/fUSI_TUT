function save_pdi_data(PDI, savepath)
    % SAVE_PDI_DATA Save PDI structure to MAT file
    %
    %   save_pdi_data(PDI, savepath)
    
    % Ensure the save directory exists
    if ~exist(savepath, 'dir')
        mkdir(savepath);
    end
    
    % Save the PDI structure
    matFilePath = fullfile(savepath, 'PDI.mat');
    save(matFilePath, 'PDI');
    
    fprintf('\n→ Processing complete!\n');
    fprintf('  Output saved: %s\n', matFilePath);
end
