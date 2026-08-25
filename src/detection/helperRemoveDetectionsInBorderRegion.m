function [bboxes, scores, labels] = helperRemoveDetectionsInBorderRegion(...
    bboxes, scores, labels, blockPosition)

% Use bboxcrop to find out which boxes are inside the block position. 
[~, valid] = bboxcrop(bboxes, blockPosition, OverlapThreshold=0.5);
bboxes = bboxes(valid,:);
scores = scores(valid);
labels = labels(valid);
end