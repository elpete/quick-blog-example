<cfoutput>
	<h2>Edit Post ###prc.post.getId()#</h2>
    #renderView( "posts/_form", {
        "method": "PUT",
        "action": event.buildLink( "posts.#prc.post.getId()#" )
    } )#
</cfoutput>
