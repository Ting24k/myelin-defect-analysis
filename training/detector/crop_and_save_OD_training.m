function crop_and_save_OD_training(folder_location)
% parameters to change
crop_size = 192;
step_size = 96;
detector_name = 'AM_CCP_60X_fractionator';

% get names of all images you want to crop and train with
S = dir(fullfile(pwd,'**','*tif.mat'));
F = {S.folder}';
now = datetime('now');
formattedDate = datestr(now, 'yyyy_mm_dd');

% loop through all images and crop them 
sub_imgs_all = {};
sub_bboxes_all = {};
for i =1:length(F)
data = load([S(i).folder, '/', S(i).name]).annotations;
name = erase(S(i).name, '.mat');
fullname = [S(i).folder , '/', name];
[sub_imgs,sub_bboxes] = crop_img_and_bbox_v2(fullname,data,crop_size,crop_size,step_size);
sub_imgs_all = cat(1,sub_imgs_all, sub_imgs);
sub_bboxes_all = cat(1,sub_bboxes_all, sub_bboxes);
end

% create a training table in hte format that YOLOv4 likes
sub_imgs = sub_imgs_all;
sub_bboxes = sub_bboxes_all;
varTypes = ["string","cell"];
varNames = ["imageFilename","myelinDefects"];
training_table = table('Size',[size(sub_imgs,1) 2],'VariableNames',varNames,'VariableTypes', varTypes);
mkdir(sprintf('training_%s_%d_step_%d_%s', detector_name,crop_size, step_size,formattedDate))
cd(sprintf('training_%s_%d_step_%d_%s', detector_name,crop_size, step_size,formattedDate))
train_count = 1;

for i = 1:length(sub_imgs)
img_name = sprintf('img_%05d.tif',i);
imwrite(sub_imgs{i},img_name)
training_table{train_count,:} = {[pwd, '\',img_name],sub_bboxes{i}};
train_count = train_count+1;
fprintf('\b\b\b\b\b[%2.0i%%]',round(100*(i/length(sub_imgs))))
end
fprintf('\nFinished Saving Training...\n')
save('Training_table.mat', 'training_table')

% to train network run this function:
training_struct = Train_yoloV4(training_table,sprintf('training_%s_%d_step_%d_%s', detector_name,crop_size, step_size,formattedDate), crop_size);
%training_struct = Train_yoloV4(training_table,detector_name, crop_size);
% inputs: training table, detector save name, detector size (should be same as the cropped data) 

% function to detect objects in an image z stack

end