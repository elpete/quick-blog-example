<cfoutput>
	<article>
		<h2>#prc.post.getTitle()#</h2>
		<p>#prc.post.getBody()#</p>
	</article>
	<a href="#event.buildLink( "posts" )#">Back</a>
    <hr />
	<h3>Comments</h3>
	<cfif prc.post.getComments().isEmpty()>
		<div class="card card-body bg-light mb-2">
			<p>No comments added yet.</p>
		</div>
	<cfelse>
		<cfloop array="#prc.post.getComments()#" index="comment">
			<div class="card card-body bg-light mb-2">
				<small>#dateTimeFormat( comment.getCreatedDate(), "full" )#</small>
				<p>#comment.getBody()#</p>
			</div>
		</cfloop>
	</cfif>

    <hr />
	#html.startForm( method = "POST", action = event.buildLink( "posts.#prc.post.getId()#.comments" ) )#
		<div class="form-group">
			<label for="body">Add a comment</label>
			<textarea class="form-control" name="body" id="body" rows="3"></textarea>
		</div>
		<div class="form-group">
			<button type="submit" class="btn btn-primary">Comment</button>
		</div>
	#html.endForm()#
</cfoutput>
