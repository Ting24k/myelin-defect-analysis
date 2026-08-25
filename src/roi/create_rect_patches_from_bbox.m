function [patchx, patchy] = create_rect_patches_from_bbox(bbox)
width = bbox(:,3)';
height = bbox(:,4)';

TLx =  bbox(:,1)';
TRx = TLx + width;
BRx = TLx + width;
BLx = TLx;
TLy = bbox(:,2)';
TRy = TLy;
BRy = TLy + height;
BLy = TLy + height;

patchx = [TLx;TRx;BRx;BLx];
patchy = [TLy;TRy;BRy;BLy];

end