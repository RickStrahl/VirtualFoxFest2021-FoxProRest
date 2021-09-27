# The Web Connection Web Server
The Web Connection Web Server is a .NET Core based, local Web Server that lets you to run Web Connection application without IIS or another Web server. The executable is self contained and includes everything you need to run a Web Connection application locally. You can also host this 'server' inside of IIS using the ASP.NET Core Hosting Module.


The main goal for this server is to provide a local development experience that doesn't require IIS. You can install it without other dependencies except for a dependency on the [.NET Core Runtime or SDK](https://dotnet.microsoft.com/download). There's no IIS configuration or other setup required - the server is pre-configured for typical Web Connection operations out of the box, is ready to go to serve requests locally and includes built-in Live Reload functionality without any configuration.

> The Web Connection Web Server can also be used as a standalone static file server - it can serve plain HTML and image resources from any folder on the local machine. 

## WebConnection Web Server Installation and Configuration
The server is a .NET Core 3.x application so in order to work you'll need:

* .NET Core Runtime 3.x
* A configuration file `WebConnectionWebServerSettings.xml` in the Web Root
* For IIS: A custom `web.config` configuration

### Requires .NET Core 3.1 Runtime or SDK
In order to run this Web Server **you need to install ASP.NET Core 3.1 or later**. To see if you need to install the SDK or runtime you can run `install.ps1` from a Powershell command prompt. If the runtimes are not installed it will prompt you to download the runtime or SDK.

If you have to install .NET Core you can install either:

* **The [.NET Core SDK (x64)](https://dotnet.microsoft.com/download)**  
(recommended for a local development box) 

* **The [ASP.NET Core Hosting Pack (x64)](https://dotnet.microsoft.com/download)**    
(minimal install recommended for a production server)

Either of these will allow you to run this Web server. Note that you can and should install the 64 bit versions and they will work with Web Connection even though your FoxPro applications run in 32 bit.

### Install.ps1
The optional install script performs two tasks:

* Checks to see if the .NET Core runtime is installed  
  and provides instructions on where to download it
* Adds the current folder to the User's global path

If .NET Core 3.x **is not installed**, it lets you know and sends you to the download site from which you can install the **.NET Core SDK** for a development machine, or the **.NET Core Hosting Bundle for IIS**.

By having the path in your OS path, `WebConnectionWebServer` is available from any folder on your machine and you can just run `WebConnectionWebServer` and specify a `--WebRoot` folder to point it at any folder.

## Running the WebConnectionWebServer
The Web Connection server is implemented as a .NET Core  Console application that is run from the Windows command prompt or Powershell.

> ##### @icon-warning Console Application: Must run from the Command Line
> `WebConnectionWebServer.exe` is a **Console Application** and it has to be launched from a Terminal window in order to run and keep running. **You can't start it from Explorer by double clicking**, as the application will start and immediately exit. Make sure to run from a Windows Command or Powershell window. If you previously ran `install.ps` the `WebConnectionServer` should be available on your Windows path. If you didn't you have to provide a path like `..\WebConnectionWebServer\WebConnectionWebServer` for example.

There are several ways to launch the server:

* From the `Deploy` folder in the VFP IDE use `Launch("WebConnectionWebServer")`
* Using `Console.exe WebConnectionWebServer` from Command Prompt in a Project folder
* Running `WebConnectionWebServer.exe` and specify a `--WebRoot`
* Running `WebConnectionWebServer.exe` out of a Web Root folder (ie. `MyProject\web`)

### Using Launch()
The `Launch()` command can be used from your project to launch the Web Connection Web server and your FoxPro application server. For the .NET Core based Web Connection Web Server you use:

```foxpro
Launch("WebConnectionWebServer")
```

If you're running launch in a project folder, the server is automatically opened in the `..\web` folder as its Web root. Requests are served by default on port 5200  (ie. `http://localhost:5200`) unless you specify a different port explicitly with the `--port` command line switch. You can also use `https://` via the `--useSSL` switch.

> The `Launch("WebConnectionWebServer")` uses `..\WebConnectionWebServer\WebConnectionWebServer.exe` to launch the server by default from the project's `Deploy` folder.

### Explicitly specify a Path, Port and other Options
You can explicitly launch the Web Server and specify a path that becomes the Web root folder by opening a command prompt and then use `WebConnectionWebServer`

```ps
# 'global' server (from `install.ps1`) - specify the Web Root
WebConnectionWebServer --WebRoot c:\webconnectionProjects\MyProject\web

# explicit Path and provide additional launch options
..\WebConnectionWebServer\WebConnectionWebServer `
                       --WebRoot c:\webconnectionProjects\MyProject\web `
                       --port 5201 `
                       --UseSsl

# global instance - launch in Web Root Folder
WebConnectionWebServer
```

To see all the options type:

```ps
WebConnectionWebServer --help
```

### Launch in the project's Web Root folder
Alternately you can launch the application in the folder you want to host as a Web site:

```ps
cd c:\webconnectionProjects\MyProject\web
WebConnectionWebServer
```

### Shut down the Web Connection Web Server
The application is a **Console Application** that runs in PowerShell or Windows Command Prompt Terminal and displays status information as it runs by default (you can disable this via options) in the Terminal. The server runs in the Terminal until you explicitly shut it down via `Ctrl-C` or `Ctrl-Break`, or you close the Terminal window.

### Server Configuration Settings
The `WebConnectionWebServer` uses a new and separate configuration file in addition to some short configuration settings inside of `web.config` to enable the .NET Core Module.


#### WebConnectionWebServerSettings.xml
The Web Connection specific features are configured in  `WebConnectionServerWebSettings.xml`. Note that this is different from the old .NET Module which used settings in `web.config`. The new settings map very closely to the settings that the classic .NET module uses although the format of the XML is a little different.

```xml
<?xml version="1.0" encoding="utf-8"?>
<WebConnectionWebServerSettings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <HandledExtensions>.wc,.wcs,.md,.wwd,.ms,.blog,.wcsx,.wst</HandledExtensions>
   <DefaultFiles>default.wwd,Default.htm,index.html</DefaultFiles>
   <WebRoot>c:\WebConnection\fox\web</WebRoot>
   <MessagingMechanism>File</MessagingMechanism>
   <ComServerProgId>wcdemo.wcdemoServer</ComServerProgId>
   <UseStaComServers>false</UseStaComServers>
   <ServerCount>2</ServerCount>
   <AutoStartServers>false</AutoStartServers>
   <ComServerLoadingMode>RoundRobin</ComServerLoadingMode>
   <TempPath>~\..\temp\</TempPath>
   <TempFilePrefix>WC_</TempFilePrefix>
   <Timeout>90</Timeout>
   <AdminAccount>ANY</AdminAccount>
   <AdminPage>~/admin/admin.html</AdminPage>
   <ExeFile>~\..\wcdemo.exe</ExeFile>
   <UpdateFile>~\..\wcdemo_Update.exe</UpdateFile>
   <UseLiveReload>true</UseLiveReload>
   <LiveReloadExtensions>.wwd,.wc,.wcs,.wst,.blog,.html,.htm,.css,.js,.ts</LiveReloadExtensions>
   <LogDetail>false</LogDetail>
   <MessageDisplayFooter>Generated by Web Connection IIS .NET Connector Module</MessageDisplayFooter>
   <VirtualDirectory>/</VirtualDirectory>
</WebConnectionWebServerSettings>
```

> ##### @icon-info-circle First Time Startup copies Settings from web.config  
> If the `WebConnectionWebServerSettings.xml` file doesn't exist and there is an existing ASP.NET  `web.config` file that holds Web Connection settings, the `WebConnectionWebServerSettings.xml` file is automatically created from the settings in `web.config`. The Middleware Admin page also includes a link that lets you import settings from a `web.config` file explicitly.


### Command Line Options
The `WebConnectionWebServer` application has a number of command line options that allow you to customize how the server runs. You can look up the options are available via the `--help` flag.

Here are the options available:

```text
----------------------------------------------
Web Connection Web Server
---------------------------------------------
(c) Rick Strahl, West Wind Technologies, 2019

Syntax:
-------
WebConnectionWebServer  <options>

Commandline options (optional):

--WebRoot            <path>  (current Path if not provided)
--Port               5200*
--UseSsl             True|False*
--UseLiveReload      True*|False{razorFlag}
--ShowUrls           True|False*
--OpenBrowser        True*|False
--DefaultFiles       ""index.html,default.htm,default.html""

Live Reload options:

--LiveReload.ClientFileExtensions   "".cshtml,.css,.js,.htm,.html,.ts""
--LiveReload ServerRefreshTimeout   3000,
--LiveReload.WebSocketUrl           ""/__livereload""

Configuration options can be specified in:

* Environment Variables with a `WEBCONNECTION_` prefix. Example: 'WEBCONNECTION_WEBROOT'
* Command Line options as shown above

Examples:
---------
WebConnectionWebServer --WebRoot "c:\temp\My Site" --port 5500 --useSsl false

$env:WEBCONNECTION_PORT 5500
WebConnectionWebServer
```

## Hosting in IIS
WebConnectionServer is a self-contained Web Server that can run as an executable, but it can also be hosted inside of IIS providing the exact same functionality as the standalone using .NET Core hosting. Instead of using the built-in native .NET Kestrel Web Server, the application uses IIS as the Web Host with an IIS module to interface directly with the .NET Core binary.

### Do you need IIS Hosting? 
For development IIS is not required nor recommended. IIS configuration requires Admin privileges and configuration can be daunting (even when automated) and the development server can run as a regular user and is entirely portable within a project. Move the project and there's nothing else that has to be configured to run the application.

For production sites you definitely want to use IIS as it provides better performance and many of the advanced features of IIS like caching, multi-domains for a single IP address, SSL management and much more.

When using IIS, WebConnectionWebServer runs as an InProcess (or optionally out of Process) ASP.NET Core Module Hosted IIS application which is very efficient.

### IIS Requirements and basic Configuration

In order for this to work you need the following on your production server:

* **ASP.NET Core 3.1 Runtime**  

* Install either the [ASP.NET Core Hosting Bundle for Windows](https://dotnet.microsoft.com/download) or the .NET Core SDK
* Copy the `.\WebConnectionWebServer` into your Project's Root Path (should be there in a new project)
* Create your Web Site (don't recommend using Virtuals)
* Point the Web Site folder at the `.\WebConnectionWebServer` folder in your project
* Set up a new Application Pool and set **No .NET Managed Code**
* Set up Application Pool Identity to SYSTEM to start - then dial back when it all works
* Make sure you have `WebConnectionWebServerSettings.xml` into your `.\web` folder
* Check settings in `WebConnectionWebServerSettings.xml`
* If `WebConnectionWebServerSettings.xml` doesn't exist it'll be created on the first request

The `web.config` in the `.\WebConnectionWebServer` folder at minimum should look like this:

```xml
<configuration>
    <system.webServer>
        <!-- <handlers> ...comment old ASP.NET handler maps... </handlers> -->
        
        <handlers>
          <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
        </handlers>
        <aspNetCore processPath="dotnet.exe" 
            arguments="..\WebConnectionWebServer\WebConnectionWebServer.dll" 
            stdoutLogEnabled="false" 
            stdoutLogFile=".\logs\stdout"
            hostingModel="InProcess">
            <environmentVariables>
                <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
                <environmentVariable name="WEBCONNECTION_USELIVERELOAD" value="False" />
                <environmentVariable name="WEBCONNECTION_OPENBROWSER" value="False" />
                <environmentVariable name="WEBCONNECTION_SHOWURLS" value="False" />
              </environmentVariables>
        </aspNetCore>
    </system.webServer>
</configuration>
```

This setup:

* Enables the ASP.NET Core Hosting Module 
* Launches `dotnet.exe` with the Web Connection Server module as the starter   `..\WebConnectionWebServer\WebConnectionWebServer.dll`
* Uses `InProcess` hosting (you can also use `OutOfProcess`)
* Sets up the startup environment:
    * Turns off Live Reload, Open Browser and Show Urls
    * These are not useful in hosted mode
* Optionally enable the logs via `stdoutLogEnabled="true"` in the `/logs` folder.

Notice that the path to the `..\web\WebConnectionWebServer.dll` is a relative path to the `web.config` where the above is defined, meaning that this `web.config` configuration is portable. If you move the project to a new folder the server link will continue to work.

> If you get IIS startup errors like *HTTP Error 500.0 - ANCM In-Process Handler Load Failure*, try hosting using `OutOfProcess` which is more forgiving. Error messages for that particular error can be found in the Event Log. Any errors during startup are logged into the Application Event Log (see error message). One common failure point is make sure Windows Authentication is enabled on the Web Site/Virtual


### Port Sharing for Port 80
The most pressing problem that IIS solves is that you can't share ports with multiple server instances easily with Kestrel, but IIS makes that easy via its host header bindings. If you're running only a single site then this might be doable, but for multiple Web sites on a Web Server you'll want to definitely go through IIS.

### Application Lifetime Management
IIS also provides lifetime management services to ensure that the .NET Core application is up and running and responding. If the application dies IIS quietly shuts it down and starts up a new instance, so IIS (actually the IIS Hosting Service) acts as a lifetime manager.

### Static File Services
IIS can also serve static file content as opposed to letting .NET Core perform that task. On Windows IIS and IIS's Kernel caching **are by far the fastest way** to serve static content that can be cached and compressed, and IIS makes this easy and transparent. The built-in Kestrel Web Server can serve all static resources internally too, and while it can do this capably, it's much less efficient compared to IIS.

To let IIS handle common static files, some extra IIS setup is required to map handlers explicitly to the StaticFileModule handler in IIS **prior** to the .NET Core module. Note that the Core module maps `path="*"` which is **every file** except the ones above explicitly mapped to something else. 

By adding specific handlers for specific extensions you can have IIS take over the most common file types:

```xml
<handlers>
      <add name="StaticFileModuleHtml" path="*.htm*" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleText" path="*.txt" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleSvg" path="*.svg" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleJs" path="*.js" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleCss" path="*.css" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleJpeg" path="*.jpeg" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleJpg" path="*.jpg" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModulePng" path="*.png" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleGif" path="*.gif" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleWoff" path="*.woff*" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      <add name="StaticFileModuleTxt" path="*.txt" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      
      <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
    </handlers>
```

This lets IIS do what it does best, and the application server do what it does best (serve dynamic Web Connection content).

### IIS Startup Troubleshooting
When an error occurs during startup there's not a lot of information available. This may show in two ways:

* Site doesn't come up at all (connection refused errorrs)'
* You can ASP.NET Core Module (ANCM) Error Page

The former means the application couldn't launch at all and the module even failed to load. The latter managed to get hte module loaded, but it failed to properly launch the ASP.NET Core application. The latter page has additional debug information along with a link to a Microsoft Doc Page with more suggestions for debugging startup errors.

The following are helpful and address common failures:

#### Errors are stored in the Application Event Log
If the Web application fails to launch, IIS and the ASP.NET Core Module write errors into the **Application Event Log**. You can use the Event View to find errors for `IIS ASP.NET Core Module V2`.

#### Make sure the IIS Site has Windows Authentication Enabled
The most common startup error you may see is that your IIS Web site **has to have Windows Authentication enabled**. Windows Auth is used for securing the Admin pages and when running under IIS ASP.NET core use the IIS Windows Auth features to authenticate users.

To enable go into the IIS Service Manager for your site, find **Authentication** and enable **Windows Authentication**.