#!/bin/bash

export GNUNET_PREFIX=/opt/gnunet

cd /opt/src/libmicrohttpd
./bootstrap
./configure --prefix=${GNUNET_PREFIX}
make
make install

cd /opt/src/gnunet
mkdir -p ${GNUNET_PREFIX}
./bootstrap
./configure \
	--prefix=${GNUNET_PREFIX} \
	--enable-logging=verbose \
	--with-sudo=sudo \
	--with-microhttpd=${GNUNET_PREFIX}
make
make install


cd /opt/src/gnunet-gtk
./bootstrap
./configure \
	--prefix=${GNUNET_PREFIX} \
	--with-gnunet=${GNUNET_PREFIX}
make
make install

