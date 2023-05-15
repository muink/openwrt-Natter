Natter on Openwrt
=================

## Introduction
This project is the software package of [Natter][] running on OpenWrt  
LuCI can be found here [luci-app-natter](https://github.com/muink/luci-app-natter)  
Recommended to use it with `luci-app-commands`

## Features included outside of Natter
- [x] Automatically configure the Firewall
- [x] NAT Loopback support
- [x] Transparent Port forward (Dynport)
- [x] Refresh the listen port of the BT Client
- [ ] Port update Notification script
- [ ] Domain 302 Redirect update script
- [ ] A/SRV Record update script

## Releases
You can find the prebuilt-ipks [here](https://fantastic-packages.github.io/packages/)

## Build

```shell
# Take the x86_64 platform as an example
tar xjf openwrt-sdk-21.02.3-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
# Go to the SDK root dir
cd OpenWrt-sdk-*-x86_64_*
# First run to generate a .config file
make menuconfig
./scripts/feeds update -a
./scripts/feeds install -a
# Get Makefile
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/openwrt-Natter.git package/natter
pushd package/natter
umask 022
git checkout
popd
# Select the package Network -> natter
make menuconfig
# Start compiling
make package/natter/compile V=99
```

## License
This project is licensed under the [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html)

  [Natter]: https://github.com/MikeWang000000/Natter
