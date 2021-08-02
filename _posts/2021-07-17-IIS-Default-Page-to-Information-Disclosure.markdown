---
layout: post
title: IIS-Default-Page-to-Information-Disclosure
date: 2021-07-17 18:54 +0600
image: "/images/iis.jpg"
permalink: /IIS-Default-Page-to-Information-Disclosure/
tags: IIS Fuzzing Information-Disclosure
featured: false
---

<p>Hello World, this is my first blog which is related to one my recent finding i found in a bug bounty program. </p>

Usually whenever i see a Default IIS Page i used to skip the domain and move on to finding issues on other subdomains.
But in Nahamcon 2021 [@infosec_au](http://twitter.com/infosec_au) gave a talk on Hacking IIS 
@infosec_au discussed a bunch of vulnerabilities to check whenever we came across a IIS SERVER

###### I highly recommend you go through the talk 

[Hacking IIS](https://www.youtube.com/watch?v=cqM-MdPkaWo)

### Shortname Scanning

* As an initial step i will check if the website is vulnerable to [IIS tilde Vulnerability](https://www.rapid7.com/db/modules/auxiliary/scanner/http/iis_shortname_scanner/)

To check this vulnerability there are 2 tools which i recommend 
*  [IIS Shortname Scanner](https://github.com/irsdl/IIS-ShortName-Scanner) and [SNS](https://github.com/sw33tLie/sns)

<div class="language-bash"><div class="highlight"><pre class="highlight"><code>─$ sns -u  https://sub.redacted.com/              

 Proxy:   None
 Target:  https://sub.redacted.com/
 Threads: 50
 Timeout: 30
________________________________________________

 - aspnet~1 (Directory)
________________________________________________                    
                                                                                                               
SHORTNAME       FULL NAME       TYPE                                                                           
aspnet~1        Not found       Directory
</code></pre></div></div>

* I used sns but the result contains only one Directory which is the default directory [aspnet_client] which gave 403 on visiting the directory 

Nothing much here so i tried traditional content Discovery


### Fuzzing


* Most of the times on default IIS Default Webpages there is a high chance of finding zip files and backup files 

* We cannot rely blindly on IIS Shortname Scanner, So i started general content discovery 

    - Also Content Discovery on IIS Servers is easy because of they are Case Insensitive
    
* So i ran ffuf with jhaddix content_discovery_all.txt
    
<div class="language-bash"><div class="highlight"><pre class="highlight"><code> ffuf -u https://sub.redacted.com/FUZZ.zip -w content_discovery_all.txt -fc 404
</code></pre></div></div>

and http://sub.redacted.com/ws.zip gave 200 OK

* Upon visiting the url i am able to downloaded the whole source code. The source code contains many sensitive api keys and dll files

* I reported it and they resolved the issue immediately

* Whenever you find a Default IIS Page on a web server,  fuzz it you might find something interesting

Hope you learned something new :)