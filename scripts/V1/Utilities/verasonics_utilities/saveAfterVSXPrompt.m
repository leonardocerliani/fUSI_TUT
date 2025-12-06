% prompt save location
prompt = {'Filename:', 'Folder:'};
dlgtitle = 'Set save location';
dims = [1 90];

[~, fname] = fileparts(P.matfile_file_name);
definput = {sprintf('%s_%s', fname, datestr(now, 'yymmdd-HHMM')), fullfile(cd(), P.data_path_save)};
answer2 = inputdlg(prompt, dlgtitle, dims, definput);
if isempty(answer2)
    return; % cancel pressed
end
save_path = fullfile(answer2{2}, answer2{1});

% clear some variables that cannot be saved
clear hwEventHandler displaySettings vsxApplication vsxLogger f hwResult
Resource.DisplayWindow.figureHandle = [];
Resource.DisplayWindow.imageHandle = [];

% and save data
fprintf('Saving data...\n');
save(save_path);
fprintf('Data saved in: %s\n', save_path);

%%
% Warning: com.verasonics.vantage.events.VantageHwEventHandler@d5bb1c4 is not
% serializable
% > In saveAfterVSXPrompt (line 13)
%   In L7_4_planewave_simple (line 506)
% Warning: Variable 'hwEventHandler' was not saved. Variables of type
% 'com.verasonics.vantage.events.VantageHwEventHandler' (or one of its members) are
% not supported for this MAT-file version. Use a newer MAT-file version.
% > In saveAfterVSXPrompt (line 13)
%   In L7_4_planewave_simple (line 506)
% Warning: Figure is saved in
% C:\Users\Lab\Documents\Rick\Matlab\imaging_sequences\plane_wave_imaging\data\datatest_210312-1055.mat.
% Saving graphics handle variables can cause the creation of very large files. To
% save graphics figures, use savefig.
% > In saveAfterVSXPrompt (line 13)
%   In L7_4_planewave_simple (line 506)
