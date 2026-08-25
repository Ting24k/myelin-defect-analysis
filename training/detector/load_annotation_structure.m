function tmp_img = load_annotation_structure(mat_filepath)
    tmp_struct = load(mat_filepath).Annotation_struct;
    tmp_img = imread([tmp_struct(1).foldername,tmp_struct(1).filename], tmp_struct.z_plane);
end