# WP Update

A bash script to update WordPress core, plugins, themes and comments via SSH.

Features:

* All updates are displayed before updating
* Interactive prompts keeps you in control of what gets updated
* Database and file backups (plugins, themes) are created when updates are made
* Manage spam and trash comments
* Set a custom backup directory in a config file

## requirements:

* [WP-CLI](http://wp-cli.org/) (1.3.0 or higher)

If it's not installed see the [WP-CLI installation instructions](http://wp-cli.org/#installing). The command `wp` should be executable and in your `PATH` (e.g. /usr/local/bin/).

If you have permission issues or have trouble moving files in your `PATH` see [this answer](https://stackoverflow.com/a/14650235) on stackoverflow.

## Installation

1 log in your server via SSH and download the `wp-update.sh` file.

```bash
curl -o wp-update.sh https://raw.githubusercontent.com/keesiemeijer/wp-update/master/wp-update.sh
```

2 Make the `wp-update.sh` file executable.

```bash
chmod +x wp-update.sh
```

3 Move it in your `PATH` (e.g /usr/local/bin/) and rename it to `wp-update`.

```bash
mv wp-update.sh /usr/local/bin/wp-update
```
4 If the WP Update script was installed successfully, you should see something like this when you run `wp-update --help`

```
wp-update usage:
	wp-update <path/to/website> [option...]

wp-update example:
	wp-update domains/my-website --plugins

Options controlling update type:
	-w, --core           Update WordPress core
	-p, --plugins        Update plugins
	-t, --themes         Update themes
	-l, --translations   Update translations
	-c, --comments       Update comments
	-a, --all            Update everything

	If you don't provide an update type option the --all option is used

Options extra:
	-h, --help           Show help
	-f, --force          Force update without confirmation prompts
	-x, --no-db-backup   Don't make a database backup before and after updating
```

## Usage

```
wp-update <path/to/website> [option...]
```

Use `wp-update --help` to see what options are available. (see above)

Without options the plugins and themes are updated by default.
Example:

```
wp-update <path/to/website>
```

The same example, but with options used:

```
wp-update <path/to/website> --plugins --themes
```

Example to update everything

```
wp-update <path/to/website> --all
```

## Backups

Backups are only created when something is updated. Newer backups replace previous backups as not to clutter your website. The `plugins` and `themes` folder backups are made before updating plugins or themes. Database backups are created before and after updating.

**Note**: Test the database backups made by this script before you rely on this feature.
## Backup Directory

The backup directory should not be publicly accessible. That's why backups are saved outside the website path you used in `<path/to/website>`. The backup directory `wp-update-backups` is saved in the parent directory of the website path used.

For example, if you used this command `wp-update /domains/my-site/src --plugins`.
The backup directory is created at `/domains/my-site/wp-update-backups`.

In most cases the directory will not be publicly accessible anymore. However, if it's still publicly accessible you can password protect it in your `htaccess` or use a custom backups directory path in the config file.

## Config file
This script reads the `wp-update-config.txt` file in the root of your site if it exists. Here you can set custom variables used by this script

### BACKUP_PATH
Use this variable in the `wp-update-config.txt` to set a custom backup directory path. It's recommended this directory is not publicly accessible. This directory must exist on your server for the path to be used.

example `wp-update-config.txt` config file
```
BACKUP_PATH=/app/backups
```