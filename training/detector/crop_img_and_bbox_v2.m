function [sub_imgs,sub_bboxes] = crop_img_and_bbox_v2(img_name,bbox,width,height,step)
% function to take in an image (zstack) and return an array of subimages with their
% bounding boxes.
%z=3; %only odd, because we want defect to be in the middle??


%%%% RGB image makes data augmentation for RGB images 
RGB_image = 0;
phi_image = 0;

% Initialize the sub-images and sub-bounding boxes cell arrays
%sub_imgs = cell(num_blocksx*num_blocksy, 1);
%sub_bboxes = cell(num_blocksx*num_blocksy, 1);
planes_with_annotations = unique(bbox{1,5});
counter = 1;
% cycle through all the planes with bounding boxes (annotations)
sub_imgs = {};
sub_bboxes = {};
for ii = 1:length(planes_with_annotations) % only look at the planes with annotations
    plane = planes_with_annotations(ii);

    % load the image and bbox info

    % code to potentially use the monochrome Ret or CCP images
    if ischar(img_name)
        img_tmp = imread(img_name,plane);
    else
        img_tmp = img_name;
    end
    
    idx = (bbox{1,5}==plane);
    bbox_tmp = bbox{1,6}(idx,:);

    % Compute the number of sub-images
    num_blocksx = floor((size(img_tmp,2)-2*width)/step)+2;
    num_blocksy = floor((size(img_tmp,1)-2*height)/step)+2;
    fprintf('Cropping Images     ')
    percent_counter = 0;
    for j =1:num_blocksy
        for i = 1:num_blocksx

            %%%%%%% crop Image %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            rectx = (i-1)*step+1; % top left corner x value of cropped image
            recty = (j-1)*step+1; % top left corner y value of cropped image
            sub_size = [rectx, recty, width, height];

            sub_img = imcrop(img_tmp, sub_size);
            % uncomment to debug
            % imshow(sub_img)
            % title(sprintf('Image X:%d Y:%d \n',i,j))
            % drawnow
            % input('Press enter to continue...')
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


            %%%% Zero Padding %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % calculate if we have the correct size image,
            missingx = width - size(sub_img, 2)+1;
            missingy = height - size(sub_img, 1)+1;

            %if not we pad with 0
            sub_img = padarray(sub_img,[missingy,missingx], 'post');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            fprintf('\b\b\b\b\b[%2.0i%%]',round(100*(percent_counter/(num_blocksx*num_blocksy))))
            percent_counter = percent_counter + 1;
            %%%%%%% check and modify bounding boxes %%%%%%%%%%%%%%%%%%%%%
            % need to handle the bboxes. Use bbox crop to determine which
            % bboxes are in the proper range.
            [bbox_cropped, valid] = bboxcrop(bbox_tmp, sub_size, OverlapThreshold=0.8);
            bbox_cropped = round(bbox_cropped); % make sure we round all data

            % randomize for selecting background images that dont have
            % bboxes
            X = 0.1; % The desired percentage of 1's (e.g., 20%)
            background_selector = rand() < X;
            %classname = bbox{1,4}(valid);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if valid || background_selector
                sub_imgs{counter,1} = sub_img; 
                if ~RGB_image
                    sub_imgs{counter,1} = cat(3,sub_img,sub_img,sub_img); % only for CCP images from a folder need to delete after
                end
                sub_bboxes{counter,1} = bbox_cropped;
                counter = counter+1;
                if phi_image
                    % rotate all phi images so we save them 3 times
                    % (rotate by 60 degrees)
                    phi_rot_0 = sub_imgs(:,:,2);
                    phi_rot_60 = phi_rot_0 + (1/3);
                    phi_rot_120 = phi_rot_0 + (2/3);

                    mask60 = phi_rot_60 > 1;
                    mask120 = phi_rot_120 > 1;

                    phi_rot_60(mask) = phi_rot_60(mask) -(1/3);
                    phi_rot_120(mask) = phi_rot_120(mask) -(1/3);

                    sub_imgs{counter,1} = cat(3,sub_imgs(:,:,1),phi_rot_60,sub_imgs(:,:,3));
                    sub_bboxes{counter,1} = bbox_cropped;
                    counter = counter+1;
                    sub_imgs{counter,1} = cat(3,sub_imgs(:,:,1),phi_rot_120,sub_imgs(:,:,3));
                    sub_bboxes{counter,1} = bbox_cropped;
                    counter = counter+1;
                end
                if RGB_image
                    % shift hte RGB images to make 3 versions of it (each
                    % shifted by 60 degrees
                    sub_imgs{counter,1} = cat(3, sub_img(:,:,3),sub_img(:,:,1),sub_img(:,:,2));
                    sub_bboxes{counter,1} = bbox_cropped;
                    counter = counter+1;
                    sub_imgs{counter,1} = cat(3, sub_img(:,:,2),sub_img(:,:,3),sub_img(:,:,1));
                    sub_bboxes{counter,1} = bbox_cropped;
                    counter = counter+1;
                end
            end
        end
    end
    fprintf('\nFinished Cropping images\n')
end
end


