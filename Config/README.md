# Configuration Directory

## Setup Instructions

This directory contains configuration files for the Clipmighty project.

### First Time Setup

1. Copy the template file to create your personal configuration:
   ```bash
   cp TeamConfig.xcconfig.template TeamConfig.xcconfig
   ```

2. Edit `TeamConfig.xcconfig` and replace `YOUR_TEAM_ID_HERE` with your Apple Developer Team ID.

3. You can find your Team ID at: https://developer.apple.com/account/#/membership

### Important Notes

- `TeamConfig.xcconfig` is **not tracked by git** (it's in `.gitignore`)
- Each developer should create their own `TeamConfig.xcconfig` file
- Never commit your actual `TeamConfig.xcconfig` to version control
- The `.template` file is the only configuration file that should be committed
