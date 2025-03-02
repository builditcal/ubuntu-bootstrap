#!/bin/bash

# Global Vars
DOWNLOAD_PATH=$HOME/Downloads/tmp
OS_VERSION=22.04
VERSION=0.0.8

# Fetch all the named args
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi

  shift
done

clear 

echo "----------------------------------------------------"
echo "Welcome to Ubuntu-Bootstrap $OS_VERSION (v$VERSION)"
echo "=> The following will be installed:"
echo " -> debs: $debs"
echo " -> flatpaks: $flatpaks"
if [ -n "$apt_install" ]; then
  echo "=> the following apt installs will be invoked"
  echo " -> $apt_install"
fi
if [ -n "$apt_remove" ]; then
  echo "=> the following apt remove will be invoked"
  echo " -> $apt_remove"
fi
if [[ $debloat == "yes" ]]; then
  echo "=> snap packages will be removed"
fi
if [[ $neaten == "yes" ]]; then
  echo "=> the shell will also be neatened"
fi
echo "----------------------------------------------------"


echo "*****************************************************"
echo "Upgrading and Updating Installing and Removing"
echo "*****************************************************"
sudo apt update
sudo apt upgrade -yq

if [ -n "$apt_install" ]; then
  IFS=',' read -ra app_list <<< "$apt_install"
  for app in "${app_list[@]}"; do
      sudo apt install -yq $app
  done
fi

if [ -n "$apt_remove" ]; then
  IFS=',' read -ra app_list <<< "$apt_remove"
  for app in "${app_list[@]}"; do
      sudo apt remove -yq $app
  done
fi


if [[ $debloat == "yes" ]]; then
  echo "*****************************************************"
  echo "Debloating"
  echo "*****************************************************"

  echo "*****************************************************"
  echo "Removing Snaps and snapd"
  echo "*****************************************************"

  MAX_TRIES=30

  for try in $(seq 1 $MAX_TRIES); do
    INSTALLED_SNAPS=$(snap list 2> /dev/null | grep -c  ^Name || true)
    if (( $INSTALLED_SNAPS == 0 )); then
      echo "all snaps removed"
    fi
    echo "Attempt $try of $MAX_TRIES to remove $INSTALLED_SNAPS snaps."

    snap list 2> /dev/null | grep -v ^Name |  awk '{ print $1 }'  | xargs -r -n1  sudo snap remove || true
  done

  sudo apt autoremove -yq --purge snapd
  sudo apt-mark hold snapd
  sudo rm -rf /snap
  sudo rm -rf $HOME/snap

  echo "*****************************************************"
  echo "Snaps removed"
  echo "*****************************************************"

  sudo apt -yq remove gnome-user-docs yelp

fi


echo "*****************************************************"
echo "Installing essential deb applications"
echo "*****************************************************"
mkdir $DOWNLOAD_PATH

# INSTALL: VS CODE
if [[ $debs =~ "vscode" ]]; then
  echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
  sudo apt-get install -yq wget gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  rm -f packages.microsoft.gpg
  sudo apt install -yq apt-transport-https
  sudo apt update
  sudo apt install -yq code
fi

# INSTALL: Chrome
if [[ $debs =~ "chrome" ]]; then
  wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $DOWNLOAD_PATH/chrome.deb
  sudo apt install -yq $DOWNLOAD_PATH/chrome.deb
fi

# INSTALL: dbeaver
if [[ $debs =~ "dbeaver" ]]; then
  wget -c https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb -O $DOWNLOAD_PATH/dbeaver.deb
  sudo apt install -yq $DOWNLOAD_PATH/dbeaver.deb
fi

# INSTALL: docker
if [[ $debs =~ "docker" ]]; then
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
  sudo apt-get update
  sudo apt-get install -yq ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get -yq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER
fi


echo "*****************************************************"
echo "Installing flatpak applications"
echo "*****************************************************"

if [ -n "$flatpaks" ]; then
  sudo apt -yq install flatpak
  sudo apt -yq install gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  # FLATPAK INSTALL: bitwarden
  if [[ $flatpaks =~ "bitwarden" ]]; then
    sudo flatpak install -y flathub com.bitwarden.desktop
  fi

  # FLATPAK INSTALL: cura
  if [[ $flatpaks =~ "cura" ]]; then
    sudo flatpak install -y flathub com.ultimaker.cura
  fi
fi

if [[ $neaten == "yes" ]]; then
  echo "*****************************************************"
  echo "Neatening up the shell"
  echo "*****************************************************"


  gsettings set org.gnome.shell favorite-apps "['org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop']"

  add_gnome_menu_folders() {
    folder_name=$1
    readable_name=$2
    apps=$3

    gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ name "$readable_name"
    gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ apps "[ $apps ]"

  }

  add_gnome_menu_folders "system" "🖥️ System" "'org.gnome.Logs.desktop', 'org.gnome.PowerStats.desktop', 'org.gnome.SystemMonitor.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.Tecla.desktop', 'org.gnome.baobab.desktop', 'org.gnome.seahorse.Application.desktop', 'org.gnome.Settings.desktop', 'org.gnome.OnlineAccounts.OAuth2.desktop', 'software-properties-drivers', 'software-properties-gtk', 'update-manager', 'nm-connection-editor', 'gnome-session-properties', 'gnome-language-selector'"

  add_gnome_menu_folders "accessories" "🖊️ Accessories" "'org.gnome.font-viewer.desktop', 'org.gnome.clocks.desktop', 'org.gnome.Characters.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.eog.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Evince'"

  gsettings set org.gnome.desktop.app-folders folder-children "[ 'accessories', 'system' ]"

fi

sudo apt autoremove -yq
rm -rf $DOWNLOAD_PATH
