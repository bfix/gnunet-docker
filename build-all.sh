#!/bin/bash

# This file is part of gnunet-docker.
# Copyright (C) 2019 - 2022 Bernd Fix  >Y<
#
# gnunet-docker is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# gnunet-docker is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL3.0-or-later

########################################################################
# Build GNUnet binaries and libraries.
########################################################################

export GNURL_VERSION=gnurl-7.72.0
export MHTTP_VERSION=v0.9.73
export GNUNET_VERSION=master
export GNUNET_GTK_VERSION=v0.17.0
export GNUNET_PREFIX=/opt/gnunet
export BUILD_LOG=~/build-all.log

declare -A VERSION
VERSION["gnurl"]="${GNURL_VERSION}"
VERSION["libmicrohttpd"]="${MHTTP_VERSION}"
VERSION["gnunet"]="${GNUNET_VERSION}"
VERSION["gnunet-gtk"]="${GNUNET_GTK_VERSION}"

declare -A SYNC
SYNC["gnurl"]=0
SYNC["libmicrohttpd"]=0
SYNC["gnunet"]=0
SYNC["gnunet-gtk"]=0

########################################################################

if [ "$1" == "sync" ]; then
	echo ">>> Pull changes from repos:"
	echo "WARNING: local changes are dropped!"
	# pull files
	for pkg in "${!VERSION[@]}"; do
		cd /opt/src/${pkg}
		echo ">>>     * ${pkg}"
		git remote update
		local=$(git rev-parse @)
		remote=$(git rev-parse '@{u}')
		base=$(git merge-base @ '@{u}')
		if [ "${local}" != "${remote}" -a "${local}" = "${base}" ]; then
			echo "Pulling updates..."
			git reset --hard
			git pull
			SYNC[${pkg}]=1
		fi
	done
fi

rm -f ${BUILD_LOG}

echo "*** Building 'gnurl'"
cd /opt/src/gnurl
if [ ${SYNC["gnurl"]} -eq 1 ]; then
	git checkout ${GNURL_VERSION}
	./buildconf >> ${BUILD_LOG}
	./configure \
		--enable-ipv6 --with-gnutls --without-libssh2 \
		--without-libmetalink --without-winidn --without-librtmp \
		--without-nghttp2 --without-nss --without-cyassl \
		--without-ssl --without-winssl --without-libpsl \
		--without-darwinssl --disable-sspi --disable-ldap \
		--disable-rtsp --disable-dict --disable-telnet --disable-tftp \
		--disable-pop3 --disable-imap --disable-smtp --disable-gopher \
		--disable-file --disable-ftp --disable-smb --disable-ntlm-wb \
		--prefix=${GNUNET_PREFIX} \
		>> ${BUILD_LOG}
fi
make >> ${BUILD_LOG}
make install >> ${BUILD_LOG}

echo "*** Building 'libmicrohttpd'"
cd /opt/src/libmicrohttpd
if [ ${SYNC["libmicrohttpd"]} -eq 1 ]; then
	git checkout ${MHTTP_VERSION}
	./bootstrap > ${BUILD_LOG}
	./configure --prefix=${GNUNET_PREFIX} >> ${BUILD_LOG}
fi
make >> ${BUILD_LOG}
make install >> ${BUILD_LOG}

echo "*** Building 'gnunet'"
cd /opt/src/gnunet
mkdir -p ${GNUNET_PREFIX}
if [ ${SYNC["gnunet"]} -eq 1 ]; then
	git checkout ${GNUNET_VERSION}
	./bootstrap >> ${BUILD_LOG}
	./configure \
		--prefix=${GNUNET_PREFIX} \
		--enable-logging=verbose \
		--with-microhttpd=${GNUNET_PREFIX} \
		--with-libgnurl=${GNUNET_PREFIX} \
		>> ${BUILD_LOG}
fi
make >> ${BUILD_LOG}
make install >> ${BUILD_LOG}

echo "*** Building 'gnunet-gtk'"
cd /opt/src/gnunet-gtk
if [ ${SYNC["gnunet-gtk"]} -eq 1 ]; then
	git checkout ${GNUNET_GTK_VERSION}
	./bootstrap >> ${BUILD_LOG}
	./configure \
		--prefix=${GNUNET_PREFIX} \
		--with-gnunet=${GNUNET_PREFIX} \
		>> ${BUILD_LOG}
fi
make >> ${BUILD_LOG}
make install >> ${BUILD_LOG}
