# Model inventory

## Production detector

File: `runtime/DeepLearning_corticalInjury_tools/models/training_struct_SM080_SM077_128_RGBV2.mat`

Known contents from MATLAB inspection:

- `inputSize`: `[128 128 3]`
- `trainingData`: transformed datastore
- `validationData`: empty in the saved structure
- `detector`: `yolov4ObjectDetector`
- `info`: training information struct
- `testData`: transformed datastore
- `AveragePrecision`: `0.3726`
- `recall`: stored precision-recall data
- `precision`: stored precision-recall data
- `training_options`: ADAM training options
- `Date`: `11-Mar-2024 13:34:28`

## Production false-positive classifier

File: `runtime/DeepLearning_corticalInjury_tools/matlab_defect_classifier.mat`

`apply_matlab_classifier.m` expects the file to contain a `classifier_model` structure with at least:

- `network`
- `input_size`
- `classes`

The training code uses a two-class scheme:

- `TRUE_POSITIVE`
- `FALSE_POSITIVE`

`train_matlab_classifier.m` defaults to ResNet-18. `train_matlab_classifier_v2.m` is configured for ResNet-50 and writes `matlab_defect_classifier_resnet50.mat`.

## Experimental/alternate models

Stored under `models/experimental/`:

- `matlab_defect_classifier_resnet50.mat`
- `training_struct_transfer_batch_trained_model.mat`

These are retained for inspection/comparison and are not selected by the active app by default.

## Legacy detector models

Older detector packages are retained under `legacy/detector_models/` so they do not appear to be active production models.
