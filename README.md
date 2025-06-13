> **Steps marked with an asterisk (\*) are optional.**

#### Prerequisites

- Entware installed
- SWAP enabled (2GB or more recommended)

#### 1 - ssh into router

#### \* - increase swappiness (if set to 0)

> Increasing swappiness can significantly improve Plex performance

```bash
# check current swappiness value
cat /proc/sys/vm/swappiness

# change swappiness at runtime and make it persistent across reboots
echo 10 > /proc/sys/vm/swappiness
echo 'echo 10 > /proc/sys/vm/swappiness' >> /jffs/scripts/post-mount
```

#### 2 - install required packages

```bash
opkg install coreutils-sha256sum debootstrap binutils perlbase-autodie
```

#### 3 - remount Entware partition

```bash
mount -i -o remount,exec,dev /opt/..
```

#### 4 - install chrooted Debian

```bash
debootstrap --variant=minbase --arch=arm64 bookworm /opt/debian/ https://ftp.debian.org/debian/
```

#### 5 - set up Debian init.d script

```bash
rm /opt/etc/init.d/S99debian
wget -O /opt/etc/init.d/S99debian https://raw.githubusercontent.com/bbeny123/Plex_Asuswrt-Merlin/main/init-debian.sh
chmod 755 /opt/etc/init.d/S99debian
```

> By default, all subdirs of `/tmp/mnt/` (excluding the **Entware** partition) are bind-mounted to the **Debian**
`/mnt/`, making them visible to **Plex**

#### \* - set up hot-plugging of USB drives in Debian

> Skipping this step, hot-plugged USB drives will only become available to **Debian** (and thus accessible by **Plex**)
> after a router reboot or a manual `debian restart` / `debian enter`

> **Prerequisite:** `JFFS custom scripts and configs` enabled (`router WebUI -> Administration -> System`)

```bash
echo 'debian postmount "$1"' >> /jffs/scripts/post-mount
```

#### \* - set up Debian graceful shutdown on Entware partition unmount

> This step ensures a graceful shutdown of **Debian** (and thus **Plex**) when the **Entware** partition is unmounted.  
> This also prevents most `Device or resource busy` errors, making the unmount process significantly faster.

> **Prerequisite:** `JFFS custom scripts and configs` enabled (`router WebUI -> Administration -> System`)

```bash
echo 'debian unmount "$1"' >> /jffs/scripts/unmount
```

#### 6 - prepare chrooted services list and set up `debian` symlink

```bash
touch /opt/etc/chroot-services.list
chmod 755 /opt/etc/chroot-services.list
ln -s /opt/etc/init.d/S99debian /opt/bin/debian
```

#### \* - copy hosts file to Debian

```bash
cp /etc/hosts /opt/debian/etc/
```

#### 7 - enter debian

```bash
debian enter
```

#### 8 - upgrade packages and install Plex prerequisites

```bash
apt update && apt upgrade -y
apt install -y apt-transport-https curl gnupg procps
```

#### 9 - configure timezone

```bash
dpkg-reconfigure tzdata

```

#### 10 - ensure `/usr/sbin/init` is not a `systemd` symlink

```bash
[ -f /usr/sbin/init ] && ls -l /usr/sbin/init | grep -q systemd && mv -f /usr/sbin/init /usr/sbin/init.bak
```

#### 11 - install Plex Media Server

```bash
curl -sS https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/plexmediaserver.gpg
echo 'deb https://downloads.plex.tv/repo/deb public main' | tee /etc/apt/sources.list.d/plexmediaserver.list
apt update
apt install plexmediaserver
```

> Plex Media Server will start automatically after installation.  
> During initial setup, which can take 5–15 minutes, CPU and RAM usage may spike to nearly 100%.  
> The router may become unresponsive during this time — just let it finish.

#### 12 - exit Debian

```bash
exit
```

#### 13 - add Plex Media Server to chrooted services list

```bash
echo 'plexmediaserver' >> /opt/etc/chroot-services.list
```

#### 14 - restart Debian

```bash
debian restart
```

> After about 30 seconds, the Plex should be reachable at `<router-ip>:32400/web`. **For example:**
> - [192.168.18.200:32400/web](http://192.168.18.200:32400/web)
> - [192.168.1.1:32400/web](http://192.168.1.1:32400/web)
> - [router.asus.com:32400/web](http://router.asus.com:32400/web)

> **Note:** Plex library configuration may cause very high CPU and RAM usage.  
> During this process, the router's web interfaces and SSH may become unresponsive.  
> Once library configuration is complete, overall performance should return to normal.

### Update procedure

#### 1 - ssh into router

#### \* - update amtm and Entware packages using `amtm`

> **Warning:** This step may overwrite `/opt/etc/init.d/S99debian`.  
> If this happens, repeat [step 5 of the installation procedure](#5---set-up-debian-initd-script) to restore it.

#### 2 - enter debian

```bash
debian enter
```

#### 3 - hold Plex and upgrade other Debian packages

> Plex should be upgraded separately to prevent other packages from creating a problematic `systemd` symlink.  
> Alternatively – upgrade everything at once, then fix the symlink and reinstall Plex.

```bash
apt-mark hold plexmediaserver
apt update && apt upgrade -y
```

#### 4 - ensure `/usr/sbin/init` is not a `systemd` symlink

```bash
[ -f /usr/sbin/init ] && ls -l /usr/sbin/init | grep -q systemd && mv -f /usr/sbin/init /usr/sbin/init.bak
```

#### 5 - unhold and upgrade Plex

```bash
apt-mark unhold plexmediaserver
apt update && apt upgrade -y
```

#### \* - restart Debian

```bash
exit
debian restart
```

### Sources

- <https://hqt.ro/how-to-install-debian-stretch-arm/> (accessed
  via [The Wayback Machine](https://web.archive.org/web/20230511031803/https://hqt.ro/how-to-install-debian-stretch-arm/))
- <https://www.hqt.ro/plex-media-server-on-asuswrt-armhf-routers/> (accessed
  via [The Wayback Machine](https://web.archive.org/web/20230512030731/https://hqt.ro/plex-media-server-on-asuswrt-armhf-routers/))
- <https://www.snbforums.com/threads/asus-rt-ac86u-and-debian-bullseye-nextcloud.79428/>