# Dependency map

## Current analysis flow

```text
Input microscopy/qBRM data
        |
        v
qBRM solve/stitch (when needed)
        |
        v
YOLOv4 candidate detector
training_struct_SM080_SM077_128_RGBV2.mat
        |
        v
candidate bounding boxes + scores
        |
        v
ROI filtering
filter_bb_in_roi / filter_bb_scores_in_roi
        |
        v
FP classifier
apply_matlab_classifier + matlab_defect_classifier.mat
        |
        v
TRUE_POSITIVE candidates retained
        |
        v
count / ROI / perilesion outputs
```

## Active app dependencies observed from App Designer source

Both `Deep_learning_app_v2_filterFP.mlapp` and `Deep_learning_app_v2_filterFP_perilesion.mlapp` reference:

- `training_struct_SM080_SM077_128_RGBV2.mat`
- local `Functions/`
- `solve_widefield_qBRM_folder`
- `stitch_qBRM`
- `findFoldersWithString`
- `count_defects_per_area`
- `filter_bb_in_roi`
- `filter_bb_scores_in_roi`
- `apply_matlab_classifier`
- `matlab_defect_classifier.mat`

The general FP app currently activates this SCC-specific path:

```matlab
addpath(genpath('/projectnb/gpumcml/annanov/EV'));
```

The perilesion app currently has the same line commented out.

## Missing source in this baseline

`findFoldersWithString.m` is referenced but was not part of the uploaded files used to build this repository. It should be copied from the existing SCC `Functions` folder into an appropriate project utility folder during the next dependency-completion step.

## qBRM preprocessing dependencies

`preprocessing/qbrm/solve_widefield_qBRM_folder.m` itself calls additional qBRM helpers, including:

- `readTiff`
- `analytical_qBRM_gpu_all`
- `write_zstack`
- `save_tiff`
- `saveastiff`
- `cmap_v3.mat`

Some of these exist in the runtime detector `Functions` directory, but `analytical_qBRM_gpu_all` and `cmap_v3.mat` were not supplied as source files in the current build. Therefore the raw-qBRM preprocessing route is not yet fully self-contained.

## Next refactoring target

After baseline validation, replace reliance on `/projectnb/gpumcml/annanov/EV` with repository-relative paths and explicitly pass the classifier model path. Do this in a separate Git commit and compare outputs to the baseline.
