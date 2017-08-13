#!/usr/bin/env bash

# =============================================================================
# DESCRIPTION
# 
# A bash script to update WordPress core, plugins, themes and comments via SSH.
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
# Install WP-CLI if not installed. The command `wp` should be 
# executable and in your PATH (e.g. /usr/local/bin/).
# See the installation instructions for WP-CLI: http://wp-cli.org/#installing
# 
# If you have permission issues or have trouble moving files in your `PATH` 
# see https://stackoverflow.com/a/14650235
# =============================================================================

# =============================================================================
# INSTALLATION
# 
# 1 Clone this repository
# git clone https://github.com/keesiemeijer/wp-update.git
# 
# 2 Edit and point the DOMAINS_PATH variable (below this section) to a 
#   parent directory with WP sites in it.  
#   Example:
#       domains <- point it here 
#         ├── wp-site1 (directory)
#         │     └── WP files
#         └── wp-site2 (directory)
#               └── WP files
# 
# 3 Upload this file to your server and log in with ssh.
# 
# 4 Go to where you uploaded it and make this file executable
# chmod +x wp-update.sh
# 
# 5 Move it in your `PATH` (e.g /usr/local/bin/) and rename it to `wp-update`.
# mv wp-update.sh /usr/local/bin/wp-update
# 
# Now you can use the `wp-update` command to update your sites.
# test it out by using "wp-update --help"
# ============================================================================

# Edit this variable to point to a directory with WordPress directories in it (see above)

readonly DOMAINS_PATH="$HOME/domains"


# =============================================================================
# USAGE
# 
#     wp-update <site-directory> [option...]
# 
# Use the site directory name for a WordPress site 
# Use "wp-update --help" to see what options are available
# 
# Without options the plugins and themes are updated. Example:
# 
#     wp-update <site-directory>
# 
# The same example, but with options used:
#    
#    wp-update <site-directory> --plugins --themes
# 
# Example to update everything
# 
#     wp-update <site-directory> --all
# 
# =============================================================================

# =============================================================================
# BACKUPS
# 
# Backups are only created when something is updated.
# 
# Database backups are created before and after updating.
# They are saved in the root directory of your website.
# Test the backups that are made by this script before you rely on this feature.
# 
# Plugin and theme folder backups are made before updating plugins or themes.
# They are saved in the wp-content folder of your website
# 
# Newer backups replace previous backups as not to clutter your website.
# =============================================================================



# Start of WP Update script

if [ $# -lt 1 ]; then
		printf "\nUsage: %s <website-directory> [option...]\n" "$0"
		printf "Example: wp-update my-website --plugins\n\n"
		printf "Use \"wp-update --help\" to see all options\n"
		exit 1
fi

# =============================================================================
# Variables
# =============================================================================

# Website directory
readonly WEBSITE=$1

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

# =============================================================================
# Functions
# =============================================================================
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
		return 1
	fi

	if ! make_database_backup "before"; then
		printf "Creating a database backup before updating failed"
		exit 1
	fi

	return 0
}

function make_database_backup(){
	local prefix=$1

	if is_file "$BACKUP_PATH/${prefix}_update_${WEBSITE}.sql"; then
		printf "Removing a previous database backup file...\n"
		rm "$BACKUP_PATH/${prefix}_update_${WEBSITE}.sql"
	fi

	printf "Creating a backup of the %s database ${prefix} updating...\n" "$WEBSITE"
	wp db export "${prefix}_update_${WEBSITE}.sql" --path="$SITE_PATH" --allow-root

	mv "${prefix}_update_${WEBSITE}.sql" "$BACKUP_PATH/${prefix}_update_${WEBSITE}.sql"

	if ! is_file "$BACKUP_PATH/${prefix}_update_${WEBSITE}.sql"; then
		printf "\e[31mWarning: No database backup file found in: %s\033[0m\n" "$BACKUP_PATH"
		return 1
	fi

	if ! [[ -s "$BACKUP_PATH/${prefix}_update_${WEBSITE}.sql" ]]; then
		printf "\e[31mWarning: database backup file is empty in: %s\033[0m\n" "$BACKUP_PATH"
		return 1
	fi

	DATABASE_BACKUP=true

	return 0
}

function wp_core_is_installed(){
	# Check for wp-config.php file
	if ! is_file "$SITE_PATH/wp-config.php"; then
		return 1
	fi

	# Check if WP tables exist
	wp core is-installed --path="$SITE_PATH" --allow-root 2> /dev/null
}

function update_wp_core(){
	printf "Checking WordPress version...\n"
	update=$(wp core check-update --field=version --format=count --path="$SITE_PATH" --allow-root)
	if [[ -z $update ]]; then
		printf "WordPress is at the latest version\n"
		return 0
	fi

	printf "Newer WordPress version available.\n"
	if [[ "$USE_PROMPT" = true ]]; then
		read -p "Do you want to update WordPress [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped updating WordPress core\n"
			return 1
		fi
	fi

	maybe_do_database_backup

	printf "Updating WordPress\n"
	wp core update --allow-root

	UPDATE_TRANSLATIONS=true
}

function update_language(){
	printf "Checking translations...\n"

	update=$(wp core language list --update=available --format=count --path="$SITE_PATH" --allow-root)
	if [[ $update = 0 ]]; then
		printf "No language updates available\n"
		return 0
	fi

	printf "New translations available.\n"
	if [[ "$USE_PROMPT" = true ]]; then
		wp core language list --update=available --path="$SITE_PATH" --allow-root
		read -p "Do you want to update translations? [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped updating translations\n"
			return 1
		fi
	fi

	maybe_do_database_backup

	printf "Updating translations\n"
	wp core language update --path="$SITE_PATH" --allow-root
}

function update_asset(){
	local asset_type=$1
	local asset_path=$(wp "$asset_type" path --path="$SITE_PATH" --allow-root)
	local update

	printf "Checking %s updates...\n" "$asset_type"
	update=$(wp "$asset_type" list --update=available --number=1 --format=count --path="$SITE_PATH" --allow-root)
	if [[ $update = 0 ]]; then
		printf "No %s updates available\n" "$asset_type"
		return 0
	fi

	printf "Updating %ss\n" "$asset_type"

	if [[ "$USE_PROMPT" = true ]]; then
		wp "$asset_type" update --all --dry-run --path="$SITE_PATH" --allow-root

		read -p "Do you want to update all ${asset_type}s [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped updating %ss\n" "$asset_type"
			return 1
		fi
	fi

	printf "backing up %ss\n" "$asset_type"
	if is_dir "$BACKUP_PATH/${asset_type}s-backup"; then
		rm -rf "$BACKUP_PATH/${asset_type}s-backup"
	fi

	if is_dir "$asset_path"; then
		cp -r "$asset_path" "$BACKUP_PATH/${asset_type}s-backup"
	else
		printf "Could not find %ss path\n" "$asset_type"
		return 1
	fi

	maybe_do_database_backup

	printf "Updating %ss\n" "$asset_type"
	wp "$asset_type" update --all --path="$SITE_PATH" --allow-root
	UPDATE_TRANSLATIONS=true

	return 0
}

function update_comments() {
	local status=$1

	printf "Checking %s comments...\n" "$status"

	count=$(wp comment list --number=1 --status="$status" --format=count --path="$SITE_PATH" --allow-root)
	if [[ $count = 0 ]]; then
		printf "No %s comments found\n" "$status"
		return 0
	fi

	if [[ "$USE_PROMPT" = true ]]; then
		wp comment list --status="$status" --fields=ID,comment_author,comment_author_email,comment_approved,comment_content --path="$SITE_PATH" --allow-root
		read -p "Do you want to delete all ${status} comments [y/n]" -r
		if ! [[ $REPLY = "Y" ||  $REPLY = "y" ]]; then
			printf "Stopped deleting %s comments\n" "$status"
			return 1
		fi
	fi

	maybe_do_database_backup

	printf "Deleting %s comments\n" "$status"
	wp comment delete $(wp comment list --status="$status" --format=ids --path="$SITE_PATH" --allow-root) --path="$SITE_PATH" --allow-root
	
	return 0
}

# =============================================================================
# Options
# =============================================================================

while test $# -gt 0; do
	
	if ! [[ "$1" =~ ^- ]]; then
		# Not starting with a dash (not an option).
		shift
	else
		case "$1" in
			-h|--help)
				printf "\nwp-update usage:\n"
				printf "\twp-update <website-directory> [option...]\n\n"
				printf "wp-update example:\n"
				printf "\twp-update my-website --plugins\n\n"
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
				printf -- "\t-x, --no-db-backup   Don't make a database backup before and after updating\n\n"
				exit 0
				;;
			-f|--force) USE_PROMPT=false ;;
			-x|--no-db-backup) DATABASE_BACKUP='none' ;;
			-w|--core) add_type_option "core" ;;
			-p|--plugins) add_type_option "plugins" ;;
			-t|--themes) add_type_option "themes";;
			-l|--translations) add_type_option "translations" ;;
			-c|--comments) add_type_option "comments";;
			-a|--all) add_type_option "all" ;;
			 *)
				printf "Unknown option: %s. Use \"wp-update --help\" to see all options\n" "$1"
				exit 1
				;;
		esac
		shift
	fi
done

# Check if options is empty or if option `all` is used 
if [[ ${#ALLOPTIONS[@]} -eq 0 || ${OPTIONS["all"]} ]]; then
	ALLOPTIONS=("all")
	UPDATE_TRANSLATIONS=true
fi
 
# =============================================================================
# Start updates
# =============================================================================

if [ -z "$DOMAINS_PATH" ]; then
	printf "Please provide a valid domains directory path in the wp-update.sh file\n"
	exit 1
fi

readonly SITE_PATH="$DOMAINS_PATH/$WEBSITE"

if ! is_dir "$SITE_PATH"; then
	printf "Could not find Website directory: %s\n" "$WEBSITE"
	exit 1
fi

cd "$SITE_PATH" || exit

readonly BACKUP_PATH="$SITE_PATH/wp-update-backups"
mkdir -p "$BACKUP_PATH"

if ! is_dir "$BACKUP_PATH"; then
	printf "Backup directory %s not found...\n" "$BACKUP_PATH"
	exit 1
fi

if ! is_file "$BACKUP_PATH/index.php"; then
	echo -e "<?php\n// Silence is golden." > "$BACKUP_PATH/index.php"
fi

if ! wp_core_is_installed; then
	printf "No WordPress website found in: %s\n" "$SITE_PATH"
	exit 1
fi

# Check network connection for options that need it.
if [[ ${OPTIONS["all"]} || ${OPTIONS[plugins]} || ${OPTIONS["themes"]} || ${OPTIONS["core"]} ||  ${OPTIONS["translations"]} ]]; then
	printf "Checking network connection...\n"
	if ! ping -c 3 -W 5 8.8.8.8 >> /dev/null 2>&1; then
		# Bail if there is no internet connection
		printf "No network connection detected\n\n"
		exit 1
	else
		printf "Network connection detected\n"
	fi
fi

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

if [[ "$DATABASE_BACKUP" = true ]]; then
	if ! make_database_backup "after"; then
		printf "Creating a database backup after updating failed"
		exit 1
	fi
fi

printf "Finished updating\n"