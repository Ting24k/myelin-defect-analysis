function [cropped_new, new_bounding_box] = randomize_cropping_around_boundingbox(image, number_crops, final_width, final_height, coordinates)
    cropped_new = cell(1,number_crops);
    new_bounding_box = cell(1,number_crops);
    for i = 1:number_crops
        rectx = round((final_width-coordinates(3))*rand(1,1));
        recty = round((final_width-coordinates(4))*rand(1,1));
        cropped_new{i} = imcrop(image,[coordinates(1)-rectx,coordinates(2)-recty,final_width-1,final_height-1]);

        new_bounding_box{i} = [rectx+1, recty+1,coordinates(3),coordinates(4)];
    end
end