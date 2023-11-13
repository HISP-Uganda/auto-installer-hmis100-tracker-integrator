#!/bin/bash

repo="https://github.com/HISP-Uganda/auto-installer-hmis100-tracker-integrator.git"

# Perform a simple Git operation to verify the token
if ! git ls-remote --exit-code "$repo" &> /dev/null; then
    echo "Error: The provided Access Token is invalid."
    exit 1
fi

# Ask the user for the DHIS2 version
# read -p "Enter the DHIS2 version (e.g. 2.40 etc.): " dhis2_version
dhis2_version=""
file_path=""
outcome_fields="Age in Days,Age in Months,Age in years,Full Name,Parish,Sex,Subcounty/District,Village"
# Loop over all arguments
for arg in "$@"
do
  # Split the argument into a name and value
  name=$(echo $arg | cut -f1 -d=)
  value=$(echo $arg | cut -f2 -d=)

  if [ "$name" == "dhis2_version" ]; then
    dhis2_version="$value"
  fi
  if [ "$name" == "file_path" ]; then
    file_path="$value"
  fi
  if [ "$name" == "outcome_fields" ]; then
    outcome_fields="$value"
  fi
done

# Check if the branch exists in the GitHub repository
if ! git ls-remote --exit-code --heads "$repo" "$dhis2_version" &> /dev/null; then
    echo "Error: The specified DHIS2 version ($dhis2_version) is not supported in the repository."
    exit 1
fi

# Ask the user if they are using LXC or other
read -r -p "Are you using LXC? (yes/no): " lxc_choice
if [ "$lxc_choice" == "yes" ]; then
    # Ask for the container name
    read -r -p "Enter the container name: " container_name

   # Run the command inside the LXC container to find the first matching file
   first_matching_file=$(lxc exec "$container_name" -- /bin/bash -c "directory='/var/lib/tomcat9/webapps/$container_name/dhis-web-tracker-capture/'; first_matching_file=\$(find \"\$directory\" -type f -name 'app-*.js' | head -n 1); echo \"\$first_matching_file\"")

# Check if a matching file was found in the container
if [ -n "$first_matching_file" ]; then
    echo "The first matching file in the container is: $first_matching_file"

    # Clone the repository with the specified DHIS2 version as the branch
    lxc exec "$container_name" -- bash -c "git clone -b $dhis2_version $repo $dhis2_version"

    # Find the file with the same name in the cloned files
    file_to_replace=$(lxc exec "$container_name" -- /bin/bash -c "find \"$dhis2_version\" -name \"\$(basename \"$first_matching_file\")\" | head -n 1")

    # Define the script content
    script_content="js_content=\"const niraFormInputs = {\"
    IFS=',' read -ra input_array <<< \"\$outcome_fields\"
    for input in \"\${input_array[@]}\"; do
        js_content+=\"    '\$input': null,\"
    done
    js_content=\"\${js_content%,*}\"
    js_content+=\"\"
    temp_file=\$(mktemp)
    echo \"\$js_content\" > \"\$temp_file\"
    cat \"\$temp_file\" \"$file_to_replace\" > app_temp.js
    mv app_temp.js \"$file_to_replace\"
    rm \"\$temp_file\""

    # Copy the script content into a file in the container
    echo "$script_content" | lxc exec "$container_name" -- bash -c "cat > /js_update.sh"
    lxc exec "$container_name" -- bash -c "chmod u+x /js_update.sh"
    # Execute the script inside the container
    lxc exec "$container_name" -- bash -c "/js_update.sh"

    if [ -n "$file_to_replace" ]; then
        # Create a backup of the original file in the container
        lxc exec "$container_name" -- /bin/bash -c "cp \"$first_matching_file\" \"$first_matching_file.bak\""
    
        # Replace the file in the container
        lxc exec "$container_name" -- /bin/bash -c "cp \"$file_to_replace\" \"$first_matching_file\""
        echo "Replaced the file in the container with $file_to_replace."
    else
        echo "No matching file found in the cloned files."
    fi
else
    echo "No matching file found in the specified directory in the container."
fi
else
    # Ask for the file path
    if [ -n "$DHIS2_UPDATE_FILE" ]; then
        read -r -p "Use environment variable DHIS2_UPDATE_FILE ($DHIS2_UPDATE_FILE) as the file path? (Y/n): " use_env_var
        if [ "$use_env_var" == "n" ]; then
            read -r -p "Do you want to use the path from the file_path argument ($file_path) as the file path? (Y/n): " use_arg_path
            if [ "$use_arg_path" == "n" ]; then
                read -r -p "Enter the file path (e.g., /path/to/your/file.js): " file_path
            else
                file_path="$file_path"
            fi
        else
            file_path="$DHIS2_UPDATE_FILE"
        fi
    else
        read -r -p "Enter the file path (e.g., /path/to/your/file.js): " file_path
    fi

    echo "Selected file path: $file_path"

    # Verify that the file_path exists and is a .js file
    if [ -f "$file_path" ] && [[ "$file_path" == *.js ]]; then
        # Clone the repository with the specified DHIS2 version as the branch
    git clone -b "$dhis2_version" "$repo" "$dhis2_version"
    cd "$dhis2_version" || return

    # Find the file with the same name in the cloned files
    file_to_replace=$(find . -name "$(basename "$file_path")" | head -n 1)

    if [ -n "$file_to_replace" ]; then
        # Create a backup of the original file
        mv "$file_path" "$file_path.bak"
        # Replace the file with the one from the cloned files

        # Create the JavaScript content
        js_content="const niraFormInputs = {"
        IFS=',' read -ra input_array <<< "$outcome_fields"
        for input in "${input_array[@]}"; do
            js_content+="    '$input': null,"
        done
        js_content="${js_content%,*}"
        js_content+="
        }"
        temp_file=$(mktemp)
        echo "$js_content" > "$temp_file"
        cat "$temp_file" "$file_path" > app_temp.js
        mv app_temp.js "$file_path"
        rm "$temp_file"

        mv "$file_to_replace" "$file_path"
        echo "Replaced the file with $file_to_replace."
    else
        echo "No matching file found in the cloned files."
    fi
    else
        echo "The specified file does not exist or is not a .js file."
        exit 1
    fi
fi
