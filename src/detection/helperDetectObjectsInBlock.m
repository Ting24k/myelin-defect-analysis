function bres = helperDetectObjectsInBlock(bstruct, detector, borderSize, threshold)

    % Get the block of data. 
    paddedBlock = bstruct.Data;
    
    % Run the object detector.
    [bboxes, scores, labels] = detect(detector, paddedBlock, Threshold = threshold);
    if ~iscell(bboxes)
        bboxes = {bboxes};
        scores = {scores};
        labels = {labels};
    end
    
    
    % Determine the position of the valid block region (excluding the border
    % area). This is needed to remove boxes that are detected in the border. 
    actualBlockSize = size(paddedBlock,[1 2]) - 2*borderSize;
    blockPosition = [borderSize([2 1])+1 actualBlockSize([2 1])];
    
    % Offset to place boxes in data world coords. This offset is used to update
    % the position of the boxes from the local block space to the world
    % coordinates of the larger image.
    offset = [1 1] - bstruct.Start(:,[2 1]);
    
    for i = 1:numel(bboxes)
    
        % Remove boxes that lie in the border region. 
        % [bboxes{i}, scores{i}, labels{i}] = ...
        %     helperRemoveDetectionsInBorderRegion(bboxes{i}, scores{i}, labels{i}, blockPosition);
        % % 
        % Update box positions to be relative to the world coordinates.
        bboxes{i}(:,[1 2]) = bboxes{i}(:,[1 2]) - offset(i,:);
    end
    
    % Pack the detection results into a struct and ensure the last dimension
    % equals bstruct.BatchSize by transposing the struct.
    bres = struct('bboxes', bboxes, 'labels', labels, 'scores', scores)';

end