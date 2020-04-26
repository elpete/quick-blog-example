<cfoutput>
	<h2>Create a new post</h2>
	<form method="POST" action="#event.buildLink( "posts" )#">
		<div class="form-group">
			<label for="title">Title</label>
			<input type="text" class="form-control" name="title" id="title">
		</div>
		<div class="form-group">
			<label for="body">Body</label>
			<textarea class="form-control" name="body" id="body" rows="3"></textarea>
		</div>
		<a href="#event.buildLink( "posts" )#" class="btn btn-outline">Back</a>
		<button type="submit" class="btn btn-primary">Submit</button>
	</form>
</cfoutput>
