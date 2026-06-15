#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🔄 Updating package lists..."
sudo apt-get update

echo "📦 Installing lightweight desktop (XFCE) and TigerVNC..."
# We use XFCE because it's lightweight and works great in containers
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    curl

echo "⚙️ Configuring VNC server..."
# Create the .vnc directory if it doesn't exist
mkdir -p ~/.vnc

# Set up the VNC startup script to launch XFCE
cat << 'EOF' > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
OS=`uname -s`
if [ $OS = 'Linux' ]; then
  case "$WINDOWMANAGER" in
    *vtwm*)
      vtwm &
      ;;
    *)
      if [ -x /usr/bin/xfce4-session ]; then
        /usr/bin/xfce4-session &
      else
        /usr/bin/startxfce4 &
      fi
      ;;
  esac
fi
EOF

# Make the startup script executable
chmod +x ~/.vnc/xstartup

echo "🔒 Setting up a temporary VNC password (default: 'vncpass')..."
# You mentioned security isn't a priority, so we will hardcode a basic password
echo "vncpass" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

echo "🚀 Killing any existing VNC instances..."
vncserver -kill :1 2>/dev/null || true

echo "🏁 Starting TigerVNC server on display :1 (Port 5901)..."
vncserver :1 -geometry 1280x720 -depth 24

echo "🌐 Starting noVNC (WebSockets wrapper) on port 6080..."
# This bridges the VNC protocol to WebSockets so your browser can view it
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 &

echo "--------------------------------------------------------"
echo "✅ Setup Complete!"
echo "👉 Go to your Codespaces 'Ports' tab."
echo "👉 Make sure port 6080 is set to 'Public' (right-click -> Port Visibility -> Public)."
echo "👉 Open the local address for port 6080 in your browser, and add '/vnc.html' to the URL."
echo "🔒 Password is: vncpass"
echo "--------------------------------------------------------"

