% INSPECT_CLASSIFIER_FOLDERS.m
% Detailed inspection of classifier data folders

clear; clc;

fprintf('========================================\n');
fprintf('   Detailed Folder Inspection\n');
fprintf('========================================\n\n');

DATA_DIR = './roboflow_classifier_data';

%% Check TRUE_POSITIVE folder

tp_dir = fullfile(DATA_DIR, 'TRUE_POSITIVE');
fprintf('Inspecting TRUE_POSITIVE folder:\n');
fprintf('--------------------------------------------------\n');

if exist(tp_dir, 'dir')
    % Count PNG files
    png_files = dir(fullfile(tp_dir, '*.png'));
    fprintf('PNG files: %d\n', length(png_files));
    
    % Count JPG files
    jpg_files = dir(fullfile(tp_dir, '*.jpg'));
    fprintf('JPG files: %d\n', length(jpg_files));
    
    % Check for subdirectories
    subdirs = dir(tp_dir);
    subdirs = subdirs([subdirs.isdir]);
    subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'}));
    
    if ~isempty(subdirs)
        fprintf('⚠ Found %d subdirectories:\n', length(subdirs));
        for i = 1:min(10, length(subdirs))
            sub_path = fullfile(tp_dir, subdirs(i).name);
            sub_files = dir(fullfile(sub_path, '*.png'));
            sub_files = [sub_files; dir(fullfile(sub_path, '*.jpg'))];
            fprintf('  %s: %d images\n', subdirs(i).name, length(sub_files));
        end
        if length(subdirs) > 10
            fprintf('  ... and %d more subdirectories\n', length(subdirs) - 10);
        end
    else
        fprintf('✓ No subdirectories (correct)\n');
    end
    
    % Show sample filenames
    all_imgs = [png_files; jpg_files];
    if ~isempty(all_imgs)
        fprintf('\nSample filenames:\n');
        for i = 1:min(5, length(all_imgs))
            fprintf('  %s\n', all_imgs(i).name);
        end
        if length(all_imgs) > 5
            fprintf('  ... and %d more\n', length(all_imgs) - 5);
        end
    end
else
    fprintf('❌ Directory not found!\n');
end

fprintf('\n');

%% Check FALSE_POSITIVE folder

fp_dir = fullfile(DATA_DIR, 'FALSE_POSITIVE');
fprintf('Inspecting FALSE_POSITIVE folder:\n');
fprintf('--------------------------------------------------\n');

if exist(fp_dir, 'dir')
    % Count PNG files
    png_files = dir(fullfile(fp_dir, '*.png'));
    fprintf('PNG files: %d\n', length(png_files));
    
    % Count JPG files
    jpg_files = dir(fullfile(fp_dir, '*.jpg'));
    fprintf('JPG files: %d\n', length(jpg_files));
    
    % Check for subdirectories
    subdirs = dir(fp_dir);
    subdirs = subdirs([subdirs.isdir]);
    subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'}));
    
    if ~isempty(subdirs)
        fprintf('⚠ Found %d subdirectories:\n', length(subdirs));
        for i = 1:min(10, length(subdirs))
            sub_path = fullfile(fp_dir, subdirs(i).name);
            sub_files = dir(fullfile(sub_path, '*.png'));
            sub_files = [sub_files; dir(fullfile(sub_path, '*.jpg'))];
            fprintf('  %s: %d images\n', subdirs(i).name, length(sub_files));
        end
        if length(subdirs) > 10
            fprintf('  ... and %d more subdirectories\n', length(subdirs) - 10);
        end
    else
        fprintf('✓ No subdirectories (correct)\n');
    end
    
    % Show sample filenames
    all_imgs = [png_files; jpg_files];
    if ~isempty(all_imgs)
        fprintf('\nSample filenames:\n');
        for i = 1:min(5, length(all_imgs))
            fprintf('  %s\n', all_imgs(i).name);
        end
        if length(all_imgs) > 5
            fprintf('  ... and %d more\n', length(all_imgs) - 5);
        end
    end
else
    fprintf('❌ Directory not found!\n');
end

fprintf('\n');

%% Summary

fprintf('========================================\n');
fprintf('   Summary\n');
fprintf('========================================\n\n');

% Count direct files only
tp_direct = dir(fullfile(tp_dir, '*.png'));
tp_direct = [tp_direct; dir(fullfile(tp_dir, '*.jpg'))];

fp_direct = dir(fullfile(fp_dir, '*.png'));
fp_direct = [fp_direct; dir(fullfile(fp_dir, '*.jpg'))];

fprintf('Direct images (no subdirs):\n');
fprintf('  TRUE_POSITIVE: %d\n', length(tp_direct));
fprintf('  FALSE_POSITIVE: %d\n', length(fp_direct));
fprintf('  Total: %d\n\n', length(tp_direct) + length(fp_direct));

% Now test imageDatastore with IncludeSubfolders
fprintf('Testing imageDatastore (IncludeSubfolders=true):\n');
imds_all = imageDatastore(DATA_DIR, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
fprintf('  Images found: %d\n\n', numel(imds_all.Files));

fprintf('Testing imageDatastore (IncludeSubfolders=false):\n');
imds_direct = imageDatastore(DATA_DIR, 'IncludeSubfolders', false, 'LabelSource', 'foldernames');
fprintf('  Images found: %d\n\n', numel(imds_direct.Files));

%% Diagnosis

fprintf('========================================\n');
fprintf('   Diagnosis\n');
fprintf('========================================\n\n');

if numel(imds_all.Files) > 5000 && numel(imds_direct.Files) < 1000
    fprintf('⚠ PROBLEM FOUND!\n\n');
    fprintf('The TRUE_POSITIVE and/or FALSE_POSITIVE folders contain\n');
    fprintf('subdirectories with many images.\n\n');
    fprintf('IncludeSubfolders=true finds: %d images\n', numel(imds_all.Files));
    fprintf('IncludeSubfolders=false finds: %d images\n', numel(imds_direct.Files));
    fprintf('\nDifference: %d images in subdirectories\n', numel(imds_all.Files) - numel(imds_direct.Files));
    
    fprintf('\nSOLUTION 1: Use IncludeSubfolders=false\n');
    fprintf('In train_matlab_classifier.m, change line ~52 to:\n');
    fprintf('imds = imageDatastore(DATA_DIR, ...\n');
    fprintf('    ''IncludeSubfolders'', false, ...  %% ← Change to false\n');
    fprintf('    ''LabelSource'', ''foldernames'');\n\n');
    
    fprintf('SOLUTION 2: Remove subdirectories\n');
    fprintf('The TRUE_POSITIVE and FALSE_POSITIVE folders should only\n');
    fprintf('contain PNG files directly, no subdirectories.\n');
    fprintf('Run roboflow_classifier_batch_config.m again to create clean folders.\n');
    
elseif numel(imds_direct.Files) > 5000
    fprintf('⚠ PROBLEM: Too many direct images (%d)\n\n', numel(imds_direct.Files));
    fprintf('The PNG files directly in TRUE_POSITIVE and FALSE_POSITIVE\n');
    fprintf('are too numerous.\n\n');
    fprintf('Expected from roboflow_classifier_batch_config.m:\n');
    fprintf('  TRUE_POSITIVE: ~100-500 PNG files\n');
    fprintf('  FALSE_POSITIVE: ~100-500 PNG files\n\n');
    fprintf('Actual:\n');
    fprintf('  TRUE_POSITIVE: %d files\n', length(tp_direct));
    fprintf('  FALSE_POSITIVE: %d files\n\n', length(fp_direct));
    
    fprintf('SOLUTION: Re-run roboflow_classifier_batch_config.m\n');
    fprintf('Make sure it is configured correctly to process your\n');
    fprintf('annotation files, not extract all images from a directory.\n');
    
else
    fprintf('✓ Image count looks reasonable!\n');
    fprintf('Direct images: %d\n', numel(imds_direct.Files));
    fprintf('This should work for training.\n\n');
    fprintf('You can continue with train_matlab_classifier.m\n');
end

fprintf('\n========================================\n');
