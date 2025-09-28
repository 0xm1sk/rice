#!/bin/bash
# Arch Linux DWM + Student Laptop Setup Script
# Clean version with colors and minimal output

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
info() { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "${PURPLE}➜${NC} $1"; }

# Quiet pacman function
quiet_pacman() {
    sudo pacman -S --noconfirm "$@" > /dev/null 2>&1 || {
        warning "Some packages failed: $@"
        return 0
    }
}

# Quiet yay function
quiet_yay() {
    yay -S --noconfirm "$@" > /dev/null 2>&1 || {
        warning "Some AUR packages failed: $@"
        return 0
    }
}

info "Starting Arch Linux DWM Setup"
echo

info "Updating system"
sudo pacman -Syu --noconfirm > /dev/null 2>&1
success "System updated"

info "Installing yay AUR helper"
if ! command -v yay &> /dev/null; then
    sudo pacman -S --noconfirm base-devel git > /dev/null 2>&1
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git > /dev/null 2>&1
    cd yay-bin
    makepkg -si --noconfirm > /dev/null 2>&1
    cd ~
    success "yay installed"
else
    success "yay already installed"
fi

info "Installing basic utilities"
quiet_pacman curl wget unzip zip htop btop fastfetch feh picom dunst pamixer
success "Basic utilities installed"

info "Creating directory structure"
mkdir -p ~/.local/src ~/.local/bin ~/.local/share/dwm ~/Pictures/wallpapers

# Add ~/.local/bin to PATH
for file in ~/.zshrc ~/.bashrc; do
  if [ -f "$file" ] && ! grep -q 'export PATH=$HOME/.local/bin:$PATH' "$file" 2>/dev/null; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> "$file"
  fi
done
success "Directory structure created"

info "Installing Xorg"
quiet_pacman xorg xorg-xinit xorg-xrandr xorg-xsetroot
success "Xorg installed"

info "Building suckless tools"
cd ~/.local/src
for repo in dwm st dmenu slock; do
  [ ! -d "$repo" ] && git clone "https://git.suckless.org/$repo" > /dev/null 2>&1
done
[ ! -d dwmblocks ] && git clone https://github.com/torrinfail/dwmblocks > /dev/null 2>&1

for repo in dwm st dmenu slock dwmblocks; do
  if [ -d ~/.local/src/$repo ]; then
    cd ~/.local/src/$repo
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1 && sudo make install > /dev/null 2>&1 || cp $repo ~/.local/bin/ 2>/dev/null || true
  fi
done
success "Suckless tools built"

info "Setting up DWM help system"
cat > ~/.local/share/dwm/keybinds.txt <<'EOF'
=====================
  DWM Keybindings
=====================

Super + Enter       → Launch terminal
Super + Space       → dmenu (run apps)
Super + h           → Show help
Super + q           → Close help
Super + b           → Toggle bar
Super + j / k       → Focus next / prev window
Super + Shift + c   → Kill window
Super + [& é " ' ( - è _ ç à] → Switch workspaces
Super + Shift + [& é " ' ( - è _ ç à] → Move window to workspace
Super + l           → Lock screen (slock)
Super + Shift + s   → Screenshot (flameshot)
Super + Shift + q   → Quit dwm
EOF

cat > ~/.local/bin/dwm-help.sh <<'EOF'
#!/bin/sh
st -c "DwmHelp" -n "DwmHelp" -g 80x24 -e less ~/.local/share/dwm/keybinds.txt
EOF
chmod +x ~/.local/bin/dwm-help.sh
success "DWM help system configured"

info "Configuring DWM with French keybindings"
CONFIG=~/.local/src/dwm/config.h
if [ -f "$CONFIG" ]; then
  cp "$CONFIG" "$CONFIG.backup"
  
  if ! grep -q 'DwmHelp' "$CONFIG"; then
    sed -i '/static const Rule rules\[\] = {/a\
    { "DwmHelp", NULL, NULL, 0, 1, -1 },\
    { "obsidian", NULL, NULL, 1 << 1, 0, -1 },\
    { "firefox",  NULL, NULL, 1 << 2, 0, -1 },\
    { "steam",    NULL, NULL, 1 << 3, 0, -1 },\
    { "Minecraft* 1.20.1", NULL, NULL, 1 << 3, 0, -1 },' "$CONFIG" 2>/dev/null || true
  fi

  if ! grep -q 'XK_h.*spawn.*dwm-help' "$CONFIG"; then
    sed -i '/static Key keys\[\] = {/a\
    { MODKEY,                       XK_space,  spawn,          {.v = (const char*[]){ "dmenu_run", NULL } } },\
    { MODKEY,                       XK_h,      spawn,          {.v = (const char*[]){ "dwm-help.sh", NULL } } },\
    { MODKEY,                       XK_q,      spawn,          {.v = (const char*[]){ "pkill", "-f", "DwmHelp", NULL } } },\
    { MODKEY|ShiftMask,             XK_s,      spawn,          {.v = (const char*[]){ "flameshot", "gui", NULL } } },\
    { MODKEY,                       XK_ampersand, view,        {.ui = 1 << 0} },\
    { MODKEY,                       XK_eacute,    view,        {.ui = 1 << 1} },\
    { MODKEY,                       XK_quotedbl,  view,        {.ui = 1 << 2} },\
    { MODKEY,                       XK_apostrophe,view,        {.ui = 1 << 3} },\
    { MODKEY,                       XK_parenleft, view,        {.ui = 1 << 4} },\
    { MODKEY,                       XK_minus,     view,        {.ui = 1 << 5} },\
    { MODKEY,                       XK_egrave,    view,        {.ui = 1 << 6} },\
    { MODKEY,                       XK_underscore,view,        {.ui = 1 << 7} },\
    { MODKEY,                       XK_ccedilla,  view,        {.ui = 1 << 8} },\
    { MODKEY,                       XK_agrave,    view,        {.ui = 1 << 9} },\
    { MODKEY|ShiftMask,             XK_ampersand, tag,         {.ui = 1 << 0} },\
    { MODKEY|ShiftMask,             XK_eacute,    tag,         {.ui = 1 << 1} },\
    { MODKEY|ShiftMask,             XK_quotedbl,  tag,         {.ui = 1 << 2} },\
    { MODKEY|ShiftMask,             XK_apostrophe,tag,         {.ui = 1 << 3} },\
    { MODKEY|ShiftMask,             XK_parenleft, tag,         {.ui = 1 << 4} },\
    { MODKEY|ShiftMask,             XK_minus,     tag,         {.ui = 1 << 5} },\
    { MODKEY|ShiftMask,             XK_egrave,    tag,         {.ui = 1 << 6} },\
    { MODKEY|ShiftMask,             XK_underscore,tag,         {.ui = 1 << 7} },\
    { MODKEY|ShiftMask,             XK_ccedilla,  tag,         {.ui = 1 << 8} },\
    { MODKEY|ShiftMask,             XK_agrave,    tag,         {.ui = 1 << 9} },' "$CONFIG" 2>/dev/null || true
  fi
fi

if [ -d ~/.local/src/dwm ]; then
  cd ~/.local/src/dwm
  make clean > /dev/null 2>&1 && make > /dev/null 2>&1
  sudo make install > /dev/null 2>&1 || cp dwm ~/.local/bin/ 2>/dev/null || true
fi
success "DWM configured with French AZERTY keybindings"

info "Installing fonts and themes"
quiet_pacman ttf-jetbrains-mono-nerd ttf-dejavu woff2-font-awesome adwaita-icon-theme gnome-themes-extra
quiet_yay catppuccin-gtk-theme-mocha tokyonight-gtk-theme
sudo fc-cache -fv > /dev/null 2>&1
success "Fonts and themes installed"

info "Setting up terminal environment"
quiet_pacman kitty alacritty zsh zsh-completions
chsh -s /bin/zsh > /dev/null 2>&1
if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
fi
success "Terminal environment configured"

info "Installing development tools"
quiet_pacman tmux neovim
[ ! -d ~/.tmux/plugins/tpm ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm > /dev/null 2>&1
mkdir -p ~/.local/share/nvim/site/pack/lazy/start
[ ! -d ~/.local/share/nvim/site/pack/lazy/start/lazy.nvim ] && \
  git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/site/pack/lazy/start/lazy.nvim > /dev/null 2>&1
success "Development tools installed"

info "Setting up laptop utilities"
sudo pacman -Rs --noconfirm pulseaudio pulseaudio-alsa 2>/dev/null || true
quiet_pacman networkmanager nm-connection-editor bluez bluez-utils blueman tlp tlp-rdw powertop acpi acpid brightnessctl pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol
sudo systemctl enable NetworkManager bluetooth tlp acpid > /dev/null 2>&1
success "Laptop utilities configured"

info "Installing study applications"
quiet_yay obsidian
quiet_pacman zathura zathura-pdf-mupdf libreoffice-fresh flameshot firefox
success "Study applications installed"

info "Enabling multilib for gaming"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    sudo pacman -Sy > /dev/null 2>&1
fi

info "Installing gaming packages"
quiet_pacman steam lutris mangohud gamemode
quiet_yay proton-ge-custom prismlauncher
success "Gaming packages installed"

info "Setting up virtualization"
quiet_pacman virtualbox virtualbox-host-modules-arch virtualbox-guest-iso qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat
sudo systemctl enable libvirtd > /dev/null 2>&1
sudo usermod -aG libvirt $(whoami) > /dev/null 2>&1
success "Virtualization configured"

info "Installing login manager"
quiet_pacman sddm
quiet_yay sddm-theme-catppuccin
sudo systemctl enable sddm > /dev/null 2>&1
success "Login manager installed"

info "Creating status bar modules"
mkdir -p ~/.local/bin/statusbar
cat > ~/.local/bin/statusbar/battery.sh <<'EOF'
#!/bin/sh
acpi | cut -d, -f2 | tr -d " "
EOF

cat > ~/.local/bin/statusbar/clock.sh <<'EOF'
#!/bin/sh
date '+%Y-%m-%d %H:%M'
EOF

cat > ~/.local/bin/statusbar/volume.sh <<'EOF'
#!/bin/sh
pamixer --get-volume-human
EOF
chmod +x ~/.local/bin/statusbar/*.sh
success "Status bar modules created"

info "Setting up autostart"
cat > ~/.xinitrc <<'EOF'
#!/bin/sh
feh --bg-fill ~/Pictures/wallpapers/dark.jpg &
picom --experimental-backends &
dunst &
nm-applet &
blueman-applet &
dwmblocks &
exec dwm
EOF
chmod +x ~/.xinitrc

info "Downloading wallpaper"
mkdir -p ~/Pictures/wallpapers
if [ ! -f ~/Pictures/wallpapers/dark.jpg ]; then
    curl -s -o ~/Pictures/wallpapers/dark.jpg "https://picsum.photos/1920/1080" || true
fi
success "Autostart configured"

echo
success "Setup complete! 🎉"
info "Reboot and enjoy your new Arch + DWM setup"
info "French AZERTY keybindings are ready to use"
info "Use Super + h to see all keybindings"
