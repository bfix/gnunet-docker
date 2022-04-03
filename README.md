# gnunet-docker
Dockerfiles for building and running [GNUnet](https://gnunet.org/).

## License

gnunet-docker is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

gnunet-docker is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL3.0-or-later

## "GNUnet deploy" image (~800MB)

The deploy image is build in a multi-stage build from `Dockerfile`:

The "builder" stage is used to compile GNUnet (core and Gtk) from source code
that is pulled from the official GNUnet Git repository (https://gnunet.org/git/).
The compiled binaries (programs and libraries) are packaged into a tar.gz; the
archive will later be used to install GNUnet into the deployment image.

The Dockerfile specifies the Git revision/tag of the GNUnet repository to be
build (`ENV GNUNET_VERSION v0.11.0`) and needs be be changed if you want
to build a different version of GNUnet. Use `ENV GNUNET_VERSION latest` to
build the latest version of GNUnet. The specified version must be consistent
between core and Gtk repositories.

If the GNUnet repositories change after the initial build, you need to re-
build the image. Just run the `mk_deploy` script again. This way also newer
Debian packages are installed.

The "deploy" stage is used to run GNUnet as a Docker container. It installs the
archive of compiled binaries from the "builder" stage and installs all
required runtime dependencies.

The Dockerfile (`Dockerfile`) is compiled into an image using the `mk_deploy`
script.

### Initial setup

Before running the `deploy image`, you need to setup the runtime environment for
GNUnet. This runtime is a directory stored outside of the Docker container on
the host file-system. This way configuration changes are persistent between
GNUnet sessions (running/terminating the Docker image).

To initialize the runtime directory run:

```bash
$ ./init_deploy ${GNUNET_RUNTIME}
```

and set `${GNUNET_RUNTIME}` to a directory of your choice. Please note that you
need `sudo` privileges to successfully run the script.

You should now edit the configuration files to customize them to your needs:

#### ${GNUNET_RUNTIME}/system/.config/gnunet.conf

This file will be accessible as `/etc/gnunet.conf` in the Docker container and
specifies the system configuration. The default configuration is an example for
an IPv4-only system behind a punched NAT. You will at least need to replace the
line `EXTERNAL_ADDRESS = xxx.xxx.xxx.xxx` with your public IPv4 address.

You need `sudo` to edit the configuration file as non-root.

#### ${GNUNET_RUNTIME}/user/.config/gnunet.conf

This file specifies the user configuration and need to be copied manually
to the correct location (see "Running GNUnet").

You need `sudo` to edit the configuration file as non-root and if your user id
is not `1000`.

### Running GNUnet in a Docker container

#### Running the container

The container is run using the `run_deploy` script (that you need to customize
for the local directories on your host system):

```bash
docker run --rm -ti --name gnunet -h gnunet \
    --cap-add=NET_ADMIN --cap-add=NET_BROADCAST --device=/dev/net/tun \
    -e DISPLAY=${DISPLAY} \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ${GNUNET_RUNTIME}/user:/home/user \
    -v ${GNUNET_RUNTIME}/system:/var/lib/gnunet \
    -p 0.0.0.0:2086:2086 \
    -p 0.0.0.0:1080:1080 \
    bfix/gnunet
```

It maps to the two folders in `${GNUNET_RUNTIME}`: the home directories for the
user `gnunet` (GNUnet system account) and `user` (GNUnet user account). If you
have created these folders yourself (and not by running the `init_deploy`
script), make sure that your folders have the following uid/gid assignments:

* `${GNUNET_RUNTIME}/user`:   (uid=1000/gid=1000)
* `${GNUNET_RUNTIME}/system`: (uid=666 /gid=666 )

When the container is run, a shell is opened for user `user` and no GNUnet
programs are started. To start GNUnet (system and user part), run the
`/usr/bin/gnunet-start` script with an appropriate argument.

#### First time setup

Please follow the instruction on the GNUnet website (https://gnunet.org/) to
setup and customize your GNUnet instance.

#### Using GNUnet

##### Starting GNUnet

```bash
$ gnunet-start [sys|usr|all]
```

For normal interactive use specify the `all` argument.

##### Running GNUnet programs

You can now run GNUnet programs as you like.

##### Stopping GNUnet

```bash
$ gnunet-end [sys|usr|all]
```

#### Stopping the container

To quit the container, stop GNUnet by running the `/usr/bin/gnunet-stop` script
and exit the shell.

The container used to run the GNUnet image is automatically removed (if you
use the `--rm` option when running the image).

## "GNUnet dev" image (~1.3GB)

This Docker image can be used to compile and run GNUnet in a development
environment. The corresponding Dockerfile (`Dockerfile.dev`) is compiled into
an image using the `mk_dev` script.

#### Running the container

The container is run using the `run_dev` script (that you need to customize
for the local directories on your host system). The directories are
specified at the beginning of the script:

```bash
export GNUNET_RUNTIME=${1:-/usr/local/gnunet/rt}
export GNUNET_SOURCE=${2:-/usr/local/gnunet/src}
```

The first directory `GNUNET_RUNTIME` maps three subfolders into the container:
the home directories for the user `gnunet` (GNUnet system account); `user`
(GNUnet user account) and `build` for the compiled binaries. If you have
created these folders yourself (and not by running the `init_deploy` script),
make sure that your folders have the following uid/gid assignments:

* `${GNUNET_RUNTIME}/user`:   (uid=1000/gid=1000)
* `${GNUNET_RUNTIME}/system`: (uid=666 /gid=666 )
* `${GNUNET_RUNTIME}/build`:  (uid=1000/gid=1000)

The second directory `GNUNET_SOURCE` maps the root of the existing source
directories (especially `libmicrohttpd`, `gnunet` and `gnunet-gtk`) into the
container at run-time. Make sure that your source directories are owned
by user id '1000' with group id '1000'.

If the container is started (it opens a bash shell), you need to run
`sudo /sbin/ldconfig` first before trying to start GNUnet. This is mandatory
for every start of the container.
