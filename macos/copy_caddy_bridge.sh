#!/bin/bash
# Copy libcaddy_bridge.dylib to the app bundle's Frameworks directory.
# Add this as a "Run Script" build phase in Xcode:
#   ${SRCROOT}/copy_caddy_bridge.sh

CADDY_LIB="${SRCROOT}/../go/caddy_bridge/build/libcaddy_bridge.dylib"
CADDY_LIB_FALLBACK="${SRCROOT}/libs/libcaddy_bridge.dylib"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ -f "${CADDY_LIB}" ]; then
    mkdir -p "${DEST_DIR}"
    cp "${CADDY_LIB}" "${DEST_DIR}/"
    echo "Copied libcaddy_bridge.dylib to ${DEST_DIR}"
elif [ -f "${CADDY_LIB_FALLBACK}" ]; then
    mkdir -p "${DEST_DIR}"
    cp "${CADDY_LIB_FALLBACK}" "${DEST_DIR}/"
    echo "Copied libcaddy_bridge.dylib from libs/ fallback to ${DEST_DIR}"
else
    echo "Warning: libcaddy_bridge.dylib not found"
    echo "Build it with: make -C go/caddy_bridge macos"
fi
