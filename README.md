# remarkable-gocryptfs
A non-failsafe way of encrypting reMarkable tablets' internal storage

So I've taken some steps to encrypt my reMarkable Notebooks on the device with the help of gocryptfs.
I want to share the steps I've taken, but first some warnings:

**Warnings**
1. You must know what you're doing on the shell. Don't follow any instructions here blindly. If you do, you're gonna have a bad time!
2. I'm not responsible for loss of data or damage to your device.
3. Make backups of the directory you're going to encrypt.
4. Write down your ssh password in case anything goes wrong and your device gets soft-bricked.
5. Make sure your rM is properly charged for this.

## Installing gocryptfs

PSA: A toltec package for gocryptfs is currently under revision for being merged into the testing branch of toltec: [Link to gocryptfs toltec PR](https://github.com/toltec-dev/toltec/pull/318)

It has also turned out that rM1 does not have the needed fuse module built into the kernel. It has to be built separately. The instructions for this are not included here but the package is also in the making: [Fuse kernel module for rM1 PR to toltec testing](https://github.com/toltec-dev/toltec/pull/331/)

### Install go
[SSH into your device](https://remarkablewiki.com/tech/ssh) and have wireless enabled and connected.

First of all, this guide assumes that you have entware/toltec installed.
In case you haven't installed it, head over to [toltec](https://github.com/toltec-dev/toltec) and follow the installation instructions there.

After doing this, you'll need to install go. It's used to build gocryptfs. This is a large package and might take some time to download.
```sh
# opkg install go
```

The package post-install script will tell you this, too. But for completeness' sake...
You'll need to put go into your PATH variable to run it, and set the GOROOT environment variable like so:
```sh
export PATH=/opt/bin/go/bin:$PATH
export GOROOT=/opt/bin/go
```
Put this in your .bashrc to make it permanent.

### Install fuse-utils
FUSE is used to mount the encrypted directory.
Install it via
```sh
# opkg install fuse-utils
```

### Build gocryptfs
I've had trouble using git from entware for pulling packages. So for this guide, download gocryptfs as zip and unpack.
```sh
# curl "https://codeload.github.com/rfjakob/gocryptfs/zip/master" > gocryptfs-master.zip
# unzip gocryptfs-master.zip
```

Then enter the directory and compile
```sh
# cd gocryptfs-master
# ./build-without-openssl.bash
```

Copy the binary to /opt/bin and test run it
```sh
# cp gocryptfs /opt/bin/
# gocryptfs
```

If everything worked, you will see a list of parameters that you can pass to gocryptfs.

### Set up the encryption
For this guide, we will encrypt the notebooks and list of recent notebooks only. 
They're located at /home/root/.local/share/remarkable/

First, stop xochitl
```sh
# systemctl stop xochitl
```

**You should have made backups by know. If not, do it now.**

Move your notebooks to a temporary directory
```sh
# cd /home/root/.local/share
# mv remarkable remarkable.old
```

Then, create the new directories. remarkable-cipher will hold encrypted files and remarkable will be an empty mountpoint.
To avoid files being written to the mountpoint before mounting, we will protect it with chattr.
```sh
# mkdir remarkable-cipher remarkable
# chattr +i
```

Set up encryption for the directories. This will ask you for a password.
(If you want to use the GUI-script provided in this repo, use a diceware password with all lowercase letters and with a . delimiter.)
```sh
# gocryptfs -init remarkable-cipher
```

Now you can mount the new directory and move or copy the old files over:
```sh
# gocryptfs /home/root/.local/share/remarkable-cipher /home/root/.local/share/remarkable
# cp -r remarkable.old/* remarkable
```

When cp is done, you may delete your old files. If you want to make sure they're not recoverable you'll want to temporarily fill your remaining disk space with random data.

If you reboot, the drive will be unmounted and xochitl will launch, but show no notebooks.
You'll have to log in via ssh and mount the drive (after stopping xochitl)
```sh
# systemctl stop xochitl
# gocryptfs /home/root/.local/share/remarkable-cipher /home/root/.local/share/remarkable
# systemctl start xochitl
```

### Using the simple app script for gocryptfs
This repo contains a [Simple App Script](https://rmkit.dev/apps/sas) GUI for gocryptfs.

Currently, it only provides lower-case letters and a period symbol on the keyboard.
This is plenty for using [Diceware Passwords](https://diceware.dmuth.org/)

To use the script, you need simple and a launcher. Remux launches xochitl by default and we don't want that. So use oxide or draft.
(**If your device is a reMarkable 2, you'll also need to install rm2fb.**)
```sh
# opkg install simple
# opkg install oxide
# systemctl disable --now xochitl
# systemctl enable --now tarnish
```

Download and install the script (make it executable) and the draft file and copy them to the right places:
```sh
# curl https://raw.githubusercontent.com/plan5/remarkable-gocryptfs/main/decrypt.draft > /etc/draft/decrypt.draft
# curl https://raw.githubusercontent.com/plan5/remarkable-gocryptfs/main/gocryptfs.sh > /home/root/gocryptfs.sh
# chmod +x /home/root/gocryptfs.sh
```

You may have to re-import all apps via the menu in Oxide.

From now on, you can decrypt via the simple script before launching xochitl!
