function [crops, filenames] = crop_defects_random_optimized(img, bboxes, crop_size, output_dir, prefix, start_counter, max_shift_ratio)
% CROP_DEFECTS_RANDOM_OPTIMIZED - One crop per defect with random shift
%
% Creates ONE crop per defect with random positioning (not perfectly centered)
% Automatically includes ALL defects that fall within each crop
%
% Inputs:
%   img - Input image
%   bboxes - Bounding boxes [x, y, width, height]
%   crop_size - [width, height] of crops
%   output_dir - Where to save crops
%   prefix - Filename prefix
%   start_counter - Starting index for filenames
%   max_shift_ratio - Max random shift as ratio of crop_size (default: 0.3)
%                     e.g., 0.3 means ±30% shift from center
%
% Outputs:
%   crops - Cell array of crop structures with .image and .bboxes
%   filenames - Cell array of saved filenames
%
% Example:
%   [crops, files] = crop_defects_random_optimized(img, bboxes, [128,128], ...
%       './output', 'defect', 0, 0.25);

    if nargin < 7
        max_shift_ratio = 0.3;  % Default: ±30% of crop size
    end
    
    crops = {};
    filenames = {};
    counter = start_counter + 1;
    
    % Track which bboxes have been "primary" (centered on)
    processed_as_primary = false(size(bboxes, 1), 1);
    
    % Calculate max shift in pixels
    max_shift_x = round(crop_size(1) * max_shift_ratio);
    max_shift_y = round(crop_size(2) * max_shift_ratio);
    
    fprintf('  Creating crops with random shifts (max: ±%d pixels)\n', max_shift_x);
    
    % Process each defect as a primary defect
    for i = 1:size(bboxes, 1)
        bbox = bboxes(i, :);
        
        % Calculate defect center
        defect_center_x = bbox(1) + bbox(3)/2;
        defect_center_y = bbox(2) + bbox(4)/2;
        
        % Random shift from center
        shift_x = randi([-max_shift_x, max_shift_x]);
        shift_y = randi([-max_shift_y, max_shift_y]);
        
        % Calculate crop position (with random shift)
        crop_x = round(defect_center_x - crop_size(1)/2 + shift_x);
        crop_y = round(defect_center_y - crop_size(2)/2 + shift_y);
        
        % Ensure within image bounds
        crop_x = max(1, min(crop_x, size(img, 2) - crop_size(1) + 1));
        crop_y = max(1, min(crop_y, size(img, 1) - crop_size(2) + 1));
        
        % Define crop rectangle
        crop_rect = [crop_x, crop_y, crop_size(1), crop_size(2)];
        
        % Find ALL defects within this crop (not just the primary one)
        overlapping_bboxes = find_overlapping_bboxes(bboxes, crop_rect);
        
        if isempty(overlapping_bboxes)
            % Defect was shifted completely out - skip
            continue;
        end
        
        % Extract crop
        x_end = min(crop_x + crop_size(1) - 1, size(img, 2));
        y_end = min(crop_y + crop_size(2) - 1, size(img, 1));
        
        cropped_img = img(crop_y:y_end, crop_x:x_end, :);
        
        % Pad if necessary (edge cases)
        if size(cropped_img, 1) < crop_size(2) || size(cropped_img, 2) < crop_size(1)
            padded_img = zeros(crop_size(2), crop_size(1), size(img, 3), 'like', img);
            padded_img(1:size(cropped_img, 1), 1:size(cropped_img, 2), :) = cropped_img;
            cropped_img = padded_img;
        end
        
        % Convert bboxes to local coordinates
        local_bboxes = overlapping_bboxes;
        local_bboxes(:, 1) = local_bboxes(:, 1) - crop_x + 1;
        local_bboxes(:, 2) = local_bboxes(:, 2) - crop_y + 1;
        
        % Clip bboxes to crop boundaries
        local_bboxes = clip_bboxes_to_crop(local_bboxes, crop_size);
        
        if isempty(local_bboxes)
            continue;  % All defects were clipped out
        end
        
        % Save crop
        filename = fullfile(output_dir, sprintf('%s_%06d.png', prefix, counter));
        imwrite(cropped_img, filename);
        
        % Store crop info
        crops{end+1}.image = cropped_img;
        crops{end}.bboxes = local_bboxes;
        crops{end}.primary_defect = i;  % Track which defect was the "target"
        crops{end}.num_defects = size(local_bboxes, 1);
        crops{end}.shift = [shift_x, shift_y];
        
        filenames{end+1} = filename;
        
        processed_as_primary(i) = true;
        counter = counter + 1;
    end
    
    % Report statistics
    num_multi_defect = sum(cellfun(@(c) c.num_defects > 1, crops));
    total_defects_captured = sum(cellfun(@(c) c.num_defects, crops));
    
    fprintf('  Created %d crops\n', length(filenames));
    fprintf('  Crops with multiple defects: %d\n', num_multi_defect);
    fprintf('  Total defect instances: %d (from %d unique defects)\n', ...
        total_defects_captured, size(bboxes, 1));
    
    if total_defects_captured > size(bboxes, 1)
        fprintf('  Bonus: %d defects appear in multiple crops (natural overlap)\n', ...
            total_defects_captured - size(bboxes, 1));
    end
end

function overlapping_bboxes = find_overlapping_bboxes(bboxes, crop_rect)
    % Find all bboxes that overlap with crop rectangle
    
    overlapping_bboxes = [];
    
    if isempty(bboxes)
        return;
    end
    
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
        
        % Check for overlap (any intersection)
        if ~(bbox_x2 < crop_x1 || bbox_x1 > crop_x2 || ...
             bbox_y2 < crop_y1 || bbox_y1 > crop_y2)
            overlapping_bboxes = [overlapping_bboxes; bbox];
        end
    end
end

function clipped_bboxes = clip_bboxes_to_crop(bboxes, crop_size)
    % Clip bounding boxes to crop boundaries
    % Only keep bboxes that have at least 20% of original area remaining
    
    clipped_bboxes = [];
    
    for i = 1:size(bboxes, 1)
        bbox = bboxes(i, :);
        original_area = bbox(3) * bbox(4);
        
        x = bbox(1);
        y = bbox(2);
        w = bbox(3);
        h = bbox(4);
        
        % Clip to [1, crop_size]
        if x < 1
            w = w - (1 - x);
            x = 1;
        end
        
        if y < 1
            h = h - (1 - y);
            y = 1;
        end
        
        if x + w > crop_size(1)
            w = crop_size(1) - x + 1;
        end
        
        if y + h > crop_size(2)
            h = crop_size(2) - y + 1;
        end
        
        % Only keep if bbox has reasonable size remaining
        if w > 0 && h > 0
            clipped_area = w * h;
            if clipped_area >= 0.2 * original_area  % At least 20% visible
                clipped_bboxes = [clipped_bboxes; round([x, y, w, h])];
            end
        end
    end
end
