# Myelin Defect Analysis

Version-controlled MATLAB code for qBRM cortical-injury myelin-defect analysis on SCC.

## Purpose

This repository is an initial clean baseline assembled from the existing working SCC code. The active analysis pipeline is a two-stage workflow:

1. YOLOv4 candidate defect detection using `training_struct_SM080_SM077_128_RGBV2.mat`.
2. False-positive filtering using `apply_matlab_classifier.m` and `matlab_defect_classifier.mat`.

The repository also preserves annotation tools, detector/classifier training code, older apps/models, and selected qBRM preprocessing functions.

## Important baseline rule

The active `.mlapp` files in `myelin-defect-analysis/` are copied **without changing their scientific logic or path code**. This is deliberate: the first Git commit should preserve the current working implementation before path cleanup/refactoring.

## Active apps

- `myelin-defect-analysis/app/Deep_learning_app_v2_filterFP.mlapp` — general FP-filtered workflow.
- `myelin-defect-analysis/app/Deep_learning_app_v2_filterFP_perilesion.mlapp` — perilesion-specific modified workflow.

## Active models

- Detector: `myelin-defect-analysis/models/training_struct_SM080_SM077_128_RGBV2.mat`
  - MATLAB variable: `training_struct`
  - detector object: `training_struct.detector`
  - detector class: `yolov4ObjectDetector`
  - input size: 128 x 128 x 3
  - stored training date: 11-Mar-2024
  - stored AveragePrecision: 0.3726
- FP classifier: `myelin-defect-analysis/matlab_defect_classifier.mat`
  - loaded by `apply_matlab_classifier.m`
  - expected labels: `TRUE_POSITIVE` and `FALSE_POSITIVE`


## Directory layout

- `app/` — current analysis apps, core detector functions, active models, and FP classifier.
- `annotation/` — manual annotation/review GUIs.
- `training/detector/` — detector training/data-preparation code.
- `training/classifier/` — FP-classifier and transfer-learning code/documentation.
- `qBRM/` — selected qBRM solving/stitching functions provided with the project.
- `models/detector/` — detector model.
- `models/classifier/` — FP-classifier model.
- `legacy/` — older apps, older detector models, and annotation MAT files retained for history.
- `scc/` — SCC startup/test helpers.
- `docs/` — dependency notes, test plan, file inventory, and original documentation.

## Recommended Git history

Create the first commit from this baseline before modifying the apps:

```text
Initial import of working SCC defect-analysis pipeline
```

Then make path cleanup a separate commit, for example:

```text
Make detector and classifier paths repository-relative
```

This separation makes it possible to compare scientific outputs before and after refactoring.
