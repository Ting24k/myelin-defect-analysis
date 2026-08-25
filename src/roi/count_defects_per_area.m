function [defect_per_area, num_defects, area_mm_calc, pos] = count_defects_per_area(img,allBoxes,magnification)
fprintf('First draw the area of the Region of interest to count defects\n')

% If the img size is larger than 1.5GB, downsample it for the display
% purpose
% Calculate total array size in GB
info = whos('img');
img_size_gb = info.bytes / (1024^3);

% Threshold limit (e.g., 1.5 GB)
gb_limit = 1.5; 

if img_size_gb > gb_limit
    scale = 0.2; % Downsample factor
else
    scale = 1;  % Keep original resolution
end

% 1. Downsample image for display only if needed
img_preview = imresize(img,scale);

% 2. Display image and get polygon ROI
figure; imshow(img_preview);
h = drawpolygon();
pos_preview = h.Position;

% 3. Map polygon coordinates back to original image scale
pos = (pos_preview - 0.5) / scale + 0.5;

%draw ROI and calculate the total area of region
% % Original code
% figure; imshow(img) 
% h = drawpolygon();
% pos = h.Position;
area_in_um = (4.25/magnification);
pos_um = pos*area_in_um; % convert from pixels to microns
area_mm_calc = polyarea(pos_um(:,1),pos_um(:,2))/(1000^2);

% calculate the total number of defects within t
overlap_val =inpolygon(allBoxes(:,1),allBoxes(:,2),pos(:,1),pos(:,2));
overlap_val2 = inpolygon(allBoxes(:,3),allBoxes(:,4),pos(:,1),pos(:,2));
overall_overlap = (overlap_val | overlap_val2);
num_defects = sum(overall_overlap(:) == 1);

% return teh defect per area
defect_per_area = num_defects/area_mm_calc;

end 

