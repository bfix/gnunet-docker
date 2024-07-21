#!/bin/bash

# This file is part of gnunet-docker.
# Copyright (C) 2019-present, Bernd Fix  >Y<
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

export MHTTP_VERSION=master
export GNUNET_VERSION=master
export GNUNET_GTK_VERSION=master
export GNUNET_PREFIX=/opt/gnunet
export BUILD_LOG=~/build-all.log

declare -A VERSION
VERSION["libmicrohttpd"]="${MHTTP_VERSION}"
VERSION["gnunet"]="${GNUNET_VERSION}"
VERSION["gnunet-gtk"]="${GNUNET_GTK_VERSION}"

declare -A REPO
REPO["libmicrohttpd"]="https://git.gnunet.org/libmicrohttpd.git"
REPO["gnunet"]="https://git.gnunet.org/gnunet.git"
REPO["gnunet-gtk"]="https://git.gnunet.org/gnunet-gtk.git"

declare -A SYNC
SYNC["libmicrohttpd"]=0
SYNC["gnunet"]=0
SYNC["gnunet-gtk"]=0

########################################################################

MODE=$1

# start logging
echo "************************************************" | tee ${BUILD_LOG}
echo "Build started on $(date)" | tee -a ${BUILD_LOG}
echo "************************************************" | tee -a ${BUILD_LOG}

# check if repos exist
pushd /opt/src/ > /dev/null
for pkg in "${!REPO[@]}"; do
	if [ ! -d ${pkg} ]; then
		echo ">>> Cloning repository ${pkg} from ${REPO[${pkg}]} ..." | tee -a ${BUILD_LOG}
		git clone ${REPO[${pkg}]} ${pkg} >> ${BUILD_LOG} 2>&1
		SYNC[${pkg}]=1
	fi
done
popd > /dev/null

if [ "${MODE}" == "sync" ]; then
	echo ">>> Pull changes from repos:" | tee -a ${BUILD_LOG}
	echo "WARNING: local changes are dropped!" | tee -a ${BUILD_LOG}
	# pull files
	for pkg in "${!VERSION[@]}"; do
		# skip newly cloned repos
		[ ${SYNC[${pkg}]} -eq 1 ] && continue

		cd /opt/src/${pkg}
		echo ">>>     * ${pkg}" | tee -a ${BUILD_LOG}
		git remote update >> ${BUILD_LOG} 2>&1
		local=$(git rev-parse @)
		remote=$(git rev-parse '@{u}')
		base=$(git merge-base @ '@{u}')
		if [ "${local}" != "${remote}" -a "${local}" = "${base}" ]; then
			echo "Pulling updates..." | tee -a ${BUILD_LOG}
			git reset --hard >> ${BUILD_LOG} 2>&1
			git clean -d --force >> ${BUILD_LOG} 2>&1
			git pull >> ${BUILD_LOG} 2>&1
			SYNC[${pkg}]=1
		fi
	done
fi

echo "*** Building 'libmicrohttpd'" | tee -a ${BUILD_LOG}
cd /opt/src/libmicrohttpd
if [ ${SYNC["libmicrohttpd"]} -eq 1 ]; then
	git checkout ${MHTTP_VERSION} >> ${BUILD_LOG} 2>&1
	./bootstrap >> ${BUILD_LOG} 2>&1
	./configure --prefix=${GNUNET_PREFIX} >> ${BUILD_LOG} 2>&1
fi
make >> ${BUILD_LOG} 2>&1
make install >> ${BUILD_LOG} 2>&1

echo "*** Building 'gnunet'" | tee -a ${BUILD_LOG}
cd /opt/src/gnunet
mkdir -p ${GNUNET_PREFIX}
if [ ${SYNC["gnunet"]} -eq 1 ]; then
	git checkout ${GNUNET_VERSION} >> ${BUILD_LOG} 2>&1
	./bootstrap >> ${BUILD_LOG} 2>&1
	./configure \
		--prefix=${GNUNET_PREFIX} \
		--enable-logging=verbose \
		--with-microhttpd=${GNUNET_PREFIX} \
		--with-libgnurl=${GNUNET_PREFIX} \
		>> ${BUILD_LOG} 2>&1
fi
make >> ${BUILD_LOG} 2>&1
make install >> ${BUILD_LOG} 2>&1

echo "*** Building 'gnunet-gtk'" | tee -a ${BUILD_LOG}
cd /opt/src/gnunet-gtk
if [ ${SYNC["gnunet-gtk"]} -eq 1 ]; then
	git checkout ${GNUNET_GTK_VERSION} >> ${BUILD_LOG} 2>&1
	./bootstrap >> ${BUILD_LOG} 2>&1
	./configure \
		--prefix=${GNUNET_PREFIX} \
		--with-gnunet=${GNUNET_PREFIX} \
		>> ${BUILD_LOG} 2>&1
fi
make >> ${BUILD_LOG} 2>&1
make install >> ${BUILD_LOG} 2>&1

echo "************************************************" | tee -a ${BUILD_LOG}
echo "Build finished on $(date)" | tee -a ${BUILD_LOG}
echo "************************************************" | tee -a ${BUILD_LOG}
