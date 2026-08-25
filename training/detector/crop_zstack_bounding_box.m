function [output_table,combined_datastore] = crop_zstack_bounding_box(mat_folderpath, output_size,number_crops, output_path)
    if ~exist("output_path", 'dir')
        mkdir(output_path)
    end

    if isa(output_path,'string')
        output_path = char(output_path);
    end

    if output_size(3) < 2
        error('Input must be a Z stack of certain size')
    end
    cd(mat_folderpath)
    files = dir('*.mat');
    counter = 1;
    for k = 1:length(files)
        mat_filepath = [files(k).folder, '\',files(k).name];

        % load the mat file structure that holds all the
        tmp_struct = load(mat_filepath).Annotation_struct;

        for ii = 1:length(tmp_struct)
            coordinates = tmp_struct.bounding_box;
            zstack = load_zstack([tmp_struct(ii).foldername, '\' ,tmp_struct(ii).filename]);
            zstack = zstack(:,:,1:output_size(3)); % only get the number of planes that we need for training
            for i = 1:number_crops
                try
                    rectx = round((output_size(1)-coordinates(3))*rand(1,1));
                    recty = round((output_size(2)-coordinates(4))*rand(1,1));
                    tmp_crop = imcrop3(zstack, [coordinates(1)-rectx,coordinates(2)-recty,1,output_size(2)-1,output_size(1)-1,output_size(3)-1]);
                    
                    [~,f,~]=fileparts(tmp_struct(ii).filename);
                    ImageFilename{counter,1} = [output_path, '\', f, '_', '_crop_',num2str(i),'_img_', num2str(ii), '.tif'];
                    write_zstack(uint8(tmp_crop), ImageFilename{counter,1})
                    new_bounding_box = [rectx+1, recty+1,coordinates(3),coordinates(4)];
                    defect{counter,1} = new_bounding_box;
                    save([output_path, '\',f, '_crop_',num2str(i), '_img_', num2str(ii), '.mat'], 'new_bounding_box');
                    counter = counter + 1;
                catch 
                    disp('didnt work')
                end
%                 tmp_cropped = imcrop(tmp_img,[coordinates(1)-rectx,coordinates(2)-recty,output_size(2)-1,output_size(1)-1]);
%                 cropped_images = pad_array_custom(tmp_cropped,output_size(2)-size(tmp_cropped,2),0,output_size(1)-size(tmp_cropped,1),0);
%                 new_bounding_box = [rectx+1, recty+1,coordinates(3),coordinates(4)];
%                 defect{counter,1} = new_bounding_box;
%                 %bounding_box_gtruth{counter,1} = table(new_bounding_box, 'VariableNames',{'defect'});
%                 [~,f,~]=fileparts(tmp_struct(ii).filename);
%                 cd(output_path)
%                 current = pwd;
%                 ImageFilename{counter,1} = [current, '\', f, '_', num2str(tmp_struct(ii).z_plane), '_',num2str(i), '.tif'];
%                 RGB_img = cat(3, cropped_images,cropped_images, cropped_images);
%                 imwrite(RGB_img, ImageFilename{counter,1});
%                 save([f, '_', num2str(tmp_struct(ii).z_plane), '_',num2str(i), '.mat'], 'new_bounding_box');
                
            end
            fprintf('File: %s - Finished Cropping image #%d \n',files(k).name, ii)
        end
    end
    
    output_table = table(ImageFilename,defect);
    blds = boxLabelDatastore(output_table(:,2:end));
    imds = imageDatastore(output_table.ImageFilename);
    combined_datastore = combine(imds,blds);
end