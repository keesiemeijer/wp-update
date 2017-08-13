# WP Update

A bash script to update WordPress core, plugins, themes and comments via SSH.

Features:

* All updates are displayed before updating
* Interactive prompts keeps you in control of what gets updated
* Database and file backups (plugins, themes) are created when updates are made
* Manage spam and trash comments

requirements:

* [WP-CLI](http://wp-cli.org/)

If it's not installed already see the [installation instructions](http://wp-cli.org/#installing) for WP-CLI. The command `wp` should be executable and in your `PATH` (e.g. /usr/local/bin/). 

If you have permission issues or have trouble moving files in your `PATH` see [this answer](https://stackoverflow.com/a/14650235) on stackoverflow.

## Installation

1 Clone this repository.

```bash
git clone https://github.com/keesiemeijer/wp-update.git
```

2 Edit the `DOMAINS_PATH` variable in the `wp-update.sh` file and point it to a parent directory with WP sites in it.

```bash
readonly DOMAINS_PATH="$HOME/domains"
```

This variable needs to point to the parent dirictory of your WP site(s).
Example:

```
domains <- point it here 
  ├── wp-site1 (directory)
  │     └── WP files -> wp-admin, wp-content, wp-config.php etc.
  └── wp-site2 (directory)
        └── WP files
```

3 Upload the `wp-update.sh` file to your server and log in with SSH.

4 Go to where you uploaded it and make the `wp-update.sh` file executable.

```bash
chmod +x wp-update.sh
```

5 Move it in your `PATH` (e.g /usr/local/bin/) and rename it to `wp-update`.

```bash
mv wp-update.sh /usr/local/bin/wp-update
```
If the WP Update script was installed successfully, you should see something like this when you run `wp-update --help`

```
wp-update usage:
	wp-update <website-directory> [option...]

wp-update example:
	wp-update my-website --plugins

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
wp-update <site-directory> [option...]
```

Use `wp-update --help` to see what options are available

Without options the plugins and themes are updated by default.
Example:

```
wp-update <site-directory>
```

The same example, but with options used:

```
wp-update <site-directory> --plugins --themes
```

Example to update everything

```
wp-update <site-directory> --all
```

## Backups

Backups are only created when something is updated. Newer backups replace previous backups as not to clutter your website. The `plugins` and `themes` folder backups are made before updating plugins or themes. Database backups are created before and after updating. All backups are saved in the `wp-update-backups` directory in the root of the website.

**Note**: Test the database backups made by this script before you rely on this feature.