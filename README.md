# gnunet-docker
Dockerfiles for building and running GNUnet

There are Dockerfiles to create two GNUnet images:

## "GNUnet build" image (~2.5GB)

The "build" image is used to compile GNUnet (core and Gtk) from source code
that is pulled from the official GNUnet Git repository (https://gnunet.org/git/).
The compiled binaries (programs and libraries) are packaged into a tar.gz; the
archive will later be used to install GNUnet into the "run" image.

The corresponding Dockerfile (`Dockerfile.build`) is compiled into an image
using the `mk_build` script. The archive with the compiled binaries is put
into the current directory by the script after the build is complete.

The Dockerfile specifies the Git revision/tag of the GNUnet repository to be
build (`ENV GNUNET_VERSION v0.11.0pre66`) and needs be be changed if you want
to buld a different version of GNUnet. The version must be consistent between
core and Gtk repositories.

## "GNUnet run" image (~400MB)

The "run" image is used to run GNUnet as a Docker container. It installs the
archive of compiled binaries from the "build" image and installs all
required runtime dependencies.

The corresponding Dockerfile (`Dockerfile.deploy`) is compiled into an image
using the `mk_deploy` script.

### Customization

Before building the `run image`, you might want to customize the runtime
configuration to your needs:

#### gnunet-system.conf

This file will be copied to `/etc/gnunet.conf` and specifies the system
configuration. The provided example file is an example of an IPv4-only
system behind a punched NAT.

#### gnunet-user.conf

This file specifies the user configuration and need to be copied manually
to the correct location (see "Running GNUnet").

### Running GNUnet in a Docker container

The container is run using the `run_deploy` script:

    docker run --rm -ti --name gnunet -h gnunet \
        --cap-add=NET_ADMIN --cap-add=NET_BROADCAST --device=/dev/net/tun \
        -e DISPLAY=${DISPLAY} \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v <local folder 1>:/home/user \
        -v <local folder 2>:/var/lib/gnunet \
        -p 0.0.0.0:2086:2086 \
        -p 0.0.0.0:1080:1080 \
        bfix/gnunet

It maps two local directories into the container, the home directories of the
user `gnunet` (GNUnet system account) and `user` (GNUnet user account). Make
sure that your local folders have the following uid/gid assignements:

* `local folder 1`: (uid=1000/gid=1000)
* `local folder 2`: (uid=102/gid=102)

You should copy the user's `gnunet.conf` to the `.config` directory in
`local folder 1` before running the container.

When the container is started, a shell is opened for user `user` and no GNUnet
programs are started. To start GNUnet (system and user part), run the
`/usr/bin/gnunet-start` script.

You can now run GNUnet programs as you like.

To quit the container, stop GNUnet by running the `/usr/bin/gnunet-stop` script
and exit the shell.

