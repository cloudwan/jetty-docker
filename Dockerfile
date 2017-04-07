FROM		oracle-java
LABEL		maintainer=eugene.kim@ntti3.com
ARG		JETTY_VERSION="9.3.17.v20170317"
ARG		MAVEN_CENTRAL_REPO="http://central.maven.org/maven2"
ARG		JETTY_DIST_SITE="${MAVEN_CENTRAL_REPO}/org/eclipse/jetty/jetty-distribution/${JETTY_VERSION}"
ARG		JETTY_DIST_URL="${JETTY_DIST_SITE}/jetty-distribution-${JETTY_VERSION}.tar.gz"
ARG		JETTY_HOME="/opt/jetty"
ENV		JETTY_HOME="${JETTY_HOME}" \
		JETTY_RUN="/jetty_run.sh" \
		JETTY_USER=nobody \
		JETTY_BASE="${JETTY_HOME}/demo-base" \
		JETTY_LOGS="" \
		JETTY_PORTS="8080 8443"
WORKDIR		/
USER		root
COPY		["files/", "/"]
RUN		set -eu; \
		apt-get update -y; \
		apt-get install -y authbind; \
		install -d -o 0 -g 0 -m 0755 "${JETTY_HOME}"; \
		wget --no-verbose -O- "${JETTY_DIST_URL}" | \
		tar -x -z -f- --strip-components=1 -C "${JETTY_HOME}" --no-same-owner; \
# Fix X-Proxied-Https handling
		sed -i 's@<Set name="forwardedForHeader"><Property name="jetty\.httpConfig\.forwardedHttpsHeader" default="X-Proxied-Https"/></Set>@<Set name="forwardedHttpsHeader"><Property name="jetty\.httpConfig\.forwardedHttpsHeader" default="X-Proxied-Https"/></Set>@g' \
			"${JETTY_HOME}/etc/jetty-http-forwarded.xml"
ENTRYPOINT	["/jetty_run.sh"]
