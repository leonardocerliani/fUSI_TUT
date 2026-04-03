# Data management for fUSI data


## Overview
The scripts in the present repo are for reconstructing, preprocessing and carrying out analyses on fUSI data. The entry point is usually `00_LAUNCHER/fusi_pipeline_launcher.m`

These scripts therefore proceed to create new file or modify existing ones, which is not ideal since we do not want to touch the analysis from our colleague. Therefore the idea here is to work on (relatively) raw data by copying it from the original location to a new location in `data03`.

The purpose of the current data management folder is that of 
- building a map of where the original files are, 
- provide a script to copy them in the new location, so that the user can then proceed with reconstruction / preprocessing and analysis.

**Note that the copying script can be re-run also once reconstruction / preprocessing procedures have already been run** (if it would ever be necessary) since only the initial files are copied. In other words, existing files (e.g. from preprocessing or analysis) are not touched.

The final user normally has an entry point directly in `03_CP_DATA/cp_fUSI_orig2dest.py`, where she can decide which files to copy from the original to the new location. However several steps are necessary for this to be possible. A detailed README.md file is provide in each ot these subdirectories, however here is a brief summary of what made this possible. If you are not interested in the preparation, you can skip down to `03. Copy data to data03`


## 01. Export `Datapath.m`  (`01_EXPORT_DATAPATH/`)
The location of the files for each experiment and condition were originally stored in `Datapath.m`. After a few manual adjustments that led to `Datapath_MOD.m`, we export this to `original_Datapath_location.csv`, which contains the same information in a CSV file.

The CSV has the following columns:
```
project, condition, subject_id, session_id, func_run_id, anatomical_path, orig_root
```
Note that `anatomical_path` is kept as a full absolute path (not reconstructable from the other columns), because the anatomy may come from a different subject or session than the functional run (e.g. USS cross-session anatomy, EmotionalContagion cross-subject anatomy).

## 02. Test Data Structure  (`02_TEST_DATA_STRUCTURE/`)
Here we test the original data structure in order to design the algorithm to copy the data from source to destination, as well as the CSV that we will use to load the files during reconstruction/preprocessing/analysis.

For instance:
- are anatomical and functional data acquired in the same session?
- is it possible to reconstruct the location of the functional files from the columns of the CSV, instead of storing the whole data path?

Output: `check_subject_id_consistency.txt` and `check_functional_paths_construction.txt` (consistency check reports).


## 03. Copy data to `data03`
Now we can copy the files from origin to destination. 

The `cp_fUSI_orig2dest.py` (mind the `venv`) can be launched with:

```bash
python cp_fUSI_orig2dest.py
```

It does a few things:

**The first time it is launched**, it produces a fresh `fUSI_data_location_STORM.csv`, which will be used for the subsequenty copy procedure. It also defines a destination root path `dest_root` based on the following two parameters close to the top of the script.

```python
DEST_BASE   = '/data03'   # base mount point
PROJ_SUFFIX = '_LC'       # appended to every project folder name
```

At this point the user needs to edit the `fUSI_data_location_STORM.csv` and define which functional runs is she interested in analyzing. E.g.

|TOCOPY|COPIED|project         |condition |subject_id   |session_id|func_run_id|anatomical_path                                                            |orig_root|dest_root                  |
|------|------|----------------|----------|-------------|----------|-----------|---------------------------------------------------------------------------|---------|---------------------------|
|YES   |   |fUSIMethodsPaper|VisualTest|sub-methods02|ses-231215|run-115047 |/data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-113409/|data06   |/data03/fUSIMethodsPaper_LC|
|YES   |   |fUSIMethodsPaper|VisualTest|sub-methods02|ses-231218|run-152539 |/data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231218/run-144557/|data06   |/data03/fUSIMethodsPaper_LC|
|YES   |   |fUSIMethodsPaper|VisualTest|sub-methods03|ses-240104|run-125448 |/data06/fUSIMethodsPaper/Data_analysis/sub-methods03/ses-240104/run-123823/|data06   |/data03/fUSIMethodsPaper_LC|
|      |      |fUSIMethodsPaper|VisualTest|sub-methods03|ses-240105|run-103457 |/data06/fUSIMethodsPaper/Data_analysis/sub-methods03/ses-240105/run-102041/|data06   |/data03/fUSIMethodsPaper_LC|
|      |      |fUSIMethodsPaper|VisualTest|sub-methods04|ses-240104|run-142825 |/data06/fUSIMethodsPaper/Data_analysis/sub-methods04/ses-240104/run-140723/|data06   |/data03/fUSIMethodsPaper_LC|
|      |      |fUSIMethodsPaper|VisualTest|sub-methods04|ses-240105|run-114946 |/data06/fUSIMethodsPaper/Data_analysis/sub-methods04/ses-240105/run-113659/|data06   |/data03/fUSIMethodsPaper_LC|


At this point, i.e. **from the second time it is launched**, 
- it will scan for the data marked as `TOCOPY = YES` 
- copy them to the destination
- mark them as `COPIED = YES` in the `fUSI_data_location_STORM.csv`
- produce a report for each functional run id in the `./logs` folder


## IMPORTANT NOTE
The file which will be used to launch the pipeline of reconstruction / preprocessing / analysis (or a single step independently) is in `00_LAUNCHER/fusi_pipeline_launcher.m` and it reads the `fUSI_data_location_STORM.csv` in **_that_** directory. Therefore when you copy new files, it can be a good idea to update the `00_LAUNCHER/fUSI_data_location_STORM.csv`.

We prefer to keep it redundant in order to have always a workable copy of `fUSI_data_location_STORM.csv`. An alternative for the future could be to implement some logic in `cp_fUSI_orig2dest.py` that scans the directory tree in `data03` and updates the columns `TOCOPY` and `COPIED`, as well as the `00_LAUNCHER/fUSI_data_location_STORM.csv`.




