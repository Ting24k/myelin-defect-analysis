[file, path] = uigetfile('*RGB.tif', 'Select a Text File');
img = imread(strcat(path, file));
bb = dir(strcat(path,'*ROI_filtered.mat'));
bb_val = load(strcat(path, bb.name));
bboxes = bb_val.bb_detector;
scores = bb_val.all_scores;
[filtered_bboxes, filtered_scores, filtered_labels, classifier_scores, tp_mask] = apply_matlab_classifier(...
       img, bboxes, scores, 'matlab_defect_classifier.mat');
bb_FP = double(~tp_mask);
bb_detector = bb_val.bb_detector;
all_bboxes=bb_val.all_bboxes;
all_scores=bb_val.all_scores;
save(strcat(path, bb.name(1:end-16),'TP.mat'),'bb_detector', 'all_bboxes', 'all_scores', 'bb_FP');