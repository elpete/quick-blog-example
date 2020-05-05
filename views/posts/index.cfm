<cfoutput>
	<h1>Posts</h1>
	<a href="#event.buildLink( "posts.new" )#">Write a new post</a>
	<cfloop array="#prc.posts#" index="post">
		<div class="card mb-3">
			<div class="card-body">
				<h5 class="card-title">#post.getTitle()#</h5>
				<p class="card-text">#post.getBody()#</p>
				<a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
				<a href="#event.buildLink( "posts.#post.getId()#.edit")#" class="card-link">Edit</a>
			</div>
		</div>
	</cfloop>
</cfoutput>
