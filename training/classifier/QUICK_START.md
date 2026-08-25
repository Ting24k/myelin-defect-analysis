# QUICK START GUIDE

## What I've Created

A complete MATLAB implementation for YOLOv4 transfer learning that uses **false positives as background training samples** to reduce FP rates.

## 📦 Files Included

### 1. Core Functions (Use these in your workflow)

**prepare_transfer_learning_dataset.m**
- Input: Large image + annotation .mat file
- Output: Dataset with cropped images
- Separates TPs (defects) from FPs (background)

**train_yoloV4_transfer_learning.m**
- Input: Dataset + pretrained model
- Output: New trained model with FP awareness
- Implements transfer learning with lower LR

### 2. Complete Workflow Scripts

**main_transfer_learning_workflow.m**
- Full end-to-end pipeline
- Handles your actual large images
- UPDATE PATHS before running

**example_run_transfer_learning.m**
- Ready to run NOW with your uploaded annotation file
- Creates mock dataset for testing
- No image file needed
- Good for testing the code structure

## 🚀 Getting Started

### Immediate Test (No setup required)

Just run this in MATLAB:
```matlab
example_run_transfer_learning
```

This will:
✓ Load your uploaded annotation file
✓ Analyze the 241 detections (137 TPs, 104 FPs)
✓ Create mock dataset with 40 samples
✓ Generate visualizations
✓ Create summary report

**Location**: `./test_transfer_learning/`

### Full Workflow (With your real images)

1. **Edit main_transfer_learning_workflow.m**
   ```matlab
   % Line 18-19: UPDATE THESE
   image_path = 'AM332_S6B4.tif';  % Your large image
   pretrained_model_path = 'training_struct_SM080_SM077_128_RGBV2.mat';
   ```

2. **Run the workflow**
   ```matlab
   main_transfer_learning_workflow
   ```

3. **Results**
   - Dataset: `./transfer_learning_data/transfer_learning_dataset.mat`
   - Trained model: `training_struct_transfer_FP_aware_v1.mat`
   - Plots: training loss, precision-recall curves

## 📊 Your Data Summary

From the uploaded annotation file:
- Total detections: 241
- True Positives: 137 (56.8%) → Will become "defect" training images
- False Positives: 104 (43.2%) → Will become "background" training images

This is an excellent balance for training!

## 🎯 How It Addresses FP Rate

### Traditional Approach
```
FP detected → Discarded → Model never learns from mistake
```

### This Approach
```
FP detected → Labeled as background → Model learns "this is NOT a defect"
                  ↓
        Added to training set with empty bbox
                  ↓
        Model explicitly trained to avoid this pattern
```

## 🔄 Iterative Workflow

For best results, use multiple iterations:

```matlab
% === Iteration 1 ===
% Prepare dataset from your annotations
dataset1 = prepare_transfer_learning_dataset(...
    'image1.tif', 'annotations1.mat', './output1', [128,128], 0.5);

% Train model
model1 = train_yoloV4_transfer_learning(...
    dataset1, 'pretrained_model.mat', 'model_v1', 128);

% === Iteration 2 ===
% Use model1 to predict on new images
% Manually review predictions and mark FPs (bb_FP = 1)
% Create new annotation file

% Prepare new dataset with new FP examples
dataset2 = prepare_transfer_learning_dataset(...
    'image2.tif', 'annotations2.mat', './output2', [128,128], 0.5);

% Continue training from model1
model2 = train_yoloV4_transfer_learning(...
    dataset2, 'training_struct_transfer_model_v1.mat', 'model_v2', 128);

% Repeat 2-3 times until FP rate is acceptable
```

## 📈 Expected Results

Based on the paper's methodology:
- **Initial FP rate**: ~30% (common for object detectors)
- **After 1 iteration**: ~15-20% reduction
- **After 2-3 iterations**: ~11% FP rate (88.7% precision)

Your dataset with 43.2% FP samples is perfect for this approach!

## ⚙️ Key Parameters to Adjust

### Dataset Creation
```matlab
crop_size = [128, 128];    % Size of training images
overlap_ratio = 0.5;        % 50% overlap between crops
```

### Training
```matlab
InitialLearnRate = 0.0001;  % Low for transfer learning
MaxEpochs = 50;             % Fewer than training from scratch
MiniBatchSize = 32;         % Adjust based on GPU memory
```

## 🐛 Troubleshooting

### Issue: "Cannot find image file"
**Solution**: Update `image_path` in main script, or use `example_run_transfer_learning.m` for testing

### Issue: "Out of memory during training"
**Solution**: Reduce `MiniBatchSize` from 32 to 16 or 8

### Issue: "Deep Learning Toolbox not found"
**Solution**: Can still use dataset preparation functions; skip training step

### Issue: Training is too slow
**Solution**: 
- Ensure GPU is being used: `options.ExecutionEnvironment = 'gpu'`
- Reduce number of training samples
- Decrease MaxEpochs

## 📝 Expected Workflow Timeline

1. **Test run** (5 minutes): `example_run_transfer_learning.m`
2. **Dataset preparation** (10-30 min): Depends on image size
3. **Transfer learning** (1-2 hours): Depends on dataset size and GPU
4. **Evaluation** (5-10 min): Test on validation set

## 🎓 Understanding the Code

### Dataset Structure
```matlab
dataset = 
    imageFilename                    myelinDefects
    'defects/defect_0001.png'       [50, 60, 20, 15]  ← Bbox coordinates
    'defects/defect_0002.png'       [55, 65, 18, 20]
    'background/bg_0001.png'        []                 ← Empty = no defect
    'background/bg_0002.png'        []
```

### Key Difference from Standard Training
- Standard: Only positive examples (defects)
- This approach: Positive examples + **explicit negative examples** (FPs)

The model learns:
- "These patterns ARE defects" (from TPs)
- "These patterns are NOT defects" (from FPs) ← **KEY INNOVATION**

## 💡 Tips for Success

1. **Start with example script** to verify everything works
2. **Review FP examples** manually to understand what the model confuses
3. **Balance dataset**: Aim for 40-60% background samples
4. **Monitor validation loss**: Should decrease steadily
5. **Iterate 2-3 times** for best results

## 📧 Next Steps

1. Run `example_run_transfer_learning.m` to test
2. Prepare your large image file
3. Update paths in `main_transfer_learning_workflow.m`
4. Run full workflow
5. Evaluate results
6. Iterate with new FP examples

---

**Questions?** Check the detailed README.md for more information.

**Ready to start?** Run `example_run_transfer_learning` now!
