#!/bin/sh
PACKAGE_NAME="$1"
REPO_URL="http://github.com/guestsneezeosdev/repo " # Replace the Username with your username
INSTALL_DIR="/root"  # Change this to your desired install directory
if [ -z "$PACKAGE_NAME" ]; then
  echo "Usage: $0 <package_name>"
  exit 1
fi
PACKAGE_FILE="${PACKAGE_NAME}"
wget -q "$REPO_URL/$PACKAGE_FILE" -O "$PACKAGE_FILE"
if [ ! -f "$PACKAGE_FILE" ]; then
  echo "Package not found or failed to download."
  exit 1
fi
echo "Package $PACKAGE_NAME installed successfully."

