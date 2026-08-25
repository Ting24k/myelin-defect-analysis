%% startup.m
% Repository startup script for myelin-defect-analysis.
% Run this once after opening MATLAB in the repository root:
%
%     startup
%
% This adds only runtime code to the MATLAB path.
% Training folders are intentionally NOT added to avoid name conflicts.

repoRoot = fileparts(mfilename('fullpath'));

runtimeFolders = {
    fullfile(repoRoot, 'src', 'classification')
    fullfile(repoRoot, 'src', 'detection')
    fullfile(repoRoot, 'src', 'roi')
    fullfile(repoRoot, 'qBRM')
    fullfile(repoRoot, 'app')
};

fprintf('\n=== myelin-defect-analysis startup ===\n');
fprintf('Repository root:\n  %s\n\n', repoRoot);

for k = 1:numel(runtimeFolders)
    folder = runtimeFolders{k};
    if isfolder(folder)
        addpath(folder);
        fprintf('[OK] Added: %s\n', folder);
    else
        warning('Repository folder not found: %s', folder);
    end
end

% Explicit model locations (for checking/documentation).
detectorFile = fullfile(repoRoot, 'models', 'detector', ...
    'training_struct_SM080_SM077_128_RGBV2.mat');

classifierFile = fullfile(repoRoot, 'models', 'classifier', ...
    'matlab_defect_classifier.mat');

fprintf('\nModel check:\n');
if isfile(detectorFile)
    fprintf('[OK] Detector:   %s\n', detectorFile);
else
    warning('Detector model missing: %s', detectorFile);
end

if isfile(classifierFile)
    fprintf('[OK] Classifier: %s\n', classifierFile);
else
    warning('Classifier model missing: %s', classifierFile);
end

fprintf('\nRuntime path setup complete.\n');
fprintf('For a dependency check, run:\n  run(fullfile(''scc'',''check_paths.m''))\n\n');
