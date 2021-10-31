release ?= 21.02.0
target ?= x86
subtarget ?= 64
builder_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/openwrt-imagebuilder-$(release)-$(target)-$(subtarget).Linux-x86_64.tar.xz
builder_filename = $(notdir $(builder_url))
checksums_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/sha256sums

# release-dependent variables
# 21.02.0 seems to have wolfssl installed by default or as a dependency of other packages
ifneq (,$(findstring 21.,$(release)))
	build_profile = generic
	release_packages = \
		kmod-sp5100-tco \
		libustream-wolfssl20201210 \
		unbound-daemon
else
	build_profile = Generic
	release_packages = \
		kmod-sp5100_tco \
		libustream-openssl20150806 \
		unbound-daemon-heavy
endif

build_dir = builder-$(release)-$(target)-$(subtarget)

router_packages = \
	6in4 \
	apinger \
	bind-host \
	bwm-ng \
	ca-bundle \
	ca-certificates \
	curl \
	ddns-scripts \
	diffutils \
	ethtool \
	iperf \
	kmod-bonding \
	luci \
	luci-app-adblock \
	luci-app-ddns \
	luci-app-openvpn \
	luci-app-unbound \
	luci-app-vpn-policy-routing \
	luci-app-wireguard \
	luci-proto-wireguard \
	mii-tool \
	nmap \
	openvpn-openssl \
	pciutils \
	python3-ctypes \
	python3-light \
	python3-logging \
	rsyslog \
	screen \
	tcpdump \
	whois

wifi_packages = \
	hostapd \
	iw-full \
	iwlwifi-firmware-iwl7260 \
	kmod-cfg80211 \
	kmod-iwlwifi \
	kmod-mac80211 \
	wireless-regdb \
	wpa-supplicant

# See: https://openwrt.org/toh/pcengines/apu2
# - kmod-sp5100-tco is in release_packages due to name change in 21.02.0
apu2_packages = \
	kmod-leds-gpio \
	kmod-crypto-hw-ccp \
	kmod-gpio-nct5104d \
	kmod-gpio-button-hotplug \
	kmod-usb-core \
	kmod-usb-ohci \
	kmod-usb2 \
	kmod-usb3 \
	kmod-sound-core \
	kmod-pcspkr \
	amd64-microcode \
	flashrom \
	irqbalance \
	fstrim

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
	rm -rf $(build_dir) && mkdir $(build_dir)
	tar -xf $(builder_filename) -C $(build_dir) --strip-components=1
	cd $(build_dir) && make image PROFILE=$(build_profile) PACKAGES="$(router_packages) $(release_packages) $(wifi_packages) $(apu2_packages)"
	du -hs $(build_dir)/bin/targets/$(target)/$(subtarget)/*
	cat $(build_dir)/bin/targets/$(target)/$(subtarget)/sha256sums
