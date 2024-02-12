# Remove previous packages.
rm -rf packages

# Compile into .deb
gmake clean package SIDELOAD=1 DEVTOOLS=1

# Rename newly created .deb
find packages/*.deb -exec sh -c 'mv "$0" packages/Enmity.deb' {} \;