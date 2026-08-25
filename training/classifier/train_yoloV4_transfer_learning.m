function training_struct = train_yoloV4_transfer_learning(dataset, pretrained_model_path, detector_name, varargin)
% TRAIN_YOLOV4_TRANSFER_LEARNING_V2 - Ultra-robust version
% Avoids bboxfliplr and other problematic functions
%
% Inputs:
%   dataset - Table with imageFilename and myelinDefects columns
%   pretrained_model_path - Path to .mat file with pretrained detector
%   detector_name - Name for the new detector
%   varargin - Optional: input_size (default: 128)
%
% Outputs:
%   training_struct - Structure containing trained detector and metrics

    fprintf('=== YOLOv4 Transfer Learning V2 (Ultra-Robust) ===\n');
    
    % Load pretrained model
    fprintf('Loading pretrained model: %s\n', pretrained_model_path);
    try
        pretrained_data = load(pretrained_model_path);
    catch ME
        error('Failed to load pretrained model: %s', ME.message);
    end
    
    if isfield(pretrained_data, 'training_struct')
        pretrained_detector = pretrained_data.training_struct.detector;
        fprintf('Loaded detector from training_struct\n');
    elseif isfield(pretrained_data, 'detector')
        pretrained_detector = pretrained_data.detector;
        fprintf('Loaded detector directly\n');
    else
        error('Cannot find detector in pretrained model file');
    end
    
    % Set input size
    inputSize = [128 128 3];
    if nargin > 3
        inputSize = [varargin{1} varargin{1} 3];
    end
    fprintf('Input size: %dx%dx%d\n', inputSize(1), inputSize(2), inputSize(3));
    
    % Verify dataset format
    fprintf('\n=== Verifying Dataset ===\n');
    if ~istable(dataset)
        error('Dataset must be a table');
    end
    if ~ismember('imageFilename', dataset.Properties.VariableNames)
        error('Dataset must have imageFilename column');
    end
    if ~ismember('myelinDefects', dataset.Properties.VariableNames)
        error('Dataset must have myelinDefects column');
    end
    
    fprintf('Dataset height: %d samples\n', height(dataset));
    
    % Check for empty samples
    num_with_defects = sum(cellfun(@(x) ~isempty(x), dataset.myelinDefects));
    num_background = sum(cellfun(@(x) isempty(x), dataset.myelinDefects));
    fprintf('  With defects: %d (%.1f%%)\n', num_with_defects, 100*num_with_defects/height(dataset));
    fprintf('  Background: %d (%.1f%%)\n', num_background, 100*num_background/height(dataset));
    
    % Split dataset into train/val/test
    fprintf('\n=== Splitting Dataset ===\n');
    rng(0); % For reproducibility
    shuffledIndices = randperm(height(dataset));
    
    % 70% train, 20% validation, 10% test
    train_idx = floor(0.7 * height(dataset));
    val_idx = floor(0.9 * height(dataset));
    
    trainingIdx = shuffledIndices(1:train_idx);
    validationIdx = shuffledIndices(train_idx+1:val_idx);
    testIdx = shuffledIndices(val_idx+1:end);
    
    trainingDataTbl = dataset(trainingIdx, :);
    validationDataTbl = dataset(validationIdx, :);
    testDataTbl = dataset(testIdx, :);
    
    fprintf('Training samples: %d\n', height(trainingDataTbl));
    fprintf('Validation samples: %d\n', height(validationDataTbl));
    fprintf('Test samples: %d\n', height(testDataTbl));
    
    % Create datastores
    fprintf('\n=== Creating Datastores ===\n');
    try
        imdsTrain = imageDatastore(trainingDataTbl.imageFilename);
        bldsTrain = boxLabelDatastore(trainingDataTbl(:, 'myelinDefects'));
        
        imdsValidation = imageDatastore(validationDataTbl.imageFilename);
        bldsValidation = boxLabelDatastore(validationDataTbl(:, 'myelinDefects'));
        
        imdsTest = imageDatastore(testDataTbl.imageFilename);
        bldsTest = boxLabelDatastore(testDataTbl(:, 'myelinDefects'));
        
        fprintf('Datastores created successfully\n');
    catch ME
        error('Failed to create datastores: %s', ME.message);
    end
    
    % Combine datastores
    trainingData = combine(imdsTrain, bldsTrain);
    validationData = combine(imdsValidation, bldsValidation);
    testData = combine(imdsTest, bldsTest);
    
    % Preprocess data with error handling
    fprintf('\n=== Preprocessing Data ===\n');
    try
        % Create preprocessing function handle
        preprocessFcn = @(data) preprocessDataSimple(data, inputSize);
        
        % Test on first sample
        fprintf('Testing preprocessing on first sample...\n');
        testSample = read(trainingData);
        reset(trainingData);
        preprocessedTest = preprocessFcn(testSample);
        fprintf('  Test successful: image size %dx%d, %d bboxes\n', ...
            size(preprocessedTest{1}, 1), size(preprocessedTest{1}, 2), ...
            size(preprocessedTest{2}, 1));
        
        % Apply to all data
        preprocessedTrainingData = transform(trainingData, preprocessFcn);
        preprocessedValidationData = transform(validationData, preprocessFcn);
        
    catch ME
        error('Preprocessing failed: %s\nAt: %s (line %d)', ...
            ME.message, ME.stack(1).name, ME.stack(1).line);
    end
    
    % Apply data augmentation
    fprintf('\n=== Applying Data Augmentation ===\n');
    try
        augmentFcn = @(data) augmentDataSimple(data);
        
        % Test augmentation
        fprintf('Testing augmentation on first sample...\n');
        testPreprocessed = read(preprocessedTrainingData);
        reset(preprocessedTrainingData);
        augmentedTest = augmentFcn(testPreprocessed);
        fprintf('  Test successful\n');
        
        augmentedTrainingData = transform(preprocessedTrainingData, augmentFcn);
        
    catch ME
        warning('Augmentation failed: %s', ME.message);
        fprintf('Continuing without augmentation...\n');
        augmentedTrainingData = preprocessedTrainingData;
    end
    
    % Display sample (optional)
    fprintf('\n=== Sample Visualization ===\n');
    try
        fprintf('Creating sample visualization...\n');
        augmentedData = cell(4, 1);
        for k = 1:4
            if hasdata(augmentedTrainingData)
                data = read(augmentedTrainingData);
                if ~isempty(data{2})
                    augmentedData{k} = insertShape(data{1}, 'rectangle', data{2}, ...
                        'Color', 'red', 'LineWidth', 2);
                else
                    augmentedData{k} = data{1};
                end
            end
        end
        reset(augmentedTrainingData);
        
        if all(cellfun(@(x) ~isempty(x), augmentedData))
            figure('Visible', 'off');
            montage(augmentedData, 'BorderSize', 10);
            saveas(gcf, sprintf('augmented_samples_%s.png', detector_name));
            close(gcf);
            fprintf('Saved: augmented_samples_%s.png\n', detector_name);
        end
    catch ME
        warning('Sample visualization skipped: %s', ME.message);
    end
    
    % Configure training options for transfer learning
    fprintf('\n=== Configuring Training Options ===\n');
    options = trainingOptions('adam', ...
        InitialLearnRate=0.0001, ...
        GradientDecayFactor=0.9, ...
        SquaredGradientDecayFactor=0.999, ...
        LearnRateSchedule='piecewise', ...
        LearnRateDropPeriod=10, ...
        LearnRateDropFactor=0.5, ...
        MiniBatchSize=32, ...
        L2Regularization=0.0005, ...
        MaxEpochs=50, ...
        BatchNormalizationStatistics='moving', ...
        ResetInputNormalization=false, ...
        Shuffle='every-epoch', ...
        VerboseFrequency=10, ...
        ValidationData=preprocessedValidationData, ...
        ValidationFrequency=50, ...
        ExecutionEnvironment='auto');
    
    fprintf('Training configuration:\n');
    fprintf('  Initial learning rate: %g\n', options.InitialLearnRate);
    fprintf('  Max epochs: %d\n', options.MaxEpochs);
    fprintf('  Mini-batch size: %d\n', options.MiniBatchSize);
    fprintf('  Execution: %s\n', options.ExecutionEnvironment);
    
    % Train detector
    fprintf('\n=== Starting Training ===\n');
    fprintf('This may take 30-60 minutes...\n\n');
    
    tic;
    try
        [trainedDetector, info] = trainYOLOv4ObjectDetector(...
            augmentedTrainingData, pretrained_detector, options);
    catch ME
        error('Training failed: %s\nAt: %s (line %d)', ...
            ME.message, ME.stack(1).name, ME.stack(1).line);
    end
    training_time = toc;
    
    fprintf('\n=== Training Complete ===\n');
    fprintf('Time: %.2f minutes\n', training_time/60);
    
    % Plot training loss
    try
        figure('Visible', 'off');
        plot(info.TrainingLoss);
        xlabel('Iteration');
        ylabel('Loss');
        title('Training Loss');
        grid on;
        saveas(gcf, sprintf('training_loss_%s.png', detector_name));
        close(gcf);
        fprintf('Saved: training_loss_%s.png\n', detector_name);
    catch ME
        warning('Failed to save training loss plot: %s', ME.message);
    end
    
    % Evaluate on test set
    fprintf('\n=== Evaluating on Test Set ===\n');
    try
        preprocessedTestData = transform(testData, @(data)preprocessDataSimple(data, inputSize));
        detectionResults = detect(trainedDetector, preprocessedTestData, MinibatchSize=4);
        [ap, recall, precision] = evaluateDetectionPrecision(detectionResults, preprocessedTestData);
        
        fprintf('Average Precision: %.4f\n', ap);
        fprintf('Recall: %.4f\n', recall(end));
        fprintf('Precision: %.4f\n', precision(end));
        
        % Plot precision-recall curve
        try
            figure('Visible', 'off');
            plot(recall, precision, 'b-', 'LineWidth', 2);
            xlabel('Recall');
            ylabel('Precision');
            title(sprintf('Precision-Recall (AP = %.4f)', ap));
            grid on;
            axis([0 1 0 1]);
            saveas(gcf, sprintf('precision_recall_%s.png', detector_name));
            close(gcf);
            fprintf('Saved: precision_recall_%s.png\n', detector_name);
        catch ME
            warning('Failed to save PR curve: %s', ME.message);
        end
        
    catch ME
        warning('Test evaluation failed: %s', ME.message);
        ap = NaN;
        recall = [];
        precision = [];
    end
    
    % Save training structure
    fprintf('\n=== Saving Results ===\n');
    training_struct.inputSize = inputSize;
    training_struct.detector = trainedDetector;
    training_struct.info = info;
    training_struct.testData = testDataTbl;
    training_struct.AveragePrecision = ap;
    training_struct.recall = recall;
    training_struct.precision = precision;
    training_struct.training_options = options;
    training_struct.training_time_minutes = training_time/60;
    training_struct.pretrained_model = pretrained_model_path;
    training_struct.Date = datetime('now');
    
    save_file = sprintf('training_struct_transfer_%s.mat', detector_name);
    save(save_file, 'training_struct');
    fprintf('Saved: %s\n', save_file);
    
    fprintf('\n=== Transfer Learning Complete ===\n');
    fprintf('Model: %s\n', detector_name);
    fprintf('Test AP: %.4f\n', ap);
    fprintf('Training time: %.2f minutes\n', training_time/60);
end

%% Simple helper functions that avoid problematic MATLAB functions

function data = preprocessDataSimple(data, targetSize)
    % Simple preprocessing without bboxresize issues
    
    try
        if isempty(data) || length(data) < 2
            return;
        end
        
        img = data{1};
        bboxes = data{2};
        
        if isempty(img)
            return;
        end
        
        % Get current and target sizes
        currentSize = [size(img, 1), size(img, 2)];
        
        % Resize image if needed
        if ~isequal(currentSize, targetSize(1:2))
            % Calculate scale
            scaleX = targetSize(2) / currentSize(2);
            scaleY = targetSize(1) / currentSize(1);
            
            % Resize image
            img = imresize(img, targetSize(1:2));
            
            % Scale bboxes manually
            if ~isempty(bboxes) && size(bboxes, 2) == 4
                % Convert to double for reliability
                bboxes = double(bboxes);
                
                % Scale: [x, y, width, height]
                bboxes(:, 1) = bboxes(:, 1) * scaleX;  % x
                bboxes(:, 2) = bboxes(:, 2) * scaleY;  % y
                bboxes(:, 3) = bboxes(:, 3) * scaleX;  % width
                bboxes(:, 4) = bboxes(:, 4) * scaleY;  % height
                
                % Ensure within bounds
                bboxes(:, 1) = max(1, min(bboxes(:, 1), targetSize(2)));
                bboxes(:, 2) = max(1, min(bboxes(:, 2), targetSize(1)));
                bboxes(:, 3) = max(1, min(bboxes(:, 3), targetSize(2) - bboxes(:, 1) + 1));
                bboxes(:, 4) = max(1, min(bboxes(:, 4), targetSize(1) - bboxes(:, 2) + 1));
                
                % Round to integers
                bboxes = round(bboxes);
            end
        end
        
        data{1} = img;
        data{2} = bboxes;
        
    catch ME
        warning('Preprocessing error: %s', ME.message);
    end
end

function data = augmentDataSimple(data)
    % Simple augmentation without bboxfliplr or other problematic functions
    
    try
        if isempty(data) || length(data) < 2
            return;
        end
        
        img = data{1};
        bboxes = data{2};
        
        if isempty(img)
            return;
        end
        
        % Convert bboxes to double for safety
        if ~isempty(bboxes)
            bboxes = double(bboxes);
        end
        
        % Random horizontal flip (manual implementation)
        if rand < 0.5 && ~isempty(bboxes) && size(bboxes, 1) > 0
            % Flip image
            img = fliplr(img);
            
            % Flip bboxes manually
            % Formula: new_x = image_width - old_x - bbox_width + 1
            imgWidth = size(img, 2);
            bboxes(:, 1) = imgWidth - bboxes(:, 1) - bboxes(:, 3) + 1;
        end
        
        % Random brightness adjustment (simple version)
        if rand < 0.5 && size(img, 3) == 3
            try
                % Simple brightness adjustment
                brightness_factor = 0.8 + rand * 0.4;  % 0.8 to 1.2
                img = img * brightness_factor;
                img = min(max(img, 0), 255);  % Clamp to valid range
                img = uint8(img);
            catch
                % Skip if fails
            end
        end
        
        data{1} = img;
        data{2} = bboxes;
        
    catch ME
        warning('Augmentation error: %s', ME.message);
    end
end
