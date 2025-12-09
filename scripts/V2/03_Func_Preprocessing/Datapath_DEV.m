function [subDataPath, subAnatPath, resultPath] = Datapath_DEV(cond)
    % Simplified Datapath for VisualTest and ShockTest (first 2 lines only)
    
    root_1 = '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/fUSIMethodsPaper/Data_analysis';

    switch cond
        case 'VisualTest'
            subDataPath = {
                fullfile(root_1, 'sub-methods02/ses-231215/run-115047/')
            };
            subAnatPath = {
                fullfile(root_1, 'sub-methods02/ses-231215/run-113409/')
            };
            resultPath = fullfile(root_1, 'sub-Group', cond, 'Functional');

        case 'ShockTest'
            subDataPath = {
                fullfile(root_1, 'sub-methods02/ses-240103/run-142553/'),
                fullfile(root_1, 'sub-methods01/ses-240104/run-155221/')
            };
            subAnatPath = {
                fullfile(root_1, 'sub-methods02/ses-240103/run-140517/'),
                fullfile(root_1, 'sub-methods01/ses-240104/run-151641/')
            };
            resultPath = fullfile(root_1, 'sub-Group', cond, 'Functional');

        otherwise
            error('Unknown condition: %s', cond);
    end
end
