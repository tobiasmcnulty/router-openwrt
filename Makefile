release ?= 19.07.7
target ?= x86
subtarget ?= 64
builder_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/openwrt-imagebuilder-$(release)-$(target)-$(subtarget).Linux-x86_64.tar.xz
builder_filename = $(notdir $(builder_url))
checksums_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/sha256sums

build_profile = Generic
router_packages = \
	rsyslog \
	luci \
	luci-app-unbound \
	unbound-daemon-heavy \
	luci-app-wireguard \
	luci-proto-wireguard \
	python3-light \
	python3-logging \
	python3-ctypes \
	libustream-openssl20150806 \
	ca-bundle \
	ca-certificates \
	nmap \
	tcpdump \
	bwm-ng \
	iperf \
	pciutils \
	screen

wifi_packages = \
	hostapd \
	iw-full \
	iwlwifi-firmware-iwl7260 \
	kmod-cfg80211 \
	kmod-iwlwifi \
	kmod-mac80211 \
	wireless-regdb \
	wpa-supplicant

.PHONY: all
all: install-deps get-builder build

install-deps:
	# https://openwrt.org/docs/guide-user/additional-software/imagebuilder#debianubuntu
	sudo apt-get update
	sudo apt-get install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python

get-builder:
	# https://openwrt.org/docs/guide-user/additional-software/imagebuilder#obtaining_the_image_builder
	wget -q $(builder_url) -O $(builder_filename)
	wget -q $(checksums_url) -O sha256sums
	grep $(builder_filename) sha256sums | sha256sum --check --status

build:
	rm -rf builder && mkdir builder/
	tar -xf $(builder_filename) -C builder/ --strip-components=1
	cd builder/ && make image PROFILE=$(build_profile) PACKAGES="$(router_packages) $(wifi_packages)"
	du -hs builder/bin/targets/$(target)/$(subtarget)/*
	cat builder/bin/targets/$(target)/$(subtarget)/sha256sums
