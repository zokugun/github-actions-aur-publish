#!/bin/bash

set -e

export HOME='/root'

cd /root

echo "Setting up ssh"
ssh-keyscan -v -t ed25519 aur.archlinux.org >> .ssh/known_hosts

echo -e "${INPUT_AUR_PRIVATE_KEY//_/\\n}" > .ssh/aur

chmod -vR 600 .ssh/aur*

ssh-keygen -vy -f .ssh/aur > .ssh/aur.pub

sha512sum .ssh/aur .ssh/aur.pub

echo "Setting up git"
git config --global user.name "${INPUT_AUR_USERNAME}"
git config --global user.email "${INPUT_AUR_EMAIL}"
git config --global --add safe.directory "/home/builder/${INPUT_PACKAGE_NAME}"

cd /home/builder

echo "Downloading package"
git clone "ssh://aur@aur.archlinux.org/${INPUT_PACKAGE_NAME}.git"
chown builder:builder "${INPUT_PACKAGE_NAME}" -R

cd "${INPUT_PACKAGE_NAME}"

if [[ -z "${INPUT_PACKAGE_VERSION}" ]]; then
    echo "Getting version"

    if [[ "${INPUT_PACKAGE_TYPE}" == "rolling" ]]; then
        cd /tmp

        git clone "https://github.com/${GITHUB_REPOSITORY}.git"

        cd "${GITHUB_REPOSITORY#*/}"

        INPUT_PACKAGE_VERSION=$( git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g' )

        cd "/home/builder/${INPUT_PACKAGE_NAME}"
    else
        INPUT_PACKAGE_VERSION=$( curl --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/latest" | jq -r .tag_name )
    fi
fi

PKGVER=$( cat "PKGBUILD" | sed -n "s/.*pkgver=\([0-9.+]*\).*/\1/p" )
PKGREL=$( cat "PKGBUILD" | sed -n "s/.*pkgrel=\([0-9]*\).*/\1/p" )
echo "Current pkgver: $PKGVER pkgrel: $PKGREL"

if [[ "${INPUT_PACKAGE_VERSION}" != "$PKGVER" ]]; then
    echo "Setting version: ${INPUT_PACKAGE_VERSION}"
    sed -i "s/pkgver=.*$/pkgver=${INPUT_PACKAGE_VERSION}/" PKGBUILD
    sed -i "s/pkgrel=.*$/pkgrel=1/" PKGBUILD
else
    echo "Same version"
fi

echo "Updating checksums"
su builder -c "updpkgsums"

echo "Detecting changes"
changes=$( git status > /dev/null 2>&1 && git diff-index --quiet HEAD && echo 'no' || echo 'yes' )
if [[ "$changes" == "yes" ]]; then
    if [[ "${INPUT_PACKAGE_VERSION}" == "$PKGVER" ]]; then
        echo "Setting release number: $(($PKGREL + 1))"
        sed -i "s/pkgrel=.*$/pkgrel="$(($PKGREL + 1))"/" PKGBUILD
    fi

    echo "Updating SRCINFO"
    su builder -c "makepkg --printsrcinfo > .SRCINFO"

    echo "Tracking files"
    git add -fv PKGBUILD .SRCINFO

    if [[ "${INPUT_SKIP_TEST}" != "yes" ]]; then
        echo "Installing dependencies"
        while IFS='= ' read -r KEY VALUE
        do
          if [[ "${KEY/[[:space:]]/}" == "makedepends" ]]; then
            su builder -c "yay --sync --needed --noconfirm --noprogressbar '${VALUE}'"
          fi
        done < .SRCINFO

        echo "Testing package"
        su builder -c "GITHUB_ENV='' makepkg --noconfirm --syncdeps --clean"
    else
        echo "Skipping testing"
    fi

    echo "Publishing new version"

    export package_name="${INPUT_PACKAGE_NAME}"
    export package_version="${INPUT_PACKAGE_VERSION}"

    message=$( echo "${INPUT_COMMIT_MESSAGE}" | envsubst )

    echo "message: $message"

    git commit -m "$message"
    git push
else
    echo "No changes"
fi
