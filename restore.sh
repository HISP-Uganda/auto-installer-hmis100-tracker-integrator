#!/bin/bash

# Ask the user for the DHIS2 version
read -r -p "Enter the DHIS2 version (e.g. 2.40 etc.): " dhis2_version

# Ask the user if they are using LXC or other
read -r -p "Are you using LXC? (yes/no): " lxc_choice

if [ "$lxc_choice" == "yes" ]; then
    # Ask for the container name
    read -r -p "Enter the container name: " container_name
    first_matching_file=$(lxc exec "$container_name" -- /bin/bash -c "directory='/var/lib/tomcat9/webapps/$container_name/dhis-web-tracker-capture/'; first_matching_file=\$(find \"\$directory\" -type f -name 'app-*.js' | head -n 1); echo \"\$first_matching_file\"")
    if [ -n "$first_matching_file" ]; then
      # Remove the cloned repository and restore the original file in the container
      lxc exec "$container_name" -- /bin/bash -c "rm -rf \"$dhis2_version\" && mv \"$first_matching_file.bak\" \"$first_matching_file\""

      echo "Changes undone in the LXC container."
    else
      echo "Backup file doesn't exist"
    fi
else
    # Ask for the file path
    read -r -p "Enter the file path (e.g., /path/to/your/file.js): " file_path

    if [ -f "$file_path" ] && [[ "$file_path" == *.js ]]; then
        # Remove the cloned repository and restore the original file
        cd "$file_path" && rm -rf icdiframe && mv "$file_path.bak" "$file_path"
        
        echo "Changes undone in the local file system."
    else
        echo "The specified file does not exist or is not a .js file."
    fi
fi
