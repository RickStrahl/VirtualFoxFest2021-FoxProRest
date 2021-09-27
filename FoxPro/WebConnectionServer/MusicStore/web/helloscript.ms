<% 	
	* VS Addin Comment: SourceFile="~\..\deploy\YOUR_PROCESS_CLASS.PRG"
	pcPageTitle = "Hello Script World" 	
%>
<% Layout="~/views/_layoutpage.wcs" %>

<div class="container">
    <div class="page-header-text">
        <i class="fas fa-globe-americas"></i>
        Hello Script World
    </div>


    <!-- poError is set in the HelloScripting Method and passed as a private variable -->
    <%= HtmlErrorDisplay(poError) %>

    <p>
        Hello from <%= Version() %>.
        <br />
        The Time is: <b><%= ShortDate( DateTime(),2) %></b>.
    </p>


    <h3>10 Most Recent Requests</h3>
    <table class="table table-striped table-dark-headers table-bordered">
        <thead>
            <tr>
                <th>Time</th>
                <th>Request</th>
                <th>Verb</th>
                <th>IP Address</th>
            </tr>
        </thead>
        <tbody>
            <%
            SELECT TRequests 
            SCAN
            %>
            <tr>
                <td><%= ShortDate(Time,2) %></td>
                <td><%= Script + IIF(!EMPTY(QueryStr),"?" + QueryStr,"") %></td>
                <td><%= Verb %></td>
                <td><%= RemoteAddr %></td>
            </tr>
            <% ENDSCAN %>
        </tbody>
    </table>

    <div class="margin-top-2x">
        <markdown>
            ### This is an MVC Script Page with Code Behind
            This page is rendered using a Script page - **<%= JUSTFNAME(Request.GetPhysicalPath() ) %>** - from disk that contains
            **FoxPro code** embedded inside of `< %= expression %>` expression tags. There's also
            a `HelloScript()` method inside of your process class that is fired to set up a 
            model of data that can be rendered. In this page a Message object for the info
            box above, and the cursor for the request list are both created in the 'code behind'
            controller method.

            Using scripts you can:

            * Embed expressions using `< %= expression % >`
            * Embed code blocks using `< %  code % >`
            * Embed Markdown using `< markdown></ markdown>`
            * Render other partial pages using `< %= RenderPartial() %>`

            You can write code inside of these scripts, and the scripts are automatically
            recompiled when you make changes.

            ### This Page uses a Layout Page
            This page is rendered using a script that references a **_Layout** page which provides
            most of the page chrome - the HTML header the toolbar and footer. 
            This **Content Page** which references this Layout page is then rendered 
            into the Layout producing the complete HTML output.

            This MVC style mechanism allows you to create a master layout for your site, and render
            content pages into it. Content pages then only need to provide the page specific
            content without having to duplicate the page chrome. You can also create multiple
            _Layout pages to provide different layouts for different pages.

            Note that you can also create completely self contained pages that include **all HTML**
            but generally using a Layout page is more productive as you don't have to duplicate
            the same common HTML into each page.

            For more info see [Mvc for Web Connection](https://webconnection.west-wind.com/docs/_4db0vhaqw.htm)
            and [Layout Pages, Content Pages, Partials and Sections](https://webconnection.west-wind.com/docs/_4ds19cqwr.htm)
            in the [Web Connection Documentation](https://webconnection.west-wind.com/docs).

            > For building applications we **highly** recommend using the MVC based approach
            > of using controller methods for setting up models that are then passed
            > to a view for rendering. In Web Connection this translates to a process
            > method that calls `Response.ExpandScript()` to render a view.
            

            ### Markdown Embedding
            This block of text is rendered using Markdown that is embedded as a Markdown
            Island into the script page using a `< markdown></ markdown>` block. Markdown
            embedded in this way is turned into HTML and embedded into the page.
        </markdown>
    </div>


</div>            

<!-- remove sections if you're not using them -->
<% section="headers" %>

<% endsection %>

<% section="scripts" %>

<% endsection %>