#!/bin/sh -e

# Define color variables
RC='\033[0m'        # Reset
RED='\033[31m'      # Red
GREEN='\033[32m'    # Green
YELLOW='\033[33m'   # Yellow
BLUE='\033[34m'     # Blue

# Create a script to toggle numlock
create_file() {
  echo "${BLUE}Creating script...${RC}"
  sudo tee "/usr/local/bin/numlock" >/dev/null <<'EOF'
#!/bin/bash

for tty in /dev/tty{1..6}
do
    /usr/bin/setleds -D +num < "$tty"; 
done
EOF

  sudo chmod +x /usr/local/bin/numlock
  echo "${GREEN}Script created and permissions set.${RC}"
}

# Create a systemd service to run the script on boot
create_service() {
  echo "${BLUE}Creating service...${RC}"
  sudo tee "/etc/systemd/system/numlock.service" >/dev/null <<'EOF'
[Unit]
Description=numlock
        
[Service]
ExecStart=/usr/local/bin/numlock
StandardInput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  echo "${GREEN}Service file created.${RC}"
}

main() {
  # Check if the script and service files exist
  if [ ! -f "/usr/local/bin/numlock" ]; then
    create_file
  else
    echo "${YELLOW}Script already exists.${RC}"
  fi

  if [ ! -f "/etc/systemd/system/numlock.service" ]; then
    create_service
  else
    echo "${YELLOW}Service file already exists.${RC}"
  fi

  # Always enable the numlock service
  sudo systemctl enable numlock.service --quiet
  echo "${GREEN}Numlock service will be enabled on boot.${RC}"
}

main
