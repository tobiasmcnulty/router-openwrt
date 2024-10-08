release ?= 23.05.2
target ?= x86
subtarget ?= 64
build_profile ?= generic
builder_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/openwrt-imagebuilder-$(release)-$(target)-$(subtarget).Linux-x86_64.tar.xz
builder_filename = $(notdir $(builder_url))
checksums_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/sha256sums

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
	keepalived \
	kmod-bonding \
	kmod-fs-vfat \
	kmod-usb-net-rtl8152 \
	luci \
	luci-app-adblock \
	luci-app-ddns \
	luci-app-openvpn \
	luci-app-mwan3 \
	luci-app-unbound \
	luci-app-vpn-policy-routing \
	luci-app-wireguard \
	luci-proto-wireguard \
	mii-tool \
	mwan3 \
	nmap \
	openvpn-openssl \
	pciutils \
	python3-ctypes \
	python3-light \
	python3-logging \
	qrencode \
	rsyslog \
	screen \
	tcpdump \
	unbound-daemon \
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

ipsec_packages = \
	strongswan-full \
	kmod-crypto-gcm \
	kmod-xfrm-interface \
	xfrm

ifeq ($(target), "x86")
	# See: https://openwrt.org/toh/pcengines/apu2
	apu2_packages = \
		grub2 \
		grub2-efi \
		kmod-leds-gpio \
		kmod-crypto-hw-ccp \
		kmod-gpio-nct5104d \
		kmod-gpio-button-hotplug \
		kmod-usb-core \
		kmod-usb-ohci \
		kmod-usb2 \
		kmod-usb3 \
		kmod-sound-core \
		kmod-sp5100-tco \
		kmod-pcspkr \
		amd64-microcode \
		flashrom \
		irqbalance \
		fstrim

	# See: https://openwrt.org/docs/guide-user/virtualization/qemu_host
	qemu_packages = \
		fdisk \
		kmod-kvm-amd \
		kmod-kvm-intel \
		kmod-tun \
		qemu-bridge-helper \
		qemu-img \
		qemu-x86_64-softmmu
else
	apu2_packages = ""
	qemu_packages = ""
endif

# See: https://openwrt.org/docs/guide-user/virtualization/docker_host
docker_packages = \
	docker \
	dockerd \
	luci-app-dockerman

.PHONY: all
ifeq ($(target), "x86")
all: deps builder build_dir image no_serial
else
all: deps builder build_dir image
endif

deps:
	# https://openwrt.org/docs/guide-user/additional-software/imagebuilder#debianubuntu
	sudo apt-get update
	sudo apt-get install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python

builder:
	# https://openwrt.org/docs/guide-user/additional-software/imagebuilder#obtaining_the_image_builder
	wget -q $(builder_url) -O $(builder_filename)
	wget -q $(checksums_url) -O sha256sums
	grep $(builder_filename) sha256sums | sha256sum --check --status

build_dir:
	rm -rf $(build_dir) && mkdir $(build_dir)
	tar -xf $(builder_filename) -C $(build_dir) --strip-components=1

image:
	sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.\+/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' $(build_dir)/.config
	cd $(build_dir) && make image \
		PROFILE=$(build_profile) \
		PACKAGES=" \
			$(router_packages) \
			$(wifi_packages) \
			$(ipsec_packages) \
			$(apu2_packages) \
			$(qemu_packages) \
			"
	du -hs $(build_dir)/bin/targets/$(target)/$(subtarget)/*
	cat $(build_dir)/bin/targets/$(target)/$(subtarget)/sha256sums

no_serial:
	./generate-no-serial-images.sh $(build_dir)/bin/targets/$(target)/$(subtarget)/*combined.img.gz $(build_dir)/bin/targets/$(target)/$(subtarget)/*combined-efi.img.gz
	cd $(build_dir)/bin/targets/$(target)/$(subtarget)/ && sha256sum -b *no-serial.img.gz >> sha256sums
