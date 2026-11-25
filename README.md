# Suspension Rig: Data Processing

Each folder contains Python and MATLAB scripts used with the lab-scale quarter-car suspension rig. 

## Requirements

MATLAB or Python 3 and the libraries used by the scripts:

Make sure all the CSV files and the Python or MATLAB files are located in the same folder. Run the scripts directly from the folder. 

## Folder and file layout

For the Free Decay Test, the folders are named according to the damping fluid used, e.g., `Free Decay 500 cSt` is the folder containing 10 experimental runs of the free decay test using damping fluid of 500 cSt. Inside the folder you will find 10 csv files associated with the 10 experimental runs.

For the Frequency Sweep Test, the folders are named according to the damping fluid used, e.g., `Sweep Test 500 cSt` is the folder containing 3 experimental runs at different crank radius size. Test 1.csv, Test 2.csv and Test 3.csv refers to crank radius size of 2mm, 4mm and 6mm, respectively. 

## CSV format

The scripts expect column headers in the first row. Keep the header names exactly as listed below unless you also update the column names used in the code.

**Free Decay Test**

- `Time_ms`
- `Chassis_Position_mm`

**Frequency Sweep Test**

- `Time_ms`
- `Wheel_Plate`
- `Chassis_Plate`
- `Road_Plate`
- `Target_Hz`
- `Actual_Hz`

## The two Python and MATLAB scripts

### 1. `damping_factor_analysis_pulldownXXXX.py` where XXXX refers to the damping fluid used.
### 1. `free_decay_dataplottingXXXX.m` where XXXX refers to the damping fluid used.

Reads numbered pull-down/release files from the configured test folder. It estimates the initial and final positions, identifies the peak excursion relative to the final position, and uses the resulting overshoot fraction to estimate the damping ratio and an equivalent damping coefficient. 

NOTE: The plots shown in the paper are plotted using MATLAB script.


### 2. `frequency_response_analysisXXXX.py` where XXXX refers to the damping fluid used.
### 2. `sweeptest_XXXX.m` where XXXX refers to the damping fluid used.

Reads one sweep CSV and groups the data by target frequency. For each step, it discards the first two seconds, estimates the road, wheel and chassis amplitudes using the 1st and 99th percentiles, and calculates wheel and chassis transmissibility relative to road motion. It plots the experimental results against the linear 2-DOF model.

The masses (`ms`, `mu`), suspension stiffness (`ks`), lower/tyre stiffness (`kt`) and damping coefficient (`c`) are specified in the script. Check these values before using the results.

NOTE: The plots shown in the paper are plotted using MATLAB script.

