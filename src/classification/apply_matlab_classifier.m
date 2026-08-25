function [filtered_bboxes, filtered_scores, filtered_labels, classifier_scores, tp_mask] = apply_matlab_classifier(img, bboxes, scores, matlab_model_path)
% APPLY_MATLAB_CLASSIFIER - Use MATLAB-trained classifier (free alternative to Roboflow)
%
% Two-stage detection pipeline using local MATLAB model:
%   Stage 1: YOLOv4 detector finds potential defects
%   Stage 2: MATLAB classifier filters false positives (NO API CALLS!)
%
% Inputs:
%   img - Image to process
%   bboxes - Bounding boxes from YOLOv4 [N x 4]
%   scores - Detection scores from YOLOv4 [N x 1]
%   matlab_model_path - Path to trained MATLAB classifier (.mat file)
%
% Outputs:
%   filtered_bboxes - Filtered bounding boxes (only TPs)
%   filtered_scores - Corresponding scores
%   filtered_labels - All original labels
%   classifier_scores - Classifier confidence for each detection
%
% Example:
%   [bboxes, scores] = detect(detector, img);
%   [filtered_bboxes, filtered_scores] = apply_matlab_classifier(...
%       img, bboxes, scores, 'matlab_defect_classifier.mat');

    fprintf('Applying MATLAB classifier filter...\n');
    fprintf('  Initial detections: %d\n', size(bboxes, 1));
    
    if isempty(bboxes)
        filtered_bboxes = [];
        filtered_scores = [];
        filtered_labels = {};
        classifier_scores = [];
        return;
    end
    
    % Load MATLAB classifier model
    if ~exist(matlab_model_path, 'file')
        error('Model file not found: %s', matlab_model_path);
    end
    
    fprintf('  Loading model: %s\n', matlab_model_path);
    model_data = load(matlab_model_path);
    
    if isfield(model_data, 'classifier_model')
        trained_net = model_data.classifier_model.network;
        input_size = model_data.classifier_model.input_size;
        class_names = model_data.classifier_model.classes;
    else
        error('Invalid model file format');
    end
    
    % Crop size (must match training)
    crop_size = input_size(1:2);
    
    % Initialize outputs
    classifier_scores = zeros(size(bboxes, 1), 1);
    classifier_labels = cell(size(bboxes, 1), 1);
    
    % Process each detection
    fprintf('  Classifying detections...\n');
    for i = 1:size(bboxes, 1)
        bbox = bboxes(i, :);
        
        % Calculate crop centered on detection
        center_x = bbox(1) + bbox(3)/2;
        center_y = bbox(2) + bbox(4)/2;
        
        crop_x = round(center_x - crop_size(1)/2);
        crop_y = round(center_y - crop_size(2)/2);
        
        % Bounds check
        crop_x = max(1, min(crop_x, size(img, 2) - crop_size(1) + 1));
        crop_y = max(1, min(crop_y, size(img, 1) - crop_size(2) + 1));
        
        % Extract crop
        crop = img(crop_y:crop_y+crop_size(2)-1, crop_x:crop_x+crop_size(1)-1, :);
        
        % Classify crop
        try
            [predicted_label, prediction_scores] = classify(trained_net, crop);
            
            % Extract confidence
            if strcmp(char(predicted_label), 'TRUE_POSITIVE')
                classifier_labels{i} = 'TP';
                % Get score for TRUE_POSITIVE class
                tp_idx = find(class_names == 'TRUE_POSITIVE');
                classifier_scores(i) = prediction_scores(tp_idx);
            else
                classifier_labels{i} = 'FP';
                % Get score for FALSE_POSITIVE class
                fp_idx = find(class_names == 'FALSE_POSITIVE');
                classifier_scores(i) = prediction_scores(fp_idx);
            end
        catch ME
            warning('Classification failed for detection %d: %s', i, ME.message);
            classifier_labels{i} = 'UNKNOWN';
            classifier_scores(i) = 0.5;
        end
        
        if mod(i, 10) == 0
            fprintf('    Classified %d/%d detections...\n', i, size(bboxes, 1));
        end
    end
    
    % Filter: keep only TRUE_POSITIVE
    tp_mask = strcmp(classifier_labels, 'TP');
    
    filtered_bboxes = bboxes(tp_mask, :);
    filtered_scores = scores(tp_mask);
    filtered_labels = classifier_labels;
    
    % Report results
    num_filtered = sum(~tp_mask);
    fprintf('\n  Filtering Results:\n');
    fprintf('    Original detections: %d\n', size(bboxes, 1));
    fprintf('    Classified as TP: %d\n', sum(tp_mask));
    fprintf('    Classified as FP: %d (filtered out)\n', num_filtered);
    fprintf('    Final detections: %d\n', size(filtered_bboxes, 1));
    fprintf('    FP reduction: %.1f%%\n', 100*num_filtered/size(bboxes, 1));
end
