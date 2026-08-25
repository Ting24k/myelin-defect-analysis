function [sub_imgs, sub_bboxes] = create_training_dataset_CCP_ObjectDetection(folder_loc, width, height, step)
% crop_img_and_bbox_v2
% This function crops sub-images and associated bounding boxes from a larger image.
% It supports grayscale Z-stacks or single RGB images and optionally includes background-only crops.
%
% INPUTS:
%   img_name : filename (string) or image matrix (for preloaded image stack)
%   bbox     : bounding box annotation data (cell format with image plane info)
%   width    : width of each cropped sub-image
%   height   : height of each cropped sub-image
%   step     : step size between sub-image crops (stride)
%
% OUTPUTS:
%   sub_imgs   : cell array of cropped sub-images
%   sub_bboxes : cell array of bounding boxes for each crop

% ---------------------- Configuration Flags -----------------------------
RGB_image = 0;     % Set to 1 if input is RGB
phi_image = 0;     % Set to 1 if working with phi channel rotation images
X = 0.1;           % Fraction of background-only crops to include

% ------------------- Initialize Output Variables ------------------------
sub_imgs = {};
sub_bboxes = {};

% get all the images that we want taken from a main foldercd
cd(folder_loc)
mat_files = dir(fullfile('**', '*tif.mat'));

% -------------------- loop through all annotated files ------------------
for k = 1:length(mat_files)
    
    % get the annotation and image data
    data = load(fullfile(mat_files(k).folder, mat_files(k).name));
    bbox = data.annotations{1,6};
    planes = data.annotations{1,5};
    class = data.annotations{1,3};
    img_name = fullfile(mat_files(k).folder, mat_files(k).name);
    img_name = erase(img_name,'.mat');
    
    % Get unique planes that have annotations
    planes_with_annotations = unique(planes);
    counter = 1;

    % ------------------- Loop Over Each Annotated Plane ---------------------
    for ii = 1:length(planes_with_annotations)
        plane = planes_with_annotations(ii);

        % Load image for the current plane
        img_tmp = imread(img_name, plane);  % If path provided, read image

        % Extract bounding boxes for the current plane
        idx = (bbox{1,5} == plane);
        bbox_tmp = bbox{1,6}(idx,:);

        % Calculate how many crops fit in x and y dimensions
        num_blocksx = floor((size(img_tmp,2) - 2 * width) / step) + 2;
        num_blocksy = floor((size(img_tmp,1) - 2 * height) / step) + 2;

        fprintf('Cropping Images     ')
        percent_counter = 0;

        % ---------------------- Sliding Window Loop --------------------------
        for j = 1:num_blocksy
            for i = 1:num_blocksx

                % Define crop position
                rectx = (i-1)*step + 1;
                recty = (j-1)*step + 1;
                sub_size = [rectx, recty, width, height];

                % Crop sub-image
                sub_img = imcrop(img_tmp, sub_size);

                % Zero-padding if sub-image is smaller than requested size
                missingx = width - size(sub_img, 2) + 1;
                missingy = height - size(sub_img, 1) + 1;
                sub_img = padarray(sub_img, [missingy, missingx], 'post');

                % Progress printout
                fprintf('\b\b\b\b\b[%2.0i%%]', round(100*(percent_counter / (num_blocksx * num_blocksy))))
                percent_counter = percent_counter + 1;

                % ------------------ Bounding Box Cropping --------------------
                % Check which boxes fall inside this crop
                [bbox_cropped, valid] = bboxcrop(bbox_tmp, sub_size, OverlapThreshold=0.8);
                bbox_cropped = round(bbox_cropped);

                % Randomly allow background crops (no objects)
                background_selector = rand() < X;

                if valid || background_selector
                    % Store sub-image (convert grayscale to RGB if needed)
                    if ~RGB_image
                        sub_img = cat(3, sub_img, sub_img, sub_img);
                    end
                    sub_imgs{counter,1} = sub_img;
                    sub_bboxes{counter,1} = bbox_cropped;
                    counter = counter + 1;

                    % ---------------- Optional Data Augmentations --------------
                    if phi_image
                        % Add additional rotated phi channels
                        phi_rot_0 = sub_img(:,:,2);
                        phi_rot_60 = mod(phi_rot_0 + 1/3, 1);
                        phi_rot_120 = mod(phi_rot_0 + 2/3, 1);

                        sub_imgs{counter,1} = cat(3, sub_img(:,:,1), phi_rot_60, sub_img(:,:,3));
                        sub_bboxes{counter,1} = bbox_cropped;
                        counter = counter + 1;

                        sub_imgs{counter,1} = cat(3, sub_img(:,:,1), phi_rot_120, sub_img(:,:,3));
                        sub_bboxes{counter,1} = bbox_cropped;
                        counter = counter + 1;
                    end

                    if RGB_image
                        % Rotate RGB channels (for data augmentation)
                        sub_imgs{counter,1} = cat(3, sub_img(:,:,3), sub_img(:,:,1), sub_img(:,:,2));
                        sub_bboxes{counter,1} = bbox_cropped;
                        counter = counter + 1;

                        sub_imgs{counter,1} = cat(3, sub_img(:,:,2), sub_img(:,:,3), sub_img(:,:,1));
                        sub_bboxes{counter,1} = bbox_cropped;
                        counter = counter + 1;
                    end
                end
            end
        end
        fprintf('\nFinished Cropping images\n')
    end
end
end