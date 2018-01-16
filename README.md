# WP Update

A bash script to update WordPress core, plugins, themes and comments via SSH.

See [this screencast](https://github.com/keesiemeijer/wp-update/wiki/Screencast) to see it in action.

Features:

* All updates are displayed before updating
* Interactive confirmation prompts keep you in control of what gets updated
* Database and file backups (plugins, themes) are created when updates are made
* Manage spam and trash comments
* WP-CLI does all the heavy lifting in the background
* Use a custom backup directory location for every site (or for all sites)

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
4 Run `wp-update --help` to see if the WP Update script was installed successfully. You should [see something like this](https://github.com/keesiemeijer/wp-update/wiki/Options)

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

You can set a [custom backup path](https://github.com/keesiemeijer/wp-update#custom-backup-path) for each site if there are permission issues or if the location is still publicly accessible.

## Custom backup path

Add custom backup paths with environment variables in your `.bashrc` or `.bash_profile` file.

Let's say you have a site directory `my-awesome-site`. Set the custom backup path for this site like this in your `.bash_profile` file.

```bash
export WP_UPDATE_BACKUP_PATH_my-awesome-site=/custom/path/to/backups/my-awesome-site
```

As you can see the environment variable consists of `WP_UPDATE_BACKUP_PATH_` and the site directory `my-awesome-site`. The custom path that will be used for this site is now `/custom/path/to/backups/my-awesome-site`. It's recommended this directory is not publicly accessible. This directory must exist on your server for the path to be used.

After adding the custom backup path you'll need to quit the terminal and log back in to your server via SSH before the environment variable is used. 