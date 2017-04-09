#!/bin/sh

set -eu

punch_port() {
	local user group port file
	user="${1}"
	shift 1
	case "${user}" in
	*:*)
		group="${user#*:}"
		user="${user%%:*}"
		;;
	*)
		group="$(id -gn "${user}")"
		;;
	esac
	for port
	do
		case $((${port} < 1024)) in
		0)
			continue
			;;
		esac
		echo "INFO: authbinding ${port} for ${user}:${group}" >&2
		file="/etc/authbind/byport/${port}"
		install -o "${user}" -g "${group}" -m 0755 /dev/null "${file}"
	done
}

punch_port "${JETTY_USER}" ${JETTY_PORTS}

case "${JETTY_LOGS-}" in
"")
	JETTY_LOGS="${JETTY_BASE}/logs"
	export JETTY_LOGS
	;;
esac
mkdir -p "${JETTY_LOGS}"
chown -RHh "${JETTY_USER}" "${JETTY_LOGS}"

exec su --shell /bin/sh "${JETTY_USER}" -c '
	set -eu
	cd "${JETTY_BASE}"
	exec authbind --deep /usr/bin/java -jar "${JETTY_HOME}/start.jar" "$@"
' jetty.logs="${JETTY_LOGS}" "$@"
