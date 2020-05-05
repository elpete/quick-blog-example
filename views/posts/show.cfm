<cfoutput>
	<article>
		<h2>#prc.post.getTitle()#</h2>
		<p>#prc.post.getBody()#</p>
	</article>
	<a href="#event.buildLink( "posts" )#">Back</a>
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
