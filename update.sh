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
age_field="Age in years"
name_field="Full Name"
parish_field="Parish"
sex_field="Sex"
sub_county_district_field="Subcounty/District"
village_field="Village"

age_field_id=""
name_field_id=""
parish_field_id=""
sex_field_id=""
sub_county_district_field_id=""
village_field_id=""

js_content=""

# Loop over all arguments
for arg in "$@"
do
  # Split the argument into a name and value
  name=$(echo $arg | cut -f1 -d=)
  value=$(echo $arg | cut -f2 -d=)
  delimiter=":"

  if [ "$name" == "dhis2_version" ]; then
    dhis2_version="$value"
  fi
  if [ "$name" == "file_path" ]; then
    file_path="$value"
  fi
  if [ "$name" == "age_field" ]; then
    age_field=$(echo $value | cut -d$delimiter -f1)
    age_field_id=$(echo $value | cut -d$delimiter -f2)
  fi
  if [ "$name" == "name_field" ]; then
    name_field=$(echo $value | cut -d$delimiter -f1)
    name_field_id=$(echo $value | cut -d$delimiter -f2)
  fi
  if [ "$name" == "parish_field" ]; then
    parish_field=$(echo $value | cut -d$delimiter -f1)
    parish_field_id=$(echo $value | cut -d$delimiter -f2)
  fi
  if [ "$name" == "sex_field" ]; then
    sex_field=$(echo $value | cut -d$delimiter -f1)
    sex_field_id=$(echo $value | cut -d$delimiter -f2)
  fi
  if [ "$name" == "sub_county_district_field" ]; then
    sub_county_district_field=$(echo $value | cut -d$delimiter -f1)
    sub_county_district_field_id=$(echo $value | cut -d$delimiter -f2)
  fi
  if [ "$name" == "village_field" ]; then
    village_field=$(echo $value | cut -d$delimiter -f1)
    village_field_id=$(echo $value | cut -d$delimiter -f2)
  fi
done

# Initialize an empty string to store the generated js_content
js_content=""

# Loop through all variables and append the formatted string to the js_content
variables=("age_field" "name_field" "parish_field" "sex_field" "sub_county_district_field" "village_field"
"age_field_id" "name_field_id" "parish_field_id" "sex_field_id" "sub_county_district_field_id" "village_field_id")

for ((i=0; i<${#variables[@]}; i++)); do
    var="${variables[$i]}"
    value="${!var}"  # Get the value of the variable using indirect reference
    js_content+="let $var=\\\"$value\\\""
    if [ $i -lt $((${#variables[@]}-1)) ]; then
        js_content+="\n"
    fi
done

# Enclose the entire js_content in double quotes
js_content="\"$js_content\""

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

    if [ -n "$file_to_replace" ]; then
        # Create a backup of the original file in the container
        lxc exec "$container_name" -- /bin/bash -c "cp \"$first_matching_file\" \"$first_matching_file.bak\""
        # update the file
        lxc exec "$container_name" -- /bin/bash -c "cd \"$dhis2_version\" || return && chmod u+x fields_updater.sh && ./fields_updater.sh \"$file_to_replace\" \"$js_content\""
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
        chmod u+x fields_updater.sh && ./fields_updater.sh "$file_to_replace" "$js_content"
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
