#!/bin/bash

# Define the port to use for the authentication process
AUTH_PORT=53682
TIMEOUT=300  # Timeout in seconds (5 minutes)

# Function to display GUI instructions
show_instructions() {
  osascript <<EOF
    tell application "System Events"
      activate
      display dialog "NYUAD Rclone-Google Drive File Transfer Utility

Utility if for internal use only. Please contact NYUAD IT on guide to use this utility.

Click \"Proceed\" to continue." with title "NYUAD USE ONLY" buttons {"Proceed"} default button "Proceed"
    end tell
EOF
}

# Function to install rclone using the official installation script
install_rclone2() {
  echo "Installing rclone..."
  sudo -v
  curl https://rclone.org/install.sh | sudo bash
}

# Function to check if Homebrew is installed
check_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Ensure brew command is in the PATH
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "Homebrew is already installed."
  fi
}

# Function to install rclone and coreutils
install_tools() {
  if ! brew list rclone &> /dev/null; then
    echo "Installing rclone..."
    brew install rclone
  else
    echo "rclone is already installed."
  fi

  if ! brew list coreutils &> /dev/null; then
    echo "Installing coreutils..."
    brew install coreutils
  else
    echo "coreutils is already installed."
  fi
}

# Function to check if a port is in use and stop the process using it
ensure_port_free() {
  local port=$1
  if lsof -i:$port &> /dev/null; then
    echo "Port $port is in use. Stopping the process using it..."
    lsof -ti:$port | xargs kill -9
  else
    echo "Port $port is free."
  fi
}

# Function to close browser tab with matching URL
close_browser_tab() {
  sleep 2
  for browser in "Google Chrome" "Safari"; do
    osascript <<EOF
      tell application "$browser"
        repeat with aWindow in every window
          repeat with atab in tabs of aWindow
            if URL of atab contains "127.0.0.1:$AUTH_PORT" then
              close atab
            end if
          end repeat
        end repeat
      end tell
EOF
  done
}

# Function to get list of Team Drives and display in a dialog
select_team_drive() {
  # Fetch the list of drives in JSON format
  json=$(rclone backend drives mygoogledrive:)

  # Extract names and IDs from the JSON
  names=$(echo "$json" | grep -o '"name": "[^"]*' | sed 's/"name": "//' | tr '\n' ',' | sed 's/,$//')

  # Convert names into a format suitable for AppleScript
  applescript_names=$(echo "$names" | sed 's/,/", "/g' | sed 's/^/"&/' | sed 's/$/&"/')

  # Present selection dialog
  selected_name=$(osascript -e "set selectedItem to choose from list {${applescript_names}} with prompt \"Choose a Drive:\" default items {\"Error! Cancel and try again\"} without multiple selections allowed and empty selection allowed")
  echo "Selected name: $selected_name"

  # Find the corresponding ID for the selected name
  if [[ $selected_name ]]; then
      selected_id=$(echo "$json" | grep -B 2 "\"name\": \"$selected_name\"" | grep '"id":' | sed 's/.*"id": "\(.*\)".*/\1/')
      echo "You selected: $selected_name (ID: $selected_id)"
  else
      echo "No selection made."
  fi
}

# Function to configure rclone with Google Drive
configure_rclone() {
  close_browser_tab
  rclone config delete mygoogledrive
  rclone config delete myteamdrive

  echo "Configuring rclone with Google Drive..."
  echo "This will open a browser window for authentication."

  ensure_port_free $AUTH_PORT

  gtimeout $TIMEOUT rclone config create mygoogledrive drive --rc-addr=127.0.0.1:$AUTH_PORT
  close_browser_tab
  select_team_drive
  gtimeout $TIMEOUT rclone config create myteamdrive drive team_drive "$selected_id" --rc-addr=127.0.0.1:$AUTH_PORT

  if [ $? -eq 124 ]; then
    echo "Utility timed out after $TIMEOUT seconds."
    exit 1
  fi

  close_browser_tab
}

# Function to prompt user for file transfer confirmation
prompt_file_transfer() {
  # AppleScript prompt for user confirmation
  response=$(osascript <<EOF
    tell application "System Events"
      activate
      set userResponse to button returned of (display dialog "Start file transfer?" buttons {"Cancel", "Proceed"} default button "Proceed" cancel button "Cancel")
      return userResponse
    end tell
EOF
  )

# Check user response
if [ "$response" = "Proceed" ]; then
  echo "Proceeding with file transfer..."
  osascript <<EOF
  tell application "Terminal"
    do script "rclone copy mygoogledrive: myteamdrive: --progress --drive-acknowledge-abuse"
    activate
  end tell
EOF
  else
    echo "File transfer canceled."
    exit 0
  fi
}

# Main script
show_instructions
check_homebrew
install_tools
configure_rclone
prompt_file_transfer

echo "Rclone configured successfully."
echo "File transfer initiated. Check Terminal for progress."
echo "To postpone the transfer, just close transfer Terminal window."
echo "To resume transfer, rerun this utility."
echo "You may close this window."
