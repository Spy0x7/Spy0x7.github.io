---
title: "OData_+_SSRF_Fun_Filter_Injection_via_File_Upload"
published: true
layout: post
categories: [bounty]
tags: [bounty, OData, injection, SSRF, IDOR, enumeration]
---

## Introduction

Assalamu Alaikum! I’m Nasur Ullah, an OSCP-certified penetration tester from Pakistan with a deep passion for discovering real-world bugs in web applications.

This write-up explains two interesting behaviors I encountered during a black-box assessment of a financial onboarding platform (client redacted). These weren’t just classic textbook bugs  they were quirks in **OData-based filters** and a suspicious **proxy header** that enabled full **user enumeration** and **SSRF-like behavior**. This post goes deep into the background of the bugs, how they work, their variants, and what made them risky in the real world.

---

## 🧠 What is OData?

**OData (Open Data Protocol)** is a REST-based protocol developed by Microsoft that enables querying and manipulating data using simple HTTP requests. It’s like SQL for APIs. If you’ve seen URLs with `$filter`, `$select`, or `$expand`, chances are you’re looking at an OData-based endpoint.

For example:
```
/users?$filter=startswith(Name,'a')&$select=Name,Username
```

This translates roughly to:

```sql
SELECT Name, Username FROM Users WHERE Name LIKE 'a%'
```

OData supports a wide range of functions like `eq`, `startswith`, `endswith`, `substring`, `or`, and more  all used through URL parameters. This is great for developers, but without strict validation, it becomes a playground for attackers.

---

## 🔎 Discovery Phase

While testing the **“Name Screening”** upload feature, I spotted a special header:

```
X-Proxy-Destination: /gateway/api/users?$filter=IdentityId eq 'abc'
```

That `$filter` keyword gave away that this backend uses **OData**. So I did what any curious hacker would do  I tried breaking it.

---

## 💥 Bug 1: OData Filter Injection

### What Is It?

An **OData filter injection** happens when user-controlled input is placed into OData query parameters without sanitization. This allows attackers to inject malicious logical expressions and extract unauthorized data.

### How I Exploited It

I replaced the filter with:
```
$filter=startswith(Name,'a') or true&$select=Name,Username
```

Instead of returning just my data, the API responded with **all users in the system**, including internal accounts:

- `admin@redacted.com`
- `opsmanager@redacted.com`
- Phone-number-style usernames
- And more…

All of this happened **with a normal user role**.

![User Enumeration](/assets/OData/info.png)

### Why This Worked

Because the server **directly injected** the `$filter` value from the `X-Proxy-Destination` header into the backend query engine  without sanitizing logical operators like `or true`, or sensitive functions like `startswith`.

### Types of Filter Injection

There are many expressions attackers can chain in OData:

- `$filter=1 eq 1`
- `$filter=startswith(Username,'a')`
- `$orderby=Name desc`
- `$select=Email,Role`
- `$expand=Permissions`
- `$top=1000` (for dumping limits)

If a server does not validate **functions, logic, or selected fields**, attackers can leak internal data or change the structure of queries.

---

## 🧪 Bug 2: SSRF-Like Behavior via Proxy Header

### What Is SSRF?

**Server-Side Request Forgery (SSRF)** allows an attacker to make the server perform HTTP requests on their behalf  often to internal systems or metadata endpoints.

In this case, the `X-Proxy-Destination` header acted like a **dynamic proxy forwarder**.

### What I Did

I changed the header from an internal API path to:

```
X-Proxy-Destination: http://127.0.0.1:80
```

![SSRF Localhost](/assets/OData/localhost.png)

The server responded differently, suggesting it actually **connected to localhost**.

Next, I used **Burp Collaborator**:
```
X-Proxy-Destination: http://<my-collab>.oastify.com
```

A few seconds later  boom 💥  a DNS callback was triggered from the backend. That proved the server could make **arbitrary outbound HTTP requests**, and I could potentially:

- Scan internal IP ranges
- Hit cloud metadata like `169.254.169.254`
- Bypass firewall egress controls
- Exploit open services (e.g., Redis, GCP APIs)


![Burp Ping](/assets/OData/burp.png)

This behavior is not full SSRF exploitation, but it’s **functionally similar**  hence, “SSRF-like”.

---

## 🔒 Why This Matters

These two bugs are **low-hanging but high-impact**:

- A single filter injection bypass leaked all usernames.
- The SSRF-like flaw enabled potential cloud metadata access or lateral moves.

Together, they expose internal logic and increase the attacker’s surface area.

---

## 🧼 What Could Fix This?

- Strict validation of all `$filter` expressions (no logic operators, no wildcards)
- Block `X-Proxy-*` headers from being user-controlled
- Allowlist only internal API paths (not full URLs)
- Rate-limit and monitor outbound connections

---

## 📌 Final Thoughts

This was one of those bugs where nothing “crashed,” but everything leaked. It’s a good reminder that:

- **Headers can be just as dangerous as URL/query params**
- **OData requires special handling, like SQL**
- **Even partial SSRF is a pivoting opportunity**

Thanks for reading! More write-ups coming soon, inshaAllah.

Stay curious & hack ethically 💻

