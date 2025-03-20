#!/bin/bash

# Text formatting for better readability
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BOLD}${BLUE}======================================================${NC}"
echo -e "${BOLD}${BLUE}  StrumentiRapidi.it PDF.js Test Script              ${NC}"
echo -e "${BOLD}${BLUE}======================================================${NC}"
echo

# Function to find available browser
find_browser() {
  for browser in google-chrome chrome firefox safari edge; do
    if command -v $browser &> /dev/null; then
      echo $browser
      return
    fi
  done
  echo "none"
}

# Get project directory
PROJECT_DIR=$(pwd)
echo -e "${YELLOW}Project directory: $PROJECT_DIR${NC}"

# Check if a server is already running on port 8000
if nc -z localhost 8000 2>/dev/null; then
  echo -e "${RED}Port 8000 is already in use. Please close any running servers on this port.${NC}"
  echo -e "You can try: ${YELLOW}lsof -i :8000${NC} to find the process"
  exit 1
fi

# Check if we have a web server available
if command -v python3 &> /dev/null; then
  SERVER_CMD="python3 -m http.server 8000"
  SERVER_TYPE="Python http.server"
elif command -v python &> /dev/null; then
  SERVER_CMD="python -m SimpleHTTPServer 8000"
  SERVER_TYPE="Python SimpleHTTPServer"
elif command -v php &> /dev/null; then
  SERVER_CMD="php -S localhost:8000"
  SERVER_TYPE="PHP built-in server"
elif command -v npx &> /dev/null; then
  echo -e "${YELLOW}Installing http-server with npx...${NC}"
  SERVER_CMD="npx http-server -p 8000"
  SERVER_TYPE="Node.js http-server"
else
  echo -e "${RED}No suitable web server found. Please install Python, PHP, or Node.js.${NC}"
  exit 1
fi

# Find available browser
BROWSER=$(find_browser)
if [ "$BROWSER" = "none" ]; then
  echo -e "${YELLOW}No browser found. You'll need to manually open http://localhost:8000/test-pdfjs.html${NC}"
else
  echo -e "${GREEN}Found browser: $BROWSER${NC}"
fi

# Instructions to clear browser cache
echo
echo -e "${BOLD}${YELLOW}Before testing, please clear your browser cache:${NC}"
echo -e "Chrome: ${YELLOW}Settings -> Privacy and security -> Clear browsing data${NC}"
echo -e "Firefox: ${YELLOW}Options -> Privacy & Security -> Cookies and Site Data -> Clear Data${NC}"
echo -e "Safari: ${YELLOW}Preferences -> Advanced -> Show Develop menu -> Develop -> Empty Caches${NC}"
echo -e "Edge: ${YELLOW}Settings -> Privacy, search, and services -> Clear browsing data -> Clear now${NC}"
echo

# Ask user if they've cleared their cache
read -p "Have you cleared your browser cache? (y/n): " clear_cache
if [ "$clear_cache" != "y" ]; then
  echo -e "${YELLOW}Please clear your browser cache before continuing.${NC}"
  exit 1
fi

# Start the server
echo -e "${GREEN}Starting local web server using $SERVER_TYPE on port 8000...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server when done testing.${NC}"
echo

# Open the browser if available
if [ "$BROWSER" != "none" ]; then
  echo -e "${GREEN}Opening test page in $BROWSER...${NC}"
  sleep 2
  $BROWSER "http://localhost:8000/test-pdfjs.html" &
fi

# Start the server
echo -e "${BLUE}Server output:${NC}"
$SERVER_CMD
