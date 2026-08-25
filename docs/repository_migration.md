# Repository migration notes

## Included as active runtime

- `Deep_learning_app_v2_filterFP.mlapp`
- `Deep_learning_app_v2_filterFP_perilesion.mlapp`
- active YOLO detector package
- active FP classifier and application function
- detector/ROI helper functions from the current `DeepLearning_corticalInjury_tools/Functions` folder
- current settings files

## Separated from active runtime

- older app variants -> `legacy/apps/`
- older detector packages -> `legacy/detector_models/`
- annotation MAT files -> `legacy/annotations/`
- alternate trained models -> `models/experimental/`
- detector training/data-preparation code -> `training/detector/`
- classifier training/transfer-learning code -> `training/classifier/`

## Intentionally excluded

- MATLAB `.asv` autosaves
- experiment image datasets
- generated analysis results
- classifier training data folders
- test-result folders
- generated files from other chats

## Important

This repository is a clean organizational baseline, not yet a fully portable rewrite. The active `.mlapp` files have not been modified.
