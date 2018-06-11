# gnunet-docker
Dockerfiles for building and running GnuNET

There are Dockerfiles to create two GnuNET images:

## "GnuNET build" image (~2.5GB)

The "build" image is used to compile GnuNET (core and Gtk) from source code
that is pulled from the official GnuNET Git repository (https://gnunet.org/git/).
The compiled binaries (programs and libraries) are packaged into a tar.gz; the
archive will later be used to install GnuNET into the "run" image.

The corresponding Dockerfile (`Dockerfile.build`) is compiled into an image
using the `mk_build` script. The archive with the compiled binaries is put
into the current directory by the script after the build is complete.

## "GnuNET run" image (~400MB)

The "run" image is used to run GnuNET as a Docker container. It installs the
archive of compiled binaries from the "build" image and installs all
required runtime dependencies.

The corresponding Dockerfile (`Dockerfile.deploy`) is compiled into an image
using the `mk_deploy` script.

### Running GnuNET in a Docker container

The container is run using the `run_deploy` script:

    docker run --rm -ti --name gnunet -h gnunet \
        --cap-add=NET_ADMIN --cap-add=NET_BROADCAST --device=/dev/net/tun \
        -e DISPLAY=${DISPLAY} \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v <local folder 1>:/home/user \
        -v <local folder 2>:/var/lib/gnunet \
        -p 127.0.0.1:2086:2086 \
        -p 127.0.0.1:1080:1080 \
        bfix/gnunet

It maps two local directories into the container, the home directories of the
user `gnunet` (GnuNET system account) and `user` (GnuNET user account). Make
sure that your local folders have the following uid/gid assignements:

* local folder 1: (uid=1000/gid=1000)
* local folder 2: (uid=102/gid=102)

When the container is started, a shell is opened for user `user` and no GnuNET
programs are started. To start GnuNET (system and user part), run the
`/usr/bin/gnunet-start` script.

If you started GnuNET for the first time, initialize GnuNET by running the
`/usr/bin/gnunet-user-init` script. Do this only once (or you will lose your
previous keys!).

You can now run GnuNET programs as you like.

To quit the container, stop GnuNET by running the `/usr/bin/gnunet-stop` script
and exit the shell.

