# Notif360 ![bash](https://img.shields.io/badge/language-bash-green.svg) ![docker](https://img.shields.io/badge/Docker-notif360.Dockerfile-blue)

> Made with love :philippines:

A `simple` :zap: and lightweight system monitoring and notification tool designed to provide comprehensive insight of critical system metrics website health, and malware scanning.

![Welcome](https://imgur.com/Ci139ot.png)

## :books: Table of Contents

- [Installation](#package-installation)
- [Usage](#rocket-usage)
- [Beneficiaries](#family-beneficiaries)
- [Rationale](#thinking-rationale)
- [Features](#fireworks-features)
- [Future](#space_invader-future)
- [Support](#hammer_and_wrench-support)
- [Contributing](#memo-contributing)
- [License](#scroll-license)
- [Resources](#bookmark-resources)

## :package: Installation

### Requirements

There are a few requirements that may already be available on your current Unix-like operating system: 

- `OpenSSL`: Mainly used for SMTP and SSL checks.
- `cURL`: Used for checking website availability and for `Slack` integration.
- `crontab`: Used as a scheduler mechanism.

> These requirements are typically present in Unix-like systems such as `Linux` or `macOS`.

To check if you have these components installed, you can run a simple command in your command-line interface `CLI`:

```sh
openssl version
curl --version
```

## :rocket: Usage
Create project folder and download the updated copy
> `/opt` directory requires `root` or `sudoer` superuser privileges.
> Optionally, you can replace the path `/opt/datacareph` according to your project folder.

```sh
sudo mkdir -p /opt/datacareph
cd /opt/datacareph
sudo git clone https://github.com/datacareph/notif360.git
```

#### Copy `env.sample` to `.env` and replace values accordingly

```sh
cd notif360/notif360/
sudo cp sample.env .env
sudo nano .env # use your preferred editor
```

To use the tool, you may need the following:
- Domains to check (for SSL validation)
- URLs to check and scan
- SMTP Credentials: You can either use your existing credentials or [contact us](https://www.datacareph.com/contact) for assistance
- SLACK: [URL Endpoint](https://slack-notif360-secure.datacareph.com/slack/install).

Furthermore, to integrate with Slack, simply click the `Add to Slack` button below, allow this app to be added into your `Workspace` and specific `Channel`, and copy the `Slack Url Endpoint` and paste it to your project `.env` file `SLACK_WEBHOOK_URL`:

<a href="https://slack-notif360-secure.datacareph.com/slack/install"><img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack.png" srcSet="https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x" /></a>

- VirusTotal API Key. You can obtain it [here](https://www.virustotal.com/gui/my-apikey).

Once you have the necessary requirements, there are two methods to use the tool: directly on your `Host Machine` or within a `Docker Container`, and you can use either approach.

### Method 1: Host Machine Installation

1. Edit your cronjob with your preferred editor (e.g., nano):
```sh
sudo crontab -e
```

2. Add the following code into your cronjob

#### You can copy and paste this code accordingly

```
# Notif360 - System monitoring and notification tool.
# Usage: ./run.sh <force_send_notif> <skip_system_check> <skip_virustotal_scan>

# Full scan with force notification: Run the script every 15 days at 9:00 AM
0 9 */15 * * /bin/bash /opt/datacareph/notif360/notif360/run.sh yes no no

# Website and Malware Scan and Disk check: Run the script every day at 10:00 AM
0 10 * * * /bin/bash /opt/datacareph/notif360/notif360/run.sh no no no

# Website and SSL Check Only: Run the script every 10 minutes
*/10 * * * * /bin/bash /opt/datacareph/notif360/notif360/run.sh no yes yes
```
> Save.

> Update `/opt/datacareph/notif360/notif360` with your correct path.

### Method 2: Docker Container Implementation

We are working to seamlessly integrate it with both new and existing Docker containers. Before proceeding, please review the [docker-compose.yml](https://github.com/datacareph/notif360/blob/main/docker-compose.yml) file.

```sh
cd /opt/datacareph/notif360
docker compose up -d
```
> Replace `$WWW_PROJECT_DIR` with your actual project folder.

This will automatically build a new `Docker image` of approximately `15MB` and spawn the `Docker container`.

Check these cron [schedules](https://github.com/datacareph/notif360/blob/main/notif360/20-scheduler) in the docker container.

#### Test it!

> Make sure you have correct values in the `.env` file
```sh
cd /opt/datacareph/notif360/notif360
./run.sh yes no no
```

### Tips

We will gradually update this readme file. Stay connected!

## :family: Beneficiaries

- System Administrators
- DevOps Engineers managing Docker and Kubernetes deployments
- Backend Developers and Engineers
- Blue teams and Defensive Security Professionals
- Cybersecurity Analysts
- End-users who rely on secure and reliable websites while browsing the internet.

## :thinking: Rationale

Imagine managing tens or hundreds of `servers`, `containers`, `apps`, and `websites`. Manually checking and maintaining them on an hourly and daily basis is a heavy lift. To ease this burden, we have developed a solution. While there may be similar or existing tools available, they often consume considerable resources and can introduce vulnerabilities by exposing APIs.

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

### :white_check_mark: Easy Integration and Automation
- **Simple Configuration:** Provides an easy-to-use configuration interface for setting up monitoring parameters and alert settings.
- **Automation:** Supports automated scheduling for regular system checks and website scans.

## :space_invader: Future
TO-DO list and additional features:
- Discord notification integration
- Network monitoring

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
git remote set-url origin https://your-username:ghp_ReplaceWithYourFineGrainToken@github.com/your-username/notif360.git
```

> Note: Keep your token safe.

> This can be repetitive based how often you made the update

```sh
git fetch origin # optional. Get the latest update from the origin
git status # optional
git checkout my-amazing-contribution # optional
git add -A
git commit -m "This is my contribution: Additional feature 1."
git push origin my-amazing-contribution
```

4. Create Pull Request: Go to your forked repository on GitHub. You should now able to select the newly created branch called `my-amazing-contribution`. Click the `Contribute` and `Open pull request` button to create a pull request. Provide a descriptive title and description of your changes, then click `Create pull request`. See screenshot

![Create pull request](https://imgur.com/xwkaAzF.png)

Or alternatively click `Compare & pull request` see screenshot
![Compare & pull request](https://imgur.com/sOpuIP1.png)

## :scroll: License

[MIT](LICENSE) © [DataCarePh](https://github.com/datacareph/)

## :bookmark: Resources
- [VirusTotal](https://www.virustotal.com/gui/) - Analyse suspicious files, domains, IPs and URLs to detect malware.
- [Email Deliverability Tool](https://mxtoolbox.com/deliverability) - DKIM, SPF, DMARC, and other email integrity check.
- [Flameshot App](https://github.com/flameshot-org/flameshot) - A screenshot application used in this project.
