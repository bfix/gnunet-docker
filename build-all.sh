#!/bin/bash

########################################################################
# Build GNUnet binaries and libraries.
########################################################################

export GNUNET_PREFIX=/opt/gnunet
export BUILD_LOG=~/build-all.log

########################################################################

if [ "$1" == "sync" ]; then
	echo ">>> Pull changes from repos:"
	for pkg in libgcrypt gnurl libmicrohttpd gnunet gnunet-gtk; do
		cd /opt/src/${pkg}
		echo ">>>     * ${pkg}"
		git pull
	done
fi

echo "*** Building 'gnurl'"
cd /opt/src/gnurl
./buildconf > ${BUILD_LOG}
./configure \
	--enable-ipv6 --with-gnutls --without-libssh2 \
	--without-libmetalink --without-winidn --without-librtmp \
	--without-nghttp2 --without-nss --without-cyassl \
	--without-ssl --without-winssl --without-libpsl \
	--without-darwinssl --disable-sspi --disable-ldap \
	--disable-rtsp --disable-dict --disable-telnet --disable-tftp \
	--disable-pop3 --disable-imap --disable-smtp --disable-gopher \
	--disable-file --disable-ftp --disable-smb --disable-ntlm-wb \
	--prefix=${GNUNET_PREFIX}  > ${BUILD_LOG}
make > ${BUILD_LOG}
make install > ${BUILD_LOG}

echo "*** Building 'libmicrohttpd'"
cd /opt/src/libmicrohttpd
./bootstrap > ${BUILD_LOG}
./configure --prefix=${GNUNET_PREFIX} > ${BUILD_LOG}
make > ${BUILD_LOG}
make install > ${BUILD_LOG}

echo "*** Building 'gnunet'"
cd /opt/src/gnunet
mkdir -p ${GNUNET_PREFIX}
./bootstrap > ${BUILD_LOG}
./configure \
	--prefix=${GNUNET_PREFIX} \
	--enable-logging=verbose \
	--with-sudo=sudo \
	--with-microhttpd=${GNUNET_PREFIX} \
	--with-libgnurl=${GNUNET_PREFIX} \
	 > ${BUILD_LOG}
make > ${BUILD_LOG}
make install > ${BUILD_LOG}

echo "*** Building 'gnunet-gtk'"
cd /opt/src/gnunet-gtk
./bootstrap > ${BUILD_LOG}
./configure \
	--prefix=${GNUNET_PREFIX} \
	--with-gnunet=${GNUNET_PREFIX} \
	 > ${BUILD_LOG}
make > ${BUILD_LOG}
make install > ${BUILD_LOG}
