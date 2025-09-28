#!/bin/bash
# Arch Linux DWM + Student Laptop Setup Script
# Structured dirs + DWM Help popup + French AZERTY + Auto workspaces

set -e

echo ">>> Updating system..."
sudo pacman -Syu --noconfirm

echo ">>> Installing basics..."
sudo pacman -S --noconfirm base-devel git curl wget unzip zip htop btop fastfetch feh picom dunst pamixer

# Structured dirs
mkdir -p ~/.local/src ~/.local/bin ~/.local/share/dwm

# Add ~/.local/bin to PATH
for file in ~/.zshrc ~/.bashrc; do
  if ! grep -q 'export PATH=$HOME/.local/bin:$PATH' $file 2>/dev/null; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> $file
  fi
done

echo ">>> Installing Xorg + drivers..."
sudo pacman -S --noconfirm xorg xorg-xinit xorg-xrandr xorg-xsetroot

echo ">>> Cloning suckless tools..."
cd ~/.local/src
for repo in dwm st dmenu slock; do
  [ ! -d $repo ] && git clone https://git.suckless.org/$repo
done
[ ! -d dwmblocks ] && git clone https://github.com/torrinfail/dwmblocks

echo ">>> Building suckless tools..."
for repo in dwm st dmenu slock dwmblocks; do
  cd ~/.local/src/$repo
  make clean
  make
  cp $repo ~/.local/bin/ 2>/dev/null || true
done

echo ">>> DWM Help popup..."
# Keybinds file
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

# Help script
cat > ~/.local/bin/dwm-help.sh <<'EOF'
#!/bin/sh
st -c "DwmHelp" -n "DwmHelp" -g 80x24 -e less ~/.local/share/dwm/keybinds.txt
EOF
chmod +x ~/.local/bin/dwm-help.sh

echo ">>> Patching dwm config..."
CONFIG=~/.local/src/dwm/config.h
if [ -f "$CONFIG" ]; then
  # Patch rules
  if ! grep -q 'DwmHelp' "$CONFIG"; then
    sed -i '/static const Rule rules\[\] = {/a\
    { "DwmHelp", NULL, NULL, 0, 1, -1 },\
    { "obsidian", NULL, NULL, 1 << 1, 0, -1 },\
    { "firefox",  NULL, NULL, 1 << 2, 0, -1 },\
    { "steam",    NULL, NULL, 1 << 3, 0, -1 },\
    { "Minecraft* 1.20.1", NULL, NULL, 1 << 3, 0, -1 },' "$CONFIG"
  fi

  # Patch keybinds
  sed -i '/static Key keys\[\] = {/a\
    { MODKEY,                       XK_space,  spawn, SHCMD("dmenu_run") },\
    { MODKEY,                       XK_h,      spawn, SHCMD("~/.local/bin/dwm-help.sh") },\
    { MODKEY,                       XK_q,      spawn, SHCMD("pkill -f DwmHelp") },\
    { MODKEY|ShiftMask,             XK_s,      spawn, SHCMD("flameshot gui") },\
    { MODKEY,                       XK_ampersand, view, {.ui = 1 << 0} },\
    { MODKEY,                       XK_eacute,    view, {.ui = 1 << 1} },\
    { MODKEY,                       XK_quotedbl,  view, {.ui = 1 << 2} },\
    { MODKEY,                       XK_apostrophe,view, {.ui = 1 << 3} },\
    { MODKEY,                       XK_parenleft, view, {.ui = 1 << 4} },\
    { MODKEY,                       XK_minus,     view, {.ui = 1 << 5} },\
    { MODKEY,                       XK_egrave,    view, {.ui = 1 << 6} },\
    { MODKEY,                       XK_underscore,view, {.ui = 1 << 7} },\
    { MODKEY,                       XK_ccedilla,  view, {.ui = 1 << 8} },\
    { MODKEY,                       XK_agrave,    view, {.ui = 1 << 9} },\
    { MODKEY|ShiftMask,             XK_ampersand, tag, {.ui = 1 << 0} },\
    { MODKEY|ShiftMask,             XK_eacute,    tag, {.ui = 1 << 1} },\
    { MODKEY|ShiftMask,             XK_quotedbl,  tag, {.ui = 1 << 2} },\
    { MODKEY|ShiftMask,             XK_apostrophe,tag, {.ui = 1 << 3} },\
    { MODKEY|ShiftMask,             XK_parenleft, tag, {.ui = 1 << 4} },\
    { MODKEY|ShiftMask,             XK_minus,     tag, {.ui = 1 << 5} },\
    { MODKEY|ShiftMask,             XK_egrave,    tag, {.ui = 1 << 6} },\
    { MODKEY|ShiftMask,             XK_underscore,tag, {.ui = 1 << 7} },\
    { MODKEY|ShiftMask,             XK_ccedilla,  tag, {.ui = 1 << 8} },\
    { MODKEY|ShiftMask,             XK_agrave,    tag, {.ui = 1 << 9} },' "$CONFIG"
fi

# Rebuild dwm
cd ~/.local/src/dwm
make clean && make
cp dwm ~/.local/bin/

echo ">>> Fonts + themes..."
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd ttf-dejavu ttf-font-awesome
yay -S --noconfirm catppuccin-gtk-theme catppuccin-cursors-mocha tokyonight-gtk-theme

echo ">>> Terminal + shell..."
sudo pacman -S --noconfirm kitty alacritty zsh zsh-completions
chsh -s /bin/zsh
if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo ">>> tmux + Neovim..."
sudo pacman -S --noconfirm tmux neovim
[ ! -d ~/.tmux/plugins/tpm ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
mkdir -p ~/.local/share/nvim/site/pack/lazy/start
[ ! -d ~/.local/share/nvim/site/pack/lazy/start/lazy.nvim ] && \
  git clone https://github.com/folke/lazy.nvim ~/.local/share/nvim/site/pack/lazy/start/lazy.nvim

echo ">>> Laptop utilities..."
sudo pacman -S --noconfirm networkmanager nm-connection-editor bluez bluez-utils blueman \
  tlp tlp-rdw powertop acpi acpid brightnessctl pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol xf86-input-synaptics

sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable tlp acpid

echo ">>> Study apps..."
yay -S --noconfirm obsidian
sudo pacman -S --noconfirm zathura zathura-pdf-mupdf libreoffice-fresh flameshot firefox

echo ">>> Gaming..."
sudo pacman -S --noconfirm steam lutris mangohud gamemode
yay -S --noconfirm proton-ge-custom prismlauncher

echo ">>> Virtualization..."
sudo pacman -S --noconfirm virtualbox virtualbox-host-modules-arch virtualbox-guest-iso \
  qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat
sudo systemctl enable libvirtd
sudo usermod -aG libvirt $(whoami)

echo ">>> Login manager + lockscreen..."
sudo pacman -S --noconfirm sddm i3lock-color
yay -S --noconfirm sddm-theme-catppuccin
sudo systemctl enable sddm

echo ">>> dwmblocks modules..."
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

echo ">>> Autostart ~/.xinitrc..."
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

echo ">>> ✅ Setup complete! Reboot and enjoy Arch + DWM with your custom workflow."
