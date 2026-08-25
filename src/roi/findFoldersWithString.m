function matching_folders = findFoldersWithString(main_folder, search_string)
    % Initialize an empty array to store matching folder names
    matching_folders = {};
    
    % Get a list of all items in the main folder
    all_items = dir(main_folder);
    
    % Filter out files and only keep directories
    all_folders = all_items([all_items.isdir]);
    
    % Loop through each folder and check if the folder name contains the string
    for i = 1:length(all_folders)
        folder_name = all_folders(i).name;
        
        % Ignore '.' and '..' directories
        if ~strcmp(folder_name, '.') && ~strcmp(folder_name, '..')
            % Full path of the folder
            full_folder_path = fullfile(main_folder, folder_name);
            
            % Check if the folder name contains the search string
            if contains(folder_name, search_string)
                % Add the matching folder name to the list
                matching_folders{end+1} = full_folder_path;
            end
            
            % Recursive call to check subdirectories within this folder
            subfolder_matches = findFoldersWithString(full_folder_path, search_string);
            
            % Append any matches found in the subfolders
            matching_folders = [matching_folders, subfolder_matches];
        end
    end
end


