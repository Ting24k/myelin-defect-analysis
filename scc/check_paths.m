%% scc/check_paths.m
% Verify that runtime functions resolve from this repository rather than
% from an external SCC folder such as /projectnb/gpumcml/annanov/EV.

thisFile = mfilename('fullpath');
sccDir = fileparts(thisFile);
repoRoot = fileparts(sccDir);

fprintf('\n=== Repository dependency check ===\n');
fprintf('Repository root:\n  %s\n\n', repoRoot);

expectedFunctions = {
    'apply_matlab_classifier'
    'detect_myelin_defects'
    'helperDetectObjectsInBlock'
    'helperRemoveDetectionsInBorderRegion'
    'helperSanitizeBoxes'
    'run_OD_onBlocked_image'
    'filter_bb_in_roi'
    'filter_bb_scores_in_roi'
    'count_defects_per_area'
    'count_defects_per_area_ROI'
    'solve_widefield_qBRM_folder'
    'stitch_qBRM'
    'stitch'
    'readTiff'
    'analytical_qBRM_gpu_all'
    'save_tiff'
    'saveastiff'
    'write_zstack'
};

allOK = true;

for k = 1:numel(expectedFunctions)
    fn = expectedFunctions{k};
    resolved = which(fn);

    if isempty(resolved)
        fprintf('[MISSING] %-38s\n', fn);
        allOK = false;
        continue
    end

    inRepo = startsWith(resolved, repoRoot);

    if inRepo
        fprintf('[OK]      %-38s -> %s\n', fn, resolved);
    else
        fprintf('[EXTERNAL]%-38s -> %s\n', fn, resolved);
        allOK = false;
    end
end

% Function known to still be an unresolved dependency unless copied.
fprintf('\nAdditional app dependency:\n');
fn = 'findFoldersWithString';
resolved = which(fn);
if isempty(resolved)
    fprintf('[MISSING] %s\n', fn);
    fprintf('          Copy findFoldersWithString.m into an appropriate runtime folder.\n');
    allOK = false;
elseif startsWith(resolved, repoRoot)
    fprintf('[OK]      %s -> %s\n', fn, resolved);
else
    fprintf('[EXTERNAL] %s -> %s\n', fn, resolved);
    allOK = false;
end

detectorFile = fullfile(repoRoot, 'models', 'detector', ...
    'training_struct_SM080_SM077_128_RGBV2.mat');
classifierFile = fullfile(repoRoot, 'models', 'classifier', ...
    'matlab_defect_classifier.mat');

fprintf('\nModels:\n');
if isfile(detectorFile)
    fprintf('[OK] Detector model   -> %s\n', detectorFile);
else
    fprintf('[MISSING] Detector model -> %s\n', detectorFile);
    allOK = false;
end

if isfile(classifierFile)
    fprintf('[OK] Classifier model -> %s\n', classifierFile);
else
    fprintf('[MISSING] Classifier model -> %s\n', classifierFile);
    allOK = false;
end

fprintf('\nAnna/EV path check:\n');
p = strsplit(path, pathsep);
annaHits = p(contains(p, '/projectnb/gpumcml/annanov/EV'));

if isempty(annaHits)
    fprintf('[OK] Anna/EV is not on the MATLAB path.\n');
else
    fprintf('[WARNING] Anna/EV is still on the MATLAB path:\n');
    fprintf('  %s\n', annaHits{:});
    allOK = false;
end

fprintf('\n');
if allOK
    fprintf('RESULT: Runtime dependency check passed.\n\n');
else
    fprintf('RESULT: One or more dependencies still need attention.\n\n');
end
