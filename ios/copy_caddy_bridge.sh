#!/bin/bash
# Copy CaddyBridge.xcframework to the app bundle's Frameworks directory.
# Add this as a "Run Script" build phase in Xcode:
#   ${SRCROOT}/copy_caddy_bridge.sh

CADDY_FRAMEWORK="${SRCROOT}/../go/caddy_bridge/build/CaddyBridge.xcframework"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ -d "${CADDY_FRAMEWORK}" ]; then
    mkdir -p "${DEST_DIR}"
    cp -r "${CADDY_FRAMEWORK}" "${DEST_DIR}/"
    echo "Copied CaddyBridge.xcframework to ${DEST_DIR}"
else
    echo "Warning: CaddyBridge.xcframework not found at ${CADDY_FRAMEWORK}"
    echo "Build it with: make -C go/caddy_bridge ios"
fi
