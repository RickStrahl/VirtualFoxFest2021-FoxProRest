# Web Connection REST Server Sample - Music Store

This is a small sample REST Service implemented as a Web Connection application. The full Web Connection project lives in the `MusicStore` folder. 

To run the application you'll need to:

* Make sure one of these [Web Servers is available](https://webconnection.west-wind.com/docs/_5u10p0fg7.htm)
    * **IIS** (part of Windows must be enabled)
    * **IIS Express**  (small, self-contained, installable)
    * **Web Connection Web Server** (requires .NET Core 5.0)
* Make sure Web Connection is installed
    * You can download the [shareware version](https://webconnection.west-wind.com/download.aspx)
* Open **Visual FoxPro** in the `Deploy` Folder 
* Make sure environment is set up to find Web Connection
    * Recommend you use the short cut in the root folder
    * Change Shortcut path to the actual `Deploy` folder
    * Modify `\Deploy\config.fpw`: update paths to point at Web Connection install  
      (typically: `\wconnect` and `\wconnect\classes`)
    * Or: Explicitly create a PRG that `SET PATH TO <path> ADDITIVE`
* Edit `launch.prg` and set the **default Web Server** you chose above:
    * `lcServerType = "IIS"`
    * `lcServerType = "IISEXPRESS`
    * `lcServerType = "WEBCONNECTIONWEBSERVER"`

* If you use full IIS you'll need to configure IIS and set up a virtual or Web site
    * You can use `MusicStore_ServerConfig.prg`
    * Default sets up for `localhost/musicstore`
    * Otherwise edit `musicstore.ini` and `[ServerConfig]` section
    * Edit site Id and/or `Virtual` - blank = root site otherwise virtual folder

Once this is done you should be able to use `launch()` from the FoxPro command window to launch the application, Web Server, and your default browser to the appropriate URL.

The default access URL depends on the type of server:

* IIS: `http://localhost/musicstore`  
* IIS Express: `http://localhost:7000/`  
* WC Server: `https://localhost:5200/`  




