#### Prerequisites:

- installed Entware
- SWAP enabled (2GB or more recommended)

> **\* steps are optional.**

#### 1 - ssh to router

#### * - increase swappiness if it is 0 

> this can significantly improved the performance of the Plex Media Server
  
```bash
# check current value of swappiness
cat /proc/sys/vm/swappiness
```

```bash
# change swappiness on runtime and persists it after reboot
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
debootstrap --variant=minbase --arch=arm64 bookworm /opt/debian/ http://ftp.debian.org/debian/
```

#### 5 - prepare Debian's init.d script

```bash
rm /opt/etc/init.d/S99debian
wget -O /opt/etc/init.d/S99debian https://raw.githubusercontent.com/bbeny123/Plex_Asuswrt-Merlin/main/init-debian.sh
chmod 755 /opt/etc/init.d/S99debian
```
> by default, all subdirs of `/tmp/mnt/` (except the *Entware* partition) will be bind-mounted on **chrooted Debian's** `/mnt/` (making them visible by *Plex Media Server*)

#### * - prepare Debian's remount hotplugged USB script

> skipping this step, newly attached USB drives will be accessible from *Debian* (and thus *Plex Media Server*) only after rebooting the router or manually executing `debian restart` / `debian enter` via SSH

> prerequisite: `JFFS custom scripts and configs` enabled (`router WebUI -> Administration -> System`)

```bash
wget -O /jffs/scripts/mount-debian.sh https://raw.githubusercontent.com/bbeny123/Plex_Asuswrt-Merlin/main/mount-debian.sh
chmod 755 /jffs/scripts/mount-debian.sh
echo './jffs/scripts/mount-debian.sh' >> /jffs/scripts/post-mount
```

#### 6 - prepare chrooted services list and create symlink to Debian

```bash
touch /opt/etc/chroot-services.list
chmod 755 /opt/etc/chroot-services.list
ln -s /opt/etc/init.d/S99debian /opt/bin/debian
```

#### * - copy hosts file to Debian

```bash
cp /etc/hosts /opt/debian/etc/
```

#### 7 - enter debian

```bash
debian enter
```

#### 8 - upgrade packages and install those required by Plex Media Server

```bash
apt update && apt upgrade -y
apt install -y apt-transport-https curl gnupg procps
```

#### 9 - configure timezone

```bash
dpkg-reconfigure tzdata
```

#### 10 - instal Plex Media Server

```bash
curl -sS https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/plexmediaserver.gpg
echo 'deb https://downloads.plex.tv/repo/deb public main' | tee /etc/apt/sources.list.d/plexmediaserver.list
apt update
apt install plexmediaserver
```

> After installation, the server will start automatically.
> During initialization (which will take about 5-15min) CPU/RAM usage will be close to 100%.
> The server will be almost unusable during this time so I recommend just waiting it out.​

#### 11 - exit Debian

```bash
exit
```

#### 12 - add Plex Media Server to chrooted services list

```bash
echo 'plexmediaserver' >> /opt/etc/chroot-services.list
```

#### 13 - restart Debian

```bash
debian restart
```

> After about 30 seconds, the server should be reachable at: [\<router-ip-address\>:32400/web](http://\<router-ip-address\>:32400/web) like:
> - [192.168.18.200:32400/web](http://192.168.18.200:32400/web)
> - [192.168.1.1:32400/web](http://192.168.1.1:32400/web)
> - [router.asus.com:32400/web](http://router.asus.com:32400/web)

> When configuring libraries, CPU/RAM consumption will also be close to 100%. Web-panel and Debian will be unresponsive during this time.
> After configuring the libraries and downloading the metadata, the Plex Media Server should start working well.
