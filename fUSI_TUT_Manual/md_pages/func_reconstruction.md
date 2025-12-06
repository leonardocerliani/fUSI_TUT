# Functional Reconstruction



## `RAW_2_MAT.m`

`RAW_2_MAT.m`

DEPENDENCIES:
```
LagAnalysisFusi.m
```

Required arguments from command line: None.

This script reconstructs the bin data from the functional scan in the DATA COLLECTION folder and creates the corresponding location in the data analysis folder.

**Input in DATA_COLLECTION** :
- a run-[runNumber] folder containing the following:
	- `TTL*.csv` file
	- `*DAQ.csv` file
	- `FUSI_data` containing:
		- `[functional_data].bin`
		- `L22-14_PlaneWave_FUSI_data.mat`
		- `post_L22-14_PlaneWave_FUSI_data.mat`

**Output in DATA_ANALYSIS** :
- `PDI.mat`

**Example of a valid input folder**
```
run-115047/
├── DAQ.csv
├── FUSI_data
│   ├── L22-14_PlaneWave_FUSI_data.mat
│   ├── fUS_block_PDI_float.bin
│   └── post_L22-14_PlaneWave_FUSI_data.mat
├── GSensor.csv
├── RunningWheel.csv
├── TTL20231215T115044.csv
├── VisualStimulation.csv
└── settings.json
```


## Current issues
See below

## TTLinfo column names
Right now we can identify the columns using their name. This uses the `TTLinfo_colNames.m` and `ttlcol.m` files in `Utils_LC`.

However since the content of the channel can change across experiments, it would be better to have an experiment-specific `ttlinfo_colname.csv` like

```
Channel,Name
1,Time
2,ch_2
3,Events
4,ShockOBSCTLStim
5,ShockTailStim
6,AdjustPDItime
7,ch_7
8,ch_8
9,ch_9
10,VisualStim
11,AuditoryStim
12,Shock
13,ch_13
```

and then build a struct in matlab

```bash
tbl = readtable('ttlinfo_colnames.csv');
tbl.Name = matlab.lang.makeValidName(tbl.Name); % ensure valid field names
col = cell2struct(num2cell(tbl.Channel), tbl.Name, 1);
```

so that then we can access the column index with their name, e.g.
```
col.Time
col.ShockOBSCTLStim
```

The drawback is that this should be done retroactively for all acquired runs.
The advantage (which I think is higher than the drawback) is that then we can be sure that the assignment is correct and we can change it when we want.

## Issues

There are still many things unclear about the processing in this script, but we will need to deal with them later.

- when I load the functional data, several errors are thrown in the section of the laganalysis
- otherwise it looks like the pdi.mat is created, but how can I check whether all the information are in there?
