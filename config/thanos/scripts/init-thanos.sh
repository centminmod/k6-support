#!/bin/sh
set -e

# set ownership
chown -R thanos:thanos /data || true

# Process the template using shell substitution and create a new config file
eval "cat <<EOF
$(cat /etc/thanos/objstore.yml)
EOF" > /tmp/objstore.yml

echo "Starting Thanos with arguments: $@"

# Get the first argument (command)
COMMAND=$1
shift

# Build the final command array without the duplicate objstore flag
FINAL_ARGS=""
HAS_OBJSTORE_FLAG=false

# Process each argument
for arg in "$@"; do
    if echo "$arg" | grep -q "^--objstore.config-file="; then
        if [ "$HAS_OBJSTORE_FLAG" = false ]; then
            FINAL_ARGS="$FINAL_ARGS --objstore.config-file=/tmp/objstore.yml"
            HAS_OBJSTORE_FLAG=true
        fi
    else
        FINAL_ARGS="$FINAL_ARGS $arg"
    fi
done

# Add objstore flag if it wasn't in the arguments and this isn't the query component
if [ "$COMMAND" != "query" ] && [ "$HAS_OBJSTORE_FLAG" = false ]; then
    FINAL_ARGS="$FINAL_ARGS --objstore.config-file=/tmp/objstore.yml"
fi

# Debug output
if [ -f /tmp/objstore.yml ]; then
  echo "inspect /tmp/objstore.yml"
  cat /tmp/objstore.yml
  echo
fi

echo "id thanos"
id thanos || true

echo "Command: /bin/thanos $COMMAND $FINAL_ARGS"

# Execute Thanos with the processed arguments
exec /bin/thanos "$COMMAND" $FINAL_ARGS