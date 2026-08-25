function [train, test] = load_annotation_datastores(output_table)
    data= cell(1,2);
    for i = 1:2
        table_tmp = output_table{2,i};
        blds = boxLabelDatastore(table_tmp(:,2:end));
        imds = imageDatastore(table_tmp.ImageFilename);
        data{i} = combine(imds,blds);
    end
    train = data{1};
    test = data{2};
end