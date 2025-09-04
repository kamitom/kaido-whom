#!/bin/sh

echo "Starting Hugo in watch mode..."
echo "BaseURL: $HUGO_BASEURL"

# Initial build
hugo --minify --destination=/target --baseURL="$HUGO_BASEURL"

# Watch for changes
echo "Watching for changes..."
while inotifywait -r -e modify,create,delete,move /src/content /src/layouts /src/static /src/config.yaml 2>/dev/null; do
    echo "Change detected, rebuilding..."
    hugo --minify --destination=/target --baseURL="$HUGO_BASEURL"
    echo "Rebuild complete"
done