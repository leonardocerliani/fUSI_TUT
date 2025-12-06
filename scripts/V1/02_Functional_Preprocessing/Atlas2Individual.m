function subAtlas = Atlas2Individual(atlas,anatomic,Transf,dispFieldA2I)

if nargin < 4
    dispFieldA2I = [];
end

% linear transformation
anatomicInterp = interpolate3D(atlas,anatomic); %atlas is adjusted so that it matches the anatomic
T = affine3d(Transf.M); %creates a tool for the spatial adjustment. Transf.M is a matrix that specifies how the image should be changed
ref = imref3d(size(anatomicInterp.Data)); % helps the computer to understand how the voxels are arranged

atlasRegionAffineTransformed=imwarp(atlas.Regions,T.invert,'nearest','OutputView',ref);
atlasHistologyAffineTransformed=imwarp(atlas.Histology,T.invert,'nearest','OutputView',ref);

% non linear deformation
if isempty(dispFieldA2I)
    anatomicInterp.Data = atlasRegionAffineTransformed;
    subAtlas.Region = interpolate3D(anatomic,anatomicInterp,'nearest');
    anatomicInterp.Data = atlasHistologyAffineTransformed;
    subAtlas.Histology = interpolate3D(anatomic,anatomicInterp,'nearest');
else
    regionInterp = imwarp(atlasRegionAffineTransformed,dispFieldA2I,'nearest');
    anatomicInterp.Data = regionInterp;
    subAtlas.Region = interpolate3D(anatomic,anatomicInterp,'nearest');
    regionInterp = imwarp(atlasHistologyAffineTransformed,dispFieldA2I,'nearest');
    anatomicInterp.Data = regionInterp;
    subAtlas.Histology = interpolate3D(anatomic,anatomicInterp,'nearest');
end

end