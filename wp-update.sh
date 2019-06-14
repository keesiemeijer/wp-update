#!/usr/bin/env bash

# =============================================================================
# DESCRIPTION
# 
# A bash script to update WordPress core, plugins, themes and comments via SSH.
# 
# Author: keesiemeijer
# Github: https://github.com/keesiemeijer/wp-update
# 
# Features:
#     All updates are displayed before updating
#     Interactive prompts keeps you in control of what gets updated
#     Database and file backups (plugins, themes) are created when updates are made
#     Manage spam and trash comments
# 
# =============================================================================

# =============================================================================
# REQUIREMENTS
# 
#     WP-CLI
#     SSH access to the server.
#     
# The command `wp` should be executable and in your PATH (e.g. /usr/local/bin/).
# See the installation instructions for WP-CLI: http://wp-cli.org/#installing
# 
# If you have permission issues or have trouble moving files in your `PATH` 
# see https://stackoverflow.com/a/14650235
# =============================================================================

# =============================================================================
# INSTALLATION
# 
# 1 log in your server via SSH and download the `wp-update.sh` file.
# curl -o wp-update.sh https://raw.githubusercontent.com/keesiemeijer/wp-update/master/wp-update.sh
# 
# 2 Make the `wp-update.sh` file executable.
# chmod +x wp-update.sh
# 
# 3 Move it in your `PATH` (e.g /usr/local/bin/) and rename it to `wp-update`.
# mv wp-update.sh /usr/local/bin/wp-update
# 
# 4 Use "wp-update --help" to see if the this script was installed successfully.
# ============================================================================

# =============================================================================
# USAGE
# 
#     wp-update <path/to/website> [option...]
# 
# Relative or full path to a WordPress Site
# Use "wp-update --help" to see what options are available
# 
# Without options the option `--all` is used. Example:
# 
#     wp-update <path/to/website>
# 
# Example to update plugins and themes only:
#    
#    wp-update <path/to/website> --plugins --themes
# 
# **Note**: Check your website if your site was updated!
# =============================================================================

# =============================================================================
# BACKUPS
# 
# Backups are only created when something is updated.
# Newer backups replace previous backups as to not clutter your website.
# The `plugins` and `themes` folder backups are created before updating plugins or themes.
# Database backups are created before and after updating.
# The backup directory `wp-update-backups` is saved in the parent directory of the site directory
# 
# If you have permission issues you can set a custom backup directory in a config file.
# See the documentation
# 
# **Note**: The backup directory should not be publicly accessible. 
#           If it's publicly accessible you can  set a custom backup directory location in a config file.
#           See the documentation.
# 
# **Note**: Test the database backups made by this script before you rely on this feature.
# =============================================================================

set -e

# Functions

function is_file() {
	local file=$1
	[[ -f $file ]]
}

function is_dir() {
	local dir=$1
	[[ -d $dir ]]
}

function add_type_option(){
	local option=$1

	if ! [[ ${OPTIONS["$option"]} ]] ; then
		OPTIONS["$option"]=1
		ALLOPTIONS+=("$option")
	fi
}

function maybe_do_database_backup(){
	if [[ "$DATABASE_BACKUP" = true || "$DATABASE_BACKUP" = 'none' ]]; then
		return 0
	fi

	make_database_backup "before"
}

function make_database_backup(){
	local prefix=$1
	local db_name db_date db_file

	db_name=$(wp config get --constant=DB_NAME --path="$CURRENT_PATH" --allow-root)
	db_date=$(date +"%Y-%m-%d")
	db_file="wp-update-${prefix}-${db_date}.sql"

	for f in "$BACKUP_PATH/wp-update-${prefix}-"*.sql; do
		if is_file "$f"; then
			printf "Removing a previous database backup file...\n"
			rm "$f"
		fi
		break
	done

	printf "Creating a backup of the %s database %s updating...\n" "$db_name" "$prefix"
	wp db export "$db_file" --path="$CURRENT_PATH" --allow-root

	mv "$db_file" "$BACKUP_PATH/$db_file"

	if ! is_file "$BACKUP_PATH/$db_file"; then
		printf "Failed to create a database backup file in: %s\n%s\n" "$BACKUP_PATH" "$QUIT_MSG"
		exit 1
	fi

	if ! [[ -s "$BACKUP_PATH/$db_file" ]]; then
		printf "\Database backup file is empty in: %s\n%s\n" "$BACKUP_PATH" "$QUIT_MSG"
		exit 1
	fi

	DATABASE_BACKUP=true
}

function update_wp_core(){
	local update

	printf "Checking WordPress version...\n"
	update=$(wp core check-update --field=version --format=count --path="$CURRENT_PATH" --allow-root)

	if [[ -z $update ]]; then
		printf "WordPress is at the latest version\n"
		return 0
	fi

	printf "Newer WordPress version available.\n"
	if [[ "$USE_PROMPT" = true ]]; then
		read -p "Do you want to update WordPress [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped updating WordPress core\n"
			return 0
		fi
	fi

	maybe_do_database_backup

	printf "Updating WordPress\n"
	wp core update --allow-root

	UPDATE_TRANSLATIONS=true
}

function update_language(){
	local update

	printf "Checking translations...\n"
	update=$(wp core language list --update=available --format=csv --field=language --path="$CURRENT_PATH" --allow-root)

	if [[ -z $update ]]; then
		printf "No language updates available\n"
		return 0
	fi

	printf "New translations available.\n"
	if [[ "$USE_PROMPT" = true ]]; then
		wp core language list --update=available --path="$CURRENT_PATH" --allow-root
		read -p "Do you want to update translations? [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped updating translations\n"
			return 0
		fi
	fi

	maybe_do_database_backup

	printf "Updating translations\n"
	wp core language update --path="$CURRENT_PATH" --allow-root
}

function update_asset(){
	local asset_type=$1
	local asset_path update
	
	asset_path=$(wp "$asset_type" path --path="$CURRENT_PATH" --allow-root)

	printf "Checking %s updates...\n" "$asset_type"
	update=$(wp "$asset_type" list --update=available --number=1 --format=count --path="$CURRENT_PATH" --allow-root)

	if [[ $update = 0 ]]; then
		printf "No %s updates available\n" "$asset_type"
		return 0
	fi

	printf "Updating %ss\n" "$asset_type"

	if [[ "$USE_PROMPT" = true ]]; then
		wp "$asset_type" update --all --dry-run --path="$CURRENT_PATH" --allow-root

		read -p "Do you want to update all ${asset_type}s [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped updating %ss\n" "$asset_type"
			return 0
		fi
	fi

	printf "backing up %ss\n" "$asset_type"
	if is_dir "$BACKUP_PATH/${asset_type}s-backup"; then
		rm -rf "$BACKUP_PATH/${asset_type}s-backup"
	fi

	if is_dir "$asset_path"; then
		cp -r "$asset_path" "$BACKUP_PATH/${asset_type}s-backup"
	else
		printf "Could not find %ss path: %s\n%s\n" "$asset_type" "$asset_path" "$QUIT_MSG"
		exit 1
	fi

	maybe_do_database_backup

	printf "Updating %ss\n" "$asset_type"
	wp "$asset_type" update --all --path="$CURRENT_PATH" --allow-root

	UPDATE_TRANSLATIONS=true
}

function delete_asset_backups() {
	printf "Deleting backed up plugins and themes...\n"

	if [[ "$USE_PROMPT" = true ]]; then
		read -p "Do you want to delete backups of plugins and themes [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped deleting backups\n"
			return 0
		fi
	fi

	if is_dir "$BACKUP_PATH/plugins-backup"; then
		printf "Deleting plugin backups...\n"
		rm -rf "$BACKUP_PATH/plugins-backup"
	else
		printf "No backed up plugins found to delete\n"
	fi

	if is_dir "$BACKUP_PATH/themes-backup"; then
		printf "Deleting theme backups...\n"
		rm -rf is_dir "$BACKUP_PATH/themes-backup"
	else
		printf "No backed up themes found to delete\n"
	fi
}

function update_comments() {
	local status=$1

	printf "Checking %s comments...\n" "$status"

	count=$(wp comment list --number=1 --status="$status" --format=count --path="$CURRENT_PATH" --allow-root)
	if [[ $count = 0 ]]; then
		printf "No %s comments found\n" "$status"
		return 0
	fi

	if [[ "$USE_PROMPT" = true ]]; then
		wp comment list --status="$status" --fields=ID,comment_author,comment_author_email,comment_approved,comment_content --path="$CURRENT_PATH" --allow-root
		read -p "Do you want to delete all ${status} comments [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped deleting %s comments\n" "$status"
			return 0
		fi
	fi

	maybe_do_database_backup

	printf "Deleting %s comments\n" "$status"
	wp comment delete "$(wp comment list --status="$status" --format=ids --path="$CURRENT_PATH" --allow-root)" --path="$CURRENT_PATH" --allow-root
}

# =============================================================================
# Variables
# =============================================================================

# Does a database backup already exist.
DATABASE_BACKUP=false

# Do translations need updating (after updating core, plugins or themes).
UPDATE_TRANSLATIONS=false

# Use a prompt before updating plugins, themes and comments.
USE_PROMPT=true

# Associative array to check CLI option
declare -A OPTIONS

# All unique CLI argument options in the right order
ALLOPTIONS=()

# Command arguments found
ARGUMENT_COUNT=0

QUIT_MSG="Stopping updates..."

# =============================================================================
# Options
# =============================================================================

for arg in "$@"
do
	if ! [[ "$arg" =~ ^- ]]; then
		# Doesn't start with a dash.
		ARGUMENT_COUNT=$((ARGUMENT_COUNT + 1))
		if [[ "$ARGUMENT_COUNT" = 1 ]]; then
			readonly SITE_PATH=$arg;
		fi
	else
		case "$arg" in
			-h|--help)
				printf "\nwp-update usage:\n"
				printf "\twp-update <path/to/website> [option...]\n\n"
				printf "wp-update example:\n"
				printf "\twp-update domains/my-website --plugins\n\n"
				printf "Options controlling update type:\n"
				printf -- "\t-w, --core           Update WordPress core\n"
				printf -- "\t-p, --plugins        Update plugins\n"
				printf -- "\t-t, --themes         Update themes\n"
				printf -- "\t-l, --translations   Update translations\n"
				printf -- "\t-c, --comments       Update comments\n"
				printf -- "\t-a, --all            Update everything\n\n"
				printf "\tIf you don't provide an update type option the --all option is used\n\n"
				printf "Options extra:\n"
				printf -- "\t-h, --help           Show help\n"
				printf -- "\t-f, --force          Force update without confirmation prompts\n"
				printf -- "\t-x, --no-db-backup   Don't make a database backup before and after updating\n"
				printf -- "\t-d, --delete-backups Delete theme and plugin backups\n\n"
				exit 0
				;;
			-f|--force) USE_PROMPT=false ;;
			-x|--no-db-backup) DATABASE_BACKUP='none' ;;
			-d|--delete-backups) add_type_option "delete_backups" ;;
			-w|--core) add_type_option "core" ;;
			-p|--plugins) add_type_option "plugins" ;;
			-t|--themes) add_type_option "themes";;
			-l|--translations) add_type_option "translations" ;;
			-c|--comments) add_type_option "comments";;
			-a|--all) add_type_option "all" ;;
			 *)
				printf "Unknown option: %s.\nUse \"wp-update --help\" to see all options\n%s\n" "$arg" "$QUIT_MSG"
				exit 1
				;;
		esac
	fi
done

# Check if no options were used or if option `all` is used.
if [[ ${#ALLOPTIONS[@]} -eq 0 || ${OPTIONS["all"]} ]]; then
	ALLOPTIONS=("all")
	OPTIONS["all"]=1
	UPDATE_TRANSLATIONS=true
fi

# =============================================================================
# Start updates
# =============================================================================

if [[ $ARGUMENT_COUNT -lt 1 || -z "$SITE_PATH" ]]; then
	printf "\nUsage: %s <path/to/website> [option...]\n" "$0"
	printf "Example: wp-update domains/my-website --plugins\n\n"
	printf "Use \"wp-update --help\" to see all options\n"
	exit 1
fi

if ! is_dir "$SITE_PATH"; then
	printf "Invalid Website directory: %s\n%s\n" "$SITE_PATH" "$QUIT_MSG"
	exit 1
fi

# Go to the website directory.
cd "$SITE_PATH" || exit

# Set the website directory to a full path.
readonly CURRENT_PATH=$(pwd)

# Current directory name
readonly CURRENT_DIR="${PWD##*/}"

if [[ -z "$CURRENT_DIR" ]]; then
	printf "Current directory not found\n"
	exit 1
fi

# Check if WordPress is installed.
if ! wp core is-installed --path="$CURRENT_PATH" --allow-root 2> /dev/null; then
	printf "No WordPress website found in: %s\n%s\n" "$CURRENT_PATH" "$QUIT_MSG"
	exit 1
fi

readonly ENV_BACKUP_PATH="WP_UPDATE_BACKUP_PATH_$CURRENT_DIR";

# Check if the backup path enviroment variable was set.
if [[ -z "${!ENV_BACKUP_PATH}" ]]; then
	# Not set, use parent directory as a backup path 
	readonly PARENT_PATH="$(dirname "$CURRENT_PATH")"

	if ! is_dir "$PARENT_PATH"; then
		printf "Parent directory doesn't exist: %s\n%s\n" "$PARENT_PATH" "$QUIT_MSG"
		exit 1
	fi

	readonly BACKUP_PATH="${PARENT_PATH%/}/wp-update-backups/$CURRENT_DIR"
	if ! is_dir "$BACKUP_PATH"; then
		printf "Creating backup path: %s\n" "$BACKUP_PATH"
		mkdir -p "$BACKUP_PATH"	|| exit
	else
		printf "Backup path: %s\n" "$BACKUP_PATH"
	fi
	
else
	# Backup path enviroment variable is set.
	readonly BACKUP_PATH="${!ENV_BACKUP_PATH}"
	printf "Backup path (from environment variable): %s\n" "$BACKUP_PATH"
fi

# Check if backup path exists.
if ! is_dir "$BACKUP_PATH"; then
	printf "Backup directory %s does not exist\n%s\n" "$BACKUP_PATH" "$QUIT_MSG"
	exit 1
fi

if ! [[ -w "$BACKUP_PATH" ]]; then
	printf "Cannot write to backup directory %s\n%s\n" "$BACKUP_PATH" "$QUIT_MSG"
	exit 1
fi

# Update everything except translations.
for type in "${ALLOPTIONS[@]}"
do  
	case "$type" in
			plugins)
				update_asset "plugin"
				;;
			themes)
				update_asset "theme"
				;;
			core)
				update_wp_core
				;;
			comments)
				update_comments "spam"
				update_comments "trash"
				;;
			all)
				update_asset "plugin"
				update_asset "theme"
				update_wp_core
				update_comments "spam"
				update_comments "trash"
				;;
			delete_backups)
				delete_asset_backups
				;;
			*)
				if ! [[ 'translations' = "$type" ]]; then
					printf "Unknown option: %s. Use \"wp-update --help\" to see all options\n" "$type"
					exit 1
				fi
	esac
done

# Translations are updated at the end (if needed)
if [[ "$UPDATE_TRANSLATIONS" = true ]]; then
	update_language
else
	if [[ ${OPTIONS["translations"]} ]]; then
		update_language
	fi
fi

# Create database after updates
if [[ "$DATABASE_BACKUP" = true ]]; then
	make_database_backup "after"
fi

printf "Finished updating\n"