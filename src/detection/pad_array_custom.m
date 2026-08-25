function array = pad_array_custom(array, Left,Right,Top,Bottom)
    % apply zero padding to the array starting with left and right side
    LR_zero = zeros(size(array,1),1);
   
    array = [repmat(LR_zero,1,Left) array  repmat(LR_zero,1,Right)];
    
    TB_zero = zeros(1,size(array,2));

    array = vertcat(repmat(TB_zero,Top,1),array,  repmat(TB_zero,Bottom,1));
end 