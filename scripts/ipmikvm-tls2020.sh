#!/bin/sh
# ipmikvm-tls2020 (part of ossobv/vcutil) // wdoekes/2020 // Public Domain
#
# A wrapper to call the SuperMicro iKVM console bypassing Java browser
# plugins.
#
# Requirements: base64, curl, java
#
# Usage:
#
#   $ ipmikvm-tls2020
#   Usage: ipmikvm-tls2020 [-u ADMIN] [-P ADMIN] IP.ADD.RE.SS
#
#   $ ipmikvm-tls2020 10.11.12.13 -P otherpassword
#   (connects KVM console on IPMI device at 10.11.12.13)
#
# This has been tested with iKVM__V1.69.39.0x0.
#
# See also: ipmikvm
#
test -z "$HOME" && echo 'missing $HOME' && exit 1
set -u
APP_CACHE_DIR="$HOME/.local/lib/ipmikvm-tls2020"

IP=
USER=ADMIN
PASS=ADMIN

# Use getopt(1) to reorder arguments
eval set --"$(getopt -- 'hk2p:u:P:' "$@")"

usage() {
    test ${1:-1} -ne 0 && exec >&2  # non-zero? write to stderr
    echo "Usage: $0 [-u ADMIN] [-P ADMIN] IP.ADD.RE.SS"
    exit ${1:-1}
}

while getopts 'hu:P:' OPTION; do
    case "$OPTION" in
    h) usage 0;;
    u) USER=$OPTARG;;
    P) PASS=$OPTARG;;
    ?) usage 1;;
    esac
done
shift $((OPTIND - 1))

test $# -ne 1 && usage
IP=${1:-}; shift
test -z "$IP" && usage


get_launch_jnlp() {
    management_ip="$1"
    user="$2"
    pass="$3"

    fail=1
    url="https://$management_ip"
    temp=$(mktemp)
    b64_user=$(echo -n "$user" | base64 -w0 | sed -e 's/=/%3D/g;s/+/%2B/g')
    b64_pass=$(echo -n "$pass" | base64 -w0 | sed -e 's/=/%3D/g;s/+/%2B/g')
    if curl --fail -sk --cookie-jar "$temp" -XPOST "$url/cgi/login.cgi" \
          --data "name=$b64_user&pwd=$b64_pass&check=00" -o/dev/null; then
        launch_jnlp=$(curl --fail -sk --cookie "$temp" \
            "$url/cgi/url_redirect.cgi?url_name=man_ikvm&url_type=jwsk")
        test $? -eq 0 && fail=
    fi
    rm "$temp"
    test -z "$fail" && echo "$launch_jnlp"
}
# SYNOPSIS: get_launch_jnlp 10.x.x.x USERNAME PASSWORD

get_username() {
    launch_jnlp="$1"
    echo "$launch_jnlp" | sed -e '/<argument>/!d' |
      sed -e '12!d;s#.*<argument>\([^<]*\)</argument>#\1#'
}
# SYNOPSIS: get_username JNLP_DATA

get_password() {
    launch_jnlp="$1"
    echo "$launch_jnlp" | sed -e '/<argument>/!d' |
      sed -e '13!d;s#.*<argument>\([^<]*\)</argument>#\1#'
}
# SYNOPSIS: get_password JNLP_DATA

exec_ikvm_tls2020() {
    jar="$1"
    management_ip="$2"
    user="$3"
    pass="$4"
    echo $jar $management_ip $user $pass
    # If you look at the (decompiled) source, you'll notice that the
    # two local ports (65534 65535) get replaced, and the two remote ports
    # are set to default (5900 623). We'll set them here in case an updated
    # jar file fixes it.
    # Additionally, if you set use_tls (argument 18) to 0, the code
    # path simply ends. So we cannot use this one to connect to older
    # plain iKVM interfaces.
    exec java -Djava.library.path="$(dirname "$jar")" \
      -cp "$jar" tw.com.aten.ikvm.KVMMain \
      0 1 2 3 4 5 6 7 8 9 \
      "$management_ip" "$user" "$pass" null 65534 65535 0 0 1 5900 \
      623 1
}
# SYNOPSIS: exec_ikvm_tls2020 10.x.x.x KVM_USERNAME KVM_PASSWORD

install_ikvm_application() {
    launch_jnlp="$1"
    destdir="$2"

    set -e
    codebase=$(
      echo "$launch_jnlp" | sed -e '/<jnlp /!d;s/.* codebase="//;s/".*//')
    jar=$(
      echo "$launch_jnlp" | sed -e '/<jar /!d;s/.* href="//;s/".*//')
    linuxlibs=$(
      echo "$launch_jnlp" |
      sed -e '/<nativelib /!d;/linux.*x86_64/!d;s/.* href="//;s/".*//' |
      sort -u)
    set -x
    mkdir -p "$destdir"
    cd "$destdir"
    for x in $jar $linuxlibs; do
        curl -o $x.pack.gz "$codebase$x.pack.gz"
        unpack200 $x.pack.gz $x
    done
    unzip -o liblinux*.jar
    rm -rf META-INF
    set +x
    set +e
}
# SYNOPSIS: install_ikvm_application JNLP_DATA DESTDIR


JNLP=$(get_launch_jnlp "$IP" "$USER" "$PASS")
test -z "$JNLP" && echo "Failed to get launch.jnlp" >&2 && exit 1

echo jnlp is $JNLP

JAR=$(find $APP_CACHE_DIR -name 'iKVM*.jar' | sort | tail -n1)
if ! test -f "$JAR"; then
    install_ikvm_application "$JNLP" "$APP_CACHE_DIR"
    JAR=$(find $APP_CACHE_DIR -name 'iKVM*.jar' | sort | tail -n1)
    if ! ls -l "$JAR"; then
        echo "Install failure" >&2
        exit 1
    fi
fi

exec_ikvm_tls2020 "$JAR" "$IP" \
    "$(get_username "$JNLP")" "$(get_password "$JNLP")"
