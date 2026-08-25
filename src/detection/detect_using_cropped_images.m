function [bbox_redone, score_redone, label_redone] = detect_using_cropped_images(detector, image)
    row = detector.Network.Layers(1,1).InputSize(1,1);
    col = detector.Network.Layers(1,1).InputSize(1,2);
    disp(row)
    disp(col)

    % get how many times we need to crop the iage
    y = ceil(size(image,1)/row);
    x = ceil(size(image,2)/col);
    counter = 1;
    for i = 1:x %number of times to crop in the x direction
        for ii = 1:y % number of times to crop in the y direction 
            detector_image = imcrop(image,[(i-1)*row+1, (ii-1)*col+1,col-1, row-1]);
            image_cropped{ii,i} = imcrop(image,[(i-1)*row+1, (ii-1)*col+1,col-1, row-1]);
            
            if (size(image_cropped{ii,i},1) < row) || (size(image_cropped{ii,i},2) < col)
                continue
                %image_cropped{ii,i} = pad_array_custom(image_cropped{ii,i},0,col-size(image_cropped{ii,i},2), 0,row-size(image_cropped{ii,i},1));
            end
            %detector_image = cat(3,detector_image,detector_image,detector_image);
            [bboxes,scores,labels] = detect(detector,detector_image);
            if ~isempty(bboxes)
                %Display the results.
                detector_image = insertObjectAnnotation(detector_image,'rectangle',bboxes, scores);
            else
                detector_image = detector_image;
            end
            imshow(detector_image)
            input('Press enter to continsue...')

            if ~isempty(bboxes)
                bbox_redone{counter,1} = [bboxes(1)+(i-1)*row,bboxes(2)+(ii-1)*col,bboxes(3),bboxes(4)];
                score_redone{counter,1} = [scores];
                label_redone{counter,1} = [labels];
                counter = counter+1;
            end
        end
    end
end