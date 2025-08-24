# My Framework Laptop Setup

Config files and installation steps used for my Framework 13 laptop.

## Overview

My laptop uses Arch Linux with an `archinstall` config for the initial
installation. Use the json config in `/archinstall/user_configuration.json` for
the initial setup.

After running archinstall, there are still more steps needed to get things
completely configured which are explained below. Everything that follows is done
after archinstall finishes and the initial boot of the new system.

## Install AUR and some packages

Install [paru](https://github.com/Morganamilo/paru) using the recommended
installation steps, then install the list of packages in `aur-packages.txt`

## Initial system configuration

First, run `./stow.sh` to symlink needed home files into the system.

Then copy all files from `/root/boot` and `/root/etc` into the root system.

```bash
sudo cp -r ./root/boot /boot
sudo cp -r ./root/etc /etc
```

At this point perform steps listed in `/nonpublic/README.md` if available.

Then enable some systemd daemons:

```bash
# Keep arch package mirrors fresh
sudo systemctl enable reflector.timer
sudo systemctl start reflector.service

# Automatic btrfs snapshots
sudo rm /etc/cron.hourly/snapper
sudo systemctl enable snapper-boot.timer
sudo systemd enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer

# Gnome SSH key agent
systemctl --user enable --now gcr-ssh-agent.socket
```

And finally, configure Gnome settings

```bash
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['terminate:ctrl_alt_bksp', 'lv3:ralt_switch', 'caps:none']"
gsettings set org.gnome.desktop.interface clock-format "'24h'"
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
gsettings set org.gnome.desktop.wm.preferences button-layout "'appmenu:minimize,maximize,close'"
gsettings set org.gnome.clocks world-clocks "[{'location': <(uint32 2, <('Reykjavík', 'BIRK', true, [(1.1193378211279323, -0.38222710618675809)], [(1.1196287151543625, -0.38309977081275531)])>)>}]"
```

Now would be a good time to reboot the system to apply all of the settings that
were just changed.

## Setting up LibreWolf as a Mail Client

Open GMail and run this JS in the browser dev tools console

```js
navigator.registerProtocolHandler('mailto', 'https://mail.google.com/mail/?extsrc=mailto&url=%s')
```

Open LibreWolf settings and set Gmail as the default mailto handler

Modify `~/.config/mimeapps.list` to update `x-scheme-handler/mailto` to use `librewolf.desktop`. Ensure this is changed in both `[Default Applications]` and `[Added Associations]`.
