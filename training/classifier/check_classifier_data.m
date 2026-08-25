% CHECK_CLASSIFIER_DATA.m
% Diagnostic script to check your classifier training data

clear; clc;

fprintf('========================================\n');
fprintf('   Classifier Data Diagnostics\n');
fprintf('========================================\n\n');

% Check the directory
DATA_DIR = './roboflow_classifier_data';

fprintf('Checking directory: %s\n', DATA_DIR);
fprintf('--------------------------------------------------\n\n');

if ~exist(DATA_DIR, 'dir')
    fprintf('❌ Directory not found!\n');
    fprintf('   Path: %s\n\n', DATA_DIR);
    fprintf('Did you run roboflow_classifier_batch_config.m first?\n');
    fprintf('If yes, check the output_dir setting in that script.\n');
    return;
end

fprintf('✓ Directory exists\n\n');

% List immediate subdirectories
fprintf('Subdirectories in %s:\n', DATA_DIR);
fprintf('--------------------------------------------------\n');

subdirs = dir(DATA_DIR);
subdirs = subdirs([subdirs.isdir]);
subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'}));

for i = 1:length(subdirs)
    subdir_path = fullfile(DATA_DIR, subdirs(i).name);
    
    % Count images in this subdirectory
    img_files = dir(fullfile(subdir_path, '*.png'));
    img_files = [img_files; dir(fullfile(subdir_path, '*.jpg'))];
    
    fprintf('  %s: %d images\n', subdirs(i).name, length(img_files));
end

fprintf('\n');

% Expected structure
fprintf('Expected Structure:\n');
fprintf('--------------------------------------------------\n');
fprintf('roboflow_classifier_data/\n');
fprintf('├── TRUE_POSITIVE/  (should have ~100-500 PNG images)\n');
fprintf('└── FALSE_POSITIVE/ (should have ~100-500 PNG images)\n\n');

% Check for the expected folders
has_tp = exist(fullfile(DATA_DIR, 'TRUE_POSITIVE'), 'dir');
has_fp = exist(fullfile(DATA_DIR, 'FALSE_POSITIVE'), 'dir');

if has_tp && has_fp
    fprintf('✓ Found both expected folders\n\n');
    
    tp_files = dir(fullfile(DATA_DIR, 'TRUE_POSITIVE', '*.png'));
    fp_files = dir(fullfile(DATA_DIR, 'FALSE_POSITIVE', '*.png'));
    
    fprintf('TRUE_POSITIVE: %d images\n', length(tp_files));
    fprintf('FALSE_POSITIVE: %d images\n', length(fp_files));
    fprintf('Total: %d images\n\n', length(tp_files) + length(fp_files));
    
    % Check balance
    if length(tp_files) > 0 && length(fp_files) > 0
        balance = min(length(tp_files), length(fp_files)) / max(length(tp_files), length(fp_files));
        fprintf('Class balance: %.2f\n', balance);
        if balance < 0.5
            fprintf('⚠ Classes are imbalanced (%.1f%% / %.1f%%)\n', ...
                100*length(tp_files)/(length(tp_files)+length(fp_files)), ...
                100*length(fp_files)/(length(tp_files)+length(fp_files)));
        else
            fprintf('✓ Classes are balanced\n');
        end
    end
    
else
    fprintf('❌ Missing expected folders!\n');
    if ~has_tp
        fprintf('   Missing: TRUE_POSITIVE/\n');
    end
    if ~has_fp
        fprintf('   Missing: FALSE_POSITIVE/\n');
    end
    fprintf('\nRun roboflow_classifier_batch_config.m to create the correct structure.\n');
end

fprintf('\n');

% Now check what imageDatastore would load
fprintf('Testing imageDatastore...\n');
fprintf('--------------------------------------------------\n');

try
    imds = imageDatastore(DATA_DIR, ...
        'IncludeSubfolders', true, ...
        'LabelSource', 'foldernames');
    
    fprintf('Images found by datastore: %d\n', numel(imds.Files));
    
    % Show class distribution
    class_counts = countEachLabel(imds);
    fprintf('\nClass distribution:\n');
    disp(class_counts);
    
    % Show sample file paths
    fprintf('\nSample file paths:\n');
    for i = 1:min(5, numel(imds.Files))
        fprintf('  %d. %s\n', i, imds.Files{i});
    end
    if numel(imds.Files) > 5
        fprintf('  ... and %d more\n', numel(imds.Files) - 5);
    end
    
    fprintf('\n');
    
    % Diagnosis
    if numel(imds.Files) > 5000
        fprintf('⚠ WARNING: Too many images (%d)\n', numel(imds.Files));
        fprintf('This suggests the directory contains extra data.\n\n');
        fprintf('Possible causes:\n');
        fprintf('1. Wrong directory path\n');
        fprintf('2. Directory has extra subdirectories with images\n');
        fprintf('3. Multiple datasets mixed together\n\n');
        fprintf('Recommendation:\n');
        fprintf('  - Check DATA_DIR in train_matlab_classifier.m\n');
        fprintf('  - Should point to folder created by roboflow_classifier_batch_config.m\n');
        fprintf('  - Should only have TRUE_POSITIVE and FALSE_POSITIVE subfolders\n');
        
    elseif numel(imds.Files) < 100
        fprintf('⚠ WARNING: Very few images (%d)\n', numel(imds.Files));
        fprintf('May not be enough for good training.\n\n');
        fprintf('Recommendation:\n');
        fprintf('  - Run roboflow_classifier_batch_config.m on more images\n');
        fprintf('  - Need at least 200-400 total samples for good results\n');
        
    else
        fprintf('✓ Image count looks reasonable (%d)\n', numel(imds.Files));
        fprintf('This should work well for training.\n');
    end
    
catch ME
    fprintf('❌ Error creating datastore: %s\n', ME.message);
end

fprintf('\n========================================\n');
fprintf('Diagnostics Complete\n');
fprintf('========================================\n');
