<cfoutput>
    #html.startForm( method = args.method, action = args.action )#
		<div class="form-group">
			<label for="title">Title</label>
			<input type="text" class="form-control" name="title" id="title" value="#prc.post.getTitle()#">
		</div>
		<div class="form-group">
			<label for="body">Body</label>
			<textarea class="form-control" name="body" id="body" rows="3">#prc.post.getBody()#</textarea>
		</div>
		<a href="#event.buildLink( "posts" )#" class="btn btn-outline">Back</a>
		<button type="submit" class="btn btn-primary">Submit</button>
    #html.endForm()#
</cfoutput>
