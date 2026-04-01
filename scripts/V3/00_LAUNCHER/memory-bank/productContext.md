# Product Context: fUSI Pipeline CLI Launcher

## Why This Exists

The fUSI analysis pipeline consists of multiple stages (reconstruction, preprocessing, analysis), each requiring specific input files and paths. Previously, researchers had to:
- Manually track which files exist for each run
- Remember the correct function signatures and paths
- Navigate between different stage directories
- Manually construct complex file paths

This launcher solves these problems by providing a single entry point that:
- Automatically checks file availability
- Shows which stages are ready to run
- Executes the correct function with proper paths
- Provides clear feedback throughout

## Problems It Solves

### 1. **Path Management Complexity**
**Before**: Researchers manually construct paths like:
- `/data03/fUSIMethodsPaper/ses-231215/run-115047/Data_collection/`
- `/data03/fUSIMethodsPaper/ses-231215/run-115047/Data_analysis/`
- `/data03/fUSIMethodsPaper/ses-231215/run-113409/Data_analysis/` (for anatomical)

**After**: Simply provide `run-115047`, and the launcher handles all path construction.

### 2. **Dependency Tracking**
**Before**: Users might try to run preprocessing without reconstruction output, leading to confusing errors.

**After**: The launcher checks dependencies and shows clearly which stages are ready.

### 3. **Multi-Location Data**
**Before**: Data might be on the server (`/data03/`) or local (`/Users/Leonardo/fUSIdata/`).

**After**: CSV database specifies data_root for each run, launcher handles any location.

### 4. **Multiple Analysis Types**
**Before**: Different analysis scripts in different directories, unclear which to use.

**After**: Launcher auto-detects available analysis types and presents them as menu options.

## How It Should Work

### Typical Workflow

1. **User starts launcher**:
   ```matlab
   fusi_pipeline_launcher('run-115047')
   ```

2. **Launcher checks files**:
   - Looks up run in CSV
   - Constructs all necessary paths
   - Checks which files exist

3. **Displays status**:
   ```
   run-115047
   [X] functional reconstruction
   [ ] functional preprocessing
   [ ] analysis: MethodPaper
   ```

4. **User selects stage**: Based on what's ready

5. **Launcher executes**: Calls appropriate function with correct paths

6. **Provides feedback**: Shows progress and results

## User Experience Goals

### Simplicity
- Single command to check and run any stage
- No need to remember complex paths or function signatures
- Clear visual feedback on what's possible

### Safety
- Cannot accidentally run a stage without required inputs
- Clear error messages if something is wrong
- No data corruption or overwriting

### Flexibility
- Works with data on any location (server, local)
- Easy to add new runs to the CSV
- Easy to add new analysis types

### Transparency
- Always shows which files it's looking for
- Clear messages about what it's doing
- Helpful error messages when things go wrong

## Integration with Existing Pipeline

The launcher doesn't replace existing scripts, it orchestrates them:

- **02_Func_Reconstruction/do_reconstruct_functional.m**: Called with correct paths
- **03_Func_Preprocessing/do_preprocessing.m**: Called with correct paths
- **04_Analysis_*/do_analysis_*.m**: Called with correct paths

Each stage script remains independent and can still be run manually if needed.
