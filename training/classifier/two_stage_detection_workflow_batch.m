% TWO_STAGE_DETECTION_WORKFLOW_BATCH.m
% Apply two-stage pipeline to multiple images
% Stage 1: YOLOv4 detection
% Stage 2: Roboflow classification filtering

clear; clc; close all;

fprintf('========================================\n');
fprintf('   Two-Stage Detection Pipeline\n');
fprintf('   BATCH VERSION - Multiple Images\n');
fprintf('========================================\n\n');

%% ============ CONFIGURATION ============

% YOLOv4 Detector
DETECTOR_FILE = 'training_struct_SM080_SM077_128_RGBV2.mat';

% Roboflow Classifier
ROBOFLOW_API_KEY = '';  % Enter your API key
ROBOFLOW_MODEL_ID = '';  % e.g., 'myelin-classifier/1'

% Input images (Option A: Manual list)
use_manual_list = false;
manual_image_list = {
    './data/image1.tif';
    './data/image2.tif';
    './data/image3.tif';
};

% Input images (Option B: Directory search)
use_directory_search = true;
image_directory = './myelin_data';
image_pattern = '*.tif';

% Detection threshold
DETECTION_THRESHOLD = 0.3;

% Output directory
OUTPUT_DIR = './two_stage_results';

%% ============ END CONFIGURATION ============

%% Validate configuration

fprintf('STEP 1: Configuration\n');
fprintf('--------------------------------------------------\n');

if isempty(ROBOFLOW_API_KEY)
    ROBOFLOW_API_KEY = input('Enter Roboflow API key: ', 's');
    if isempty(ROBOFLOW_API_KEY)
        error('Roboflow API key required!');
    end
end

if isempty(ROBOFLOW_MODEL_ID)
    ROBOFLOW_MODEL_ID = input('Enter Roboflow model ID (e.g., myelin-classifier/1): ', 's');
    if isempty(ROBOFLOW_MODEL_ID)
        error('Roboflow model ID required!');
    end
end

fprintf('Configuration:\n');
fprintf('  YOLOv4 Model: %s\n', DETECTOR_FILE);
fprintf('  Roboflow Model: %s\n', ROBOFLOW_MODEL_ID);
fprintf('  Detection threshold: %.2f\n', DETECTION_THRESHOLD);
fprintf('  Output directory: %s\n\n', OUTPUT_DIR);

%% Gather images

fprintf('STEP 2: Gathering images\n');
fprintf('--------------------------------------------------\n');

if use_manual_list
    image_list = manual_image_list;
    fprintf('Using manual image list\n');
    
elseif use_directory_search
    fprintf('Searching directory: %s\n', image_directory);
    fprintf('Pattern: %s\n', image_pattern);
    
    if ~exist(image_directory, 'dir')
        error('Directory not found: %s', image_directory);
    end
    
    image_files = dir(fullfile(image_directory, image_pattern));
    image_list = {};
    
    for i = 1:length(image_files)
        image_list{end+1, 1} = fullfile(image_directory, image_files(i).name);
        fprintf('  ✓ Found: %s\n', image_files(i).name);
    end
else
    error('Must enable either use_manual_list or use_directory_search');
end

fprintf('\nTotal images: %d\n\n', length(image_list));

if isempty(image_list)
    error('No images found');
end

% Verify all files exist
fprintf('Verifying files...\n');
for i = 1:length(image_list)
    if ~exist(image_list{i}, 'file')
        error('Image not found: %s', image_list{i});
    end
end
fprintf('✓ All files verified\n\n');

%% Load detector

fprintf('STEP 3: Load YOLOv4 Detector\n');
fprintf('--------------------------------------------------\n');

if ~exist(DETECTOR_FILE, 'file')
    error('Detector file not found: %s', DETECTOR_FILE);
end

detector_data = load(DETECTOR_FILE);

if isfield(detector_data, 'training_struct')
    detector = detector_data.training_struct.detector;
elseif isfield(detector_data, 'detector')
    detector = detector_data.detector;
else
    error('Cannot find detector in file');
end

fprintf('✓ YOLOv4 detector loaded\n\n');

%% Create output directory

if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
end

%% Process each image

fprintf('STEP 4: Processing images\n');
fprintf('--------------------------------------------------\n\n');

results_summary = struct();
total_stage1_detections = 0;
total_final_detections = 0;
total_fp_removed = 0;
total_time_stage1 = 0;
total_time_stage2 = 0;

for img_idx = 1:length(image_list)
    fprintf('Processing image %d/%d\n', img_idx, length(image_list));
    fprintf('==========================================\n');
    
    image_path = image_list{img_idx};
    [~, img_name, ~] = fileparts(image_path);
    
    fprintf('Image: %s\n', img_name);
    
    % Load image
    try
        img = imread(image_path);
        fprintf('  Size: %dx%d\n', size(img, 1), size(img, 2));
    catch ME
        warning('Failed to load image: %s', ME.message);
        continue;
    end
    
    % Stage 1: YOLOv4 Detection
    fprintf('  Stage 1: YOLOv4 detection...\n');
    tic;
    [bboxes, scores, labels] = detect(detector, img, 'Threshold', DETECTION_THRESHOLD);
    stage1_time = toc;
    
    fprintf('    Detections: %d (%.2fs)\n', size(bboxes, 1), stage1_time);
    
    if isempty(bboxes)
        fprintf('    No detections\n');
        
        % Save result
        results_summary(img_idx).image = img_name;
        results_summary(img_idx).stage1_detections = 0;
        results_summary(img_idx).final_detections = 0;
        results_summary(img_idx).fp_removed = 0;
        results_summary(img_idx).stage1_time = stage1_time;
        results_summary(img_idx).stage2_time = 0;
        
        fprintf('\n');
        continue;
    end
    
    % Stage 2: Roboflow Classification
    fprintf('  Stage 2: Roboflow classification...\n');
    tic;
    [filtered_bboxes, filtered_scores, all_labels, classifier_scores] = ...
        apply_classifier_filter(img, bboxes, scores, ROBOFLOW_API_KEY, ROBOFLOW_MODEL_ID);
    stage2_time = toc;
    
    num_fp_removed = size(bboxes, 1) - size(filtered_bboxes, 1);
    
    fprintf('    Classified as TP: %d\n', size(filtered_bboxes, 1));
    fprintf('    Classified as FP: %d (removed)\n', num_fp_removed);
    fprintf('    Processing time: %.2fs\n', stage2_time);
    
    % Update totals
    total_stage1_detections = total_stage1_detections + size(bboxes, 1);
    total_final_detections = total_final_detections + size(filtered_bboxes, 1);
    total_fp_removed = total_fp_removed + num_fp_removed;
    total_time_stage1 = total_time_stage1 + stage1_time;
    total_time_stage2 = total_time_stage2 + stage2_time;
    
    % Save result
    results_summary(img_idx).image = img_name;
    results_summary(img_idx).stage1_detections = size(bboxes, 1);
    results_summary(img_idx).final_detections = size(filtered_bboxes, 1);
    results_summary(img_idx).fp_removed = num_fp_removed;
    results_summary(img_idx).stage1_time = stage1_time;
    results_summary(img_idx).stage2_time = stage2_time;
    results_summary(img_idx).bboxes_all = bboxes;
    results_summary(img_idx).bboxes_filtered = filtered_bboxes;
    results_summary(img_idx).scores_all = scores;
    results_summary(img_idx).scores_filtered = filtered_scores;
    results_summary(img_idx).classifier_labels = all_labels;
    
    % Save visualization
    fprintf('  Creating visualization...\n');
    
    fig = figure('Visible', 'off', 'Position', [100, 100, 1800, 600]);
    
    % Stage 1: All detections
    subplot(1, 3, 1);
    imshow(img);
    hold on;
    for i = 1:size(bboxes, 1)
        rectangle('Position', bboxes(i, :), 'EdgeColor', 'yellow', 'LineWidth', 2);
    end
    title(sprintf('Stage 1: YOLOv4 (%d)', size(bboxes, 1)), ...
        'FontSize', 14, 'FontWeight', 'bold');
    hold off;
    
    % Stage 2: Classifier decisions
    subplot(1, 3, 2);
    imshow(img);
    hold on;
    for i = 1:size(bboxes, 1)
        if strcmp(all_labels{i}, 'TP')
            color = 'green';
        else
            color = 'red';
        end
        rectangle('Position', bboxes(i, :), 'EdgeColor', color, 'LineWidth', 2);
    end
    title('Stage 2: Classification (G=TP, R=FP)', ...
        'FontSize', 14, 'FontWeight', 'bold');
    hold off;
    
    % Final: Filtered results
    subplot(1, 3, 3);
    imshow(img);
    hold on;
    for i = 1:size(filtered_bboxes, 1)
        rectangle('Position', filtered_bboxes(i, :), 'EdgeColor', 'cyan', 'LineWidth', 3);
    end
    title(sprintf('Final: Filtered (%d)', size(filtered_bboxes, 1)), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Color', 'blue');
    hold off;
    
    sgtitle(sprintf('%s - FP Removed: %d', img_name, num_fp_removed), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    vis_file = fullfile(OUTPUT_DIR, sprintf('results_%s.png', img_name));
    saveas(fig, vis_file);
    close(fig);
    
    fprintf('    Saved: %s\n', vis_file);
    fprintf('\n');
end

%% Overall summary

fprintf('========================================\n');
fprintf('   OVERALL SUMMARY\n');
fprintf('========================================\n\n');

fprintf('Images processed: %d\n', length(image_list));
fprintf('Output directory: %s\n\n', OUTPUT_DIR);

fprintf('Stage 1 (YOLOv4):\n');
fprintf('  Total detections: %d\n', total_stage1_detections);
fprintf('  Avg per image: %.1f\n', total_stage1_detections / length(image_list));
fprintf('  Total time: %.2f seconds\n', total_time_stage1);
fprintf('  Avg time: %.2f seconds/image\n\n', total_time_stage1 / length(image_list));

fprintf('Stage 2 (Classifier):\n');
fprintf('  Final detections: %d\n', total_final_detections);
fprintf('  FP removed: %d\n', total_fp_removed);
fprintf('  FP reduction: %.1f%%\n', 100*total_fp_removed/total_stage1_detections);
fprintf('  Total time: %.2f seconds\n', total_time_stage2);
fprintf('  Avg time: %.2f seconds/image\n\n', total_time_stage2 / length(image_list));

fprintf('Overall:\n');
fprintf('  Total time: %.2f seconds\n', total_time_stage1 + total_time_stage2);
fprintf('  Time per image: %.2f seconds\n\n', ...
    (total_time_stage1 + total_time_stage2) / length(image_list));

%% Per-image table

fprintf('========================================\n');
fprintf('   Per-Image Results\n');
fprintf('========================================\n\n');

fprintf('%-30s %10s %10s %10s %10s\n', ...
    'Image', 'Stage1', 'Final', 'FP Removed', 'FP Reduction');
fprintf('%-30s %10s %10s %10s %10s\n', ...
    repmat('-', 1, 30), '------', '-----', '----------', '------------');

for i = 1:length(results_summary)
    if results_summary(i).stage1_detections > 0
        fp_reduction = 100 * results_summary(i).fp_removed / results_summary(i).stage1_detections;
    else
        fp_reduction = 0;
    end
    
    fprintf('%-30s %10d %10d %10d %10.1f%%\n', ...
        results_summary(i).image, ...
        results_summary(i).stage1_detections, ...
        results_summary(i).final_detections, ...
        results_summary(i).fp_removed, ...
        fp_reduction);
end

fprintf('%-30s %10s %10s %10s %10s\n', ...
    repmat('-', 1, 30), '------', '-----', '----------', '------------');
fprintf('%-30s %10d %10d %10d %10.1f%%\n', ...
    'TOTAL', ...
    total_stage1_detections, ...
    total_final_detections, ...
    total_fp_removed, ...
    100*total_fp_removed/total_stage1_detections);

fprintf('\n');

%% Save results

fprintf('Saving results...\n');

results_file = fullfile(OUTPUT_DIR, 'batch_results.mat');
save(results_file, 'results_summary', 'total_stage1_detections', ...
    'total_final_detections', 'total_fp_removed');

fprintf('✓ Results saved: %s\n\n', results_file);

% Save summary CSV
csv_file = fullfile(OUTPUT_DIR, 'batch_results.csv');
fid = fopen(csv_file, 'w');
fprintf(fid, 'Image,Stage1_Detections,Final_Detections,FP_Removed,FP_Reduction_Percent\n');
for i = 1:length(results_summary)
    if results_summary(i).stage1_detections > 0
        fp_reduction = 100 * results_summary(i).fp_removed / results_summary(i).stage1_detections;
    else
        fp_reduction = 0;
    end
    fprintf(fid, '%s,%d,%d,%d,%.1f\n', ...
        results_summary(i).image, ...
        results_summary(i).stage1_detections, ...
        results_summary(i).final_detections, ...
        results_summary(i).fp_removed, ...
        fp_reduction);
end
fclose(fid);

fprintf('✓ CSV saved: %s\n\n', csv_file);

%% Done

fprintf('========================================\n');
fprintf('   Batch Processing Complete!\n');
fprintf('========================================\n\n');

fprintf('Output files:\n');
fprintf('  1. Visualizations: %s/results_*.png\n', OUTPUT_DIR);
fprintf('  2. Results data: %s\n', results_file);
fprintf('  3. Summary CSV: %s\n', csv_file);
fprintf('\nTwo-stage pipeline successfully applied to %d images!\n', length(image_list));
fprintf('Average FP reduction: %.1f%%\n', 100*total_fp_removed/total_stage1_detections);
