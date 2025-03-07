sudo pacman -Syu --noconfirm

# Accelerate pacman
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sudo echo "ILoveCandy" >> /etc/pacman.conf

sudo pacman -S --noconfirm reflector git nano

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install paru AUR helper
sudo pacman -S --needed --noconfirm base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

# Install xorg
sudo pacman -S --noconfirm xorg

# Install GNOME
sudo pacman -S --noconfirm gnome-shell gdm gnome-console gnome-control-center gnome-keyring gnome-menus gnome-session gnome-settings-daemon gnome-shell-extensions gnome-text-editor nautilus 

sudo systemctl enable gdm.service

sudo pacman -S --noconfirm cpupower acpi acpid intel-ucode 

# Create the power management script
sudo tee /usr/local/bin/power-management.sh << 'EOF'
#! /bin/bash
cpupower frequency-set -g powersave -d 0.8G -u 1.2G
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
echo 0 > /sys/devices/system/cpu/cpu7/online
echo 0 > /sys/devices/system/cpu/cpu6/online
echo 0 > /sys/devices/system/cpu/cpu5/online
echo 0 > /sys/devices/system/cpu/cpu4/online
echo "400" > /sys/class/drm/card*/gt_max_freq_mhz
echo "400" > /sys/class/drm/card*/gt_boost_freq_mhz
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/power-management.sh

# Create systemd service
sudo tee /etc/systemd/system/power-management.service << EOF
[Unit]
Description=Power Management Settings
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/power-management.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable power-management.service

# Install and enable tlp
sudo pacman -S --noconfirm tlp tlp-rdw smartmontools ethtool

sudo tlp start

sudo systemctl enable tlp
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket
sudo systemctl enable NetworkManager-dispatcher.service

# Undervolt CPU
sudo pacman -S intel-undervolt

sudo tee /etc/intel/intel-undervolt.conf << EOF
# Enable or Disable Triggers (elogind)
# Usage: enable [yes/no]

enable no

# CPU Undervolting
# Usage: undervolt ${index} ${display_name} ${undervolt_value}
# Example: undervolt 2 'CPU Cache' -25.84

undervolt 0 'CPU' -115
undervolt 1 'GPU' -90
undervolt 2 'CPU Cache' -115
undervolt 3 'System Agent' -30
undervolt 4 'Analog I/O' -30

# Power Limits Alteration
# Usage: power ${domain} ${short_power_value} ${long_power_value}
# Power value: ${power}[/${time_window}][:enabled][:disabled]
# Domains: package
# Example: power package 45 35
# Example: power package 45/0.002 35/28
# Example: power package 45/0.002:disabled 35/28:enabled
power package 10 5

# Critical Temperature Offset Alteration
# Usage: tjoffset ${temperature_offset}
# Example: tjoffset -20
tjoffset -50

# Energy Versus Performance Preference Switch
# Usage: hwphint ${mode} ${algorithm} ${load_hint} ${normal_hint}
# Hints: see energy_performance_available_preferences
# Modes: switch, force
# Load algorithm: load:${capture}:${threshold}
# Power algorithm: power[:${domain}:[gt/lt]:${value}[:[and/or]]...]
# Capture: single, multi
# Threshold: CPU usage threshold
# Domain: RAPL power domain, check with `intel-undervolt measure`
# Example: hwphint force load:single:0.8 performance balance_performance
# Example: hwphint switch power:core:gt:8 performance balance_performance
hwphint switch load:single:0.9 balance_power power

# Daemon Update Interval
# Usage: interval ${interval_in_milliseconds}

interval 5000

# Daemon Actions
# Usage: daemon action[:option...]
# Actions: undervolt, power, tjoffset
# Options: once

daemon undervolt:once
daemon power
daemon tjoffset
EOF

sudo systemctl enable intel-undervolt

# Install video drivers
paru -S --noconfirm xf86-video-intel libvdpau-va-gl intel-media-driver sof-firmware nvidia-dkms nvidia-utils nvidia-settings

# Set environment variables safely using tee
sudo tee -a /etc/environment << EOF
LIBVA_DRIVER_NAME=iHD
VDPAU_DRIVER=va_gl
EOF

sudo pacman -S --noconfirm timeshift htop

# Create wallpapers directory and download a default wallpaper
mkdir -p ~/Pictures/Wallpapers
curl -o ~/Pictures/Wallpapers/default-wallpaper.jpg https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/Monterey-dark.jpg

# Set the wallpaper
gsettings set org.gnome.desktop.background picture-uri "file:///home/$USER/Pictures/Wallpapers/default-wallpaper.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$USER/Pictures/Wallpapers/default-wallpaper.jpg"

# Install vscode, chrome and other apps
paru -S visual-studio-code-bin google-chrome legcord-bin vlc envycontrol

# install uv 
curl -LsSf https://astral.sh/uv/install.sh | sh

# Enable the integrated graphics
sudo envycontrol -s integrated

sudo systemctl enable bluetooth

sudo systemctl reboot
