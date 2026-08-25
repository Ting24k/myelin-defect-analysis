function [defect_per_area, num_defects, area_mm_calc, pos] = count_defects_per_area_ROI(img,allBoxes,magnification, pos)
fprintf('First draw the area of the Region of interest to count defects\n')

%draw ROI and calculate the total area of region 
if isempty(pos) 
    figure; imshow(img) 
    h = drawpolygon();
    pos = h.Position;
end
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

