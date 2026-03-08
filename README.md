# dotfiles

## Installation

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

### Using Git and the bootstrap script

You can clone the repository wherever you want. The `.config/dotfiles/bin/install.sh` script will checkout the files to your `${HOME}` folder.

```sh
git clone https://<redacted>/dotfiles.git dotfiles/
cd dotfiles/
.config/dotfiles/bin/install.sh
```

### Using the bootstrap script url

```sh
  curl -fsSL https://raw.githubusercontent.com/leonrd/dotfiles/refs/heads/main/.config/dotfiles/bin/install.sh \
  | DOTFILES_REPO="https://github.com/leonrd/dotfiles.git" \
    sh
```

Or, if you want to install it in a different `${HOME}`:

```sh
  curl -fsSL https://raw.githubusercontent.com/leonrd/dotfiles/refs/heads/main/.config/dotfiles/bin/install.sh \
  | DOTFILES_REPO="https://github.com/leonrd/dotfiles.git" \
    DOTFILES_HOME_DIR="${HOME}" \
    sh
```

If there are any conflict with your current`${HOME}`files, it will do a `git stash` to them. Apply afterwards with `dotfiles stash apply` or `dotfiles stash pop`

## Updates

### Using the `dotfiles` alias loaded from `${HOME}/.config/shell/aliases`

```sh
dotfiles pull
```

### Using the install path

```sh
${HOME}/.config/dotfiles/bin/dotfiles pull
```

## Shell includes

### Specify the `${PATH}`

If `${HOME}/.path` exists, it will be sourced along with the other files, before any feature testing (such as detecting which version of `ls` is being used) takes place.

Here’s an example `${HOME}/.path` file:

```sh
export PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"
```

### Add custom commands without creating a new fork

If `${HOME}/.extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.

You could also use `${HOME}/.extra` to override settings, functions and aliases from the dotfiles repository. It’s probably better to fork this repository instead, though.

## Scripts

### Install packages

When setting up a new `${HOME}`, you may want to install/update/cleanup some common packages:

```sh
# On macos
~/.util/macos/pkg-install.sh
~/.util/macos/pkg-update.sh
~/.util/macos/pkg-cleanup.sh

# On Ubuntu
~/.util/ubuntu/pkg-install.sh
~/.util/ubuntu/pkg-update.sh
~/.util/ubuntu/pkg-cleanup.sh
```

### Sensible defaults

When setting up a new `${HOME}`, you may want to set some sensible defaults:

```sh
# On macos
~/.util/macos/settings.sh

# On Ubuntu
~/.util/ubuntu/settings.sh
```

### System cleanup

```sh
# On macos
~/.util/macos/cleanup.sh

# On Ubuntu
~/.util/ubuntu/cleanup.sh
```

## Thanks to…
* [Mathias Bynens](https://mathiasbynens.be/) and his [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
