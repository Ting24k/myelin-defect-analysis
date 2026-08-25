function [img, bounding_box,scores_all,label_all] = detect_zstack_defects(detector, image_path)
    image_info = imfinfo(image_path);
    bounding_box = cell(size(image_info));
    scores_all = cell(size(image_info));
    label_all = cell(size(image_info));
    img = cell(size(image_info));
    for i = 1:length(image_info)
        img{i} = imread(image_info(i).Filename, i);
        [bbox,scores, labels] = detect_using_cropped_images(detector, img{i});
        bounding_box{i} = cell2mat(bbox);
        scores_all{i} = scores;
        label_all{i} = labels;
        fprintf('Annotated Images %d/%d \n',i,length(image_info))
    end
end