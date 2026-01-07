SUMMARY = "Canonical cloud-utils growpart (partition grow helper) + firstboot integration"
HOMEPAGE = "https://github.com/canonical/cloud-utils/"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d32239bcb673463ab874e80d47fae504"

SRC_URI = "\
  git://github.com/canonical/cloud-utils.git;branch=main;protocol=https \
  file://growpart-firstboot.service \
  file://growpart-firstboot.sh \
"

# Pin this in your build for reproducibility:
SRCREV = "49e5dd7849ee3c662f3db35e857148d02e72694b"
# SRCREV ??= "${AUTOREV}"

DEPENDS = "util-linux e2fsprogs"

inherit systemd

SYSTEMD_SERVICE:${PN} = "growpart-firstboot.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/bin/growpart ${D}${bindir}/growpart

    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/sources/growpart-firstboot.sh ${D}${sbindir}/growpart-firstboot

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/sources/growpart-firstboot.service ${D}${systemd_system_unitdir}/growpart-firstboot.service
}

FILES:${PN} += "\
  ${bindir}/growpart \
  ${sbindir}/growpart-firstboot \
  ${systemd_system_unitdir}/growpart-firstboot.service \
"

# Minimal runtime deps:
# - growpart itself uses shell + common text utils + util-linux tools (sfdisk/lsblk/blkid etc depending on path)
# - wrapper needs findmnt/lsblk to identify root device
# - resizing ext* needs resize2fs (optional if you later support xfs/btrfs)
RDEPENDS:${PN} += "\
  bash \
  coreutils \
  grep \
  gawk \
  sed \
  util-linux \
  e2fsprogs-resize2fs \
"
