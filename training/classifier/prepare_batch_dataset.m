function dataset = prepare_batch_dataset(image_annotation_pairs, output_dir, crop_size, max_shift_ratio)
% PREPARE_BATCH_DATASET_V2 - Updated with optimized cropping strategy
%
% Key improvements:
%   - ONE crop per defect with random shift (not centered)
%   - Automatically captures ALL defects within each crop
%   - Background crops verified to be defect-free
%   - More efficient dataset generation
%
% Inputs:
%   image_annotation_pairs - Cell array of {image_path, annotation_path} pairs
%   output_dir - Directory to save cropped images and dataset
%   crop_size - Size of cropped windows [width, height] (default: [128, 128])
%   max_shift_ratio - Max random shift as ratio of crop_size (default: 0.3)
%
% Example:
%   pairs = {
%       {'image1.tif', 'annot1.mat'};
%       {'image2.tif', 'annot2.mat'};
%   };
%   dataset = prepare_batch_dataset_v2(pairs, './output', [128, 128], 0.25);

    if nargin < 3
        crop_size = [128, 128];
    end
    if nargin < 4
        max_shift_ratio = 0.3;  % ±30% shift from center
    end
    
    fprintf('==================================================\n');
    fprintf('   Batch Dataset Preparation V2\n');
    fprintf('   Optimized Random Cropping Strategy\n');
    fprintf('==================================================\n');
    fprintf('Number of image-annotation pairs: %d\n', size(image_annotation_pairs, 1));
    fprintf('Crop size: %dx%d\n', crop_size(1), crop_size(2));
    fprintf('Max random shift: ±%.0f%% (±%d pixels)\n', ...
        max_shift_ratio*100, round(crop_size(1)*max_shift_ratio));
    fprintf('Output directory: %s\n\n', output_dir);
    
    % Create output directories
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    defect_dir = fullfile(output_dir, 'defects');
    background_dir = fullfile(output_dir, 'background');
    if ~exist(defect_dir, 'dir')
        mkdir(defect_dir);
    end
    if ~exist(background_dir, 'dir')
        mkdir(background_dir);
    end
    
    % Initialize combined dataset
    all_imageFilenames = {};
    all_defectBboxes = {};
    
    % Statistics tracking
    total_tp = 0;
    total_fp = 0;
    total_defect_crops = 0;
    total_background_crops = 0;
    total_multi_defect_crops = 0;
    total_contaminated_skipped = 0;
    
    % Process each image-annotation pair
    for idx = 1:size(image_annotation_pairs, 1)
        fprintf('\n--------------------------------------------------\n');
        fprintf('Processing pair %d of %d\n', idx, size(image_annotation_pairs, 1));
        fprintf('--------------------------------------------------\n');
        
        image_path = image_annotation_pairs{idx, 1};
        annotation_path = image_annotation_pairs{idx, 2};
        
        % Verify files exist
        if ~exist(image_path, 'file')
            warning('Image file not found: %s (skipping)', image_path);
            continue;
        end
        if ~exist(annotation_path, 'file')
            warning('Annotation file not found: %s (skipping)', annotation_path);
            continue;
        end
        
        fprintf('Image: %s\n', image_path);
        fprintf('Annotations: %s\n', annotation_path);
        
        % Load image
        fprintf('Loading image...\n');
        try
            img = imread(image_path);
            fprintf('  Size: %dx%d\n', size(img, 1), size(img, 2));
        catch ME
            warning('Failed to load image: %s (skipping)', ME.message);
            continue;
        end
        
        % Load annotations
        fprintf('Loading annotations...\n');
        try
            annot_data = load(annotation_path);
        catch ME
            warning('Failed to load annotations: %s (skipping)', ME.message);
            continue;
        end
        
        % Extract data
        [bboxes, is_fp, scores] = extract_annotation_data(annot_data);
        
        fprintf('  Total detections: %d\n', size(bboxes, 1));
        fprintf('  True positives: %d\n', sum(is_fp == 0));
        fprintf('  False positives: %d\n', sum(is_fp == 1));
        
        % Update totals
        total_tp = total_tp + sum(is_fp == 0);
        total_fp = total_fp + sum(is_fp == 1);
        
        % Separate TP and FP
        tp_indices = find(is_fp == 0);
        fp_indices = find(is_fp == 1);
        
        tp_bboxes = bboxes(tp_indices, :);
        fp_bboxes = bboxes(fp_indices, :);
        
        % Create unique prefix for this image
        [~, img_name, ~] = fileparts(image_path);
        prefix_defect = sprintf('%s_defect', img_name);
        prefix_background = sprintf('%s_bg', img_name);
        
        % Process true positives with optimized random cropping
        fprintf('Processing true positives (random shift + multi-defect)...\n');
        if ~isempty(tp_bboxes)
            [defect_crops, defect_files] = crop_defects_random_optimized(...
                img, tp_bboxes, crop_size, defect_dir, prefix_defect, ...
                total_defect_crops, max_shift_ratio);
            
            fprintf('  Created %d defect crops\n', length(defect_files));
            
            % Count multi-defect crops
            num_multi = sum(cellfun(@(c) c.num_defects > 1, defect_crops));
            if num_multi > 0
                fprintf('  Multi-defect crops: %d (bonus coverage!)\n', num_multi);
            end
            
            total_defect_crops = total_defect_crops + length(defect_files);
            total_multi_defect_crops = total_multi_defect_crops + num_multi;
            
            % Add to dataset
            for i = 1:length(defect_files)
                all_imageFilenames{end+1, 1} = defect_files{i};
                all_defectBboxes{end+1, 1} = defect_crops{i}.bboxes;
            end
        else
            fprintf('  No true positives to process\n');
        end
        
        % Process false positives as background (with defect verification)
        fprintf('Processing false positives (verified defect-free background)...\n');
        if ~isempty(fp_bboxes)
            [background_crops, background_files, num_skipped] = ...
                crop_background_defect_free(...
                    img, fp_bboxes, tp_bboxes, crop_size, background_dir, ...
                    prefix_background, total_background_crops, max_shift_ratio);
            
            fprintf('  Created %d background crops\n', length(background_files));
            if num_skipped > 0
                fprintf('  Skipped %d contaminated crops (contained defects)\n', num_skipped);
            end
            
            total_background_crops = total_background_crops + length(background_files);
            total_contaminated_skipped = total_contaminated_skipped + num_skipped;
            
            % Add to dataset
            for i = 1:length(background_files)
                all_imageFilenames{end+1, 1} = background_files{i};
                all_defectBboxes{end+1, 1} = zeros(0, 4); % Empty bbox
            end
        else
            fprintf('  No false positives to process\n');
        end
    end
    
    % Create final dataset table
    fprintf('\n==================================================\n');
    fprintf('   Creating Final Dataset\n');
    fprintf('==================================================\n');
    
    dataset = table(all_imageFilenames, all_defectBboxes, ...
        'VariableNames', {'imageFilename', 'myelinDefects'});
    
    % Save dataset
    dataset_file = fullfile(output_dir, 'batch_dataset_v2.mat');
    save(dataset_file, 'dataset');
    
    % Display final statistics
    fprintf('\nDataset Summary:\n');
    fprintf('--------------------------------------------------\n');
    fprintf('Source Statistics:\n');
    fprintf('  Images processed: %d\n', size(image_annotation_pairs, 1));
    fprintf('  Total true positives: %d\n', total_tp);
    fprintf('  Total false positives: %d\n', total_fp);
    fprintf('\nGenerated Dataset:\n');
    fprintf('  Total samples: %d\n', height(dataset));
    fprintf('  Defect crops: %d\n', total_defect_crops);
    fprintf('    Multi-defect crops: %d (%.1f%%)\n', ...
        total_multi_defect_crops, 100*total_multi_defect_crops/max(1,total_defect_crops));
    fprintf('  Background crops: %d (verified defect-free)\n', total_background_crops);
    fprintf('  Contaminated crops skipped: %d\n', total_contaminated_skipped);
    fprintf('  Dataset file: %s\n', dataset_file);
    fprintf('\nEfficiency:\n');
    fprintf('  Crops per defect: %.2f (vs ~6-10 with sliding window)\n', ...
        total_defect_crops / max(1, total_tp));
    fprintf('  Class balance: %.1f%% defects, %.1f%% background\n', ...
        100*total_defect_crops/height(dataset), ...
        100*total_background_crops/height(dataset));
    fprintf('==================================================\n');
    
    if total_contaminated_skipped > 0
        fprintf('\n✓ Background verification: %d contaminated crops excluded\n', ...
            total_contaminated_skipped);
    end
    if total_multi_defect_crops > 0
        fprintf('✓ Multi-defect capture: %d crops with multiple defects\n', ...
            total_multi_defect_crops);
    end
end

%% Helper functions

function [crops, filenames, num_skipped] = crop_background_defect_free(...
    img, fp_bboxes, tp_bboxes, crop_size, output_dir, prefix, start_counter, max_shift_ratio)
    % Crop background regions with random shift, ensuring no real defects
    
    crops = {};
    filenames = {};
    num_skipped = 0;
    counter = start_counter + 1;
    
    if isempty(fp_bboxes)
        return;
    end
    
    max_shift_x = round(crop_size(1) * max_shift_ratio);
    max_shift_y = round(crop_size(2) * max_shift_ratio);
    
    for i = 1:size(fp_bboxes, 1)
        fp_bbox = fp_bboxes(i, :);
        
        % Calculate center
        center_x = fp_bbox(1) + fp_bbox(3)/2;
        center_y = fp_bbox(2) + fp_bbox(4)/2;
        
        % Random shift
        shift_x = randi([-max_shift_x, max_shift_x]);
        shift_y = randi([-max_shift_y, max_shift_y]);
        
        crop_x = round(center_x - crop_size(1)/2 + shift_x);
        crop_y = round(center_y - crop_size(2)/2 + shift_y);
        
        % Ensure bounds
        crop_x = max(1, min(crop_x, size(img, 2) - crop_size(1) + 1));
        crop_y = max(1, min(crop_y, size(img, 1) - crop_size(2) + 1));
        
        crop_rect = [crop_x, crop_y, crop_size(1), crop_size(2)];
        
        % CRITICAL: Check if contains any true positive defects
        overlapping_tp = find_overlapping_bboxes(tp_bboxes, crop_rect);
        
        if ~isempty(overlapping_tp)
            % Contains real defects - SKIP!
            num_skipped = num_skipped + 1;
            continue;
        end
        
        % Safe to create background crop
        x_end = min(crop_x + crop_size(1) - 1, size(img, 2));
        y_end = min(crop_y + crop_size(2) - 1, size(img, 1));
        
        cropped_img = img(crop_y:y_end, crop_x:x_end, :);
        
        % Pad if necessary
        if size(cropped_img, 1) < crop_size(2) || size(cropped_img, 2) < crop_size(1)
            padded_img = zeros(crop_size(2), crop_size(1), size(img, 3), 'like', img);
            padded_img(1:size(cropped_img, 1), 1:size(cropped_img, 2), :) = cropped_img;
            cropped_img = padded_img;
        end
        
        % Save crop
        filename = fullfile(output_dir, sprintf('%s_%06d.png', prefix, counter));
        imwrite(cropped_img, filename);
        
        crops{end+1}.image = cropped_img;
        crops{end}.bboxes = zeros(0, 4);  % Empty = background
        filenames{end+1} = filename;
        
        counter = counter + 1;
    end
end

function [bboxes, is_fp, scores] = extract_annotation_data(annot_data)
    if isfield(annot_data, 'bb_detector')
        bboxes = annot_data.bb_detector;
    elseif isfield(annot_data, 'all_bboxes')
        bboxes = annot_data.all_bboxes;
    else
        error('Cannot find bounding box data');
    end
    
    if isfield(annot_data, 'bb_FP')
        is_fp = annot_data.bb_FP;
    else
        error('Cannot find bb_FP field');
    end
    
    if isfield(annot_data, 'all_scores')
        scores = annot_data.all_scores;
    else
        scores = ones(size(bboxes, 1), 1);
    end
    
    if size(is_fp, 2) > 1, is_fp = is_fp'; end
    if size(scores, 2) > 1, scores = scores'; end
end

function overlapping = find_overlapping_bboxes(bboxes, crop_rect)
    overlapping = [];
    if isempty(bboxes), return; end
    
    crop_x1 = crop_rect(1);
    crop_y1 = crop_rect(2);
    crop_x2 = crop_rect(1) + crop_rect(3);
    crop_y2 = crop_rect(2) + crop_rect(4);
    
    for i = 1:size(bboxes, 1)
        bbox = bboxes(i, :);
        bbox_x1 = bbox(1);
        bbox_y1 = bbox(2);
        bbox_x2 = bbox(1) + bbox(3);
        bbox_y2 = bbox(2) + bbox(4);
        
        if ~(bbox_x2 < crop_x1 || bbox_x1 > crop_x2 || ...
             bbox_y2 < crop_y1 || bbox_y1 > crop_y2)
            overlapping = [overlapping; bbox];
        end
    end
end
