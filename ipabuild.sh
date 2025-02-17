WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=Evyrest
HELPER_EXEC_NAME=evyrestrefresher
CONFIGURATION=Debug

echo "downloading ldid..."
     wget https://nightly.link/ProcursusTeam/ldid/workflows/build/master/ldid_macosx_x86_64.zip
     echo "download finished!"
     echo "unzipping ldid..."
     unzip ldid_macosx_x86_64.zip
     echo "unzipping finished!"
     echo "doing some extra magic..."
     chmod a+x ldid
     chmod a+x ./ldid

# If the folder 'build' does not exist, create it
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

# remove already built tipa if present
if [ -e "$APPLICATION_NAME.tipa" ]; then
rm $APPLICATION_NAME.tipa
fi


DD_BUILD_PATH="$WORKING_LOCATION/build/DerivedData/Build/Products/$CONFIGURATION-iphoneos"
TARGET_APP="build/$APPLICATION_NAME.app"

# Build APPLICATION_NAME
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme $APPLICATION_NAME \
    -configuration $CONFIGURATION \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedData" \
    -destination 'generic/platform=iOS' \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGNING_ALLOWED="NO" 
    
cp -r "$DD_BUILD_PATH/$APPLICATION_NAME.app" "$WORKING_LOCATION/$TARGET_APP"

# Build HELPER_EXEC_NAME
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme $HELPER_EXEC_NAME \
    -configuration $CONFIGURATION \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedData" \
    -destination 'generic/platform=iOS' \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGNING_ALLOWED="NO" 

cp -r "$DD_BUILD_PATH/$HELPER_EXEC_NAME" "$WORKING_LOCATION/$TARGET_APP/$HELPER_EXEC_NAME"


# Remove signature
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi


# Add entitlements
echo "Adding entitlements to $APPLICATION_NAME"
./ldid -S"$WORKING_LOCATION/entitlements.plist" "$WORKING_LOCATION/$TARGET_APP/$APPLICATION_NAME"
echo "Adding entitlements $HELPER_EXEC_NAME"
./ldid -S"$WORKING_LOCATION/entitlements.plist" "$WORKING_LOCATION/$TARGET_APP/$HELPER_EXEC_NAME"


# Package .ipa
rm -rf Payload
mkdir Payload
cp -r $APPLICATION_NAME.app Payload/$APPLICATION_NAME.app

# Zip the Payload and rename
zip -vr $APPLICATION_NAME.tipa Payload

# Cleanup
rm -rf $APPLICATION_NAME.app
rm -rf $HELPER_EXEC_NAME
rm -rf Payload
