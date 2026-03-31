#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

CR_USERNAME="${1:-jcshins}"

# Get package name from pyproject.toml
PKG_NAME=$(awk '
/^\[project\]/ { in_section=1; next }
/^\[/ { in_section=0 }
in_section && /^name/ {
    gsub(/"/, "", $3)
    print $3
    exit
}
' pyproject.toml)

# Get version from pyproject.toml
VERSION=$(awk '
/^\[project\]/ { in_section=1; next }
/^\[/ { in_section=0 }
in_section && /^version/ {
    gsub(/"/, "", $3)
    print $3
    exit
}
' pyproject.toml)

# Get system architecture
case "$(uname -m)" in
  x86_64) ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

# Build & push image for current architecture
docker buildx build \
  --platform "linux/${ARCH}" \
  -t "$CR_USERNAME/$PKG_NAME:$VERSION-${ARCH}" \
  --push .

# Find existing digest for the other architecture
OTHER_ARCH=$( [ "$ARCH" = "amd64" ] && echo "arm64" || echo "amd64" )
if ! command -v jq
then
  sudo apt update && sudo apt install -y jq
fi
OTHER_DIGEST="$(docker buildx imagetools inspect --raw "$CR_USERNAME/$PKG_NAME:$VERSION" \
  | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="'"$OTHER_ARCH"'") | .digest')"

if [[ -n "$OTHER_DIGEST" ]]; then
  # Create multi-arch manifest
  docker buildx imagetools create \
    -t "$CR_USERNAME/$PKG_NAME:$VERSION" \
    "$CR_USERNAME/$PKG_NAME@${OTHER_DIGEST}" \
    "$CR_USERNAME/$PKG_NAME:$VERSION-${ARCH}"
else
  # If no existing image for the other arch, just tag current image as latest
  docker tag "$CR_USERNAME/$PKG_NAME:$VERSION-${ARCH}" "$CR_USERNAME/$PKG_NAME:$VERSION"
  docker push "$CR_USERNAME/$PKG_NAME:$VERSION"
fi

# Update local image
docker pull "$CR_USERNAME/$PKG_NAME:$VERSION"
EOF
