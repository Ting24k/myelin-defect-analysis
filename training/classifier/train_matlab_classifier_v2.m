% TRAIN_MATLAB_CLASSIFIER.m
% Train your own binary classifier in MATLAB (no Roboflow needed)
% Uses the same data prepared for Roboflow

clear; clc; close all;

fprintf('========================================\n');
fprintf('   MATLAB Binary Classifier Training\n');
fprintf('   FREE Alternative to Roboflow\n');
fprintf('========================================\n\n');

%% Configuration

% Data directory (same as prepared for Roboflow)
DATA_DIR = './roboflow_classifier_data';

% Model settings
INPUT_SIZE = [64, 64, 3];  % Must match crop size from roboflow_classifier_batch_config.m
MODEL_TYPE = 'resnet50';   % Options: 'resnet18', 'resnet50', 'mobilenetv2', 'squeezenet'

% Data sampling (for large datasets)
MAX_SAMPLES_PER_CLASS = Inf;  % Maximum samples per class (set to Inf for no limit)

% Training settings
BATCH_SIZE = 32;
MAX_EPOCHS = 30;
LEARNING_RATE = 0.001;
VALIDATION_SPLIT = 0.2;

% Output
OUTPUT_MODEL = 'matlab_defect_classifier_resnet50.mat';

%% Step 1: Load Data

fprintf('STEP 1: Loading Data\n');
fprintf('--------------------------------------------------\n');

if ~exist(DATA_DIR, 'dir')
    error('Data directory not found: %s\nRun roboflow_classifier_batch_config.m first!', DATA_DIR);
end

fprintf('Looking for data in: %s\n', DATA_DIR);

% Check what's in the directory
dir_contents = dir(DATA_DIR);
fprintf('Directory contents:\n');
for i = 1:min(10, length(dir_contents))
    if dir_contents(i).isdir
        fprintf('  [DIR]  %s\n', dir_contents(i).name);
    else
        fprintf('  [FILE] %s\n', dir_contents(i).name);
    end
end
if length(dir_contents) > 10
    fprintf('  ... and %d more items\n', length(dir_contents) - 10);
end
fprintf('\n');

% Create image datastore
fprintf('Creating image datastore...\n');
imds = imageDatastore(DATA_DIR, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

fprintf('Total images: %d\n', numel(imds.Files));

% Check if this seems reasonable
if numel(imds.Files) > 5000
    fprintf('\n⚠ Large dataset detected (%d images)\n', numel(imds.Files));
    fprintf('Will randomly sample %d images per class for training.\n\n', 1000);
end

% Get unique classes
class_names = categories(imds.Labels);
fprintf('Classes: %s\n', strjoin(string(class_names), ', '));

% Show class distribution
label_counts = countEachLabel(imds);
disp(label_counts);

% Filter to only TRUE_POSITIVE and FALSE_POSITIVE classes
valid_classes = {'TRUE_POSITIVE', 'FALSE_POSITIVE'};
idx_valid = ismember(imds.Labels, valid_classes);

if sum(~idx_valid) > 0
    fprintf('\n⚠ Found %d images with unexpected labels. Removing them...\n', sum(~idx_valid));
    imds = subset(imds, find(idx_valid));
    
    % CRITICAL: Remove unused categories from the categorical array
    imds.Labels = removecats(imds.Labels);
    
    % Recount after filtering
    label_counts = countEachLabel(imds);
    fprintf('\nAfter filtering:\n');
    disp(label_counts);
    
    % Verify we now have exactly 2 classes
    num_classes = length(categories(imds.Labels));
    fprintf('Number of classes: %d\n', num_classes);
    if num_classes ~= 2
        error('Expected 2 classes after filtering, but found %d', num_classes);
    end
end

% Extract class counts - simplified approach
% After filtering, we only have TRUE_POSITIVE and FALSE_POSITIVE
if height(label_counts) ~= 2
    error('Expected 2 classes after filtering, found %d', height(label_counts));
end

% Find which row is which class
for i = 1:height(label_counts)
    label_str = char(label_counts.Label(i));
    if strcmp(label_str, 'TRUE_POSITIVE')
        num_tp = label_counts.Count(i);
    elseif strcmp(label_str, 'FALSE_POSITIVE')
        num_fp = label_counts.Count(i);
    end
end

% Verify we got both
if ~exist('num_tp', 'var') || ~exist('num_fp', 'var')
    error('Could not extract class counts from table');
end

% Check class balance
balance = min(num_tp, num_fp) / max(num_tp, num_fp);
fprintf('\nClass balance: %.2f\n', balance);
fprintf('TRUE_POSITIVE: %d images\n', num_tp);
fprintf('FALSE_POSITIVE: %d images\n', num_fp);

if balance < 0.5
    warning('Imbalanced classes (%.0f%% / %.0f%%) - sampling will balance them', ...
        100*num_tp/(num_tp+num_fp), 100*num_fp/(num_tp+num_fp));
end

%% Randomly sample if too many images

if num_tp > MAX_SAMPLES_PER_CLASS || num_fp > MAX_SAMPLES_PER_CLASS
    fprintf('\n========================================\n');
    fprintf('   Random Sampling Large Dataset\n');
    fprintf('========================================\n\n');
    fprintf('Original dataset:\n');
    fprintf('  TRUE_POSITIVE: %d images\n', num_tp);
    fprintf('  FALSE_POSITIVE: %d images\n', num_fp);
    fprintf('  Total: %d images\n\n', num_tp + num_fp);
    
    fprintf('Randomly sampling up to %d images per class...\n', MAX_SAMPLES_PER_CLASS);
    fprintf('(This prevents overfitting and speeds up training)\n\n');
    
    % Split by class
    idx_tp = find(imds.Labels == 'TRUE_POSITIVE');
    idx_fp = find(imds.Labels == 'FALSE_POSITIVE');
    
    % Randomly sample with seed for reproducibility
    rng(42);
    
    % Sample TRUE_POSITIVE
    if length(idx_tp) > MAX_SAMPLES_PER_CLASS
        idx_tp_sample = idx_tp(randperm(length(idx_tp), MAX_SAMPLES_PER_CLASS));
        fprintf('  TRUE_POSITIVE: Sampled %d from %d\n', MAX_SAMPLES_PER_CLASS, length(idx_tp));
    else
        idx_tp_sample = idx_tp;
        fprintf('  TRUE_POSITIVE: Using all %d images\n', length(idx_tp));
    end
    
    % Sample FALSE_POSITIVE
    if length(idx_fp) > MAX_SAMPLES_PER_CLASS
        idx_fp_sample = idx_fp(randperm(length(idx_fp), MAX_SAMPLES_PER_CLASS));
        fprintf('  FALSE_POSITIVE: Sampled %d from %d\n', MAX_SAMPLES_PER_CLASS, length(idx_fp));
    else
        idx_fp_sample = idx_fp;
        fprintf('  FALSE_POSITIVE: Using all %d images\n', length(idx_fp));
    end
    
    % Combine sampled indices
    sampled_indices = [idx_tp_sample; idx_fp_sample];
    
    % Create new datastore with sampled images
    imds = subset(imds, sampled_indices);
    
    % Ensure no extra categories carried over
    imds.Labels = removecats(imds.Labels);
    
    % Show new counts
    fprintf('\nSampled dataset:\n');
    label_counts_new = countEachLabel(imds);
    disp(label_counts_new);
    
    % Verify exactly 2 classes
    if length(categories(imds.Labels)) ~= 2
        error('Expected 2 classes after sampling, found %d', length(categories(imds.Labels)));
    end
    
    % Update counts for subsequent steps
    num_tp = sum(imds.Labels == 'TRUE_POSITIVE');
    num_fp = sum(imds.Labels == 'FALSE_POSITIVE');
    
    fprintf('Total samples for training: %d\n', num_tp + num_fp);
    fprintf('========================================\n');
end

fprintf('\n');

%% Step 2: Split Data

fprintf('STEP 2: Splitting Data\n');
fprintf('--------------------------------------------------\n');

% Final verification: ensure exactly 2 classes
num_classes_final = length(categories(imds.Labels));
if num_classes_final ~= 2
    error('Training data has %d classes, expected 2. Classes: %s', ...
        num_classes_final, strjoin(string(categories(imds.Labels)), ', '));
end

% Split into train and validation
[imdsTrain, imdsValidation] = splitEachLabel(imds, 1-VALIDATION_SPLIT, 'randomized');

fprintf('Training samples: %d\n', numel(imdsTrain.Files));
fprintf('Validation samples: %d\n\n', numel(imdsValidation.Files));

%% Step 3: Data Augmentation

fprintf('STEP 3: Setting Up Data Augmentation\n');
fprintf('--------------------------------------------------\n');

% Define augmentation (similar to Roboflow)
imageAugmenter = imageDataAugmenter( ...
    'RandXReflection', true, ...           % Horizontal flip
    'RandRotation', [-15, 15], ...         % Rotation ±15°
    'RandXTranslation', [-5, 5], ...       # Small shifts
    'RandYTranslation', [-5, 5], ...
    'RandScale', [0.9, 1.1]);              % Slight zoom

% Create augmented image datastores
augmentedTrainingSet = augmentedImageDatastore(INPUT_SIZE, imdsTrain, ...
    'DataAugmentation', imageAugmenter);

augmentedValidationSet = augmentedImageDatastore(INPUT_SIZE, imdsValidation);

fprintf('Augmentation enabled:\n');
fprintf('  - Horizontal flip\n');
fprintf('  - Rotation: ±15°\n');
fprintf('  - Translation: ±5 pixels\n');
fprintf('  - Scale: 0.9-1.1x\n\n');

%% Step 4: Load/Create Network

fprintf('STEP 4: Creating Network\n');
fprintf('--------------------------------------------------\n');

% Check for Deep Learning Toolbox
if ~license('test', 'Neural_Network_Toolbox')
    error('Deep Learning Toolbox required. Consider using Roboflow or install toolbox.');
end

% Load pretrained network
fprintf('Loading pretrained %s...\n', MODEL_TYPE);

switch lower(MODEL_TYPE)
    case 'resnet18'
        net = resnet18;
        featureLayer = 'pool5';
        
    case 'resnet50'
        net = resnet50;
        featureLayer = 'avg_pool';
        
    case 'mobilenetv2'
        net = mobilenetv2;
        featureLayer = 'global_average_pooling2d_1';
        
    case 'squeezenet'
        net = squeezenet;
        featureLayer = 'pool10';
        
    otherwise
        error('Unknown model type: %s', MODEL_TYPE);
end

fprintf('Network: %s\n', MODEL_TYPE);
fprintf('Input size: %dx%dx%d\n\n', INPUT_SIZE);

%% Step 5: Modify Network for Binary Classification

fprintf('STEP 5: Modifying Network\n');
fprintf('--------------------------------------------------\n');

% Get layer graph
lgraph = layerGraph(net);

% Replace input layer to accept our input size (64×64 instead of 224×224)
inputLayer = imageInputLayer(INPUT_SIZE, 'Name', 'input_new', 'Normalization', 'zscore');
lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, inputLayer);

% Find and replace final layers
numClasses = 2;  % TRUE_POSITIVE, FALSE_POSITIVE

% Get the last few layers
lastLayerName = lgraph.Layers(end).Name;
secondLastLayerName = lgraph.Layers(end-1).Name;

% Find the fully connected layer (usually near the end)
fcLayerName = '';
for i = length(lgraph.Layers):-1:1
    if isa(lgraph.Layers(i), 'nnet.cnn.layer.FullyConnectedLayer')
        fcLayerName = lgraph.Layers(i).Name;
        break;
    end
end

if isempty(fcLayerName)
    error('Could not find fully connected layer in network');
end

% Create new layers for binary classification
newLayers = [
    fullyConnectedLayer(numClasses, 'Name', 'fc_binary', ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10)
    softmaxLayer('Name', 'softmax_binary')
    classificationLayer('Name', 'classoutput_binary')
];

% Replace FC layer
lgraph = replaceLayer(lgraph, fcLayerName, newLayers(1));

% Replace softmax layer
try
    lgraph = replaceLayer(lgraph, secondLastLayerName, newLayers(2));
catch
    % If softmax has different name, find it
    for i = length(lgraph.Layers):-1:1
        if isa(lgraph.Layers(i), 'nnet.cnn.layer.SoftmaxLayer')
            lgraph = replaceLayer(lgraph, lgraph.Layers(i).Name, newLayers(2));
            break;
        end
    end
end

% Replace classification layer
lgraph = replaceLayer(lgraph, lastLayerName, newLayers(3));

fprintf('Network modified for binary classification\n');
fprintf('Input size: %dx%dx%d (updated from 224×224)\n', INPUT_SIZE);
fprintf('Output classes: %d\n', numClasses);

% Verify input layer
inputLayerSize = lgraph.Layers(1).InputSize;
fprintf('✓ Input layer size: [%d %d %d]\n', inputLayerSize(1), inputLayerSize(2), inputLayerSize(3));

fprintf('\n');

%% Step 6: Training Options

fprintf('STEP 6: Setting Training Options\n');
fprintf('--------------------------------------------------\n');

options = trainingOptions('adam', ...
    'InitialLearnRate', LEARNING_RATE, ...
    'MaxEpochs', MAX_EPOCHS, ...
    'MiniBatchSize', BATCH_SIZE, ...
    'ValidationData', augmentedValidationSet, ...
    'ValidationFrequency', 10, ...
    'Shuffle', 'every-epoch', ...
    'Verbose', true, ...
    'VerboseFrequency', 10, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto');  % Uses GPU if available

fprintf('Training configuration:\n');
fprintf('  Learning rate: %g\n', LEARNING_RATE);
fprintf('  Max epochs: %d\n', MAX_EPOCHS);
fprintf('  Batch size: %d\n', BATCH_SIZE);
fprintf('  Validation split: %.1f%%\n\n', VALIDATION_SPLIT * 100);

%% Step 7: Train Network

fprintf('STEP 7: Training Network\n');
fprintf('--------------------------------------------------\n');
fprintf('This will take 10-20 minutes...\n\n');

tic;
[trainedNet, trainInfo] = trainNetwork(augmentedTrainingSet, lgraph, options);
training_time = toc;

fprintf('\n✓ Training complete!\n');
fprintf('  Time: %.1f minutes\n\n', training_time/60);

%% Step 8: Evaluate

fprintf('STEP 8: Evaluating Model\n');
fprintf('--------------------------------------------------\n');

% Classify validation set
YPred = classify(trainedNet, augmentedValidationSet);
YValidation = imdsValidation.Labels;

% Calculate accuracy
accuracy = sum(YPred == YValidation) / numel(YValidation);

fprintf('Validation Accuracy: %.2f%%\n\n', accuracy * 100);

% Confusion matrix
figure('Name', 'Confusion Matrix');
confusionchart(YValidation, YPred);
title(sprintf('Validation Accuracy: %.2f%%', accuracy * 100));

% Per-class metrics
tp_mask = YValidation == 'TRUE_POSITIVE';
fp_mask = YValidation == 'FALSE_POSITIVE';

tp_correct = sum(YPred(tp_mask) == 'TRUE_POSITIVE');
tp_total = sum(tp_mask);
fp_correct = sum(YPred(fp_mask) == 'FALSE_POSITIVE');
fp_total = sum(fp_mask);

fprintf('Per-Class Performance:\n');
fprintf('  TRUE_POSITIVE: %.1f%% (%d/%d)\n', 100*tp_correct/tp_total, tp_correct, tp_total);
fprintf('  FALSE_POSITIVE: %.1f%% (%d/%d)\n\n', 100*fp_correct/fp_total, fp_correct, fp_total);

%% Step 9: Save Model

fprintf('STEP 9: Saving Model\n');
fprintf('--------------------------------------------------\n');

% Save everything
classifier_model = struct();
classifier_model.network = trainedNet;
classifier_model.classes = trainedNet.Layers(end).Classes;
classifier_model.input_size = INPUT_SIZE;
classifier_model.accuracy = accuracy;
classifier_model.training_info = trainInfo;
classifier_model.training_time = training_time;
classifier_model.model_type = MODEL_TYPE;
classifier_model.date = datetime('now');

save(OUTPUT_MODEL, 'classifier_model', '-v7.3');

fprintf('✓ Model saved: %s\n', OUTPUT_MODEL);
fprintf('  Size: %.1f MB\n', dir(OUTPUT_MODEL).bytes / 1e6);
fprintf('  Accuracy: %.2f%%\n\n', accuracy * 100);

%% Step 10: Test Inference Speed

fprintf('STEP 10: Testing Inference Speed\n');
fprintf('--------------------------------------------------\n');

% Test on a few images
test_img = readimage(imdsValidation, 1);
test_img_resized = imresize(test_img, INPUT_SIZE(1:2));

% Warm-up
classify(trainedNet, test_img_resized);

% Benchmark
num_tests = 10;
times = zeros(num_tests, 1);
for i = 1:num_tests
    tic;
    [label, scores] = classify(trainedNet, test_img_resized);
    times(i) = toc;
end

avg_time = mean(times);
fprintf('Average inference time: %.3f seconds/image\n', avg_time);
fprintf('Throughput: %.1f images/second\n\n', 1/avg_time);

%% Summary

fprintf('========================================\n');
fprintf('   Training Complete!\n');
fprintf('========================================\n\n');

fprintf('Model Performance:\n');
fprintf('  Validation Accuracy: %.2f%%\n', accuracy * 100);
fprintf('  Training Time: %.1f minutes\n', training_time/60);
fprintf('  Inference Speed: %.3f s/image\n', avg_time);
fprintf('  Model Size: %.1f MB\n\n', dir(OUTPUT_MODEL).bytes / 1e6);

fprintf('Model saved: %s\n\n', OUTPUT_MODEL);

fprintf('Next Steps:\n');
fprintf('1. Test with apply_matlab_classifier.m\n');
fprintf('2. Compare performance to Roboflow\n');
fprintf('3. If good, deploy instead of Roboflow API\n\n');

fprintf('Expected Performance:\n');
if accuracy > 0.92
    fprintf('  ✓ Excellent! (>92%% accuracy)\n');
    fprintf('  Ready for deployment\n');
elseif accuracy > 0.85
    fprintf('  ✓ Good (85-92%% accuracy)\n');
    fprintf('  Consider more training data or epochs\n');
else
    fprintf('  ⚠ Could be better (<85%% accuracy)\n');
    fprintf('  Recommendations:\n');
    fprintf('    - Add more training data\n');
    fprintf('    - Try different model (ResNet50)\n');
    fprintf('    - Increase epochs\n');
    fprintf('    - Check for mislabeled data\n');
end

fprintf('\n========================================\n');
