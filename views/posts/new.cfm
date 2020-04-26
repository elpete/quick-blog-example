<cfoutput>
	<h2>Create a new post</h2>
    #renderView( "posts/_form", {
		"method": "POST",
		"action": event.buildLink( "posts" )
	} )#
</cfoutput>
