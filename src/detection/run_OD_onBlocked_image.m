function run_OD_onBlocked_image(img,borderSize, input_size, detector)
if length(borderSize)<2
error('Border size must be a MxN matrix')
end
bim = blockedImage(img);    

blockSize = input_size; % this will change depending on network you use
actualBlockSize = blockSize - 2*borderSize;
threshold = 0.3;
detectionFcn = @(bstruct)helperDetectObjectsInBlock(bstruct, detector, borderSize, threshold);
batchSize = 2; % change depending on how much GPU memory you have
results = apply(bim, detectionFcn, ...
PadPartialBlocks=true, ...
BlockSize=actualBlockSize,...
BorderSize=borderSize, ...
DisplayWaitbar=true,...
BatchSize=batchSize);
allBoxes  = vertcat(results.Source.bboxes);
allScores = vertcat(results.Source.scores);
allLabels = vertcat(results.Source.labels);
figure
bigimageshow(bim)
showShape("rectangle", allBoxes)

end