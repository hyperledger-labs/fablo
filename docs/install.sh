#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Installing Fablo..."

# Check if curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}Error: curl is required but not installed.${NC}"
  echo "Please install curl and try again."
  exit 1
fi

# Determine installation location
INSTALL_DIR="${FABLO_INSTALL_DIR:-$(pwd)}"
INSTALL_PATH="$INSTALL_DIR/fablo"

# Download fablo.sh
echo "Downloading script..."
if curl -f -sSL https://fablo.io/fablo.sh -o "$INSTALL_PATH"; then
  chmod +x "$INSTALL_PATH"
  echo ""
  echo -e "${GREEN}✓ Fablo installed successfully!${NC}"
  echo ""
  echo "You can now use Fablo with:"
  echo ""
  if [ "$INSTALL_PATH" = "./fablo" ] || [ "$INSTALL_PATH" = "$(pwd)/fablo" ]; then
    echo "  ./fablo init"
    echo "  ./fablo up"
  else
    echo "  $INSTALL_PATH init"
    echo "  $INSTALL_PATH up"
  fi
else
  echo -e "${RED}Error: Failed to download Fablo.${NC}"
  echo "Please check your internet connection and try again."
  exit 1
fi
