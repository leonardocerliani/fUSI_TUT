function makeFuncSliceNii(PDI,anatomic)

if isfield(PDI,'anatSlice')
    ss = PDI.anatSlice(3);
elseif isfield(anatomic,'funcSlice')
    ss = anatomic.funcSlice(3);
else
    error('No matching between functional and anatomic scan was found, please check.')
end

fprintf('Generating registered slice file... \n')
load('allen_brain_atlas.mat')
load([anatomic.savepath filesep 'Transformation'])

c.Data=zeros(size(anatomic.Data));
c.Data(:,:,ss) = 1;
c.VoxelSize=anatomic.VoxelSize;
c.Type=anatomic.Type;
c.Direction=anatomic.Direction;
tmptmap=registerData(atlas, c, Transf);
tmapAtlas = tmptmap;

atlasnii = load_nifti('atlas.nii');

atlasnii.vol = tmapAtlas;

save_nifti(atlasnii,[PDI.savepath filesep 'FuncSlice' num2str(ss) '.nii']);
path2write = strrep(PDI.savepath,'\','\\');
fprintf(['Nifti file for functional slice is generated at: \n ' path2write '\\FuncSlice' num2str(ss) '.nii \n'])


end