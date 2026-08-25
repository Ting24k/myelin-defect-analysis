function training_struct = Train_yoloV4(dataset, detector_name,varargin)

% load detector
%detector = yolov4ObjectDetector("tiny-yolov4-coco");
featureExtractionNetwork = resnet50;
featureLayer = 'activation_30_relu';

%%%%%%%%%%% old training code %%%%%%%%%%%%%%%
% imds = imageDatastore(dataset.imageFilename);
% blds = boxLabelDatastore(dataset(:,2:end));
% 
% ds = combine(imds,blds);
% ds = transform(ds,@augmentData);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rng(0)
shuffledIndices = randperm(height(dataset));
idx = floor(0.7 * height(dataset));

trainingIdx = 1:idx;
trainingDataTbl = dataset(shuffledIndices(trainingIdx),:);

validationIdx = idx+1 : idx + 1 + floor(0.2 * length(shuffledIndices) );
validationDataTbl = dataset(shuffledIndices(validationIdx),:);

testIdx = validationIdx(end)+1 : length(shuffledIndices);
testDataTbl = dataset(shuffledIndices(testIdx),:);

% conver to image datastores for each dataset
imdsTrain = imageDatastore(trainingDataTbl{:,'imageFilename'});
bldsTrain = boxLabelDatastore(trainingDataTbl(:,'myelinDefects'));

imdsValidation = imageDatastore(validationDataTbl{:,'imageFilename'});
bldsValidation = boxLabelDatastore(validationDataTbl(:,'myelinDefects'));

imdsTest = imageDatastore(testDataTbl{:,'imageFilename'});
bldsTest = boxLabelDatastore(testDataTbl(:,'myelinDefects'));

trainingData = combine(imdsTrain,bldsTrain);
validationData = combine(imdsValidation,bldsValidation);
testData = combine(imdsTest,bldsTest);
inputSize = [192 192 3];
if nargin > 1
    inputSize = [varargin{1} varargin{1} 3];
    disp('her;)')
end

preprocessedTrainingData = transform(trainingData, @(data)preprocessData(data,inputSize));
trainingDataForEstimation = transform(preprocessedTrainingData,@(data)preprocessData(data,inputSize));

%%%%%% Calculate the estimated anchorboxes %%%%%%%%%%%%
numAnchors = 15;
[anchors, meanIoU] = estimateAnchorBoxes(trainingDataForEstimation,numAnchors);
area = anchors(:,1).*anchors(:,2);
[~,idx] = sort(area,"descend");
anchors = anchors(idx,:);
anchorBoxes = {anchors(1:3,:);anchors(4:6,:)};
% anchorBoxes = {anchors(1:3,:)
%     anchors(4:6,:)
%     anchors(7:9,:)
%     };
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% Create augmented Dataset %%%%%%%%%%
augmentedTrainingData = transform(trainingData,@augmentData);

augmentedData = cell(4,1);
for k = 1:4
    data = read(augmentedTrainingData);
    augmentedData{k} = insertShape(data{1},'rectangle',data{2});
    reset(augmentedTrainingData);
end
figure
montage(augmentedData,'BorderSize',10)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trainingData = transform(augmentedTrainingData,@(data)preprocessData(data,inputSize));
validationData = transform(validationData,@(data)preprocessData(data,inputSize));

classes = {'myelinDefects'};

detector = yolov4ObjectDetector("tiny-yolov4-coco",classes,anchorBoxes,InputSize=inputSize);
%detector = yolov4ObjectDetector("csp-darknet53-coco",classes,anchorBoxes,InputSize=inputSize);


% %train Network
% options = trainingOptions("adam", ...
%     InitialLearnRate=0.0001, ...
%     MiniBatchSize=64,...
%     MaxEpochs=75, ...  
%     BatchNormalizationStatistics="moving",...
%     ResetInputNormalization=false,...
%     VerboseFrequency=30,...
% ValidationData=validationData);

options = trainingOptions("adam",...
    GradientDecayFactor=0.9,...
    SquaredGradientDecayFactor=0.999,...
    InitialLearnRate=0.001,...
    LearnRateSchedule="piecewise",...
    LearnRateDropPeriod=10,...
    LearnRateDropFactor=0.5,...
    MiniBatchSize=64,... %original was 128. changed to 64
    L2Regularization=0.0005,...
    MaxEpochs=100,...
    BatchNormalizationStatistics="moving",...
    DispatchInBackground=true,...
    ResetInputNormalization=false,...
    Shuffle="every-epoch",...
    VerboseFrequency=10,...
    ValidationFrequency=100,...
    CheckpointPath=tempdir,...
    ValidationData=validationData,...
ExecutionEnvironment='gpu');

[trainedDetector, info] = trainYOLOv4ObjectDetector(trainingData,detector,options);

figure
plot(info.TrainingLoss)
xlabel('Iteration')
ylabel('Loss')


%%%%% Run testing data to see average precision and recall %%%%%%
testData = transform(testData,@(data)preprocessData(data,inputSize));


detectionResults = detect(trainedDetector,testData,'MinibatchSize',4);   

[ap, recall, precision] = evaluateDetectionPrecision(detectionResults,testData);

%save all training info into a structure
training_struct.inputSize = inputSize;
training_struct.trainingData = trainingData;
training_struct.validationData = validationData;
training_struct.detector = trainedDetector;
training_struct.info = info;
training_struct.testData = testData;
training_struct.AveragePrecision = ap;
training_struct.recall = recall;
training_struct.precision = precision;
training_struct.training_options = options;
format longG
t = now;
d = datetime(t,'ConvertFrom','datenum');
training_struct.Date = d;

save(sprintf('training_strcuture_%s.mat', detector_name), 'training_struct')

figure
plot(recall,precision)
xlabel('Recall')
ylabel('Precision')
grid on
title(sprintf('Average Precision = %.2f', ap))
end