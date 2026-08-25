function boxLabelTable = helperCombineClasses(boxLabelTable)
for i = 1:height(boxLabelTable)
    numLabels = numel(boxLabelTable{i,2}{1});
    boxLabelTable{i,2}{1} = repmat("Airplane", numLabels, 1);
end
end