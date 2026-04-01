We have several matlab scripts/functions to conduct different stages of fUS image reconstruction, preprocessing and analysis.
Now I want to build a CLI launcher that does the following:

- given a certain run number (to be taken from a csv file later on)
- it checks whether specific files are available for a certain stage of the pipeline
- requires an input from the user about which stage to run

for instance

```
run-122333
[X] functional reconstruction
[ ] functional preprocessing
[ ] analisys type 1
[ ] analysis type 2
[ ] analysis type 3

Which step do you want to run?
```

The functions are inside the 02 03 04 folders in this directory. You should **not** read them for the moment.

## 02_Func_Reconstruction
do_reconstruct_functional(datapath, savepath)

## 03_Func_Preprocessing
do_preprocessing(anatPath, funcPath, atlasPath)

## 04_Analysis_MethodPaper
not yet a function, but I will tell you later what to do about this


Right now there are some inconsistencies in the naming convention, for instance do_reconstruct_functional(_, savepath) is the same as do_preprocessing(_, funcPath, _). 
We will need to change this along the way.

We will go step by step. For each stage, we will identify which are the necessary files to run a certain part of the pipeline, and you will write the test 
that looks for those files.

Also, we will build a csv along the way which will be the source of information for where the different files are for each run. I still don't have a clear ides. We will build it along the way

For the moment, the main aim is to create a script that represents the skeleton of this CLI launcher

If it is all clear, you can initialize the memory-bank and then come back to me.


----------

Answers to your questions:

## 1. CSV file location
the csv location will actually be in the present directory (000_LAUNCHER), but we still need to understand how to organize it. We will make it together along the way. The current 00_Datapaths/datapath* are not good examples.

I envision that we will need the following columns:
- experiment (experiment label)
- func_run (e.g. run-115047)
- data_root, e.g. /data03/fUSIMethodsPaper for the server or /Users/Leonardo/fUSIdata for local data
- session_id, e.g. ses-222233
- anatomic_run, e.g. run-111340

Note that several functional runs can be acquired in a session, and in that session there is always also an anatomical acquisition, so in the end the complete paths are:

anatomic_path: data_root/session_id/anatomic_run, e.g. 
/Users/Leonardo/fUSIdata / ses-222233 / run-111340

functional path condition 1: data_root/session_id/func_run, e.g.
/Users/Leonardo/fUSIdata / ses-222233 / run-115047
/Users/Leonardo/fUSIdata / ses-222233 / run-112059

This is my first plan, but it might change later.

## Atlas path 
That can be hardcoded: it will always be a directory named `allen_brain_atlas` in the $PWD


## Multiple Analysis Types
For the moment there is only a 04_Analysis_MethodPaper. Later on I will add some other folders, each one containing all the code to go from the preprocessed data to the analysis, for instance 04_Analysis_Emotional_Contagion.

The idea is that when new analyses are devised, one should be able to just add another function to the launcher, which will present it as an option

## Run ID Format
Let's make it that it should always be `run-[run number]` like `run-111333`


-------

Perfect. And let's put the data_root always as the last field (since it's the longest and most difficult to read)

experiment,func_run,session_id,anatomic_run,data_root

Also, the csv file will be called fUSI_data_location.csv


-------

Great! New we will work on harmonizing the path names across the scripts

## 02_Func_Reconstruction
do_reconstruct_functional(datapath, savepath)

## 03_Func_Preprocessing
do_preprocessing(anatPath, funcPath, atlasPath)

## 04_Analysis_MethodPaper
not yet a function, but I will tell you later what to do about this

Right now there are some inconsistencies in the naming convention, for instance do_reconstruct_functional(_, savepath) is the same as do_preprocessing(_, funcPath, _). 
We will need to change this along the way.

There are some important information I need to give you first:

The data is organized always in two big folders: Data_collection and Data_analysis.

/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data
├── Data_analysis
│   └── ses-231215
│       ├── run-113409-anat
│       └── run-115047-func-visual
└── Data_collection
    ├── ses-231215
    │   ├── run-113409-anat
    │   └── run-115047-func-visual
    └── ses-240103
        ├── run-140517-anat
        └── run-142553-func-shock

When the raw data (anatomical or functional) are acquired, they are stored in the Data_collection folder. When they are reconstructed, they end up in a directory tree with the same exact name, e.g. ses-231215/run-113409, but in the Data_analysis directory

The 01_Anat_Registration was ignored since it's done at experiment time. The reconstructed
file is placed in the Data_analysis/ses-number/run-number directory, which therefore should already be present.

That's why the launcher starts with the functional reconstruction. 

do_reconstruct_functional(datapath, savepath)
- datapath refers to the **Data_collection** folder
- savepath to the **Data_analysis** folder, which has the same name and it is dynamically created by the script

do_preprocessing(anatPath, funcPath, atlasPath)
- anatPath is the anatomic reconstructed data as a subfolder of the **Data_analysis** folder
- funcPath is the functional reconstructed data in the **Data_analysis** folder produced by do_reconstruct_functional

As you can see there is little consistency and information about this in the current version. I hope the structure is clear to you now.

I am thinking to modify them to something like:

- do_reconstruct_functional(func_collection_path, func_analysis_path)
- do_preprocessing(anat_analysis_path, func_analysis_path, atlasPath)

Is it all clear now? How does it sound?

---

oh one more thing! In the fusi_pipeline_launcher.m I want to put, in one of the first lines, the name of the csv to be used.

I have two files, where the location of data_root (and possibly some other values in other columns) change:
- fUSI_data_location_STORM.csv <- I use this on the remote server
- fUSI_data_location_local.csv <- I use this locally

It is ok to hard code it in one of the first lines of fusi_pipeline_launcher.m.


---

ok, I deleted the fusi_data_location.csv since it was just a test. I will build a proper one later for STORM

Now let's make a test. If I call

fusi_pipeliine_launcher('run-115047')

show me how the other scripts will be run with the actual ses and run number

do_reconstruct_functional([path], [path])
do_preprocessing([path], [path], [path])


---- 

I updated the fUSI_data_location_LOCAL.csv to the right values

I see some mistakes in what you show me. It should be

do_reconstruct_functional(
    '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_collection/ses-231215/run-115047',  % func_collection_path
    '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-115047'     % func_analysis_path
)


do_preprocessing(
    '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-113409',   % anat_analysis_path
    '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_collection/ses-231215/run-115047',   % func_analysis_path
    '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/scripts/allen_brain_atlas' % atlasPath
)

What do you think?


-----

I also don't like this in load_run_info.m

% Handle optional CSV filename
if nargin < 2 || isempty(csvFilename)
    csvFilename = 'fUSI_data_location.csv';
end

There is no default. The csv to be used is the one defined in the first lines of fusi_pipeline_launcher.m. If it's not present, it should return an error and stop


-----

good morning!

Now we can proceed to the actual implementation.
Checking the files required for the reconstruction will probably be the toughest part.

Looking at my documentation, I see that the following must be present:

- experiment_config.json  # description of experiment and data channels
- TTL*.csv                # main source of data
- NIDAQ.csv or DAQ.csv    # do not remember what this is
- a FUSI_data directory with
    - fUS_block_PDI_float.bin   # binary file of fUS data
    - post_L22-14_PlaneWave_FUSI_data.mat or L22-14_PlaneWave_FUSI_data.mat  # don't remember what this is

for instance for run-115047

ses-231215/
└── run-115047
    ├── DAQ.csv
    ├── FUSI_data
    │   ├── L22-14_PlaneWave_FUSI_data.mat
    │   ├── fUS_block_PDI_float.bin
    │   └── post_L22-14_PlaneWave_FUSI_data.mat
    ├── GSensor.csv
    ├── RunningWheel.csv
    ├── TTL20231215T115044.csv
    ├── VisualStimulation.csv
    ├── experiment_config.json
    └── settings.json

is this correct according to you?


--- 

the PDI.mat was reconstructed, but there are some things which are problematic

# 1. functional reconstruction already marked
When I launched fusi_pipeline_launcher('run-115047') i got 

```
run-115047
[X] Functional Reconstruction
[ ] Functional Preprocessing
[ ] Analysis: MethodPaper
```

although the reconstruction had not been carried out yet. Indeed the folder `/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-115047` was not even there (which is the situation when you launch the reconstruction: only the files in the corresponding `Data_collection` folder are present)

# 2. Strange nonexistent directory alert/error

```
=== Running Stage 02: Functional Reconstruction ===

Warning: Name is nonexistent or not a directory: /Users/leonardo/Dropbox/fUSI/fUSI_TUT/scripts/V3/../02_Func_Reconstruction
> In path (line 109)
In addpath (line 96)
In fusi_pipeline_launcher>run_reconstruction (line 143)
In fusi_pipeline_launcher (line 96)
Collection path: /Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_collection/ses-231215/run-115047
Analysis path: /Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-115047
```

Also, one thing which is not an issue, but it would be nice to have: the report printed to the terminal should be saved
in the corresponding Data_analysis/ses-[number]/run-[number]/logs folder (which should be created)

---

## Issue 1: Reconstruction Incorrectly Marked as Ready ✓
the `[X] Functional Reconstruction` should mean that the reconstruction (or any other step, like preprocessing) has already been carried out - although the user has the possibility to run it again and overwriting the reconstrution, maybe after a warning message like " ⚠️ Reconstruction exists!! Do you really want to overwrite it?"

Related to this, I am having an idea: instead of just a cross, let's use the following icons:
✅ success: the procedure has been completed
❌ error/fail: e.g. some files are missing


## Issue 2: Path Warning for 02_Func_Reconstruction ✓
Please fix it for me. Ideally, the user will always run the script from the root directory of the scripts, so in this case from `/Users/leonardo/Dropbox/fUSI/fUSI_TUT/scripts/V3`

## Issue 3: Log File Creation (Feature Request) ✓
Yes, please implement it


--------

ok, now it runs fine, but there are still two minor issues

- I ran reconstruction, and then called the fusi_pipeline_launcher again. Reconstruction was now marked (correctly) as completed, but also preprocessing, although I had run only reconstruction. In general, the rule is that a step is marked as completed only when the files created by that step are present, so
    - for reconstruction : PDI.mat
    - for preprocessing : prepPDI.mat

- related to this, I would like that
    - the not-yet-run steps are marked with an empty checkbox : `[ ]`
    - the one completed or failed with a checkbox that has **inside** the corresponding icon, so:
        - [✅] : completed and succesful
        - [❌] : failed / error


-----

this starts to be ok, but there are some issues.

After running reconstruction, I get:

```
[✅] Functional Reconstruction : correct:  I ran the reconstruction and not this is marked as completed
    ✅ Reconstruction already completed : correct
[ ] Functional Preprocessing : correct: preprocessing has not yet been run, therefore it should be empty [ ]
    ❌ Ready to run - all input files found (4 files) : ready to run but not yet run: this should be empty [ ]
[❌] Analysis: MethodPaper : should be empty for the same reason as above : should be empty for the same reason as above
    ❌ Cannot run - missing 1 required file(s) : when one file is missing, should be marked as warning [⚠️] instead of error
```

Also, for the moment let's not make any check at all for the completion of the analysis. I still have to think as how to check whether an analysis has been completed

Then there is an issue when I try to re-run the reconstruction:

```
Which step do you want to run?
1 - Functional Reconstruction
2 - Functional Preprocessing
3 - Analysis: MethodPaper
0 - Exit

? 1

→ Executing pipeline stage...

⚠️  WARNING: Reconstruction already exists!
? 
```

as you see, I don't get any option to proceed. It should be `y/N` with the N (no) as default. At this point the user can decide whether to re-run the analysis (pressing `y`) or skip and exit (pressing `N`)

I also realize that maybe the checking pipeline is not clear to me, so I want to explain you how I see it.

When I run the fusi_pipeline_launcher, the following things happen
- it checkes whether the files for single steps exist:
    - for reconstruction: all the files we mentioned before in the `Data_collection folder`
    - for preprocessing: the `PDI.mat` in the `Data_collection` folder, as well as the atlas and the `anatomic.mat` in the corresponding anatomical run (taken from the csv, e.g. `fUSI_data_location_LOCAL.csv`) in the `Data_analysis` folder
    - for analysis : the `prepPDI` in the `Data_analysis` folder

If all the files required for a given step are found, it shows a thumbs up (👍) and waits for the input of the user

If some files are missing for that step, it shows a warning (⚠️)

Does this all make sense?

------

Two small details


## detail 1
There was a problem with displaying the warning sign e.g. in 

```
status.message = sprintf('⚠️ Missing %d required file(s)', length(status.missing_files));
```

The warning was covering part of the following letter. Introducing more spaces didn't work.
I fixed it by putting the warning at the end.

```
status.message = sprintf('Missing %d required file(s) ⚠️', length(status.missing_files));
```

## detail 2
when I re-run the pipeline after reconstruction, and i ask to re-run reconstruction, I still don't get
the y/N option. However indeed the y and N input work.

```
⚠️  WARNING: Reconstruction already exists!
? y
```

I don't know the reason for this, but I fixed it like this

```matlab
            fprintf('WARNING: Reconstruction already exists!\nOverwrite it? (y/N)');
            response = input('Do you want to overwrite it? (y/N): ', 's');
```

and it works fine.

## Instead there is still an issue with the logs

First of all, please use the .txt extension

The big issue is that the logs now contain only

```
Enter your choice: Do you want to overwrite it? (y/N): 
````


whereas they should actually contain the log printed on screen, e.g:

```
=== Running Stage 02: Functional Reconstruction ===

Collection path: /Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_collection/ses-231215/run-115047
Analysis path: /Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-115047

Executing: do_reconstruct_functional(func_collection_path, func_analysis_path)


========================================
fUSI Data Processing Pipeline
========================================

→ Loading configuration: experiment_config.json
  Experiment: run-115047-func (2023-12-15)
  Visual stimulation with running wheel and gsensor

→ TTL Channel Configuration:
  ✓ PDI frames:        Channel 3
  ✓ Experiment start:  Channel 6 (fallback: 5)
  ✓ Visual stim:       Channel 10

→ Loading core data files:
  ✓ Scan parameters loaded: post_L22-14_PlaneWave_FUSI_data.mat
  ✓ PDI binary loaded: fUS_block_PDI_float.bin (90 × 158 × 3652 frames)
  ✓ TTL data loaded: TTL20231215T115044.csv (13 channels, 3840000 samples)
  ✓ DAQ log loaded: DAQ.csv
  ```

If it is too complex let's skip this


----- 

ok, now we need to take care of transforming the script `/Users/leonardo/Dropbox/fUSI/fUSI_TUT/scripts/V3/04_Analysis_MethodPaper/do_analysis_methods_paper.m` into a function.

As you see, now it assumes that the `prepPDI.mat`, which is required to run the analysis, is in the same directory.

We should change this. Now the pipeline will be started as usual with

```
fusi_pipeline_launcher('run-115047')
```

if the user selects option 3 (Analysis: MethodPaper), the appropriate prepPDI.mat will be loaded, and the analysis carried out and saved.

There is another detail: this analysis can be run only on the dataset specified in the csv file (e.g. fUSI_data_location_LOCAL.csv) which have the value `MethodsPaper` in the `experiment` column. If that is not the case, the launcher should display a message like `This analysis cannot be carried out on run-[number]`.

That's all. Can you do that?


----

I don't like using `prepPDI_path`. Let's just use `func_analysis_path` for consistency with the reconstruction and preprocessing path. In any case you have already checked that the `prepPDI.mat` exists in that folder.

Also, it is not necessary for the user to input the `experiment` in the `do_analysis_methods_paper` call since you can retrieve that from the csv. 

So the call should be implemented as:

```
do_analysis_methods_paper(func_analysis_path)
```

--------

Great! Everything works perfectly!

Now you need to do two things before we conclude the session:

- Update the README.md file. Make it as a getting started tutorial. Highlight also the fact that the single scripts (e.g. do_reconstruct_functional.m) can be run as a standalone - although it is advised to use the launcher to have more information at runtime

- Update the memory bank

that's it for now! Thank you!