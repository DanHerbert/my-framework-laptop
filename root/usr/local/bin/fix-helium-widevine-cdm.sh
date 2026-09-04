#!/bin/bash -ex
cleanup() {
    rm -rf "$tmp_workdir"
}

# Assumes Helium browser is installed for the primary user on the system, which
# implies a single-user desktop setup, which is what I use on my laptop.
helium_user=$(loginctl list-sessions --no-legend | awk '{print $3}' | sort -u | head)
helium_user_home=$(getent passwd "$helium_user" | cut -d: -f6)

tmp_workdir=$(mktemp -d)
trap cleanup EXIT
cd "$tmp_workdir"

_base_url="https://dl.google.com/linux/chrome/deb"
_packages_url="$_base_url/dists/stable/main/binary-amd64/Packages"
_file_path=$(wget -qO- "$_packages_url" | awk '/^Package: google-chrome-stable/{flag=1} flag && /^Filename:/{print $2; exit}')
if [ -z "$_file_path" ]; then
    echo "Error: can't get latest Chrome version."
    exit 1
fi
_download_url="$_base_url/$_file_path"
_deb_file=$(basename "$_file_path")
wget --show-progress -O "$_deb_file" "$_download_url"

# Correct path, at least on Arch Linux when Helium is installed through AUR
# with helium-browser-bin package.
_target_dir="$helium_user_home/.config/net.imput.helium/WidevineCdm"
ownership=$(stat -c "%U:%G" "$_target_dir")

# Unpack deb
mkdir ./unpacked_deb
cd ./unpacked_deb
ar x "../$_deb_file"
tar -xf ./data.tar.* -C .
cd ../

# Move WidevineCdm to target dir owned by current user
rm -r "$_target_dir" || true
_widevine_version=$(jq -r '.version' ./unpacked_deb/opt/google/chrome/WidevineCdm/manifest.json)
mkdir -p "$_target_dir/$_widevine_version"
mv ./unpacked_deb/opt/google/chrome/WidevineCdm/* "$_target_dir/$_widevine_version/"
chmod 755 "$_target_dir/$_widevine_version/_platform_specific/linux_x64/libwidevinecdm.so"
chown -R "$ownership" "$_target_dir"
echo '{"Path":"'"$_target_dir/$_widevine_version"'"}' > "$_target_dir/latest-component-updated-widevine-cdm"
