function find_defects(folder_path, width, height, step_size, z_size)
%z_size - in how many planes across z we want to cut images
    original = pwd;
    cd(folder_path)


    % loop through all images in folder and save then into a cell array
    files = dir('*.tif');
    % check image type
    img_type=imfinfo(files(1).name).PhotometricInterpretation;
    
    sub_img_all = {};
    fprintf('Cropping all Bounding Boxes     ')
    for i = 1:length(files)
        sub_imgs = crop_img(files(i).name,width,height,step_size, z_size);
        sub_img_all = cat(1, sub_img_all, sub_imgs);
        fprintf('\b\b\b\b\b[%2.0d%%]',round(100*(i/length(files))))
    end
    fprintf('\nCropped all images\n')
    % save all the images and other stuff

    train_count = 1;
    mkdir('test')
    cd('test')

    fprintf('Saving images     ')
    for i = 1:length(sub_img_all)
        img_name = sprintf('img_%05d.png',i);
        if strcmp(img_type, 'BlackIsZero')
            if size(sub_img_all{i},3)>1
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
        train_count = train_count+1;
        fprintf('\b\b\b\b\b[%2.0i%%]',round(100*(i/length(sub_img_all))))
    end
    fprintf('\nSaved all images\n')
    % go back to our original file path
    cd(original)
end