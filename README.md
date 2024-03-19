# Notif360 ![bash](https://img.shields.io/badge/language-bash-green.svg) ![docker](https://img.shields.io/badge/Docker-notif360.Dockerfile-blue)

> System monitoring and notifications

A `simple` :zap: and lightweight system monitoring and notification tool designed to provide comprehensive insight of critical system metrics and website health.

![Welcome](https://imgur.com/Ci139ot.png)

## :books: Table of Contents

- [Installation](#package-installation)
- [Usage](#rocket-usage)
- [Features](#fireworks-features)
- [Future](#space_invader-future)
- [Support](#hammer_and_wrench-support)
- [Contributing](#memo-contributing)
- [License](#scroll-license)

## :package: Installation

### Requirements

There are few requirements that may also available on your current Unix-like operating system, `cURL` and `OpenSSL` installed in your computer system.

To check if you have these requirements installed, run this command in your `CLI`:

```sh
openssl version
curl --version
```

## :rocket: Usage

```sh
git clone https://github.com/datacareph/notif360.git
cd notif360
```

### Copy 'env.sample' to '.env' and replace values accordingly

```sh
cd ./notif360/
cp env.example .env
nano .env
```

You may need the following
- Domains to check (SSL Check)
- URLs to check and scan
- SMTP Credentials. You can use your existing or [contact us](https://www.datacareph.com/contact).
- SLACK URI Endpoint
- VirusTotal. [Get API Key here](https://www.virustotal.com/gui/my-apikey)

### Test it
> Make sure you have correct values in the `.env` file
```sh
./run.sh yes no no
```

### Add this into Cronjob
> You can use `sudo crontab -e` as root privilege
```sh
crontab -e
```

### You can copy and paste these code accordingly
> Change this `/opt/datacareph/notif360` according to your correct path
```
# Monitoring System
# Usage: ./run.sh <force_send_notif> <skip_system_check> <skip_virustotal_scan>

# Full scan with force notification: Run the script every 15 days at 9:00 AM
0 9 */15 * * /bin/bash /opt/datacareph/notif360/run.sh yes no no

# Website and Malware Scan and Disk check: Run the script every day at 10:00 AM
0 10 * * * /bin/bash /opt/datacareph/notif360/run.sh no no no

# Website Check Only: Run the script every 5 minutes
*/5 * * * * /bin/bash /opt/datacareph/notif360/run.sh no yes yes
```

Check these cron [schedules](https://github.com/datacareph/notif360/blob/main/notif360/20-scheduler) in the docker container.

### Tips

We will gradually update this readme file. Stay connected.

## :fireworks: Features
Here's the feature-rich functionality that this script can provide.

### :white_check_mark: System Monitoring
- **RAM Usage Monitoring:** Tracks memory usage to identify potential issues or bottlenecks.
- **Disk Space Monitoring:** Monitors available disk space to prevent storage capacity issues.
- **CPU Performance Monitoring:** Tracks CPU usage to ensure optimal system performance.

### :white_check_mark: Website Health Checks
- **Virus Scan:** Conducts regular scans to detect and mitigate any malware or malicious code on websites.
- **SSL Certificate Check:** Verifies SSL/TLS certificate validity and configuration to ensure secure connections.
- **Website Uptime Monitoring:** Monitors website availability and responsiveness to prevent downtime.

### :white_check_mark: Customizable Alerts and Notifications
- **Alerts for System Metrics:** Sends alerts when system metrics (RAM, disk, CPU) exceed predefined thresholds.
- **Alerts for Website Health:** Notifies users of website health issues, such as malware detection or SSL certificate expiry.
- **Notification Customization:** Allows users to customize alert settings, including recipients, notification methods, and threshold values.
- **Integration with Email and Slack:** Utilizes SMTP for email notifications and Slack webhooks for real-time communication.

### :white_check_mark: Reporting and Logging
- **System Reports:** Generates detailed reports on system metrics, website health status, and scan results.
- **Logging:** Logs all monitoring activities, alerts, and notifications for auditing and troubleshooting purposes.

### :white_check_mark: Easy Integration and Automation
- **Simple Configuration:** Provides an easy-to-use configuration interface for setting up monitoring parameters and alert settings.
- **Automation:** Supports automated scheduling for regular system checks and website scans.

### :white_check_mark: Open-Source and Extensible
- **Open-Source:** Licensed under an open-source license, allowing for community contributions and collaboration.
- **Extensibility:** Provides extensibility options for adding new monitoring checks or integrating with third-party tools and services.

## :space_invader: Future
TO-DO list and additional features
- Discord notification option
- Connectivity and network monitoring

## :hammer_and_wrench: Support

Please [open an issue](https://github.com/datacareph/notif360/issues/new) for support.

## :memo: Contributing

Contributing to this project is made simple, just follow these steps.
1. Fork the Repository under your GitHub account.
2. Clone your forked repo and go into that folder

```sh
git clone https://github.com/your-username/notif360.git
cd notif360
```
3. Create a separate branch and push your changes
> You may do this once
```sh
git checkout -b my-amazing-contribution
# Add your amazing feature
# Get the token here https://github.com/settings/tokens
git remote set-url origin https://your-username:ghp_YourGeneratedTokenypy63uudYz9mtu3iLQah@github.com/your-username/notif360.git
```
> This can be repetitive based how often you made the update
```sh
git fetch origin # optional. Get the latest update from the origin
git status # optional
git checkout my-amazing-contribution # optional
git add -A
git commit -m "This is my contribution: Additional feature 1."
git push origin my-amazing-contribution
```

4. Create Pull Request: Go to your forked repository on GitHub. You should now able to select the newly created branch called `my-amazing-contribution`. Click the `Contribute` and `Open pull request` button to create a pull request. Provide a descriptive title and description of your changes, then click 'Create pull request'. See screenshot
![Create pull request](https://imgur.com/xwkaAzF.png)

Or alternatively click 'Compare & pull request' see screenshot
![Compare & pull request](https://imgur.com/sOpuIP1.png)

## :scroll: License

[MIT](LICENSE) © [DataCarePh](https://github.com/datacareph/)