# YOLOv4 Transfer Learning with False Positive Handling

This MATLAB code implements transfer learning for myelin defect detection using YOLOv4, with explicit handling of false positives as background training samples.

## Overview

The code addresses the false positive rate issue by:
1. **Identifying false positives** from model predictions (bb_FP = 1)
2. **Converting FPs into background training samples** (empty bounding boxes)
3. **Retraining the model** to explicitly learn what NOT to detect
4. **Iterative improvement** through human-in-the-loop workflow

## Key Innovation

Unlike standard pseudo-labeling that discards incorrect predictions, this approach:
- Uses false positives as **negative training examples**
- Teaches the model: "This looks like a defect, but it's NOT"
- Reduces FP rate through explicit learning from mistakes

## Files Included

### Core Functions
1. **prepare_transfer_learning_dataset.m**
   - Loads large images and annotations
   - Separates true positives (defects) from false positives (background)
   - Creates cropped images for training
   - Generates dataset table for YOLOv4

2. **train_yoloV4_transfer_learning.m**
   - Applies transfer learning to pretrained YOLOv4 model
   - Uses lower learning rate for fine-tuning
   - Evaluates performance on test set
   - Saves trained model and metrics

### Example Scripts
3. **main_transfer_learning_workflow.m**
   - Complete end-to-end workflow
   - Handles full-size images and annotations
   - Includes visualization and reporting

4. **example_run_transfer_learning.m**
   - Simplified example that runs with just annotation files
   - Creates mock dataset for testing
   - Demonstrates data analysis and visualization

## Input Data Format

### Annotation File (.mat)
Expected fields:
- `bb_detector` or `all_bboxes`: [N x 4] matrix of bounding boxes [x, y, width, height]
- `bb_FP`: [N x 1] vector where:
  - 0 = True Positive (real defect)
  - 1 = False Positive (should be background)
- `all_scores` (optional): [N x 1] confidence scores

### Image Files
- Large RGB images (e.g., 25000 x 10000 pixels)
- Supported formats: .tif, .png, .jpg

## Usage

### Option 1: Full Workflow (with real images)

```matlab
% Configure paths
image_path = 'path/to/your/large_image.tif';
annotation_path = 'path/to/annotations.mat';
pretrained_model_path = 'training_struct_SM080_SM077_128_RGBV2.mat';
output_dir = './transfer_learning_output';

% Step 1: Prepare dataset
dataset = prepare_transfer_learning_dataset(...
    image_path, annotation_path, output_dir, [128, 128], 0.5);

% Step 2: Train with transfer learning
training_struct = train_yoloV4_transfer_learning(...
    dataset, pretrained_model_path, 'my_model_v1', 128);
```

### Option 2: Quick Test (without images)

```matlab
% Run the example script
example_run_transfer_learning;
```

This will:
- Analyze your annotation file
- Create mock dataset
- Generate visualizations
- Demonstrate the workflow

## Workflow Steps

### 1. Data Preparation
```
Large Image + Annotations → Cropped Images
                          ↓
              ┌───────────┴───────────┐
              ↓                       ↓
      True Positives          False Positives
      (defects/)              (background/)
         with bboxes            empty bboxes
```

### 2. Dataset Creation
```matlab
dataset = 
    imageFilename          myelinDefects
    'defects/defect_001.png'    [x, y, w, h]        % Has defect
    'defects/defect_002.png'    [x, y, w, h]        % Has defect
    'background/bg_001.png'     []                  % No defect (FP)
    'background/bg_002.png'     []                  % No defect (FP)
```

### 3. Transfer Learning
- Load pretrained model
- Fine-tune with new dataset (including FP as background)
- Lower learning rate (0.0001)
- Fewer epochs (50)
- Evaluate on test set

## Key Parameters

### Image Cropping
- `crop_size`: [width, height] of cropped windows (default: [128, 128])
- `overlap_ratio`: Overlap between crops (default: 0.5)

### Training Options
- `InitialLearnRate`: 0.0001 (lower for transfer learning)
- `MaxEpochs`: 50 (fewer than training from scratch)
- `MiniBatchSize`: 32
- `LearnRateDropPeriod`: 10 epochs
- `LearnRateDropFactor`: 0.5

## Output Files

### Dataset Preparation
```
output_dir/
├── defects/                           # True positive images
│   ├── defect_0001.png
│   ├── defect_0002.png
│   └── ...
├── background/                        # False positive images
│   ├── background_0001.png
│   ├── background_0002.png
│   └── ...
└── transfer_learning_dataset.mat     # Training dataset table
```

### Training Outputs
```
├── training_struct_transfer_[name].mat  # Trained model
├── training_loss_[name].png            # Loss curve
├── precision_recall_[name].png         # PR curve
└── augmented_samples_[name].png        # Sample images
```

## Performance Metrics

The code evaluates:
- **Average Precision (AP)**: Overall detection accuracy
- **Precision**: True Positives / (True Positives + False Positives)
- **Recall**: True Positives / (True Positives + False Negatives)
- **F1 Score**: Harmonic mean of precision and recall

## Iterative Improvement

For best results, use multiple iterations:

```matlab
% Iteration 1
dataset1 = prepare_transfer_learning_dataset(...);
model1 = train_yoloV4_transfer_learning(dataset1, pretrained_model, 'v1');

% Use model1 to detect on new images, manually mark FPs
% Create new annotations with bb_FP labels

% Iteration 2
dataset2 = prepare_transfer_learning_dataset(...); % New annotations
model2 = train_yoloV4_transfer_learning(dataset2, model1, 'v2');

% Repeat until performance is acceptable
```

## Requirements

### MATLAB Toolboxes
- Deep Learning Toolbox
- Computer Vision Toolbox
- Image Processing Toolbox

### Hardware
- GPU recommended (CUDA-compatible)
- Sufficient RAM for large images (16GB+ recommended)
- Storage for cropped images

## Troubleshooting

### "Out of memory" error
- Reduce `MiniBatchSize` in training options
- Use smaller `crop_size`
- Process fewer images at once

### "Cannot find detector" error
- Verify pretrained model path
- Check that model file contains 'detector' or 'training_struct.detector'

### Low performance
- Increase number of training samples
- Add more false positive examples
- Adjust confidence thresholds
- Run more training epochs

## Tips for Best Results

1. **Balance your dataset**: Aim for ~40-60% background samples
2. **Include diverse FPs**: Capture different types of false positives
3. **Use data augmentation**: Enabled by default (flips, color jitter, rotation)
4. **Monitor validation loss**: Stop if overfitting occurs
5. **Iterate**: Use human review to identify challenging FPs for next iteration

## Citation

Based on the methodology from:
- Paper: "Accelerating myelin defect detection in neurodegenerative disorders"
- Authors: Novoseltseva et al., Neurophotonics (2025)

## Contact

For questions or issues, please refer to the original paper or contact the authors.

---
**Note**: This implementation follows the human-in-the-loop approach described in the paper, where false positives are explicitly used as training data to reduce FP rates in subsequent iterations.
