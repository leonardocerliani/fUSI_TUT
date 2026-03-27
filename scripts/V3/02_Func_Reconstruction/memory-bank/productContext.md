# Product Context: fUSI Reconstruction Documentation

> **Note**: This documentation reflects the refactoring work completed in `02_Functional_Reconstruction/` with sample data located in `sample_data/`.

## Purpose
This documentation exists to provide a clear, accurate reference for understanding how raw functional ultrasound imaging data is processed into analysis-ready format. Lab members need to understand this pipeline to:
- Verify data integrity during processing
- Troubleshoot reconstruction issues
- Modify or extend the pipeline for new experimental designs
- Train new team members on the data workflow

## Problem It Solves

### Current Challenges
1. **Complex synchronization**: Multiple data streams (imaging, TTL, stimulation, behavior) must be precisely aligned
2. **Opaque processing**: The RAW_2_MAT.m script performs many operations that aren't self-documenting
3. **Knowledge transfer**: Understanding gained through experience needs to be captured
4. **Debugging difficulty**: When reconstruction fails, it's hard to pinpoint the issue without understanding each step

### How Documentation Addresses These
- **Step-by-step explanation** of each processing stage
- **Clear data flow diagrams** showing how inputs transform to outputs
- **Synchronization logic** explained with concrete examples
- **TTL channel mapping** documented for reference
- **Common issues** identified with solutions

## Target Users
1. **Lab researchers** analyzing fUSI data
2. **New team members** learning the pipeline
3. **Method developers** extending or modifying the reconstruction
4. **Troubleshooters** diagnosing data processing issues

## User Experience Goals

### For Documentation Readers
- **Quick orientation**: Understand overall pipeline in 5 minutes
- **Deep dive capability**: Detailed explanation of each step available
- **Example-driven**: Real data examples (run-115047-func) illustrate concepts
- **Reference-friendly**: Easy to look up specific processing steps

### For the Reconstruction Process
The documentation should make it clear that the refactored pipeline (`do_reconstruct_functional.m`):
- Loads per-experiment configuration for TTL channels
- Takes raw, unsynchronized data from multiple sources
- Auto-detects available stimulation and behavioral data
- Aligns everything to a common timeline
- Handles hardware timing imperfections (lag correction)
- Produces a single, well-structured MAT file
- Preserves all relevant experimental information
- Provides clear terminal feedback about what's happening

## Key Features to Document
1. **Configuration system** - how `experiment_config.json` defines TTL channels per experiment
2. **Input data structure** - what files are required and their formats
3. **Scan parameter loading** - how imaging configuration is read
4. **Binary PDI reading** - how raw imaging data is loaded and reshaped
5. **TTL synchronization** - how hardware timing signals align events
6. **Lag correction** - how frame timing imperfections are handled
7. **Timeline adjustment** - how all timestamps are aligned to common zero
8. **Event extraction** - how stimulation events are parsed from various sources
9. **Behavioral integration** - how auxiliary data (wheel, gsensor, pupil) is included
10. **Auto-detection** - how the pipeline discovers available data files automatically
11. **Output structure** - complete specification of PDI.mat contents

## Success Metrics
- Lab members can understand the pipeline without asking questions
- Troubleshooting time for reconstruction issues is reduced
- New team members can get up to speed faster
- Documentation serves as authoritative reference during method development
