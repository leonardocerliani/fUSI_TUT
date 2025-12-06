# Functional Preprocessing



**_in development_**



## `Preprocessing_DEV.m`

`Preprocessing/Preprocessing.m`

DEPENDENCIES:

```
Datapath.m
Preprocessing/DCThighpass.m
Preprocessing/PDIfilter.m
Preprocessing/fillmissingTime.m
Preprocessing/resamplePDI.m
Registration/Atlas2Individual.m
Registration/allen_brain_atlas.mat
```


Required arguments from command line:
The script runs `DataPath` with a given experimental protocol, e.g. `VisualTest`, therefore this should be passed. Not implemented yet

**NB** the original version of this script is is suitable for parallel processing with the `parfor` on the variable `isub`

```
for isub = 1:numel(subDataPath)
```
However I still didn't implement / test this yet



## Questions about the Preprocessing.m script

### re-setting the savepath
The code below first loads the PDI in a tmp variable, and then modifies the savepath with SubDataPath. It seems unnecessary since Datapath.m already generates and writes in the PDI.mat the savepath. The only difference is the trailing slash (/) at the end
```matlab
% load functional scan
tmp = load([subDataPath{isub} filesep 'PDI.mat']);
n = fieldnames(tmp);
PDI = tmp.(n{1});
PDI.savepath = subDataPath{isub};
```



### removing `nearest` from `Atlas2Individual.m`

```matlab
subAtlas=Atlas2Individual(atlas,anatomic,Transf);
```

`Atlas2Individual` calls `interpolate3d.m` from Brunner with calls like 

```matlab
subAtlas.Region = interpolate3D(anatomic,anatomicInterp,'nearest');
```

This code breaks because `interpolate3d.m` accepts only two arguments, and already implements nearest neighbour interpolation, so I had to remove the `'nearest'`



### different dimensions in the funcSlice and in the anatomic and atlasSub

When we select the slice in the Allen atlas - using `SelectAnatomicSlice.m` - the value stored in the `anatomic.funcSlice` is a vector of three numbers, in which the slice number is the last, e.g. `[79,45,14]`.

In the preprocessing script we first bring the atlas in the subject space (`subAtlas`) and then select the nonzero voxels in the `subAtlas.Region.Data` to create a binary mask of the voxels we want to retain for the functional analysis

```matlab
subAtlas=Atlas2Individual(atlas,anatomic,Transf);
subRegions = subAtlas.Region.Data(:,:,anatomic.funcSlice(3));
```

Although the first two numbers (79x45 in the example) - likely corresponding to the X and Z dimensions - are not used, I noticed that they are exactly half of the size of the `anatomic.Data` and `subAtlas.Data` (158x90).
I was wondering why.


### saving the prepPDI.mat in a subfoler `Functional`

```
parsave([subDataPath{isub} filesep 'Functional' filesep 'prepPDI.mat'],PDI);
```
why so?


### second type of preprocessing
In the script there is a second type of preprocessing after the first one, with many commented lines. 
- What is it? 
- Is it necessary to run it? 
- it loads a file `LTPDI.mat`. How is this created and when?





## Stages

### Build a mask of the slice from the Allen atlas

### Motion correction

### Voxelwise outlier rejection

### Convert to % signal change

### Resample to 5 Hz

### Highpass filtering

### Spatial smoothing

