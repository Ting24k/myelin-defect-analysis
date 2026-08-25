% ROBOFLOW_CLASSIFIER_BATCH_CONFIG.m
% Configuration file for batch Roboflow classifier workflow
% Matches the style of your existing batch training workflow

clear; clc; close all;

%% ============ CONFIGURATION ============

% Option A: Manually specify image-annotation pairs
use_manual_pairs = false;  % Set to true to use manual specification

manual_pairs = {
    % Syntax: {'image_path', 'annotation_path'}
    {'./data/AM332_S6B4.tif', './data/AM332_S6B4_annotations_128.mat'};
    {'./data/AM333_S6B4.tif', './data/AM333_S6B4_annotations_128.mat'};
    {'./data/AM334_S6B4.tif', './data/AM334_S6B4_annotations_128.mat'};
};

% Option B: Or specify a directory and pattern
use_directory_search = true;  % Set to true to use this method

data_directory = './myelin_data';
image_pattern = '*.tif';
annotation_suffix = '_annotations_128.mat';

% Output settings
output_dir = './roboflow_classifier_data';
crop_size = [64, 64];  % Smaller for classification (64x64 works well)

%% ============ END CONFIGURATION ============

fprintf('========================================\n');
fprintf('   Roboflow Classifier Data Prep\n');
fprintf('   BATCH VERSION\n');
fprintf('========================================\n\n');

%% Step 1: Gather image-annotation pairs

fprintf('STEP 1: Gathering image-annotation pairs\n');
fprintf('--------------------------------------------------\n');

if use_manual_pairs
    % Use manually specified pairs
    image_annotation_pairs = manual_pairs;
    fprintf('Using manual pairs\n');
    
elseif use_directory_search
    % Automatically find pairs in directory
    fprintf('Searching directory: %s\n', data_directory);
    
    if ~exist(data_directory, 'dir')
        error('Directory not found: %s', data_directory);
    end
    
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
else
    error('Must enable either use_manual_pairs or use_directory_search');
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
    error('Some files not found. Please check paths.');
end

fprintf('✓ All files verified\n\n');

%% Step 2: Create output directories

fprintf('STEP 2: Creating output directories\n');
fprintf('--------------------------------------------------\n');

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

tp_dir = fullfile(output_dir, 'TRUE_POSITIVE');
fp_dir = fullfile(output_dir, 'FALSE_POSITIVE');

if ~exist(tp_dir, 'dir')
    mkdir(tp_dir);
end
if ~exist(fp_dir, 'dir')
    mkdir(fp_dir);
end

fprintf('Output directory: %s\n', output_dir);
fprintf('  TRUE_POSITIVE: %s\n', tp_dir);
fprintf('  FALSE_POSITIVE: %s\n\n', fp_dir);

%% Step 3: Process each image

fprintf('STEP 3: Processing images\n');
fprintf('--------------------------------------------------\n\n');

total_tp = 0;
total_fp = 0;
total_skipped = 0;

for pair_idx = 1:size(image_annotation_pairs, 1)
    fprintf('Processing pair %d/%d\n', pair_idx, size(image_annotation_pairs, 1));
    fprintf('==========================================\n');
    
    image_path = image_annotation_pairs{pair_idx, 1};
    annotation_path = image_annotation_pairs{pair_idx, 2};
    
    [~, img_name, ~] = fileparts(image_path);
    fprintf('Image: %s\n', img_name);
    
    % Load image
    try
        img = imread(image_path);
        fprintf('  Image size: %dx%d\n', size(img, 1), size(img, 2));
    catch ME
        warning('Failed to load image: %s', ME.message);
        continue;
    end
    
    % Load annotations
    try
        annot = load(annotation_path);
    catch ME
        warning('Failed to load annotations: %s', ME.message);
        continue;
    end
    
    % Extract bboxes and labels
    if isfield(annot, 'bb_detector')
        bboxes = annot.bb_detector;
    elseif isfield(annot, 'all_bboxes')
        bboxes = annot.all_bboxes;
    else
        warning('Cannot find bounding boxes in %s', annotation_path);
        continue;
    end
    
    if isfield(annot, 'bb_FP')
        is_fp = annot.bb_FP;
    else
        warning('Cannot find bb_FP labels in %s', annotation_path);
        continue;
    end
    
    if size(is_fp, 2) > 1
        is_fp = is_fp';
    end
    
    num_tp_in_image = sum(is_fp == 0);
    num_fp_in_image = sum(is_fp == 1);
    
    fprintf('  Detections: %d (TP: %d, FP: %d)\n', ...
        size(bboxes, 1), num_tp_in_image, num_fp_in_image);
    
    % Create crops for this image
    num_tp_created = 0;
    num_fp_created = 0;
    num_skipped_in_image = 0;
    
    for i = 1:size(bboxes, 1)
        bbox = bboxes(i, :);
        
        % Calculate center of detection
        center_x = bbox(1) + bbox(3)/2;
        center_y = bbox(2) + bbox(4)/2;
        
        % Calculate crop position (centered on detection)
        crop_x = round(center_x - crop_size(1)/2);
        crop_y = round(center_y - crop_size(2)/2);
        
        % Check bounds
        if crop_x < 1 || crop_y < 1 || ...
           crop_x + crop_size(1) - 1 > size(img, 2) || ...
           crop_y + crop_size(2) - 1 > size(img, 1)
            num_skipped_in_image = num_skipped_in_image + 1;
            continue;
        end
        
        % Extract crop
        crop = img(crop_y:crop_y+crop_size(2)-1, crop_x:crop_x+crop_size(1)-1, :);
        
        % Save to appropriate folder with unique filename
        if is_fp(i) == 0
            % True positive
            filename = fullfile(tp_dir, sprintf('%s_TP_%04d.png', img_name, num_tp_created + 1));
            imwrite(crop, filename);
            num_tp_created = num_tp_created + 1;
        else
            % False positive
            filename = fullfile(fp_dir, sprintf('%s_FP_%04d.png', img_name, num_fp_created + 1));
            imwrite(crop, filename);
            num_fp_created = num_fp_created + 1;
        end
    end
    
    fprintf('  Created: %d TPs, %d FPs\n', num_tp_created, num_fp_created);
    if num_skipped_in_image > 0
        fprintf('  Skipped: %d (out of bounds)\n', num_skipped_in_image);
    end
    
    total_tp = total_tp + num_tp_created;
    total_fp = total_fp + num_fp_created;
    total_skipped = total_skipped + num_skipped_in_image;
    
    fprintf('\n');
end

%% Step 4: Summary

fprintf('========================================\n');
fprintf('   SUMMARY\n');
fprintf('========================================\n\n');

fprintf('Images processed: %d\n', size(image_annotation_pairs, 1));
fprintf('Crop size: %dx%d pixels\n\n', crop_size(1), crop_size(2));

fprintf('Crops created:\n');
fprintf('  TRUE_POSITIVE: %d\n', total_tp);
fprintf('  FALSE_POSITIVE: %d\n', total_fp);
fprintf('  Total: %d\n', total_tp + total_fp);
fprintf('  Skipped (out of bounds): %d\n\n', total_skipped);

% Check class balance
if total_tp > 0 && total_fp > 0
    balance = min(total_tp, total_fp) / max(total_tp, total_fp);
    fprintf('Class balance: %.2f\n', balance);
    fprintf('  TRUE_POSITIVE: %.1f%%\n', 100*total_tp/(total_tp+total_fp));
    fprintf('  FALSE_POSITIVE: %.1f%%\n\n', 100*total_fp/(total_tp+total_fp));
    
    if balance < 0.5
        fprintf('⚠ WARNING: Imbalanced classes\n');
        fprintf('  Roboflow works best with 40-60%% of each class\n\n');
    else
        fprintf('✓ Classes are reasonably balanced\n\n');
    end
end

%% Step 5: Create visualization

fprintf('Creating sample visualization...\n');

try
    fig = figure('Position', [100, 100, 1400, 700]);
    
    % Show TP samples
    subplot(1, 2, 1);
    tp_files = dir(fullfile(tp_dir, '*.png'));
    if length(tp_files) >= 16
        montage_imgs = cell(16, 1);
        indices = round(linspace(1, length(tp_files), 16));
        for i = 1:16
            montage_imgs{i} = imread(fullfile(tp_dir, tp_files(indices(i)).name));
        end
        montage(montage_imgs, 'Size', [4, 4], 'BorderSize', 2);
        title(sprintf('TRUE POSITIVE (n=%d)', total_tp), 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    % Show FP samples
    subplot(1, 2, 2);
    fp_files = dir(fullfile(fp_dir, '*.png'));
    if length(fp_files) >= 16
        montage_imgs = cell(16, 1);
        indices = round(linspace(1, length(fp_files), 16));
        for i = 1:16
            montage_imgs{i} = imread(fullfile(fp_dir, fp_files(indices(i)).name));
        end
        montage(montage_imgs, 'Size', [4, 4], 'BorderSize', 2);
        title(sprintf('FALSE POSITIVE (n=%d)', total_fp), 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    sgtitle(sprintf('Classifier Data (%d images, %d samples)', ...
        size(image_annotation_pairs, 1), total_tp + total_fp), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    sample_file = fullfile(output_dir, 'sample_preview.png');
    saveas(fig, sample_file);
    close(gcf);
    
    fprintf('✓ Preview saved: %s\n\n', sample_file);
catch ME
    warning('Could not create visualization: %s', ME.message);
end

%% Step 6: Create README

fprintf('Creating README file...\n');

readme_file = fullfile(output_dir, 'README.txt');
fid = fopen(readme_file, 'w');

fprintf(fid, 'ROBOFLOW CLASSIFIER DATASET\n');
fprintf(fid, '===========================\n\n');
fprintf(fid, 'Dataset Type: Binary Classification\n');
fprintf(fid, 'Classes: TRUE_POSITIVE, FALSE_POSITIVE\n\n');
fprintf(fid, 'Statistics:\n');
fprintf(fid, '  Source images: %d\n', size(image_annotation_pairs, 1));
fprintf(fid, '  TRUE_POSITIVE: %d samples\n', total_tp);
fprintf(fid, '  FALSE_POSITIVE: %d samples\n', total_fp);
fprintf(fid, '  Total: %d samples\n\n', total_tp + total_fp);
fprintf(fid, 'Crop Size: %dx%d pixels\n\n', crop_size(1), crop_size(2));
fprintf(fid, 'Recommended Split: 70/20/10 (train/val/test)\n\n');
fprintf(fid, 'Next Steps:\n');
fprintf(fid, '1. Upload to https://roboflow.com\n');
fprintf(fid, '2. Create Classification project\n');
fprintf(fid, '3. Set 70/20/10 split\n');
fprintf(fid, '4. Enable augmentation\n');
fprintf(fid, '5. Train Fast-ViT model (20 min)\n');
fprintf(fid, '6. Get API key and Model ID\n');

fclose(fid);

fprintf('✓ README created\n\n');

%% Final instructions

fprintf('========================================\n');
fprintf('   READY FOR ROBOFLOW!\n');
fprintf('========================================\n\n');

fprintf('✓ Data prepared successfully\n');
fprintf('  Output: %s\n', output_dir);
fprintf('  Total samples: %d (%d TP, %d FP)\n\n', total_tp + total_fp, total_tp, total_fp);

fprintf('Next steps:\n');
fprintf('1. Go to https://roboflow.com\n');
fprintf('2. Create account (free)\n');
fprintf('3. New Project → Classification\n');
fprintf('4. Upload folder: %s\n', output_dir);
fprintf('5. Set split: 70/20/10\n');
fprintf('6. Enable augmentation (Flip, Rotate ±15°, Brightness ±15%%)\n');
fprintf('7. Train Fast-ViT (20 min)\n');
fprintf('8. Copy API key and Model ID\n');
fprintf('9. Use with two_stage_detection_workflow_batch.m\n\n');

fprintf('Expected performance:\n');
fprintf('  Training accuracy: >95%%\n');
fprintf('  FP reduction: 70-85%%\n\n');

fprintf('========================================\n');
