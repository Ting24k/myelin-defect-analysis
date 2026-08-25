function detection_struct = detect_myelin_defects_zstack(img,trainedDetector, border_size, input_size)
    detection_struct.Detector = trainedDetector;
    blockSize = input_size; % this will change depending on network you use
    borderSize = [border_size border_size];
    actualBlockSize = blockSize - 2*borderSize;
    threshold = 0.3;
    detectionFcn = @(bstruct)helperDetectObjectsInBlock(bstruct,trainedDetector, borderSize, threshold);
    batchSize = 512; % change depending on how much GPU memory you have
    
    z_idx = []; % keep track of z for all the bboxes
    allBoxes = [];
    allscores = [];
    alllabels = [];
    % loop through the z stack to accumulate bounding boxes in XYZ then
    % apply non-max suppresion
    fprintf('Detecting Objects     ')
    percent_counter = 1;
    for i =1:size(img,3)
        img_tmp = cat(3,squeeze(img(:,:,i)),squeeze(img(:,:,i)),squeeze(img(:,:,i)));
        bim = blockedImage(img_tmp);
        
        results = apply(bim, detectionFcn, ...
            PadPartialBlocks=true, ...
            BlockSize=actualBlockSize,...
            BorderSize=borderSize, ...
            DisplayWaitbar=true,...
            BatchSize=batchSize);
        allBoxes_tmp  = vertcat(results.Source{1,1}.bboxes);
        alllabels_tmp  = vertcat(results.Source{1,1}.labels);
        allscores_tmp  = vertcat(results.Source{1,1}.scores);

        allBoxes = [allBoxes; allBoxes_tmp];
        alllabels = [alllabels; alllabels_tmp];
        allscores = [allscores; allscores_tmp];
        z_idx = [z_idx; i*ones([size(allBoxes_tmp,1),1])];
        fprintf('\b\b\b\b\b[%2.0i%%]',round(100*(percent_counter/size(img,3))))
        percent_counter = percent_counter + 1;
    end 
    fprintf('\n')
    fprintf('%%%%%%%%%%%%%%%%%%%%%')
    fprintf('\n')
        % figure
        % imshow(img)
        % [patchx, patchy] = create_rect_patches_from_bbox(allBoxes);
        % patch(patchx,patchy,'red','EdgeColor','b','Facecolor','none')
        
        [bbox_comb, score_comb,bbox_idx] = selectStrongestBbox(allBoxes,allscores, 'OverlapThreshold', 0.5, 'RatioType', 'Min');

        %save everyting to an output structure
        detection_struct.allBoxes = allBoxes;
        detection_struct.alllabels = alllabels;
        detection_struct.allscores = allscores;
        detection_struct.z_idx = z_idx;
        detection_struct.scores_nms = score_comb;
        detection_struct.bbox_nms = bbox_comb;
        detection_struct.z_idx_nms = z_idx(bbox_idx);
        %detection_struct.img = img;
    
        detection_struct.resultstable{i,1} = results;
        
        % create annotations        
        annotation_all{1} = "Need to add image location";
        annotation_all{2} = 'Object Detector';
        annotation_all{3} = alllabels(bbox_idx);
        Color = repmat([1 0 0], [size(bbox_idx,1), 1]);
        annotation_all{4} = Color;
        annotation_all{5} = z_idx(bbox_idx);
        annotation_all{6} = bbox_comb;
        detection_struct.annotations = annotation_all;

end