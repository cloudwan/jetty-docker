# Jetty Docker

This creates a Docker image of Apache Jetty.  The image is to be used as a
parent by a child image which supplies its own configuration files.

## Important Licensing Notes

This Jetty docker image includes Oracle Java, which may not be redistributed
without permission.  Therefore, this image as well as any of its descendant
images may not be uploaded to a public registry or otherwise redistributed.

## Build-time Knobs

A few knobs control the image build.  They can be passed as build arguments
(``docker build --build-arg``):

### Jetty Home

Use ``JETTY_HOME`` to change where Jetty distribution is installed, also known
as [the Jetty home](
http://www.eclipse.org/jetty/documentation/9.4.x/startup-base-and-home.html).
It must be an absolute pathname.  The default is ``/opt/jetty``.

### Jetty Version & Distribution

Use ``JETTY_VERSION`` to change the version of Jetty to install.  It should be a
full version string complete with major/minor/micro/datestamp components, such
as ``9.3.17.v20170317``.

By default, the installation script fetches the distribution tarball from [the
Maven Central Repository](http://central.maven.org/maven2/).  If you want to use
a different mirror, specify its URL using ``MAVEN_CENTRAL_REPO``.

Alternatively, if you have a local, non-Maven-style mirror of the Jetty
distribution, specify its URL using ``JETTY_DIST_SITE``.  It must be a directory
URL, in which the installation script will then locate and fetch an
appropriately named tarball.  ``MAVEN_CENTRAL_REPO`` is ignored in this case.

Finally, if you need to fetch and use a specific distribution tarball whose name
does not conform to the standard naming scheme, such as a patched tarball like
``myjetty.tar.gz``, specify its full URL using ``JETTY_DIST_URL``.
``MAVEN_CENTRAL_REPO`` and ``JETTY_DIST_SITE`` are both ignored in this case.

## Runtime Knobs

A few runtime knobs are available as environment variables.  Descendant
Dockerfiles and images can read them.  Descendant Dockerfiles and the ``--env``
family of the ``docker run`` options can also override them.  They are not used
while building this base image (not descendants), so they may not be passed to
``docker build --build-arg``.

### Jetty User & Base

``JETTY_USER`` (default ``nobody``) is the name of the user that runs Jetty.

``JETTY_BASE`` is [the Jetty base](
http://www.eclipse.org/jetty/documentation/9.4.x/startup-base-and-home.html),
i.e.  where Jetty runs.

The default Jetty base (``${JETTY_HOME}/demo-base``) is only for demo purposes;
descendant images should create and populate their own Jetty base directory,
then set ``JETTY_BASE`` to the directory.

### Logging

``JETTY_LOGS`` (default ``${JETTY_BASE}/logs``) is a directory where Jetty
stores the log files.

The startup script creates this directory if it does not exist, then ``chown``-s
the directory and all its contents to ``${JETTY_USER}``.  The startup script
also passes this directory as [the ``jetty.logs`` property](
http://www.eclipse.org/jetty/documentation/9.4.x/configuring-logging.html).

### Listening Ports

``JETTY_PORTS`` (default 8080 and 8443) is the whitespace-separated list of TCP
ports that Jetty listens on.

Note: Concrete (leaf) descendant Dockerfiles should include ``EXPOSE
${JETTY_PORTS}`` to expose these things.  This image does not do so—not even
using ``ONBUILD EXPOSE``, because it does not know how many interim images will
be there between it and a leaf image.

Thie Jetty image runs Jetty under Debian authbind.  At runtime, the startup
script automatically enables privileged ports (those under 1024) in
``${JETTY_PORTS}`` for authbinding by ``${JETTY_USER}``.

## Read-only Environment Variables

A few read-only environment variables are available, again both at build time
and at runtime.  Descendant Dockerfiles and images should consider them as
read-only; the result of overriding them in descendant Dockerfiles or by
``docker run --env`` is undefined.

``JETTY_HOME`` holds the Jetty home directory configured during build time and
baked into the image.

``JETTY_RUN`` is the full pathname to the Jetty startup script.  See Overriding
Entrypoint below for details.

## Overriding Entrypoint

The Dockerfile of a child image may override ``ENTRYPOINT`` if the child image
needs its own startup behavior.  If the Jetty still needs to be run as the main
process, the entrypoint script of the child image should, at its end,
execute ``${JETTY_RUN}`` along with any appropriate command-line
entrypoint arguments that it decides are for Jetty.

For example, the following entrypoint script processes a few options, then
passes the remaining positional (non-option) arguments to Jetty::

    #!/bin/sh
    set -eu
    unset opt jetty_args
    while getopts :xy: opt
    do
            case "${opt}" in
            '?') echo "error: unknown option -${OPTARG}" >&2; exit 64;;
            ':') echo "error: missing argument for -${OPTARG}" >&2; exit 64;;
            x)
                    # do something
                    ;;
            y)
                    # do something with ${OPTARG}
                    ;;
            esac
    done
    shift $((${OPTIND} - 1))
    # The remaining positional arguments are for Jetty
    exec "${JETTY_RUN}" "$@"

**Note:** The child image must ``exec``-ute ``${JETTY_RUN}`` as shown above; so
that the Java process for Jetty becomes the main process of the docker.  Simply
running ``${JETTY_RUN}`` without ``exec`` makes the entrypoint script the main
process, which is not desirable.

## Creating & Using Non-official Jetty Distribution Tarballs

When using a non-official Jetty distribution tarball, make sure that
``JETTY_VERSION`` is set to the version string used in that tarball.  Look in
the ``lib/`` subdirectory for filenames suffixed with this version string, e.g.
``jetty-client-9.3.17.v20170317.jar`` has the version string of
``9.3.17.v20170317``.

When creating a custom Jetty distribution tarball, make sure that all members
reside in a standard top-level directory prefix:
``jetty-distribution-${JETTY_VERSION}/``.

To Do/Wishlist
--------------

* Parametrize the parent image (depends on [Docker PR
  #31352](https://github.com/docker/docker/pull/31352)).
