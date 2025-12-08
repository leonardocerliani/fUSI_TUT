function print_dependencies(filename, mode)
%PRINT_DEPENDENCIES Print the dependencies of a MATLAB script or function.
%
%   PRINT_DEPENDENCIES(FILENAME) prints the top-level dependencies of
%   FILENAME using matlab.codetools.requiredFilesAndProducts with 'toponly'.
%
%   PRINT_DEPENDENCIES(FILENAME, MODE) allows you to specify the mode:
%       'toponly' (default) - list only the top-level user dependencies
%       'deep'              - list all dependencies (no 'toponly' flag)
%
%   PRINT_DEPENDENCIES with no input will open a file selection dialog
%   to choose the MATLAB script or function.
%
% Example:
%   print_dependencies('myscript.m');
%   print_dependencies('myscript.m', 'deep');
%   print_dependencies();   % opens a file picker

    % ---- Print help when the script starts ----
    help(mfilename);

    % Handle missing inputs
    if nargin < 1 || isempty(filename)
        [file, path] = uigetfile('*.m', 'Select a MATLAB file');
        if isequal(file, 0)
            disp('No file selected. Exiting.');
            return;
        end
        filename = fullfile(path, file);
    end

    if nargin < 2 || isempty(mode)
        mode = 'toponly';
    end

    % Validate mode
    validModes = {'toponly', 'deep'};
    if ~ismember(lower(mode), validModes)
        error('Invalid mode. Use ''toponly'' or ''deep''.');
    end

    % Collect dependencies
    if strcmpi(mode, 'toponly')
        deps = matlab.codetools.requiredFilesAndProducts(filename, 'toponly');
    else
        deps = matlab.codetools.requiredFilesAndProducts(filename);
    end

    % Print results
    fprintf('\nDependencies for: %s\n', filename);
    fprintf('Mode: %s\n\n', mode);

    if isempty(deps)
        disp('No dependencies found.');
    else
        for i = 1:numel(deps)
            fprintf('%s\n', deps{i});
        end
    end
    fprintf('\n');
end
