function solve_widefield_qBRM_folder(folder_loc, varargin)
   
    
   % cd(folder_loc)
   % load cmap for RGB image creation      

    cd(folder_loc)
    files = dir('*.tif'); 
    mkdir('qBRM')
    cd('qBRM')
    mkdir('Ret')
    mkdir('RGB_norm')
    mkdir('phi')
%%%%% Uncomment for transmittance
%%%%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       mkdir('trans') 
%%%%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    cd(folder_loc)

    % try to run flatfield
        if exist('Flatfield', 'dir')
            fprintf('Flatfield Images Detected \n')
            cd('Flatfield')
            ff = double(readTiff('Flatfield.tif'));
            ff_images = ff;

            [I0, ~,~,~] = analytical_qBRM_gpu_all(ff_images, 0);
            ff_I0 = I0;

            ff = ff - mean(ff,3);
            if nargin > 1
                if varargin{1}
                    phi_shift = varargin{1};
                end
                if nargin > 2
                    if varargin{2}
                        ff = 0;
                    end
                end
            else
                phi_shift = 0;
            end
        else
            ff = 0;
            ff_I0 = 0;
            disp('No Flatfield Images detected.')
        end
        gpuDetected = 0;
        if canUseGPU()
            D = gpuDevice;
            %D.CachePolicy = 'maximum';
            fprintf('GPU loaded for analysis\n');
            ff = gpuArray(ff);
            gpuDetected = 1;
        end
    for i = 1:length(files)
        fprintf('######### Running Analysis on image (%d/%d) ######### \n', i,length(files))
        cd(files(i).folder)
        fprintf('Loading Image ("%s") \n', files(i).name)
        tic
        img = readTiff(files(i).name);

        img_num = files(i).name;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        img_num = str2num(img_num(5:7));
        % img_num = str2num(img_num(6:8));

        y = toc;
        fprintf('Loaded Image ("%s") %5.2f seconds\n', files(i).name, y)
        img = single(img);
        
        %% NEW: detect intentionally black ROI tile
        isBlackTile = all(img(:) == 0);

        if isBlackTile        
            fprintf('Black input detected. Saving black qBRM outputs.\n');
        
            output_size = size(img(:,:,1));
        
            trans_norm       = zeros(output_size, 'single');
            phi      = zeros(output_size, 'single');
            A        = zeros(output_size, 'single');
            RGB_norm = zeros([output_size 3], 'single');

            imwrite(im2uint8(RGB_norm), fullfile(folder_loc,'qBRM','RGB_norm', sprintf('RGB_norm_%03d.tif',img_num)));       
            saveastiff(im2single(phi), fullfile(folder_loc,'qBRM','phi', sprintf('phi_%03d.tif',img_num)));       
            saveastiff(im2single(A), fullfile(folder_loc,'qBRM','Ret', sprintf('ret_%03d.tif',img_num)));
            imwrite(im2uint16(trans_norm), fullfile(folder_loc,'qBRM','trans', sprintf('trans_normalized_%03d.tif',img_num)));       
         
            % Skip the rest of this loop
            continue
        end

        if gpuDetected
            img = single(gpuArray(img));
        end
        img = img-ff;


        if length(size(img)) > 3
            % new code for doign gpu calculations
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [I0, phi, A, RGB_norm] = analytical_qBRM_gpu_all(img, ff_I0);


            % old code when the GPU wasnt working 
            % if size(img,4) > 10
            %    [~, phi, A] = analytical_qBRM(img(:,:,1,:),img(:,:,2,:),img(:,:,3,:));
            % 
            %    [~, RGB_norm] = phi_to_rgb_nogpu(phi,cmap,A);
            %    %%%% DO NOT MAKE EDITS TO ANY OF THIS CODE
            % 
            %    x=0;
            % else
            %     [I0, phi, A, RGB_norm] = qBRM_solve_gpu(img);
            % end
            %[A, RGB_norm, phi] = analyze_qBRM_zstack(img, phi_shift);
            %write_zstack(A,sprintf('Ret/ret_%03d.tif',i));
            write_zstack(im2uint8(RGB_norm), fullfile(folder_loc,'qBRM','RGB_norm', sprintf('RGB_norm_%03d.tif',img_num)));
            save_tiff(im2single(phi), fullfile(folder_loc,'qBRM','phi', sprintf('phi_%03d.tif',img_num)));
            save_tiff(im2single(A), fullfile(folder_loc,'qBRM','Ret', sprintf('ret_%03d.tif',img_num)));

%%%%% Uncomment for transmittance
%%%%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            % if exist('Flatfield', 'dir')
            % else
            %     ff_images = 1;
            % end
            % 

            trans_norm = rescale(I0./ff_I0);
            write_zstack(im2uint16(trans_norm), fullfile(folder_loc,'qBRM','trans', sprintf('trans_normalized_%03d.tif',i))); 
%%%%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            else
            %[I0, phi, A, RGB_norm] = qBRM_solve_gpu(img, phi_shift);

            %[A, ~, phi] = solve_qBRM_symbolic_full(img);
            %[~,RGB_norm] = convert_phi_to_RGB(phi, cmap,A);
            %[~, RGB_norm] = phi_to_rgb_nogpu(phi,cmap,A);
            %[I0, phi, A, RGB_norm] = qBRM_solve_gpu(img);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [I0, phi, A, RGB_norm] = analytical_qBRM_gpu_all(img, ff_I0);
            imwrite(im2uint8(RGB_norm), fullfile(folder_loc,'qBRM','RGB_norm', sprintf('RGB_norm_%03d.tif',img_num)));
            saveastiff(im2single(phi), fullfile(folder_loc,'qBRM','phi', sprintf('phi_%03d.tif',img_num)));
            saveastiff(im2single(A), fullfile(folder_loc,'qBRM','Ret', sprintf('ret_%03d.tif',img_num)));

            % Save transmittance

            trans_norm = rescale(I0./ff_I0);
            imwrite(im2uint16(trans_norm), fullfile(folder_loc,'qBRM','trans', sprintf('trans_normalized_%03d.tif',i))) 
        end
    end
    disp('########### Finished qBRM Analysis ###########')
end