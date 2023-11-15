#### How To
> Run command below
```sh
DHIS2_VERSION="2.40" && \
DHIS2_UPDATE_FILE="/var/lib" && \
rm -rf updates && \
url="https://github.com/HISP-Uganda/auto-installer-hmis100-tracker-integrator.git" && \
git clone -b "$DHIS2_VERSION" "$url" updates && \
cd updates && \
chmod u+x update.sh && \
./update.sh dhis2_version="$DHIS2_VERSION" file_path="$DHIS2_UPDATE_FILE" \
age_filed="Client Age" \
name_field="Client Name" \
parish_field="Parish" \
sex_field="Sex" \
sub_county_district_field="Subcounty/District" \
village_field="Village"
```
