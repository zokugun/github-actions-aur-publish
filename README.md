[AUR Releaser (GitHub Action)](https://github.com/zokugun/github-actions-aur-releaser)
======================================================================================

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/zokugun/github-actions-aur-releaser/blob/master/LICENSE)
[![current release](https://img.shields.io/github/release/zokugun/github-actions-aur-releaser.svg?colorB=green)](https://github.com/zokugun/github-actions-aur-releaser/releases)

With AUR Releaser, you can automatically publish new release of your AUR.

If the version isn't defined, it will get it for the GitHUb repository, even if it's a rolling AUR (`-git`).<br />
If an identical version has already been published, it will increment the release number.

Inputs
------

| Input             | Required | Description                                       | Default value                  | Possible values     |
| ----------------- | :------: | ------------------------------------------------- | ------------------------------ | ------------------- |
| `package_name`    |    ✅    | Name of the package to publish                    |                                |                     |
| `package_version` |    ❌    | Version of the package to publish                 |                                |                     |
| `package_type`    |    ❌    | Type of the package to publish                    | `stable`                       | `rolling`, `stable` |
| `commit_message`  |    ❌    | Message to use when commiting                     | `Update to ${package_version}` |                     |
| `aur_private_key` |    ✅    | SSH private key with write permissions to AUR Git |                                |                     |
| `aur_username`    |    ✅    | Username to configure the AUR Git with            |                                |                     |
| `aur_email`       |    ✅    | Email to configure the AUR Git with               |                                |                     |
| `skip_test`       |    ❌    | Flag if testing has to be skipped                 | `no`                           | `no`, `yes`         |

Usage
-----

```yaml
name: release

on:
  workflow_dispatch:
  push:
    tags:
      - "*"

jobs:
  aur:
    runs-on: ubuntu-latest

    steps:
      - name: Register local actions
        uses: actions/checkout@master

      - name: Publish mrcode-bin
        uses: zokugun/github-actions-aur-releaser@v1
        with:
          package_name: mrcode-bin
          aur_private_key: ${{ secrets.AUR_PRIVATE_KEY }}
          aur_username: ${{ secrets.AUR_USERNAME }}
          aur_email: ${{ secrets.AUR_EMAIL }}

      - name: Publish mrcode
        uses: zokugun/github-actions-aur-releaser@v1
        with:
          package_name: mrcode
          aur_private_key: ${{ secrets.AUR_PRIVATE_KEY }}
          aur_username: ${{ secrets.AUR_USERNAME }}
          aur_email: ${{ secrets.AUR_EMAIL }}

      - name: Publish mrcode-git
        uses: zokugun/github-actions-aur-releaser@v1
        with:
          package_name: mrcode-git
          package_type: rolling
          aur_private_key: ${{ secrets.AUR_PRIVATE_KEY }}
          aur_username: ${{ secrets.AUR_USERNAME }}
          aur_email: ${{ secrets.AUR_EMAIL }}

```
