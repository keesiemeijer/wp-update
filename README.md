# WP Update

A bash script to update WordPress core, plugins, themes and comments via SSH.

Features:

* All updates are displayed before updating
* Interactive prompts keeps you in control of what gets updated
* Database and file backups (plugins, themes) are created when updates are made
* Manage spam and trash comments
* Use a custom backup directory location

See [this screencast](https://github.com/keesiemeijer/wp-update/wiki/Screencast) to see it in action.

## requirements:

* [WP-CLI](http://wp-cli.org/) (1.3.0 or higher)

See the [WP-CLI installation instructions](http://wp-cli.org/#installing) if it's not installed . The command `wp` should be executable and in your PATH (e.g. /usr/local/bin/).

If you have permission issues or have trouble moving files in your PATH see [this answer](https://stackoverflow.com/a/14650235) on stackoverflow.

## Installation

1 log in your server via SSH and download the `wp-update.sh` file.

```bash
curl -o wp-update.sh https://raw.githubusercontent.com/keesiemeijer/wp-update/master/wp-update.sh
```

2 Make the `wp-update.sh` file executable.

```bash
chmod +x wp-update.sh
```

3 Move it in your PATH (e.g /usr/local/bin/) and rename it to `wp-update`.

```bash
mv wp-update.sh /usr/local/bin/wp-update
```
4 Run `wp-update --help` to see if the WP Update script was installed successfully, you should [see something like this](https://github.com/keesiemeijer/wp-update/wiki/Options)

## Usage

```
wp-update <path/to/website> [option...]
```

Use a relative or full path to the WP site you want to update.

See [all available options](https://github.com/keesiemeijer/wp-update/wiki/Options)

Without options everything is updated.
Example:

```
wp-update path/to/my/website
```

Example to update plugins and themes only:

```
wp-update path/to/my/website --plugins --themes
```

**Note**: After updating it's recommended you inspect your website.

## Backups

Backups are only created when something is updated. Newer backups replace previous backups as not to clutter your website. 

* The `plugins` and `themes` folder backups are made before updating plugins or themes.
* Database backups are created before and after updating.

**Note**: Test the database backups made by this script before you rely on this feature.

## Backup Directory

The backup directory ***should not be publicly accessible***. That's why backups are saved outside the website path you provide in `<path/to/website>`. In most cases this will fix the public access issue.

Before updating a backup directory called `wp-update-backups` is created if it doesn't exist yet. 

For example, if you've used this command:
```
wp-update domains/my-site
```
The backup directory is created at `domains/wp-update-backups`.

You can set a custom backup directory location for a site in the [config file](https://github.com/keesiemeijer/wp-update#config-file). Set it there if there are permission issues or if the location is still publicly accessible.

## Config file

If you add a `wp-update-config.txt` config file to the root of a site this script will import the custom config variables from it. For now there is only one variable you can set there

#### Variable BACKUP_PATH
Use this config variable to set a custom backup directory path. It's recommended this directory is not publicly accessible. This directory must exist on your server for the path to be used.

Example of the `wp-update-config.txt` config file.
```
BACKUP_PATH=/custom/path/to/backups
```