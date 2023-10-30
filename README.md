#### How To
> Run command below
```sh
DHIS2_VERSION="{dhis2_version}" && \
rm -rf updates && \
url="{repo}" && \
git clone -b "$DHIS2_VERSION" "$url" updates && \
cd updates && \
./update.sh "$DHIS2_VERSION"

```
> e.g.
```sh
DHIS2_VERSION="2.38" && \
rm -rf updates && \
url="https://github.com/HISP-Uganda/auto-installer-hmis100-tracker-integrator.git" && \
git clone -b "$DHIS2_VERSION" "$url" updates && \
cd updates && \
chmod u+x update.sh && \
./update.sh "$DHIS2_VERSION"

```
