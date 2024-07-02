#!/usr/bin/bash

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to generate random passwords
generate_password() {
    local password_length=12
    tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges" >&2
    log "Script not run as root or with sudo privileges"
    exit 1
fi

# File paths
USER_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Check if a file name is provided as an argument
if [ -z "$USER_FILE" ]; then
    echo "Usage: $0 <name-of-text-file>"
    log "No user file provided. Usage: $0 <name-of-text-file>"
    exit 1
fi

# Check if the input file exists
if [ ! -f "$USER_FILE" ]; then
    echo "Input file not found"
    log "Input file '$USER_FILE' not found"
    exit 1
fi

# Create the log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 0600 "$LOG_FILE"
    log "Log file created: $LOG_FILE"
fi

# Create the password file if it doesn't exist
if [ ! -f "$PASSWORD_FILE" ]; then
    mkdir -p /var/secure
    touch "$PASSWORD_FILE"
    chmod 0600 "$PASSWORD_FILE"
    log "Password file created: $PASSWORD_FILE"
fi

# Flags to track various failures
users_created=false
user_creation_failed=false
password_setting_failed=false
group_creation_failed=false
home_directory_setup_failed=false
all_users_exist=true
any_users_created=false

# Validate username and groups
validate_username() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi
    return 0
}

validate_groups() {
    IFS=',' read -ra group_list <<< "$1"
    for group in "${group_list[@]}"; do
        if [[ ! "$group" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            return 1
        fi
    done
    return 0
}

# Read the user file line by line
while IFS=';' read -r username groups; do
    # Trim whitespace from username and groups
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if the username and groups are not empty and valid
    if [ -z "$username" ] || [ -z "$groups" ]; then
        log "Invalid line format in user file: '$username;$groups'"
        user_creation_failed=true
        continue
    fi

    if ! validate_username "$username"; then
        log "Invalid username format: '$username'"
        user_creation_failed=true
        continue
    fi

    if ! validate_groups "$groups"; then
        log "Invalid group format: '$groups'"
        group_creation_failed=true
        continue
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        log "User $username already exists."
        continue
    fi

    # User does not exist, so there's work to be done
    all_users_exist=false

    # Create personal group for the user
    if ! getent group "$username" > /dev/null; then
        if groupadd "$username"; then
            log "Group $username created."
        else
            log "Failed to create group $username."
            group_creation_failed=true
            continue
        fi
    fi

    # Create groups if they don't exist
    IFS=',' read -ra group_list <<< "$groups"
    for group in "${group_list[@]}"; do
        if ! getent group "$group" > /dev/null; then
            if groupadd "$group"; then
                log "Group $group created."
            else
                log "Failed to create group $group."
                group_creation_failed=true
            fi
        fi
    done
    unset IFS

    # Create the user and add to the groups
    if useradd -m -g "$username" -G "$groups" "$username"; then
        log "User $username created and added to groups $groups"
        users_created=true
        any_users_created=true
    else
        log "Failed to create user $username"
        user_creation_failed=true
        continue
    fi

    # Generate a random password
    password=$(generate_password)
    log "Generated password for $username"

    # Set the user's password
    if echo "$username:$password" | chpasswd; then
        # Store the password securely in TXT format    
        echo "$username,$password" >> "$PASSWORD_FILE"
        log "Password set for $username and stored securely"
    else
        log "Failed to set password for $username"
        password_setting_failed=true
        continue
    fi

    # Set appropriate permissions and ownership
    if chown "$username:$username" "/home/$username" && chmod 700 "/home/$username"; then
        log "Home directory for $username set up with appropriate permissions."
    else
        log "Failed to set up home directory for $username"
        home_directory_setup_failed=true
    fi

done < "$USER_FILE"

# End of script summary
log "User creation script run completed."

if [ "$any_users_created" = true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - User creation script completed successfully."
elif [ "$all_users_exist" = true ]; then
    echo "Users already exist. Nothing left to do"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - No users were created successfully. Check log file."
    log "No users were created successfully. Please check the input file format: username;group1,group2,group3."
fi

[ "$user_creation_failed" = true ] && echo "Users creation incomplete." && log "Some users were not created due to errors. Check file format"
[ "$password_setting_failed" = true ] && echo "Users' passwords creation incomplete." && log "Some users' passwords were not set due to errors. Check file format"
[ "$group_creation_failed" = true ] && echo "Groups creation incomplete." && log "Some groups were not created due to errors. Check file format"
[ "$home_directory_setup_failed" = true ] && echo "Home directories creation incomplete." && log "Some home directories were not set up due to errors."

exit 0