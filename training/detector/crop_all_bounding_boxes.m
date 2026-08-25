function [output_table] = crop_all_bounding_boxes(mat_folderpath, output_size,number_crops, output_path)
    if ~exist("output_path", 'dir')
        mkdir(output_path)
        mkdir([output_path,'\Test'])
        mkdir([output_path,'\Training'])
    end
    cd(mat_folderpath)
    %files = dir('*.mat');
    files = fileDatastore(pwd,"ReadFcn",@load,"FileExtensions",".mat", 'IncludeSubfolders',true).Files;
    counter = [1,1,1];
    output_counter = 1;
    total_images = 0;
    for k = 1:length(files)
        mat_filepath = files{k};
        tmp_struct = load(mat_filepath).annotations;
        total_images = total_images + length(tmp_struct);
    end
    
    m = repelem([1 2], [round(total_images*0.8) round(total_images*0.2)]);
    output_type = m(randperm(numel(m)));

    for k = 1:length(files)
        
        mat_filepath = files{k};
        
        % load the mat file structure that holds all the
        tmp_struct = load(mat_filepath).annotations;
        for ii = 1:length(tmp_struct{1,5})
            tmp_img = imread(erase(files{k}, '.mat'), tmp_struct{1,5}(ii));
            coordinates = tmp_struct{1,6}(ii,:);
            for i = 1:number_crops
                rectx = round((output_size(1)-coordinates(3))*rand(1,1));
                recty = round((output_size(2)-coordinates(4))*rand(1,1));
                
                
                tmp_cropped = imcrop(tmp_img,[coordinates(1)-rectx,coordinates(2)-recty,output_size(2)-1,output_size(1)-1]);
                %cropped_images = pad_array_custom(tmp_cropped,output_size(2)-size(tmp_cropped,2),0,output_size(1)-size(tmp_cropped,1),0);
                pad_size = output_size([1 2])-size(tmp_cropped, [1 2]);
                
                % if there is any truncating of the image just skip it. 
                if any(pad_size)
                    disp('Not saving this iamge')
                    continue
                else
                    %III = padarray(tmp_cropped, floor(pad_size/2), 'pre');
                    %cropped_images = padarray(III, ceil(pad_size/2), 'post');
                    cropped_images = tmp_cropped;
                    new_bounding_box = [rectx+1, recty+1,coordinates(3),coordinates(4)];
                    
                    % uncomment to view all cropping and bb 
%                     imshow(tmp_cropped)
%                     hold on
%                     rectangle('Position', new_bounding_box, 'EdgeColor','w', 'LineWidth',3)
%                     input('Enter to Continue')
%                     clf()
                    %bounding_box_gtruth{counter,1} = table(new_bounding_box, 'VariableNames',{'defect'});
                    [~,f,~]=fileparts(files{k});
                end

                switch output_type(output_counter)
                    case 1
                        cd([output_path,'\Training'])
                    case 2
                        cd([output_path,'\Test'])
                end

                current = pwd;
                if counter == 1
                    defect{1,output_type(output_counter)}{1,1} = new_bounding_box;
                    ImageFilename{1,output_type(output_counter)}{1,1} = [current, '\', f, '_', num2str(tmp_struct{1,5}(ii)), '_',num2str(i),'_img_', num2str(ii), '.tif'];
                end
                defect{1,output_type(output_counter)}{counter(output_type(output_counter)),1} = new_bounding_box;
                ImageFilename{1,output_type(output_counter)}{counter(output_type(output_counter)),1} = [current, '\', f, '_', num2str(tmp_struct{1,5}(ii)), '_',num2str(i),'_img_', num2str(ii), '.tif'];
                
                % need to handle RGB and grayscale images (need to fix)
                RGB_img = cat(3, cropped_images,cropped_images, cropped_images);
                RGB_img = cropped_images;
                
                
                imwrite(RGB_img, ImageFilename{1,output_type(output_counter)}{counter(output_type(output_counter)),1});
                %save([f, '_', num2str(tmp_struct(ii).z_plane), '_',num2str(i),'_img_', num2str(ii), '.mat'], 'new_bounding_box');
                counter(output_type(output_counter)) = counter(output_type(output_counter)) +1;
            end

            fprintf('File: %s - Finished Cropping image #%d \n',files{k}, ii)
            output_counter =  output_counter +1; % increment to change the type of output for that image
        end
        
    end
    training = table(ImageFilename{1,1},defect{1,1}, 'VariableNames', {'ImageFilename', 'defect'});
    test = table(ImageFilename{1,2},defect{1,2}, 'VariableNames', {'ImageFilename', 'defect'});
    output_table = {'Training', 'Test', ; training, test};
    save([output_path, '\AnnotationTable.mat'], 'output_table')
%     output_table = table(ImageFilename,defect);
%     blds = boxLabelDatastore(output_table(:,2:end));
%     imds = imageDatastore(output_table.ImageFilename);
%     combined_datastore = combine(imds,blds);
    
end