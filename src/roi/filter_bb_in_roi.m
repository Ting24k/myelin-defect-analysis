% Helper function to filter bounding boxes within ROI polygon
function bb_filtered = filter_bb_in_roi(bb_data, roi_polygon)
    % bb_data is expected to be Nx4 [x, y, width, height] or Nx5 [x, y, w, h, score]
    % roi_polygon is Mx2 [x, y] coordinates of the polygon
    
    if isempty(bb_data)
        bb_filtered = bb_data;
        return;
    end
    
    % Calculate bounding box centers
    bb_centers_x = bb_data(:, 1) + bb_data(:, 3) / 2;
    bb_centers_y = bb_data(:, 2) + bb_data(:, 4) / 2;
    
    % Check which centers are inside the ROI polygon
    inside = inpolygon(bb_centers_x, bb_centers_y, roi_polygon(:, 1), roi_polygon(:, 2));
    
    % Filter bounding boxes
    bb_filtered = bb_data(inside, :);
end