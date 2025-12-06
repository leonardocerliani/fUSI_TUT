### Data on Storm

several locations, e.g. `/data08/fUSI/fUSI-Analysis`, `/data06/fUSIMethodsPaper/`
### Local folder

`/Users/leonardo/Dropbox/fUSI`



### Scripts

- [github repo](https://github.com/Herseninstituut/fUSI-Analysis/tree/master/AnalysisFcn) maintained by Chaoyi
- additional scripts in `/data08/fUSI/fUSI-Analysis` and `/data08/fUSI/fUSIexperiment`

### Folder structure
The input files *must* be in a folder called `Data_collection` which has subfolders for sessions. The sessions have subfolders for runs. 

The corresponding output `anatomic.mat` or `pdi.mat` (the latter for functional scans) will be automatically created together in a folder `Data_analysis/sub-[number]/ses-[number]/run-[number]` together with all the necessary directory tree (like for `mkdir -p`).

For instance:

```
Data_collection/
└── sub-methods02
    └── ses-231215
        ├── run-113409
        │   ├── FUSI_data
        │   ├── MotorScan.csv
        │   ├── NIDAQ.csv
        │   ├── TTL20231215T113402.csv
        │   └── gui_settings.json
        └── run-115047
            ├── DAQ.csv
            ├── FUSI_data
            ├── GSensor.csv
            ├── RunningWheel.csv
            ├── TTL20231215T115044.csv
            ├── VisualStimulation.csv
            └── settings.json
```

Each run must have as a minimum requirement the `TTL*.csv` file and a folder `FUSI_data` containing the following files
```
├── FUSI_data
    ├── L22-14_PlaneWave_FUSI_data.mat
    ├── fUS_block_PDI_float.bin
    └── post_L22-14_PlaneWave_FUSI_data.mat
```



## Matlab stuff

### Dependencies in scripts

- use `print_dependencies('myScript.m')` to get a list of the scripts that needs to be in the path for that script to run. Before that, it is advisable to run an `addpath(genpath('.'))` in the root directory.
- to know in which script a certain script is used (reverse dependency), run the following in bash: `grep -iRl 'myScript' [root];`

### Matlab from x2goclient
I encountered an issue running Matlab from x2goclient, but also found the fix:
- Screen turns black -> Apply the first solution mentioned [here](https://nl.mathworks.com/matlabcentral/answers/1622355-matlab-gui-displays-black-with-xquartz) and then open matlab from the home folder
- The keyboard shortcut for Run Section is not present, but fortunately Ctrl-Alt-Enter works

### Matlab web gui
- on storm create a vevn with jupyter lab, jupyter-matlab-proxy and notebook < 7.00
- launch the vevn, launch `jupyter lab --no-browser --port 5100` and cp/paste the link
- open the corresponding port in vs code
- open the link in the browser



## Useful links
### Videos
- [Functional Ultrasound (fUS) Imaging in the Brain of Awake Behaving Mice](https://www.youtube.com/watch?v=7xBbxE_iOn8)


### Brunner 2021
- [Brunner 2021 Nature Protocols](https://www.nature.com/articles/s41596-021-00548-8)
- [Github](https://github.com/nerf-common/whole-brain-fUS)
- [Dataset on Zenodo](https://zenodo.org/records/4905862)


### Lambert 2025
- [PyfUS Guthub repo](https://github.com/tlambertnerf/PyfUS)
- [PyfUS Neurocomputing paper 2025](https://www.sciencedirect.com/science/article/pii/S0925231225015711)
- [Dataset on Zenodo](https://zenodo.org/records/13341387)

### Lambert 2024
- [Dataset on Zenodo](https://zenodo.org/records/14534340)
- [Original paper for the Zenodo dataset](https://direct.mit.edu/imag/article/doi/10.1162/IMAG.a.34/131016/Functional-ultrasound-imaging-and-neuronal)

### fUSI in Humans
- [Soulokey 2025 Science Advances](https://www.science.org/doi/10.1126/sciadv.adu9133)

  
### fsl nipype interface
- [fsl_glm](https://nipype.readthedocs.io/en/latest/api/generated/nipype.interfaces.fsl.model.html#glm)