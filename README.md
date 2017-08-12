# WP Update

A bash script to update WordPress core, plugins, themes and comments via SSH.

Features:

* All updates are displayed before updating
* Interactive prompts keeps you in control of what gets updated
* Database and file backups (plugins, themes) are created when updates are made
* Manage spam and trash comments

requirements:

* [WP-CLI](http://wp-cli.org/)

Install WP-CLI if not installed. The command `wp` should be executable and in your PATH (e.g. /usr/local/bin/). See the [installation instructions](http://wp-cli.org/#installing) for WP-CLI.

If you have permission issues or have trouble moving files in your PATH see [this answer](https://stackoverflow.com/a/14650235) on stackoverflow

## Installation

1 Clone this repository.

```bash
git clone https://github.com/keesiemeijer/wp-update.git
```

2 Edit the `DOMAINS_PATH` variable in the wp-update file and point it to a parent directory with WP sites in it.

```bash
readonly DOMAINS_PATH="$HOME/domains"
```

This variable points to the (parent) dirictory of your WP site(s).
Example:

```
domains <- point it here 
  ├── wp-site1 (directory)
  │     └── WP files -> wp-admin, wp-content, wp-config.php etc.
  └── wp-site2 (directory)
        └── WP files
```

3 Upload this file to your server and log in with SSH.

4 Go to where you uploaded it and make the wp-update file executable.

```bash
chmod +x wp-update
```

5 Move it in your PATH (e.g /usr/local/bin/). 

```bash
mv wp-update /usr/local/bin/wp-update
```

Now you can use the `wp-update` command to update your sites. Check it out by using `wp-update --help`

## Usage

```bash
wp-update <site-directory> [option...]
```

Use `wp-update --help` to see what options are available

Without options the plugins and themes are updated by default. Example:

```bash
wp-update <site-directory>
```

The same example, but with options used:

```bash 
wp-update <site-directory> --plugins --themes
```

Example to update everything

```bash
wp-update <site-directory> --all
```

##Backups

Backups are only created when something is updated. Newer backups replace previous backups as not to clutter your website.

Database backups are created before and after updating. They are saved in the root directory of your website.

**Note** Test the database backups made by this script before you rely on this feature.

Plugin and theme folder backups are made before updating plugins or themes. They are saved in the `wp-content` folder of your website as `themes-backup` and `plugins-backup`

