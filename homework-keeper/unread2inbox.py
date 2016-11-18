#!/usr/bin/python
#-*- encoding: utf-8 -*-

import imaplib
import email

def get_charset(message, default="ascii"):
    # Get the message charset
    return message.get_charset()
    return default

def get_filename(part):
    charset = get_charset(part)
    decoded_header = email.Header.decode_header(email.Header.Header(part.get_filename()))
    fname = decoded_header[0][0]
    encodeStr = decoded_header[0][1]
    if encodeStr != None:
        if charset == None:
            fname = fname.decode(encodeStr, 'gbk')
        else:
            fname = fname.decode(encodeStr, charset)
    return fname


def read(username, password, imap_host="imap.qq.com", imap_port=993):
    # Login to INBOX
    imap = imaplib.IMAP4_SSL(imap_host, imap_port)
    imap.login(username, password)
    imap.select('INBOX', False)

    # Use search(), not status()
    status, response = imap.search(None, 'UNSEEN')
    unread_msg_nums = response[0].split()

    # Print the count of all unread messages
    print "Processing %s messages" % len(unread_msg_nums)

    # Print all unread messages from a certain sender of interest
    for e_id in unread_msg_nums:
        _, response = imap.fetch(e_id, '(RFC822)')
        email_body = response[0][1]
        mail = email.message_from_string(email_body)
        if mail.get_content_maintype() != 'multipart':
            return
        for part in mail.walk():
            if part.get_content_maintype() != 'multipart' and part.get('Content-Disposition') is not None:
                open('/root/inbox/' + get_filename(part), 'wb').write(part.get_payload(decode=True))

    # Mark them as seen
    for e_id in unread_msg_nums:
        imap.store(e_id, '+FLAGS', '\Seen')

read('', '')

