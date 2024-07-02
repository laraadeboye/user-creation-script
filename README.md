# User Management Script

This bash script automates the process of creating new users, assigning them to groups, generating passwords, and setting up home directories with appropriate permissions. The script also logs each step to a log file and securely stores the generated passwords.

## Requirements

- This script must be run as the root user or with sudo privileges.
- Ensure you have the necessary permissions to create users and groups on your system.
- Ensure you have the necessary permissions to create files in /var/log and /var/secure.

## Files

- `create_users.sh`: The main script for creating users.
- `users_list.txt`: A text file containing the usernames and groups (semicolon-separated) to be processed by the script.


## Usage

**Prepare the User File**

   Create a text file (e.g., `users_list.txt`) containing the usernames and their respective groups. Each line should be in the format: `username;group1,group2,group3`
Each line represents one user.

`username`: The username to be created.
`group1,group2,group3`: A comma-separated list of groups the user should be added to.

   Example input file:
   ```
   alice;sudo,dev
   bob;dev,www-data
   charlie;sudo,admin

   ```

## Running the Script

1. Clone this repository
```
git clone https://github.com/laraadeboye/user-creation-script.git

cd user-creation-script
```

2. Ensure the script has executable permissions. If not, set the permissions using:

```
chmod +x create_users.sh
```

3. Execute the script with the user file as an argument:

```
sudo ./user_creation.sh /path/to/users_list.txt
```

### Script Details
**Logging**: All script activities are logged in `/var/log/user_management.log`.
**Password Storage**: Generated passwords are stored securely in `/var/secure/user_passwords.txt`.
**Group Creation**: The script creates groups with the same name as the username provided. Also, If the specified groups do not exist, the script will create them.
**Home Directory Setup**: The script sets up home directories with appropriate ownership and permissions (700).

### Example Log Output
Here is an example of what the log file might contain:

```
024-07-02 20:41:44 - Password file created: /var/secure/user_passwords.txt
2024-07-02 20:41:44 - Group alice created.
2024-07-02 20:41:44 - Group sudo created.
2024-07-02 20:41:45 - Group dev created.
2024-07-02 20:41:45 - User alice created and added to groups sudo,dev
2024-07-02 20:41:45 - Generated password for alice
2024-07-02 20:41:45 - Password set for alice and stored securely
2024-07-02 20:41:45 - Home directory for alice set up with appropriate permissions.
2024-07-02 20:41:45 - Group bob created.
2024-07-02 20:41:45 - Group www-data created.
2024-07-02 20:41:45 - User bob created and added to groups dev,www-data

```

### Error Handling
- If a user already exists, the script logs the information and skips the creation of that user.

- If a group already exists, the script logs the information and skips the creation of that group.

- If any step fails (e.g., user creation, password setting), the script logs the failure and continues with the next user.

## Important Notes
- The script must be run with root privileges to perform user and group management.
- Ensure the user file is properly formatted to avoid any issues during execution.


## Exit Codes and Messages
- `0`: Success
- `1`: Script was not run with root privileges.
- `1`: No user file provided or the user file does not exist.
- **Logs**: Detailed logs are stored in `/var/log/user_management.log` for troubleshooting.

## Troubleshooting
- Ensure the input file follows the correct format.
- Check /var/log/user_management.log for detailed error messages if the script fails.
- Verify that the script has permission to create and write to `/var/log` and `/var/secure`.
