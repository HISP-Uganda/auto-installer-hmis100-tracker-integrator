#### How To
> Run command below
```sh
DHIS2_VERSION="2.40" && \
DHIS2_UPDATE_FILE="/var/lib" && \
OUTCOME_FIELDS="Client Age,Client Name,Parish,Sex,Subcounty/District,Village"
rm -rf updates && \
url="https://github.com/HISP-Uganda/auto-installer-hmis100-tracker-integrator.git" && \
git clone -b "$DHIS2_VERSION" "$url" updates && \
cd updates && \
chmod u+x update.sh && \
./update.sh dhis2_version="$DHIS2_VERSION" file_path="$DHIS2_UPDATE_FILE" outcome_fields="$OUTCOME_FIELDS"
```
