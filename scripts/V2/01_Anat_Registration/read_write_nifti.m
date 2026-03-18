%% add fsl matlab utils to the path

addpath(genpath("/Applications/fsl/etc/matlab"))


%% 

root="/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-113409-anat";

[img, dims,scales,bpp,endian] = read_avw(strcat(root,'/','pippo.nii'));

length(unique(img))