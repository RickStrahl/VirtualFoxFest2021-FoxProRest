# Building and Consuming REST Services with Visual FoxPro

*Virtual FoxFest 2021 Presentation*


## Session Description

REST APIs or Services that use plain HTTP requests and JSON have become the de facto replacement for the more complex SOAP Based architectures of the past. Most modern APIs available on the Web—from Credit Card Processors, to E-Commerce backends, to Mail services and Social Media data access—use REST services or variants thereof like GraphQL to make their remote data available for interaction.

REST based services tend to be much simpler to build and consume than SOAP services because they don't require any custom tooling like SOAP/WSDL services did and are using JSON which is inherently a much easier format to create and parse into usable object structures. All you need is an HTTP Client and a JSON parser and good API documentation.

In this session I'll demonstrate how to build a server-side REST API using both .NET Core and FoxPro (using West Wind Web Connection) and then demonstrate how to consume those APIs from a FoxPro client application using various JSON and Service client tools. I'll also discuss some common strategies for writing client side API code that helps with error handling and consistent access to API calls via wrappers that abstract API calls into easy to use application level classes that behave more like traditional business objects.

You will learn:

* What a REST API is
* How and why JSON is different than XML
* How to call a REST API with raw HTTP calls
* How to parse and send JSON between FoxPro and APIs
* How to call a REST API with high level service APIs
* How to organize API client code for resiliency and ease of integration
* Prerequisites: Some familiarity with Web Technologies. I'll be using some West Wind tools (provided with samples) to demonstrate the FoxPro features but concepts can be easily applied to other tools and even other platform.


## Documents

* [White Paper PDF](https://github.com/RickStrahl/VirtualFoxFest2021-FoxProRest/blob/main/Documents/Strahl_FoxProAndREST.pdf)
* [White Paper HTML](https://htmlpreview.github.io/?https://raw.githubusercontent.com/RickStrahl/VirtualFoxFest2021-FoxProRest/main/Documents/Strahl_FoxProAndREST.html) <small>([download](https://github.com/RickStrahl/VirtualFoxFest2021-FoxProRest/raw/main/Documents/Strahl_FoxProAndREST.html))</small>
* [Slides](https://github.com/RickStrahl/VirtualFoxFest2021-FoxProRest/raw/main/Documents/Strahl_FoxProREST.pptx)

## Source Code

* [FoxPro Client Samples](https://github.com/RickStrahl/VirtualFoxFest2021-FoxProRest/tree/main/FoxPro)  
You can start up FoxPro in the root folder, then run the examples in the `Client` folder. The samples include support libraries in the `\classes` folder.

* [Web Connection REST Service](https://github.com/RickStrahl/VirtualFoxFest2021-FoxProRest/tree/main/FoxPro/WebConnectionServer)  
This folder contains the full Web Connection project described in the Session/White Paper. You need to have a copy Web Connection (shareware version available) in order to run these examples. The `Readme.md` file has additional project configuration instructions.

## Follow up
Have questions or comments? Come ask questions on the West Wind Message board in the `Conferences` or product specific forum, and 

## Contact 
If you need more personalized support or guidance you can find more contact options for me here:

* [Rick Strahl Contact](https://west-wind.com/contact)
