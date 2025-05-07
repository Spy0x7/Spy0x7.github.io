---
title: "OData_+_SSRF_Fun_Filter_Injection_via_File_Upload"
published: true
layout: post
categories: [bounty]
tags: [bounty, OData, injection, SSRF, IDOR, enumeration]
---

## Introduction: Unmasking Subtle Vulnerabilities in a Financial Onboarding Platform

Assalamu Alaikum! I'm Nasur Ullah, an OSCP-certified penetration tester operating from Pakistan, with a profound interest in dissecting the intricate security mechanisms of web applications. My investigative approach often involves a meticulous examination of data flow and control mechanisms to identify deviations from expected behavior that can be exploited by malicious actors.

This comprehensive write-up provides an exhaustive analysis of two interconnected security vulnerabilities unearthed during a black-box assessment of a financial onboarding platform (client confidentiality strictly maintained). These vulnerabilities, a sophisticated **OData filter injection flaw** leading to complete user enumeration and a compelling **Server-Side Request Forgery (SSRF)** arising from the insecure handling of a custom proxy header, were not immediately obvious. Their discovery necessitated a deep understanding of **OData query semantics**, the security implications of **custom HTTP header processing**, and the potential for **server-side request manipulation**. This detailed exploration will delve into the granular technical details of these vulnerabilities, meticulously examine their potential attack vectors, and thoroughly articulate the tangible real-world risks they introduce.

---

## Deconstructing OData: The Double-Edged Sword of Flexible Data Access

**OData (Open Data Protocol)**, a robust RESTful API standard championed by Microsoft, empowers clients to interact with and manipulate data in a structured and uniform manner through standard HTTP methods. Its core strength lies in its expressive and standardized query language, typically embedded within URL parameters, which grants developers granular control over the data retrieval process. Key OData constructs, including `$filter` for conditional data retrieval, `$select` for specifying desired fields, `$orderby` for sorting results, `$expand` for retrieving related entities, and a rich library of built-in functions, offer significant development convenience.

Consider the illustrative OData query:

/users?$filter=startswith(Name,'a')&$select=Name,Username

This OData query is semantically equivalent to the following SQL statement:

```sql
SELECT Name, Username FROM Users WHERE Name LIKE 'a%'
```

However, the very flexibility that makes OData a powerful tool also introduces significant security challenges. If the server-side application fails to implement rigorous input validation and output sanitization for the parameters passed to the OData endpoint, attackers can craft malicious payloads within these parameters. These injected payloads can then manipulate the intended query logic, leading to the unauthorized disclosure of sensitive information or even more severe security breaches. The extensive range of supported functions and logical operators within the OData specification dramatically expands the potential attack surface, requiring developers to adopt a defense-in-depth security posture.

## The Genesis of Discovery: Atypical Header Behavior and the OData Indicator

During the security assessment of the "Name Screening" file upload functionality, an unusual HTTP header piqued my interest:

```
X-Proxy-Destination: /gateway/api/users?$filter=IdentityId eq 'abc'
```

The presence of the $filter keyword within the value of a custom HTTP header immediately suggested the utilization of an OData backend for data retrieval. This seemingly innocuous detail became the critical pivot point for subsequent investigation, prompting a focused effort to understand the intricate interplay between this custom header and the underlying data access mechanisms. The direct exposure of OData query parameters within a custom header, rather than the more conventional URL parameters, hinted at a potential lack of robust abstraction layers and consequently, an elevated risk of injection vulnerabilities.

## Bug 1: In-Depth Exploitation of OData Filter Injection for Comprehensive User Enumeration

### Technical Dissection: The Inner Workings of Filter Injection

An OData filter injection vulnerability arises when user-controlled input is directly incorporated into the $filter parameter of an OData query without undergoing rigorous input sanitization and validation. This oversight allows a malicious actor to inject arbitrary OData expressions, effectively manipulating the intended logic of the data retrieval query to extract unauthorized information. The expressive power of OData's filter syntax, encompassing Boolean logic operators (and, or, not) and a diverse set of built-in functions (startswith, endswith, substringof, eq, ne, gt, lt, ge, le), provides a rich landscape for crafting sophisticated injection payloads.

### The Exploitation Methodology: Bypassing Intended Filtering Mechanisms

Recognizing the direct utilization of the X-Proxy-Destination header's value in the construction of the backend OData query, I embarked on an attempt to inject carefully crafted malicious OData filter expressions. By strategically replacing the original filter with the following crafted payload:

```
$filter=startswith(Name,'a') or true&$select=Name,Username
```

The underlying objective was to introduce a logical tautology (or true) that would effectively circumvent the intended filtering logic enforced by the original query. The initial condition, startswith(Name,'a'), would evaluate to either true or false for each user record. However, the subsequent or true clause would ensure that the entire filter expression invariably evaluates to true, thereby causing the query to return all user records irrespective of their name. Furthermore, the inclusion of the $select=Name,Username parameter explicitly instructed the server to return the Name and Username fields for each retrieved user.

### The Ramifications: Unveiling a Trove of Sensitive User Data

The server's response to this meticulously crafted request was deeply concerning from a security perspective. Instead of merely returning data associated with my test user account, the API disclosed a comprehensive inventory of all user accounts within the system, including highly privileged and sensitive internal accounts:

- **admin@redacted.com**
- **opsmanager@redacted.com**
- **Usernames formatted as phone numbers**
- **A multitude of other internal user accounts**

![User Enumeration](/assets/OData/info.png)

This unauthorized disclosure of a complete user directory, achieved through a standard user role, constitutes a severe horizontal privilege escalation and a blatant violation of the fundamental security principle of least privilege.

### Root Cause Analysis: Direct Parameter Injection and the Absence of Robust Input Validation

The successful exploitation of this injection vulnerability can be directly attributed to the server's insecure practice of directly injecting the unfiltered value extracted from the X-Proxy-Destination header into the backend OData query engine.

### Exploring the Broader Spectrum of OData Filter Injection Attack Vectors

Advanced techniques:
- Boolean-based Blind Injection
- Time-based Blind Injection
- Function Abuse
- Type Coercion
- Encoding Bypass

##  Bug 2: Unveiling Server-Side Request Forgery (SSRF) Through the Proxy Header

### Deep Dive into SSRF Vulnerabilities

SSRF lets attackers make the vulnerable server send HTTP requests on their behalf. This can target internal systems, cloud metadata, and more.

### Systematic Exploitation

Examples:
- `X-Proxy-Destination: http://127.0.0.1:80`
- `X-Proxy-Destination: http://<your-collab>.oastify.com`

Results proved SSRF was present and exploitable.

![SSRF Localhost](/assets/OData/localhost.png)

![Burp Ping](/assets/OData/burp.png)

### Security Implications

- Internal reconnaissance
- Cloud metadata access
- Firewall evasion
- Exploitation of internal services

## The Synergistic Threat

Combined, these bugs allow:
- Easy user enumeration
- SSRF-based lateral movement
- Huge attack surface

## Comprehensive Remediation Recommendations

- Validate and sanitize OData filters
- Remove user control over proxy headers
- Enforce API allowlists
- Add rate limiting
- Monitor outbound traffic
- Conduct regular pentests

## Conclusion

This case highlights how subtle misuses of headers and query features (like OData) can result in high-impact vulnerabilities. Developers must apply secure design principles at every step to prevent exploitation.

