release = 19.07.7
target = x86
subtarget = 64
builder_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/openwrt-imagebuilder-$(release)-$(target)-$(subtarget).Linux-x86_64.tar.xz
builder_filename = $(notdir $(builder_url))
checksums_url = https://downloads.openwrt.org/releases/$(release)/targets/$(target)/$(subtarget)/sha256sums

install-deps:
	# https://openwrt.org/docs/guide-user/additional-software/imagebuilder#debianubuntu
	sudo apt-get update
	sudo apt-get install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python

get-builder:
	# https://openwrt.org/docs/guide-user/additional-software/imagebuilder#obtaining_the_image_builder
	wget -q $(builder_url) -O $(builder_filename)
	wget -q $(checksums_url) -O sha256sums
	grep $(builder_filename) sha256sums | sha256sum --check --status
	mkdir -p builder/
	tar -xf $(builder_filename) -C builder/ --strip-components=1

