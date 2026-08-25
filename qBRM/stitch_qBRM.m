function out = stitch_qBRM(folder, gridx, gridy, overlap, filenames)  
    % Setup variables and image data
    % folder = strrep(string(folder), '\', '\\');
    % filenames = strrep(string(filenames), '\', '\\');
    % loc = folder + '\\' + filenames;

    % Change to work for linux as well
    folder = string(folder);
    filenames = string(filenames);
    loc = fullfile(folder, filenames);
    

    overlap = overlap / 100;

    % Read the first image to determine size and data type
    sample_image = imread(sprintf(loc, 1));
    img_class = class(sample_image);
    
    % Get the dimensions of the image
    [ysize, xsize, zsize] = size(sample_image);

    % Determine overlap size
    oversizex = round(xsize * overlap);
    oversizey = round(ysize * overlap);
    
    % Initialize stitched image with correct data type
    bodyx = xsize - 2 * oversizex;
    bodyy = ysize - 2 * oversizey;
    
    im = zeros(ysize, gridx * bodyx + (gridx + 1) * oversizex, zsize, img_class);
    
    [~, imsizex, ~] = size(im);
    imcell = {};
    
    for j = 1:gridy
        startpoint = (j - 1) * gridx + 1;
        
        if ~mod(j, 2) == 0
            im1 = imread(sprintf(loc, startpoint));
            im(:, 1:oversizex, :) = im1(:, 1:oversizex, :);
            
            for i = startpoint:startpoint + gridx - 2
                im2 = imread(sprintf(loc, i + 1));
                im1body = im1(:, oversizex + 1:xsize - oversizex, :);
                im2body = im2(:, oversizex + 1:xsize, :);
                im1over = im1(:, xsize - oversizex + 1:xsize, :);
                im2over = im2(:, 1:oversizex, :);

                % Generate blending weights
                mult1 = cast(oversizex:-1:1, 'double');
                mult2 = cast(1:oversizex, 'double');

                % Blending with correct data type
                % overim = cast((mult1 .* double(im1over) + mult2 .* double(im2over)) / (oversizex + 1), img_class);
                
                % real + real   -> normal blending
                % real + black  -> keep the real overlap
                % black + real  -> keep the real overlap
                % black + black -> black
                
                % Remove bad values first
                im1over(~isfinite(im1over)) = 0;
                im2over(~isfinite(im2over)) = 0;
                % Normal horizontal blending
                overim = cast((mult1 .* double(im1over) + mult2 .* double(im2over)) / (oversizex + 1), img_class);
                black1 = all(im1over == 0, 3);
                black2 = all(im2over == 0, 3);
                
                black1 = repmat(black1, 1, 1, zsize);
                black2 = repmat(black2, 1, 1, zsize);
                
                mask = ~black1 & black2;
                overim(mask) = im1over(mask);
                
                mask = black1 & ~black2;
                overim(mask) = im2over(mask);
                
                mask = black1 & black2;
                overim(mask) = cast(0, img_class);


                im(:, (i - startpoint) * (bodyx + oversizex) + oversizex + 1:(i - startpoint) * (bodyx + oversizex) + bodyx + oversizex, :) = im1body;
                im(:, (i - startpoint) * (bodyx + oversizex) + bodyx + oversizex + 1:(i - startpoint) * (bodyx + oversizex) + bodyx + 2 * oversizex, :) = overim;
                im1 = im2;
            end
            im(:, imsizex - bodyx - oversizex + 1:imsizex, :) = im2body;
        else
            im1 = imread(sprintf(loc, startpoint + gridx - 1));
            im(:, 1:oversizex, :) = im1(:, 1:oversizex, :);
            
            for i = startpoint + gridx - 1:-1:startpoint + 1
                im2 = imread(sprintf(loc, i - 1));
                im1body = im1(:, oversizex + 1:xsize - oversizex, :);
                im2body = im2(:, oversizex + 1:xsize, :);
                im1over = im1(:, xsize - oversizex + 1:xsize, :);
                im2over = im2(:, 1:oversizex, :);

                % Generate blending weights
                mult1 = cast(oversizex:-1:1, 'double');
                mult2 = cast(1:oversizex, 'double');

                % Blending with correct data type
                % overim = cast((mult1 .* double(im1over) + mult2 .* double(im2over)) / (oversizex + 1), img_class);
                
                % real + real   -> normal blending
                % real + black  -> keep the real overlap
                % black + real  -> keep the real overlap
                % black + black -> black
                if all(im1over(:) == 0) && all(im2over(:) == 0)
                    overim = zeros(size(im1over), 'like', im1over);                
                elseif all(im1over(:) == 0)                
                    overim = im2over;                
                elseif all(im2over(:) == 0)                
                    overim = im1over;                
                else
                overim = cast((mult1 .* double(im1over) + mult2 .* double(im2over)) / (oversizex + 1), img_class);
                end


                im(:, (gridx - i + startpoint - 1) * (bodyx + oversizex) + 1 + oversizex:(gridx - i + startpoint) * (bodyx + oversizex), :) = im1body;
                im(:, (gridx - i + startpoint - 1) * (bodyx + oversizex) + 1 + bodyx + oversizex:(gridx - i + startpoint) * (bodyx + oversizex) + oversizex, :) = overim;
                im1 = im2;
            end
            im(:, imsizex - bodyx - oversizex + 1:imsizex, :) = im2body;
        end
        imcell = [imcell {im}];
    end
    
    % Stitches together the rows into a complete image
    im = zeros(gridy * bodyy + (gridy + 1) * oversizey, gridx * bodyx + (gridx + 1) * oversizex, zsize, img_class);
    
    [imsizey, ~, ~] = size(im);
    im1 = imcell{1};
    im(1:oversizey, :, :) = im1(1:oversizey, :, :);
    
    for i = 2:length(imcell)
        im2 = imcell{i};
        im1body = im1(oversizey + 1:ysize - oversizey, :, :);
        im2body = im2(oversizey + 1:ysize, :, :);
        im1over = im1(bodyy + oversizey + 1:ysize, :, :);
        im2over = im2(1:oversizey, :, :);

        % Generate blending weights
        mult1 = cast((oversizey:-1:1)', 'double');
        mult2 = cast((1:oversizey)', 'double');

        % Blending with correct data type
        % overim = cast((mult1 .* double(im1over) + mult2 .* double(im2over)) / (oversizey + 1), img_class);
        % real + real   -> normal blending
        % real + black  -> keep the real overlap
        % black + real  -> keep the real overlap
        % black + black -> black
        
        overim = cast((mult1 .* double(im1over) + mult2 .* double(im2over)) / (oversizey + 1), img_class);
        
        black1 = all(im1over == 0, 3);
        black2 = all(im2over == 0, 3);
        
        black1 = repmat(black1, 1, 1, zsize);
        black2 = repmat(black2, 1, 1, zsize);
        
        mask = ~black1 & black2;
        overim(mask) = im1over(mask);
        
        mask = black1 & ~black2;
        overim(mask) = im2over(mask);
        
        mask = black1 & black2;
        overim(mask) = cast(0, img_class);


        im((i - 2) * (bodyy + oversizey) + oversizey + 1:(i - 2) * (bodyy + oversizey) + bodyy + oversizey, :, :) = im1body;
        im((i - 2) * (bodyy + oversizey) + bodyy + oversizey + 1:(i - 2) * (bodyy + oversizey) + bodyy + 2 * oversizey, :, :) = overim;
        im1 = imcell{i};
    end
    im(imsizey - bodyy - oversizey + 1:imsizey, :, :) = im2body;
    out = im;
end
