function comb_table = combine_training_table(table1,table2)

blds_1_cell = table2cell(table1);
blds_2_cell = table2cell(table2);
comb_cell = cat(1,blds_1_cell,blds_2_cell);
comb_table = cell2table(comb_cell, 'VariableNames', {'imageFilename','myelinDefects'});
end