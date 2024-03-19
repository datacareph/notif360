# Notif360 ![bash](https://img.shields.io/badge/language-bash-green.svg) ![docker](https://img.shields.io/badge/Docker-notif360.Dockerfile-blue)

> System monitoring and notification

A `simple` :zap: and lightweight system monitoring and notification tool designed to provide comprehensive insight of critical system metrics and website health.

## :books: Table of Contents

- [Installation](#package-installation)
- [Usage](#rocket-usage)
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
cd ./pdisk/notif360/
cp env.example .env
nano .env
```

You may need the following
- SMTP Credentials
- SLACK URI Endpoint
- VirusTotal API
- Domains to check (SSL Check)
- URLs to check and scan

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
> Change this `/opt/datacareph/notif360` to the correct path
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

Check these cron [schedules](https://github.com/datacareph/notif360/blob/main/20-scheduler) in the docker container.

### Tips

We will gradually update this readme file. Stay connected.

### Screenshot with Flameshot

![screencast](https://imgur.com/CeueuNB.png)

## :hammer_and_wrench: Support

Please [open an issue](https://github.com/datacareph/notif360/issues/new) for support.

## :memo: Contributing

Please contribute using [Github Flow](https://guides.github.com/introduction/flow/). Create a branch, add commits, and [open a pull request](https://github.com/datacareph/notif360/compare/). Or simply
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
> This can be repetitive
```sh
git fetch origin # optional
git status # optional
git checkout my-amazing-contribution # optional
git add -A
git commit -m "This is my contribution: Additional feature 1."
git push origin my-amazing-contribution
```

4. Create Pull Request: Go to your forked repository on GitHub. You should now able to select the newly created branch called 'my-amazing-contribution'. Click the 'Contribute' and 'Open pull request' button to create a pull request. Provide a descriptive title and description of your changes, then click 'Create pull request'.

or click 'Compare & pull request' see screenshot
![Flameshot](https://imgur.com/Y4WEad4.png)

## :scroll: License

[MIT](LICENSE) © [DataCarePh](https://github.com/datacareph/)