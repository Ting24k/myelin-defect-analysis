function create_training_set_zstack_folder(folder_path, width, height, step_size, z_size)
%z_size - in how many planes across z we want to cut images
    original = pwd;
    cd(folder_path)


    % loop through all images in folder and save then into a cell array
    files = dir('*.tif');
    % check image type
    img_type=imfinfo(files(1).name).PhotometricInterpretation;
    
    sub_img_all = {};
    sub_bboxes_all = {};
    fprintf('Cropping all Bounding Boxes     ')
    for i = 1:length(files)
        try
            bbox = load([files(i).name, '.mat']).annotations;
            [sub_imgs, sub_bboxes] = crop_img_and_bbox_v2(files(i).name,bbox,width,height,step_size);
            sub_img_all = cat(1, sub_img_all, sub_imgs);
            sub_bboxes_all = cat(1, sub_bboxes_all, sub_bboxes);
            fprintf('\b\b\b\b\b[%2.0d%%]',round(100*(i/length(files))))
        catch
            % No annotaiton for this file
            x = 0;
        end
    end
    fprintf('\nCropped all images\n')
    % save all the images and other stuff
    varTypes = ["string","cell"];
    varNames = ["imageFilename","myelinDefects"];
    training_table = table('Size',[size(sub_img_all,1) 2],'VariableNames',varNames,'VariableTypes', varTypes);
    train_count = 1;
    mkdir('tif')
    cd('tif')

    fprintf('Saving images     ')
    for i = 1:length(sub_img_all)
        img_name = sprintf('img_%05d.tif',i);
        if strcmp(img_type, 'BlackIsZero')
            if size(sub_img_all{i},3)>3
                write_zstack(sub_img_all{i},img_name)
            else
                imwrite(sub_img_all{i},img_name)
            end
        elseif strcmp(img_type, 'RGB')
            if size(sub_img_all{i},4)>1
                save_tiff(sub_img_all{i},img_name)
            else
                imwrite(sub_img_all{i},img_name)
            end
        end
        training_table{train_count,:} = {[pwd, '\',img_name],sub_bboxes_all{i}};
        train_count = train_count+1;
        fprintf('\b\b\b\b\b[%2.0i%%]',round(100*(i/length(sub_img_all))))
    end
    fprintf('\nSaved all images\n')
    save('Training_table.mat', 'training_table')
    % go back to our original file path
    cd(original)
end