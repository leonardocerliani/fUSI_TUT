



% select the initial plane to plot.
planeChoice.sag = 6.95; % in mm
planeChoice.tra = 5.35;
planeChoice.cor = 13.0;

save_settings = struct( ...
    'save_immediate', true, ... % save figure immediately after plotting to specified output folder with specified name
    'folder', output_fig_path, ... % output folder
    'filename', 'temp', ... % filename
    'cor', true, ... % 1 if need to save coronal image
    'sag', true, ... % 1 if need to save sagittal image
    'tra', true, ... % 1 if need to save transversal image
    'overview', true); % 1 if save overview image wihth all view

% atlas, atlas loaded from Brunner, with vascular, histology, regions and
% borders
    
% mapRegistered = 3d correlation map after registration:
%   mapRegistered = registerData(atlas, correlationmap, Transf);

% interactive plot that allows clicking in different directions
fig = interactive_plane_selection_atlas(atlas, mapRegistered, planeChoice, save_settings);
