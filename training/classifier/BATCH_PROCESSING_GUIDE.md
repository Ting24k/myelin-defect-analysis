# BATCH PROCESSING GUIDE

## Overview

Yes! The code now **fully supports multiple images** to create a unified training dataset. This is essential for building robust models that generalize across different samples.

## 🎯 Why Batch Processing?

### Benefits
✅ **Larger training datasets** from multiple source images  
✅ **Better generalization** across tissue samples  
✅ **Diverse pathology examples** from different subjects  
✅ **Unified dataset** ready for training  
✅ **Automatic tracking** of which samples came from which source

### Use Cases
- Combine images from multiple subjects (Control, AD, CTE)
- Process entire experimental batches at once
- Create comprehensive training sets from archival data
- Balance dataset with samples from different conditions

## 📦 New Files for Batch Processing

### Core Function
**prepare_batch_dataset.m**
- Processes multiple image-annotation pairs
- Creates unified dataset from all sources
- Tracks provenance of each sample
- Maintains separate defect/background organization

### Example Scripts
**example_batch_processing.m** - Full demonstration with 3 methods:
1. Manual specification
2. Automatic directory search
3. Configuration file loading

**simple_batch_workflow.m** - Easiest to use:
- Just update the configuration section
- Runs complete workflow
- Includes demo mode if files not found

## 🚀 Quick Start

### Method 1: Manual Specification (Simplest)

```matlab
% Define your image-annotation pairs
pairs = {
    {'image1.tif', 'image1_annotations.mat'};
    {'image2.tif', 'image2_annotations.mat'};
    {'image3.tif', 'image3_annotations.mat'};
};

% Process all images into unified dataset
dataset = prepare_batch_dataset(pairs, './output', [128, 128], 0.5);

% Train
training_struct = train_yoloV4_transfer_learning(...
    dataset, 'pretrained_model.mat', 'batch_model', 128);
```

### Method 2: Automatic Directory Search

```matlab
% Your directory structure:
% myelin_data/
% ├── subject1.tif
% ├── subject1_annotations_128.mat
% ├── subject2.tif
% ├── subject2_annotations_128.mat
% └── ...

% Automatically find all pairs
data_dir = './myelin_data';
image_files = dir(fullfile(data_dir, '*.tif'));

pairs = {};
for i = 1:length(image_files)
    img_path = fullfile(data_dir, image_files(i).name);
    [~, name, ~] = fileparts(image_files(i).name);
    annot_path = fullfile(data_dir, [name, '_annotations_128.mat']);
    
    if exist(annot_path, 'file')
        pairs{end+1, 1} = img_path;
        pairs{end, 2} = annot_path;
    end
end

dataset = prepare_batch_dataset(pairs, './output', [128, 128], 0.5);
```

### Method 3: Using simple_batch_workflow.m (Recommended)

1. **Edit the configuration section** (lines 6-21):
```matlab
image_annotation_pairs = {
    {'/data/AM332_S6B4.tif', '/data/AM332_annotations.mat'};
    {'/data/AM333_S6B4.tif', '/data/AM333_annotations.mat'};
    {'/data/AM334_S6B4.tif', '/data/AM334_annotations.mat'};
};

output_dir = './my_batch_dataset';
pretrained_model_path = 'training_struct_SM080_SM077_128_RGBV2.mat';
```

2. **Run**:
```matlab
simple_batch_workflow
```

That's it! The script handles everything.

## 📊 Example: 3 Images from Different Subjects

```matlab
% Process 3 subjects: 1 Control, 1 AD, 1 CTE
pairs = {
    {'Control_S1.tif', 'Control_S1_annotations.mat'};
    {'AD_S2.tif', 'AD_S2_annotations.mat'};
    {'CTE_S3.tif', 'CTE_S3_annotations.mat'};
};

dataset = prepare_batch_dataset(pairs, './multi_subject', [128, 128], 0.5);
```

**Output structure:**
```
multi_subject/
├── defects/
│   ├── Control_S1_defect_000001.png
│   ├── Control_S1_defect_000002.png
│   ├── AD_S2_defect_000001.png
│   ├── AD_S2_defect_000002.png
│   ├── CTE_S3_defect_000001.png
│   └── ...
├── background/
│   ├── Control_S1_bg_000001.png
│   ├── AD_S2_bg_000001.png
│   └── ...
└── batch_transfer_learning_dataset.mat
```

Notice how each filename includes the source image name!

## 📈 Understanding the Output

### Console Output
```
==================================================
   Batch Dataset Preparation
==================================================
Number of image-annotation pairs: 3

Processing pair 1 of 3
--------------------------------------------------
Image: Control_S1.tif
  Size: 25000x10000
  Total detections: 180
  True positives: 105
  False positives: 75
  Created 85 defect crops
  Created 62 background crops

Processing pair 2 of 3
--------------------------------------------------
[... similar for each image ...]

==================================================
   Creating Final Dataset
==================================================

Dataset Summary:
--------------------------------------------------
Source Statistics:
  Images processed: 3
  Total true positives: 310
  Total false positives: 245

Generated Dataset:
  Total samples: 442
  Defect crops: 265
  Background crops: 177
  
Class Balance:
  With defects: 59.9%
  Background: 40.1%
==================================================
```

### Dataset Structure

```matlab
>> load('batch_transfer_learning_dataset.mat');
>> height(dataset)
ans = 442

>> dataset(1:5, :)

    imageFilename                           myelinDefects
    'Control_S1_defect_000001.png'         [45 52 18 16]
    'Control_S1_defect_000002.png'         [30 40 22 19]
    'AD_S2_defect_000001.png'              [55 60 15 17; ...]
    'CTE_S3_bg_000001.png'                 []
    'Control_S1_bg_000001.png'             []
```

## 🔧 Advanced Features

### 1. Tracking Source Images

Each cropped image filename includes the source:
```matlab
% Extract source image from filename
[~, filename, ~] = fileparts(dataset.imageFilename{i});
source_parts = strsplit(filename, '_');
source_image = source_parts{1};  % e.g., 'Control', 'AD', 'CTE'
```

### 2. Filtering by Source

```matlab
% Get only samples from AD subjects
ad_samples = dataset(contains(dataset.imageFilename, 'AD_'), :);

% Get only Control samples
control_samples = dataset(contains(dataset.imageFilename, 'Control_'), :);
```

### 3. Stratified Splits

```matlab
% Ensure each train/val/test split has samples from all sources
sources = {'Control', 'AD', 'CTE'};
train_data = table();
val_data = table();

for i = 1:length(sources)
    % Get samples from this source
    source_data = dataset(contains(dataset.imageFilename, sources{i}), :);
    
    % Split 70/20/10
    n = height(source_data);
    train_idx = 1:floor(0.7*n);
    val_idx = floor(0.7*n)+1:floor(0.9*n);
    
    % Combine
    train_data = [train_data; source_data(train_idx, :)];
    val_data = [val_data; source_data(val_idx, :)];
end
```

## 📝 Real-World Example

### Scenario: Process 15 subjects (5 Control, 5 AD, 5 CTE)

```matlab
% Define all pairs
subjects = {
    % Controls
    'Control01', 'Control02', 'Control03', 'Control04', 'Control05';
    % AD
    'AD01', 'AD02', 'AD03', 'AD04', 'AD05';
    % CTE
    'CTE01', 'CTE02', 'CTE03', 'CTE04', 'CTE05'
};

pairs = {};
for i = 1:numel(subjects)
    img_path = sprintf('/data/%s.tif', subjects{i});
    annot_path = sprintf('/data/%s_annotations_128.mat', subjects{i});
    
    if exist(img_path, 'file') && exist(annot_path, 'file')
        pairs{end+1, 1} = img_path;
        pairs{end, 2} = annot_path;
    end
end

% Process all 15 subjects
fprintf('Processing %d subjects...\n', length(pairs));
dataset = prepare_batch_dataset(pairs, './15_subject_dataset', [128, 128], 0.5);

% Expected result: ~2000-6000 training samples
% (depending on defect density per image)
```

## 🎓 Best Practices

### 1. Balance Your Sources
✅ Include roughly equal numbers from each condition  
✅ Aim for 40-60% background samples overall  
❌ Don't heavily oversample one condition

### 2. Verify Before Processing
```matlab
% Check all files exist
for i = 1:size(pairs, 1)
    assert(exist(pairs{i,1}, 'file'), 'Missing: %s', pairs{i,1});
    assert(exist(pairs{i,2}, 'file'), 'Missing: %s', pairs{i,2});
end
```

### 3. Monitor Memory Usage
- Large batches (>20 images) may need more RAM
- Process in smaller batches if memory limited
- Save intermediate results

### 4. Document Your Sources
```matlab
% Save provenance information
source_info.pairs = pairs;
source_info.date_processed = datetime('now');
source_info.crop_size = crop_size;
save('dataset_provenance.mat', 'source_info');
```

## 🐛 Troubleshooting

### "Out of memory"
**Solution**: Process fewer images at once
```matlab
% Process in batches of 5
for batch = 1:5:length(all_pairs)
    batch_pairs = all_pairs(batch:min(batch+4, end), :);
    batch_dataset = prepare_batch_dataset(...);
    % Combine later
end
```

### "File not found"
**Solution**: Use absolute paths
```matlab
pairs = {
    {fullfile(pwd, 'image1.tif'), fullfile(pwd, 'annot1.mat')};
};
```

### "Some images skipped"
**Solution**: Check the warnings for missing annotations
- Ensure annotation files match image names
- Verify annotation file format

## ⏱️ Processing Time Estimates

| Number of Images | Image Size | Estimated Time |
|-----------------|------------|----------------|
| 1 image | 25000×10000 | 5-10 min |
| 3 images | 25000×10000 | 15-30 min |
| 10 images | 25000×10000 | 1-2 hours |
| 20 images | 25000×10000 | 2-4 hours |

*Time varies based on:*
- Number of annotations per image
- Overlap ratio (higher = more crops = longer)
- CPU speed
- Disk I/O speed

## 🔄 Integration with Training

Once you have the batch dataset, training is identical:

```matlab
% Load batch dataset
load('./batch_dataset/batch_transfer_learning_dataset.mat');

% Train
training_struct = train_yoloV4_transfer_learning(...
    dataset, 'pretrained_model.mat', 'batch_model', 128);
```

The model automatically learns from samples across all source images!

## 📊 Monitoring Dataset Quality

```matlab
% Load dataset
load('batch_transfer_learning_dataset.mat');

% Check balance
num_defects = sum(cellfun(@(x) ~isempty(x), dataset.myelinDefects));
num_background = sum(cellfun(@(x) isempty(x), dataset.myelinDefects));

fprintf('Dataset balance:\n');
fprintf('  Defects: %d (%.1f%%)\n', num_defects, 100*num_defects/height(dataset));
fprintf('  Background: %d (%.1f%%)\n', num_background, 100*num_background/height(dataset));

% Recommended: 40-60% background
if num_background/height(dataset) < 0.35
    warning('Too few background samples - consider adding more FP examples');
elseif num_background/height(dataset) > 0.65
    warning('Too many background samples - may need more defect examples');
else
    fprintf('✓ Good balance!\n');
end
```

## 🎯 Summary

**Simple answer**: YES! The code fully supports multiple images.

**Three ways to use it**:
1. **Manual**: List pairs directly in code
2. **Automatic**: Search directory for matching files  
3. **Simple script**: Edit config and run

**Key benefits**:
- Larger, more diverse datasets
- Better model generalization
- Unified training workflow
- Source tracking built-in

**Next steps**:
1. Try `example_batch_processing.m` to see it in action
2. Use `simple_batch_workflow.m` for your real data
3. Train with the unified dataset

All files are ready to use!
