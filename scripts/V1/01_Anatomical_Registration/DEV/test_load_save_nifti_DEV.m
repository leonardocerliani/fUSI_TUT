

% First let's try to read and write the same file
% and diff it and view it in itksnap to see whether anything changes

hdr1 = load_nifti('./DEV/atlas.nii');
hdr2 = hdr1;

save_nifti(hdr2, './DEV/atlas_rewritten.nii')


hdr1 = load_nifti('atlas.nii');
hdr2 = load_nifti('atlas_rewritten.nii');

fprintf('Comparing original vs rewritten NIfTI:\n');

fprintf('Volume data identical?    %d\n', isequal(hdr1.vol, hdr2.vol));
fprintf('pixdim identical?         %d\n', isequal(hdr1.pixdim, hdr2.pixdim));
fprintf('srow_x identical?         %d\n', isequal(hdr1.srow_x, hdr2.srow_x));
fprintf('srow_y identical?         %d\n', isequal(hdr1.srow_y, hdr2.srow_y));
fprintf('srow_z identical?         %d\n', isequal(hdr1.srow_z, hdr2.srow_z));
fprintf('magic identical?          %d\n', isequal(hdr1.magic, hdr2.magic));


% Note that the dim is now starting with 4 instead of 3, but it's just the
% trailing singleton dimension. In reality it's a 3D volume.

% The orientation can be accessed in the fields srow_x, srow_y, srow_z




%%
clear; clc

% Load the source header from atlas
hdr = load_nifti('atlas.nii');

% Load your anatomic data
load('anatomic_2_atlas.mat');  % contains struct "anatomic"

% Replace volume with your own
hdr.vol = anatomic_2_atlas.Data;

% Save as nifti
err = save_nifti(hdr, './DEV/anatomic_2_atlas.nii');
if err
    error('Error saving NIfTI file.');
else
    fprintf('NIfTI saved successfully: anatomic.nii\n');
end

