function [sub_imgs, sub_bboxes] = crop_img_and_bbox(img_name,bbox,width,height,step, z)
% function to take in an image (zstack) and return an array of subimages with their
% bounding boxes.
%z=3; %only odd, because we want defect to be in the middle??

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
        img_type=imfinfo(img_name).PhotometricInterpretation; %'RGB' 'mono'
        stack_size = length(imfinfo(img_name));
        if strcmp(img_type, 'BlackIsZero')
        for i = 1:z
           if plane<(z+1)/2 %first layers
                Nch = i;
                img_tmp(:,:,i) = imread(img_name,Nch);
            elseif plane>stack_size - (z+1)/2 %last layers
                Nch = stack_size - z + i;
                img_tmp(:,:,i) = imread(img_name,Nch);
           else % normal case - plane is in the middle
                Nch = plane+i-2;
                img_tmp(:,:,i) = imread(img_name,Nch);
            end
        end
    elseif strcmp(img_type, 'RGB')
        %handling extracting data from the first and last layers of z-stack
        for i = 1:z
            if plane<(z+1)/2 %first layers
                Nch = i;
                img_tmp(:,:,:,i) = imread(img_name,Nch);
            elseif plane>stack_size - (z+1)/2 %last layers
                Nch = stack_size - z + i;
                img_tmp(:,:,:,i) = imread(img_name,Nch);
            else % normal case - plane is in the middle
                Nch = plane+i-2;
                img_tmp(:,:,:,i) = imread(img_name,Nch);
            end
        end
    end
    else
        img_type= 'RGB';
        img_tmp = img_name;
    end
    
    idx = (bbox{1,5}==plane);
    bbox_tmp = bbox{1,6}(idx,:);

    % Compute the number of sub-images
    num_blocksx = floor((size(img_tmp,2)-2*width)/step)+2;
    num_blocksy = floor((size(img_tmp,1)-2*height)/step)+2;
    for j =1:num_blocksy
        for i = 1:num_blocksx
            try

            %%%%%%% crop Image %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            rectx = (i-1)*step+1; % top left corner x value of cropped image
            recty = (j-1)*step+1; % top left corner y value of cropped image
            sub_size = [rectx, recty, width, height];
            if strcmp(img_type, 'BlackIsZero')
                for k=1:z
                    
                    sub_img(:,:,k) = imcrop(img_tmp(:,:,k), sub_size);
                    % uncomment to debug
                    %imshow(sub_img)
                    %title(sprintf('Image X:%d Y:%d \n',i,j))
                    %drawnow
                    % input('Press enter to continue...')
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
                    %%%% Zero Padding %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % calculate if we have the correct size image,
                    missingx = width - size(sub_img, 2)+1;
                    missingy = height - size(sub_img, 1)+1;
        
                    %if not we pad with 0
                    sub_img(:,:,k) = padarray(sub_img(:,:,k),[missingy,missingx], 'post');
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end
            elseif strcmp(img_type, 'RGB')
                for k=1:z
                    
                    sub_img(:,:,:,k) = imcrop(img_tmp(:,:,:,k), sub_size);
                    % uncomment to debug
                    %imshow(sub_img)
                    %title(sprintf('Image X:%d Y:%d \n',i,j))
                    %drawnow
                    % input('Press enter to continue...')
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
                    %%%% Zero Padding %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % calculate if we have the correct size image,
                    missingx = width - size(sub_img, 2)+1;
                    missingy = height - size(sub_img, 1)+1;
        
                    %if not we pad with 0
                    sub_img(:,:,:,k) = padarray(sub_img(:,:,:,k),[missingy,missingx], 'post');
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   
                end
            end

            %%%%%%% check and modify bounding boxes %%%%%%%%%%%%%%%%%%%%%
            % need to handle the bboxes. Use bbox crop to determine which
            % bboxes are in the proper range.
            [bbox_cropped, valid] = bboxcrop(bbox_tmp, sub_size, OverlapThreshold=0.8);
            bbox_cropped = round(bbox_cropped); % make sure we round all data
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if valid
                sub_imgs{counter,1} = sub_img;
                sub_bboxes{counter,1} = bbox_cropped;
                counter = counter+1;
            end
            catch
                disp('error')%error
            end
        end
    end
end
end