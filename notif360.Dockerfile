FROM alpine:3.19.1

LABEL maintainer="DataCarePh Containerized <esstat17@gmail.com>"
LABEL version="alpine-dcph-3.19.1"
LABEL description="Security information and event management (SIEM) using cron jobs"

# Arguments defined in docker-compose.yml
ARG uid gid
ARG UID=$uid
ARG USER=usr1
ARG GID=$gid
ARG GROUP=usr1

RUN set -x \
    && apk add --no-cache \
    openssl \
    bash \
    curl

# Clear cache
RUN set -x \
    # && apk del $PHPIZE_DEPS \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Delete user by UID if it exists
RUN if getent passwd $UID >/dev/null 2>&1; then \
    deluser $(getent passwd $UID | cut -d: -f1); \
fi

# Check if the specified group exists on the host and remove it
RUN if getent group $GID >/dev/null 2>&1; then \
    delgroup $(getent group $GID | cut -d: -f1); \
fi

# Create a non-root user
RUN set -x \
    && addgroup -g $GID -S $GROUP \
    && adduser -S -D -H -u $UID -h /home/$USER -s /sbin/nologin -G $GROUP -g $GID $USER \
    && mkdir -p /home/$USER \
    && chown $USER:$GROUP /home/$USER \
    && mkdir -p /opt/datacareph/notif360

# Copy notif360 job file and set ownership
COPY ./pdisk/notif360/20-scheduler /etc/crontabs/root

# Altered on docker compose
RUN set -x \
    chown root:$GROUP /etc/crontabs/root \
    && chmod 660 /etc/crontabs/root \
    && chown -R $USER:$GROUP /opt/datacareph/notif360 \
    && find /opt/datacareph/notif360 -type f -name "*.sh" -exec chmod u+x {} +

# Load the user's crontab
# RUN crontab -u $USER /etc/crontabs/$USER

# Set user
# USER $UID

# Set working directory
WORKDIR /opt/datacareph/notif360

# CMD to run crond in the foreground
# CMD ["crond", "-f"]
CMD ["tail", "-f", "/dev/null"]