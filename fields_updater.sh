#!/bin/bash

file_path=$1 # Use a relative path if the file is in the same directory

new_content=$(echo -e "$2")
result=$(echo "$new_content" | sed 's/^"\(.*\)"$/\1/g; s/\\//g')

if ! grep -q "// Nira generated fields //" "$file_path"; then
    # Add the new content to the top of the file and exit
      { echo -e "// Nira generated fields //"; echo -e "$result"; echo -e "// Nira generated fields //"; cat "$file_path"; } > temp_file
    mv temp_file "$file_path"
    echo "File updated successfully."
    exit
fi

# Find the line number of the second instance of the marker
second_instance_line=$(grep -n -m 2 "// Nira generated fields //" "$file_path" | tail -n 1 | cut -d ":" -f 1)

if [ -z "$second_instance_line" ]; then
    # Second instance not found, exit
    echo "Second instance not found. Exiting."
    exit 1
fi

# Remove content between the markers
awk -v start=1 -v end="$second_instance_line" 'NR < start || NR > end' "$file_path" > temp_file
mv temp_file "$file_path"

# Add the new content to the top of the file
{ echo -e "// Nira generated fields //"; echo -e "$result"; echo -e "// Nira generated fields //"; cat "$file_path"; } > temp_file
mv temp_file "$file_path"

echo "File updated successfully."

