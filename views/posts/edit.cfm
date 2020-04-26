<cfoutput>
	<div class="d-flex">
		<h2 class="mr-3">Edit Post ###prc.post.getId()#</h2>
	    #html.startForm( method = "DELETE", action = event.buildLink( "posts.#prc.post.getId()#" ) )#
	        <button type="submit" class="btn btn-outline-danger">Delete</button>
	    #html.endForm()#
	</div>
    #renderView( "posts/_form", {
        "method": "PUT",
        "action": event.buildLink( "posts.#prc.post.getId()#" )
    } )#
</cfoutput>
