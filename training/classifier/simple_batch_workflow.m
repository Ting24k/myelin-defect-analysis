% SIMPLE_BATCH_WORKFLOW.m
% Easy-to-use script for batch processing multiple images
% Just update the configuration section and run!

%% ============ CONFIGURATION (UPDATE THIS) ============

% Option A: List your image-annotation pairs manually
% image_annotation_pairs = {
%     % Format: {'image_file', 'annotation_file'}
%     % Example:
%     % {'/path/to/image1.tif', '/path/to/image1_annotations.mat'};
%     % {'/path/to/image2.tif', '/path/to/image2_annotations.mat'};
% 
%     % Add your pairs here:
%     {'path/to/your/image1.tif', 'path/to/your/annotations1.mat'};
%     {'path/to/your/image2.tif', 'path/to/your/annotations2.mat'};
%     {'path/to/your/image3.tif', 'path/to/your/annotations3.mat'};
% };

% Option B: Or specify a directory and pattern
use_directory_search = true;  % Set to true to use this method
data_directory = './myelin_data';
image_pattern = '*.tif';
annotation_suffix = '_annotations_128.mat';

% Output settings
output_dir = './batch_training_dataset';
crop_size = [128, 128];
max_shift_ratio = 0.5;

% Pretrained model for transfer learning
pretrained_model_path = 'training_struct_SM080_SM077_128_RGBV2.mat';
new_model_name = 'batch_trained_model';

%% ============ END CONFIGURATION ============

%clear; clc; close all;

fprintf('========================================\n');
fprintf('   Batch Transfer Learning Workflow\n');
fprintf('========================================\n\n');

%% Step 1: Gather image-annotation pairs

fprintf('STEP 1: Gathering image-annotation pairs\n');
fprintf('----------------------------------------\n');

if use_directory_search
    % Automatically find pairs in directory
    fprintf('Searching directory: %s\n', data_directory);
    
    image_files = dir(fullfile(data_directory, image_pattern));
    image_annotation_pairs = {};
    
    for i = 1:length(image_files)
        img_path = fullfile(data_directory, image_files(i).name);
        
        % Construct annotation filename
        [~, base_name, ~] = fileparts(image_files(i).name);
        annot_name = [base_name, annotation_suffix];
        annot_path = fullfile(data_directory, annot_name);
        
        if exist(annot_path, 'file')
            image_annotation_pairs{end+1, 1} = img_path;
            image_annotation_pairs{end, 2} = annot_path;
            fprintf('  ✓ Found: %s\n', base_name);
        else
            warning('  ✗ Missing annotation for: %s', image_files(i).name);
        end
    end
end

% Display what we found
fprintf('\nTotal image-annotation pairs: %d\n', size(image_annotation_pairs, 1));

if size(image_annotation_pairs, 1) == 0
    error('No image-annotation pairs found. Please update the configuration.');
end

% Verify all files exist
fprintf('\nVerifying files...\n');
valid_pairs = true;
for i = 1:size(image_annotation_pairs, 1)
    if ~exist(image_annotation_pairs{i, 1}, 'file')
        warning('Image not found: %s', image_annotation_pairs{i, 1});
        valid_pairs = false;
    end
    if ~exist(image_annotation_pairs{i, 2}, 'file')
        warning('Annotation not found: %s', image_annotation_pairs{i, 2});
        valid_pairs = false;
    end
end

if ~valid_pairs
    fprintf('\n⚠ Some files not found. Running demo mode with mock data...\n\n');
    % Create demo data
    demo_dir = './demo_batch_data';
    if ~exist(demo_dir, 'dir'), mkdir(demo_dir); end
    image_annotation_pairs = create_quick_demo(demo_dir, 3);
end

%% Step 2: Prepare batch dataset

fprintf('\nSTEP 2: Preparing batch dataset\n');
fprintf('----------------------------------------\n');

try
    dataset = prepare_batch_dataset(...
        image_annotation_pairs, output_dir, crop_size, max_shift_ratio);
    
    fprintf('\n✓ Dataset created successfully!\n');
    
catch ME
    error('Failed to create dataset: %s', ME.message);
end

%% Step 3: Train with transfer learning

fprintf('\nSTEP 3: Training with transfer learning\n');
fprintf('----------------------------------------\n');

if ~exist(pretrained_model_path, 'file')
    fprintf('\n⚠ Pretrained model not found: %s\n', pretrained_model_path);
    fprintf('  Skipping training step.\n');
    fprintf('  You can train later using:\n');
    fprintf('    load(''%s'');\n', fullfile(output_dir, 'batch_transfer_learning_dataset.mat'));
    fprintf('    training_struct = train_yoloV4_transfer_learning(...\n');
    fprintf('        dataset, pretrained_model_path, ''%s'', %d);\n', ...
        new_model_name, crop_size(1));
else
    fprintf('Starting training...\n');
    fprintf('This may take 1-2 hours depending on dataset size.\n\n');
    
    try
        training_struct = train_yoloV4_transfer_learning(...
            dataset, pretrained_model_path, new_model_name, crop_size(1));
        
        fprintf('\n✓ Training completed!\n');
        fprintf('  Model: training_struct_transfer_%s.mat\n', new_model_name);
        fprintf('  Test AP: %.4f\n', training_struct.AveragePrecision);
        fprintf('  Training time: %.2f minutes\n', training_struct.training_time_minutes);
        
    catch ME
        warning('Training failed: %s', ME.message);
        fprintf('Dataset is ready and can be used with other training scripts.\n');
    end
end

%% Step 4: Summary

fprintf('\n========================================\n');
fprintf('   Workflow Complete!\n');
fprintf('========================================\n\n');

fprintf('Generated outputs:\n');
fprintf('1. Dataset: %s/batch_transfer_learning_dataset.mat\n', output_dir);
fprintf('2. Images: %s/defects/ and %s/background/\n', output_dir, output_dir);
fprintf('3. Visualizations: %s/batch_dataset_samples.png\n', output_dir);

if exist('training_struct', 'var')
    fprintf('4. Trained model: training_struct_transfer_%s.mat\n', new_model_name);
    fprintf('5. Training plots: training_loss_%s.png, precision_recall_%s.png\n', ...
        new_model_name, new_model_name);
end

fprintf('\nDataset statistics:\n');
fprintf('  Total samples: %d\n', height(dataset));
fprintf('  From %d source images\n', size(image_annotation_pairs, 1));

%% Helper function for demo

function pairs = create_quick_demo(output_dir, num_images)
    % Create quick demo data
    
    pairs = {};
    fprintf('Creating %d demo images...\n', num_images);
    
    for i = 1:num_images
        % Simple mock image
        img = uint8(randi([100, 200], 500, 500, 3));
        
        % Add texture
        for j = 1:5
            y = randi(500);
            for x = 1:500
                img(max(1, min(500, round(y + 30*sin(x/30)))), x, :) = 180;
            end
        end
        
        img_path = fullfile(output_dir, sprintf('demo_%d.tif', i));
        imwrite(img, img_path);
        
        % Mock annotations
        num_tp = randi([5, 10]);
        num_fp = randi([3, 8]);
        
        all_bboxes = [
            randi([50, 400], num_tp, 1), randi([50, 400], num_tp, 1), ...
            randi([10, 25], num_tp, 1), randi([10, 25], num_tp, 1);
            randi([50, 400], num_fp, 1), randi([50, 400], num_fp, 1), ...
            randi([10, 25], num_fp, 1), randi([10, 25], num_fp, 1)
        ];
        
        bb_FP = [zeros(num_tp, 1); ones(num_fp, 1)];
        all_scores = rand(num_tp + num_fp, 1) * 0.4 + 0.6;
        
        annot_path = fullfile(output_dir, sprintf('demo_%d_annotations_128.mat', i));
        save(annot_path, 'all_bboxes', 'bb_FP', 'all_scores');
        
        pairs{end+1, 1} = img_path;
        pairs{end, 2} = annot_path;
        
        fprintf('  Created demo_%d: %d TP, %d FP\n', i, num_tp, num_fp);
    end
end
