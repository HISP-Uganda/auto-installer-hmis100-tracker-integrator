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
age_field="Age:s2Fmb8zgEem" \
name_field="Client name:sB1IHYu2xQT" \
parish_field="Parish:M3trOwAtMqR" \
sex_field="Sex:FZzQbW8AWVd" \
sub_county_district_field="Subcounty/District:Za0xkyQDpxA" \
village_field="Village:zyhxsh0kFx5"
```
