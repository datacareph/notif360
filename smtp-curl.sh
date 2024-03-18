#!/bin/bash

## This is undergoing developement (NOT PRODUCTION READY)
set -e

# SMTP server details
smtp_server="mx1.yourstmp.com"
smtp_port="465"
smtp_user="reports.noreply@yoursmtp.com"
smtp_password="NotSecurePassword"

# Sender details
sender_address="$smtp_user"
sender_name="Reports from Datacareph"

# Recipient details
recipient_address="esstat17@gmail.com"
recipient_name="Ven Ven"

# Email content
subject="No Reply: Test Email"
# content='Please do not reply <b>HTML</b> of the letter.'
html_content='Hi,<br>***Please*** do not reply <b>HTML</b> of *_the_* letter.<br>See ya!'
plain_text_content='Please do not reply HTML of the letter.'

# Construct email headers and body
# email_data=$'From: $sender_address\nTo: $recipient_address\nSubject: $subject\n\n$body'
email_data="From: $sender_address\nTo: $recipient_address\nSubject: $subject\nContent-Type: text/html;charset=utf-8\n\n$html_content"

# $'Line 1\nLine 2'
# Set the current date in RFC 2822 format
date_header=$(date -R)

# Generate a unique Message-Id
message_id=$(openssl rand -hex 16)@yoursmtp.com

# Send email using curl with SSL/TLS and authentication
# Source: https://www.baeldung.com/linux/curl-send-mail
curl --ssl-reqd \
    --url "smtps://$smtp_server:$smtp_port" \
    --user "$smtp_user:$smtp_password" \
    --mail-from "$sender_address" \
    --mail-rcpt "" \
    --header "Date: $date_header" \
    --header "Message-Id: $message_id" \
    --header "Subject: $subject" \
    --header "From: $sender_name <$sender_address>" \
    --header "To: $recipient_name <$recipient_address>" \
    --form '=(;type=multipart/mixed' \
    --form "=$html_content;type=text/html;charset=utf-8" \
    --form '=)' \
    --verbose
    
    #--data '<!doctype html><html lang="en"><title>Simple Transactional Email</title><body><b>This is sample content</b></body></html>' \
    # --upload-file <(echo -e "$email_data")

echo "executed!"