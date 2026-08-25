function [detection_struct] = detect_myelin_defects(img,trainedDetector, border_size, input_size)
    bim = blockedImage(img);
    blockSize = input_size; % this will change depending on network you use
    borderSize = [border_size border_size];
    actualBlockSize = blockSize - 2*borderSize;
    threshold = 0.3;
    detectionFcn = @(bstruct)helperDetectObjectsInBlock(bstruct,trainedDetector, borderSize, threshold);
    batchSize = 512; % change depending on how much GPU memory you have
    results = apply(bim, detectionFcn, ...
        PadPartialBlocks=true, ...
        BlockSize=actualBlockSize,...
        BorderSize=borderSize, ...
        DisplayWaitbar=true,...
        BatchSize=batchSize);
    allBoxes  = vertcat(results.Source{1,1}.bboxes);
    alllabels  = vertcat(results.Source{1,1}.labels);
    allscores  = vertcat(results.Source{1,1}.scores);

    % figure
    % imshow(img)
    % [patchx, patchy] = create_rect_patches_from_bbox(allBoxes);
    % patch(patchx,patchy,'red','EdgeColor','b','Facecolor','none')

    %save everyting to an output structure
    detection_struct.bboxes = allBoxes;
    detection_struct.labels = alllabels;
    detection_struct.scores = allscores;
    
    %detection_struct.img = img;
    detection_struct.Detector = trainedDetector;
    detection_struct.resultstable = results;
    
    % create annotations
    annotation_all{1} = "Need to add image location";
    annotation_all{2} = 'Object Detector';
    label = repmat("Defect", [size(allBoxes,1), 1]);
    annotation_all{3} = label;
    Color = repmat([1 0 0], [size(allBoxes,1), 1]);
    annotation_all{4} = Color;
    annotation_all{5} = ones([size(allBoxes,1), 1]);
    annotation_all{6} = allBoxes;
    detection_struct.annotations = annotation_all;

end