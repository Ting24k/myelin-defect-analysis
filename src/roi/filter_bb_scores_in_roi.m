% Helper function to filter bounding boxes and scores within ROI polygon
function [bb_filtered, scores_filtered] = filter_bb_scores_in_roi(bb_data, roi_polygon, scores)
    % bb_data is expected to be Nx4 [x, y, width, height] or Nx5 [x, y, w, h, score]
    % roi_polygon is Mx2 [x, y] coordinates of the polygon
    % scores (optional) is Nx1 array of confidence scores
    
    % Initialize outputs
    bb_filtered = [];
    scores_filtered = [];
    
    if isempty(bb_data)
        return;
    end
    
    % Calculate bounding box centers
    bb_centers_x = bb_data(:, 1) + bb_data(:, 3) / 2;
    bb_centers_y = bb_data(:, 2) + bb_data(:, 4) / 2;
    
    % Check which centers are inside the ROI polygon
    inside = inpolygon(bb_centers_x, bb_centers_y, roi_polygon(:, 1), roi_polygon(:, 2));
    
    % Filter bounding boxes
    bb_filtered = bb_data(inside, :);
    
    % Filter scores if provided
    if nargin >= 3 && ~isempty(scores)
        % Check if scores length matches bb_data
        if length(scores) == size(bb_data, 1)
            scores_filtered = scores(inside);
        else
            warning('Score array length (%d) does not match bounding box count (%d). Scores not filtered.', ...
                    length(scores), size(bb_data, 1));
            scores_filtered = scores;  % Return original scores
        end
    end
end