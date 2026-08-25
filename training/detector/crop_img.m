function sub_imgs = crop_img(img_name,width,height,step, z)
% function to take in an image (zstack) and return an array of subimages with their
% bounding boxes.
%z=3; %only odd, because we want defect to be in the middle??
img_type=imfinfo(img_name).PhotometricInterpretation; %'RGB' 'mono'
stack_size = length(imfinfo(img_name));

% Initialize the sub-images and sub-bounding boxes cell arrays
%sub_imgs = cell(num_blocksx*num_blocksy, 1);
%sub_bboxes = cell(num_blocksx*num_blocksy, 1);
counter = 1;
% cycle through all the planes with bounding boxes (annotations)
sub_imgs = {};
for ii = 1:stack_size % only look at the planes with annotations
    try
    % code to potentially use the monochrome Ret or CCP images
    if strcmp(img_type, 'BlackIsZero')
        for i = 1:z
           if ii<(z+1)/2 %first layers
                Nch = i;
                img_tmp(:,:,i) = imread(img_name,Nch);
            elseif ii>stack_size - (z+1)/2 %last layers
                Nch = stack_size - z + i;
                img_tmp(:,:,i) = imread(img_name,Nch);
            else % normal case - ii is middle
                Nch = ii+i-1;
                img_tmp(:,:,i) = imread(img_name,Nch);
            end
        end
    elseif strcmp(img_type, 'RGB')
        %handling extracting data from the first and last layers of z-stack
        for i = 1:z
            if ii<(z+1)/2 %first layers
                Nch = i;
                img_tmp(:,:,:,i) = imread(img_name,Nch);
            elseif ii>stack_size - (z+1)/2 %last layers
                Nch = stack_size - z + i;
                img_tmp(:,:,:,i) = imread(img_name,Nch);
            else % normal case - ii is middle
                Nch = ii+i-1;
                img_tmp(:,:,:,i) = imread(img_name,Nch);
            end
        end
    end
    catch
        img_tmp = imread(img_name);
    end
    % Compute the number of sub-images
    num_blocksx = floor((size(img_tmp,2)-2*width)/step)+2;
    num_blocksy = floor((size(img_tmp,1)-2*height)/step)+2;
    for j =1:num_blocksy
        for i = 1:num_blocksx

            %%%%%%% crop Image %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            rectx = (i-1)*step+1; % top left corner x value of cropped image
            recty = (j-1)*step+1; % top left corner y value of cropped image
            sub_size = [rectx, recty, width, height];
            try
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
            catch
                sub_img = imcrop(img_tmp, sub_size);
            end

            sub_imgs{counter,1} = sub_img;
            counter = counter+1;
            end
        end
    end
end