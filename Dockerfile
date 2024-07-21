
############################################################
# Dockerfile to build ">Y< GNUnet" compile & deploy image.
#
# This file is part of gnunet-docker.
# Copyright (C) 2019-2024 Bernd Fix  >Y<
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
############################################################

FROM debian:bookworm AS builder

LABEL maintainer="Bernd Fix <brf@hoi-polloi.org>"

ENV MHTTP_VERSION=v0.9.75
ENV GNUNET_VERSION=v0.21.2
ENV GNUNET_GTK_VERSION=v0.21.0

ENV GNUNET_PREFIX=/opt/gnunet


#-----------------------------------------------------------
# Install dependencies.
#-----------------------------------------------------------

ENV DEBIAN_FRONTEND=noninteractive

RUN \
	apt update && \
	apt -y upgrade && \
	apt -y install --no-install-recommends \
		autopoint \
		bluetooth \
		build-essential \
		ca-certificates \
		git \
		iptables \
		libcurl4-gnutls-dev \
		libextractor-dev \
		libgcrypt-dev \
		libgladeui-dev \
		libglpk-dev \
		libidn11-dev \
		libjose-dev \
		libogg-dev \
		libopus-dev \
		libpq-dev \
		libpulse-dev \
		libqrencode-dev \
		librec-dev \
		libsodium-dev \
		libsqlite3-dev \
		libtool \
		libunistring-dev \
		libzbar-dev \
		miniupnpc \
		python3-sphinx \
		python3-sphinx-rtd-theme \
		python3-zbar \
		recutils \
		texi2html \
		texinfo \
	&& \
	apt clean all && \
	apt -y autoremove --purge && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#-----------------------------------------------------------
# Install latest libmicrohttpd
#-----------------------------------------------------------

RUN \
	mkdir -p /opt/src && \
	cd /opt/src && \
	git clone https://git.gnunet.org/libmicrohttpd.git libmicrohttpd && \
	cd /opt/src/libmicrohttpd && \
	git checkout ${MHTTP_VERSION} && \
	./bootstrap && \
	./configure --prefix=${GNUNET_PREFIX} && \
	make && \
	make install

#===========================================================
# GNUnet CORE
#===========================================================

#-----------------------------------------------------------
# Get GNUnet source code
#-----------------------------------------------------------

RUN \
	mkdir -p /opt/src && \
	cd /opt/src && \
	git clone https://git.gnunet.org/gnunet.git gnunet && \
	cd gnunet && \
	git checkout ${GNUNET_VERSION}

#-----------------------------------------------------------
# Build GNUnet core
#-----------------------------------------------------------

RUN \
	adduser --system --home /var/lib/gnunet --uid 666 --group --disabled-password gnunet && \
	addgroup --system --gid 667  gnunetdns && \
	cd /opt/src/gnunet && \
	mkdir -p ${GNUNET_PREFIX} && \
	./bootstrap && \
	./configure \
		--prefix=${GNUNET_PREFIX} \
		--enable-logging=verbose \
		--with-microhttpd=${GNUNET_PREFIX} \
		&& \
	make && \
	make install

#===========================================================
# GNUnet GTK
#===========================================================

#-----------------------------------------------------------
# Get GNUnet GTKsource code (latest revision)
#-----------------------------------------------------------

RUN \
	cd /opt/src && \
	git clone https://git.gnunet.org/gnunet-gtk.git gnunet-gtk && \
	cd gnunet-gtk && \
	git checkout ${GNUNET_GTK_VERSION}

#-----------------------------------------------------------
# Build GNUnet GTK
#-----------------------------------------------------------

RUN \
	cd /opt/src/gnunet-gtk && \
	./bootstrap && \
	./configure \
		--prefix=${GNUNET_PREFIX} \
		--with-gnunet=${GNUNET_PREFIX} \
		&& \
	make && \
	make install

#-----------------------------------------------------------
# Package binaries.
#-----------------------------------------------------------

RUN \
	tar cvzf /opt/gnunet-bin.tar.gz -C ${GNUNET_PREFIX} .


#===========================================================
# Deployment image
#===========================================================

FROM debian:bookworm AS deploy

LABEL maintainer="Bernd Fix <brf@hoi-polloi.org>"

ENV DEBIAN_FRONTEND=noninteractive

#-----------------------------------------------------------
# Install dependencies.
#-----------------------------------------------------------

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		gnutls-bin \
		libatomic1 \
		libcurl3-gnutls \
		libextractor3 \
		libgladeui-2-13 \
		libnss3-tools \
		libqrencode4 \
		libsqlite3-0 \
		openssl \
		procps \
		screen \
		sudo \
		vim \
		&& \
	apt-get clean all && \
	apt-get -y autoremove --purge && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#-----------------------------------------------------------
# Install application binaries (apps and libs).
#-----------------------------------------------------------

COPY --from=builder /opt/gnunet-bin.tar.gz /root

RUN \
	mkdir -p /opt/gnunet && \
	tar xvzf /root/gnunet-bin.tar.gz -C /opt/gnunet && \
	rm -f /root/gnunet-bin.tar.gz

#-----------------------------------------------------------
# Prepare runtime environment.
#-----------------------------------------------------------

COPY gnunet-ldconfig.conf /etc/ld.so.conf.d/gnunet.conf
COPY gnunet-start         /usr/bin/
COPY gnunet-end	          /usr/bin/

RUN \
	ldconfig && \
	adduser --system --home /var/lib/gnunet --uid 666 --group --disabled-password gnunet && \
	addgroup --system --gid 667 gnunetdns && \
	mkdir -p /var/lib/gnunet/.config/gnunet && \
	ln -s /var/lib/gnunet/.config/gnunet.conf /etc/gnunet.conf && \
	sed -i -e "s/^hosts:\([[:space:]]*\).*$/hosts:\1files gns [NOTFOUND=return] dns/" /etc/nsswitch.conf

#-----------------------------------------------------------
# Setup application user.
#-----------------------------------------------------------

RUN \
	export uid=1000 gid=1000 && \
	mkdir -p /home/user && \
	echo "user:x:${uid}:${gid}:User,,,:/home/user:/bin/bash" >> /etc/passwd && \
	echo "user:x:${uid}:" >> /etc/group && \
	echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user && \
	chmod 0440 /etc/sudoers.d/user && \
	echo "export PATH=/opt/gnunet/bin:\$PATH" > /home/user/.bash_profile && \
	chown ${uid}:${gid} -R /home/user && \
	gpasswd -a user gnunet && \
	echo "neednone\nneednone" | passwd user

#-----------------------------------------------------------
# Entry point
#-----------------------------------------------------------

USER user
ENV HOME=/home/user
CMD ["/bin/bash", "-l"]

EXPOSE 1080 2086
