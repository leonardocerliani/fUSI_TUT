# Understanding Stationary Trial Selection

## The Paper Criterion

> **"trials in which wheel velocity exceeded 2 cm/s for less than 200ms during the stimulation period"**

This means: **Keep trials where the mouse NEVER moved continuously for more than 200ms at speeds > 2 cm/s**

---

## Step-by-Step Explanation with Code in `IndividualRunningOrNot.m` by Chaoyi

In summary:

- identify the regions of `wheelInfo.wheelspeed` which occur during the presentation of a stimulus, based on `wheelInfo.time`

- in `wheelInfo.wheelspeed` there is the count of wheel portions per second. The entire circumference of the wheel has 2^10 (1024) counts, and a circumference of 19\*pi = 59.69 cm, therefore one wheel portion is (19\*pi/1024) ≈ 0.0584 cm.

- Therefore we first need to check which samples of wheelspeed contain more than 35 counts, since the threshold is 2cm (2/0.0584 = 34.26).

- At this point we check how many contigous sections *above threshold* (so above 35) are found.

- The other criterion is that the mouse must not have moved for more than 2cm in a time of 200ms. Therefore we need to convert this to number of portions which represent this threshold. Since the sampling of the wheel is 55Hz, the number of samples needed to encode 200ms or 0.2s is about 11 (0.2/(1/55)) = 10.989.

- Therefore the last thing to do is to check if the number of contigous portions of the wheelrecording which *exceed* 2cm/s is lower than 11.1 samples. Only those stimuli will be deemed as stationary.


### The Complete Code

```matlab
runningTrialIndex = [];
for itrl = 1:numel(PDI.stimInfo.stimCond)
    trialRunning = PDI.wheelInfo.wheelspeed(PDI.wheelInfo.time>=PDI.stimInfo.startTime(itrl)&...
        PDI.wheelInfo.time<=PDI.stimInfo.endTime(itrl));
    timeDev = mean(diff(PDI.wheelInfo.time));
    CC = bwconncomp(abs(trialRunning) >35); % speed above 2cm/s
    CCsize = cellfun(@(x) numel(x), CC.PixelIdxList);
    if any(CCsize>0.2/timeDev) % time last more than 200ms
        runningTrialIndex = [runningTrialIndex,itrl];
    end
end
```

---

## Line-by-Line with Concrete Example

### **Setup**
```matlab
runningTrialIndex = [];
```
→ Empty list to store trials with "too much running"

```matlab
for itrl = 1:numel(PDI.stimInfo.stimCond)
```
→ Loop through each stimulus trial (let's follow **Trial #3**)

---

### **STEP 1: Extract wheel data during this stimulus**
```matlab
trialRunning = PDI.wheelInfo.wheelspeed(PDI.wheelInfo.time>=PDI.stimInfo.startTime(itrl) & ...
                                        PDI.wheelInfo.time<=PDI.stimInfo.endTime(itrl));
```

**What it does:**
- Stimulus #3 runs from t=10.0s to t=15.0s
- Wheel is sampled at ~55 Hz (every 18ms)
- Extract ONLY wheel measurements during this 5-second period

**Example result:**
```
trialRunning = [12, 15, 180, 190, 185, 20, 15, 12, 18, 220, 210, 15, 10]
                ↑ These are raw encoder counts per second
```

---

### **STEP 2: Calculate sampling interval**
```matlab
timeDev = mean(diff(PDI.wheelInfo.time));
```

**What it does:**
- Calculate time between consecutive wheel samples
- Wheel timestamps: [10.000, 10.018, 10.036, ...]
- Differences: [0.018, 0.018, 0.018, ...]

**Example result:**
```
timeDev = 0.018 seconds  (i.e., 55 Hz sampling)
```

---

### **STEP 3: Find continuous periods above threshold**
```matlab
CC = bwconncomp(abs(trialRunning) > 35);
```

**What it does:**
- Create True/False array where speed > 35
- Find **groups** of consecutive TRUE values (= continuous movement periods)

**Example:**
```
trialRunning:  [12, 15, 180, 190, 185, 20, 15, 12, 18, 220, 210, 15, 10]
Above 35?:     [F,  F,  T,   T,   T,   F,  F,  F,  F,  T,   T,   F,  F ]
                       └──GROUP 1───┘                  └─GROUP 2┘
```

`bwconncomp` found **2 groups** of consecutive TRUE values!

**Why 35?** Raw data is in encoder counts/sec, not cm/s:
- 35 counts/sec × (19π/1024) ≈ **2.04 cm/s**

---

### **STEP 4: Count samples in each group**
```matlab
CCsize = cellfun(@(x) numel(x), CC.PixelIdxList);
```

**What it does:**
- For each group, count how many samples it contains

**Example:**
```
GROUP 1: positions [3, 4, 5] → 3 samples
GROUP 2: positions [10, 11]  → 2 samples

CCsize = [3, 2]
```

---

### **STEP 5: Check if any group exceeds 200ms**
```matlab
if any(CCsize > 0.2/timeDev)
    runningTrialIndex = [runningTrialIndex, itrl];
end
```

**What it does:**
- Convert 200ms to number of samples
- Check if ANY group is too long

**Calculation:**
```
Duration threshold: 200ms = 0.2 seconds
Samples per second: 1/0.018 = 55.56
Threshold in samples: 0.2 / 0.018 = 11.1 samples
```

**Check each group:**
```
GROUP 1: 3 samples < 11.1  ✓ OK (only 54ms)
GROUP 2: 2 samples < 11.1  ✓ OK (only 36ms)

Result: NO group exceeds 200ms → STATIONARY trial
        (do NOT add to runningTrialIndex)
```

---

## Example 2: A Running Trial

```
trialRunning:  [12, 180, 190, 185, 180, 175, 190, 185, 180, 175, 185, 190, 180, 15, 10]
Above 35?:     [F,  T,   T,   T,   T,   T,   T,   T,   T,   T,   T,   T,   T,   F,  F ]
                    └────────────────────GROUP 1─────────────────────────┘
```

**Analysis:**
```
GROUP 1: 12 samples
Duration: 12 × 0.018 = 216ms  ✗ EXCEEDS 200ms!

Result: RUNNING trial (add to runningTrialIndex)
```

---

## Key Concepts

### **Connected Components (`bwconncomp`)**

This MATLAB function finds **groups of consecutive TRUE values**:

```
Input:  [F F T T T F F T T F]
        └──┘ └G1─┘ └──┘└G2┘└─┘

Output: 2 groups
- Group 1: indices [3,4,5]  (3 elements)
- Group 2: indices [8,9]    (2 elements)
```

### **Why NOT Just Sum?**

❌ **WRONG**: Sum all time above threshold
```
3 bursts: 80ms + 70ms + 90ms = 240ms total
→ Would reject (>200ms)
BUT each burst is brief! Should keep!
```

✓ **CORRECT**: Check longest continuous period
```
3 bursts: max(80ms, 70ms, 90ms) = 90ms
→ Keep (< 200ms)
```

### **The Biological Interpretation**

The criterion separates:
- **Stationary trials**: Mouse was still (or had only brief twitches)
- **Running trials**: Mouse was actively locomoting

This allows comparing brain activity during:
- Visual stimulus + stillness
- Visual stimulus + locomotion

---

## Diagnostic Tools

### 1. Verify Implementation
```matlab
cd unit_tests
diagnose_wheelspeed
```
Compares your implementation with colleague's reference method.

### 2. Understand `bwconncomp`
```matlab
cd unit_tests
explain_bwconncomp
```
Shows visual examples of how connected components work.

### 3. Test Different Thresholds
```matlab
% Very lenient (should accept almost all)
[stim, wheel, stim_stat] = create_predictors(data, 100.0, 5000);

% Paper criterion
[stim, wheel, stim_stat] = create_predictors(data, 2.0, 200);

% Very strict (should reject almost all)
[stim, wheel, stim_stat] = create_predictors(data, 0.1, 10);
```

---

## Summary

> **Keep trials where the mouse NEVER moved continuously for more than 200ms at speeds > 2 cm/s**

**Key Points:**
1. Extract wheel data during stimulus period
2. Find **continuous runs** above threshold using `bwconncomp`
3. Check if **ANY run** exceeds 200ms
4. Reject trial if yes, keep if no

**Not:** checking total accumulated time above threshold  
**But:** checking longest single continuous period
