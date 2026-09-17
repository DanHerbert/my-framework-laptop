#!/bin/bash -e
# This script is run any time the "google-chrome" AUR package is updated, and
# only does anything if the "helium-browser-bin" AUR package is also installed
# on the system. This script assumes the machine is a single-user system and
# will only update Widevine for the primary system user.

if ! pacman -Q helium-browser-bin &>/dev/null; then
    echo 'Helium browser is not installed. Doing nothing.'
    exit 0
fi

# Assumes Helium browser is installed for the primary user on the system, which
# implies a single-user desktop setup, which is what I use on my laptop.
helium_user=$(loginctl list-sessions --no-legend | awk '{print $3}' | sort -u | head)
helium_user_home=$(getent passwd "$helium_user" | cut -d: -f6)

# Correct path, at least on Arch Linux when Helium is installed through AUR
# with helium-browser-bin package.
helium_widevine_path="$helium_user_home/.config/net.imput.helium/WidevineCdm"
ownership=$(stat -c "%U:%G" "$helium_widevine_path")
chrome_widevine_path="/opt/google/chrome/WidevineCdm"
latest_widevine_version=$(jq -r '.version' "$chrome_widevine_path/manifest.json")
should_update_widevine=0
if ! [[ -f "$helium_widevine_path/latest-component-updated-widevine-cdm" ]]; then
    should_update_widevine=1
else
    existing_helium_widevine_path=$(jq -r '.Path' "$helium_widevine_path/latest-component-updated-widevine-cdm")
    existing_widevine_version="${existing_helium_widevine_path##*/}"
    if [[ "$existing_widevine_version" != "$latest_widevine_version" ]]; then
        should_update_widevine=1
    fi
fi
if [[ -f "$helium_widevine_path/$latest_widevine_version/_platform_specific/linux_x64/libwidevinecdm.so" ]]; then
    existing_widevine_hash=$(sha256sum "$helium_widevine_path/$latest_widevine_version/_platform_specific/linux_x64/libwidevinecdm.so" | awk '{print $1}')
    latest_widevine_hash=$(sha256sum "$chrome_widevine_path/_platform_specific/linux_x64/libwidevinecdm.so" | awk '{print $1}')
    if [[ "$existing_widevine_hash" != "$latest_widevine_hash" ]]; then
        should_update_widevine=1
    fi
else
    should_update_widevine=1
fi
if [ "$should_update_widevine" -eq 0 ]; then
    exit 0
fi
echo 'Widevine update detected, copying from google-chrome install...'

# Copy WidevineCdm from google-chrome package to target dir
rm -r "$helium_widevine_path" || true
mkdir -p "$helium_widevine_path/$latest_widevine_version"
cp -r "$chrome_widevine_path"/* "$helium_widevine_path/$latest_widevine_version/"
chmod 755 "$helium_widevine_path/$latest_widevine_version/_platform_specific/linux_x64/libwidevinecdm.so"
chown -R "$ownership" "$helium_widevine_path"
echo '{"Path":"'"$helium_widevine_path/$latest_widevine_version"'"}' > "$helium_widevine_path/latest-component-updated-widevine-cdm"
