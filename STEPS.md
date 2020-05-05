# Build a Blog in 30 minutes with ColdBox and Quick

## Step 1
Add ColdBox's advanced-script template
We run `box coldbox create app` and let CommandBox do its magic!

## Step 2
Set up datasource

To set up our datasource, we will use cfconfig and commandbox-dotenv.
These come pre-installed from our template.
You can configure an existing datasource if you prefer.

We are using MySQL for this blog, but any of the supported qb grammars will do.
If you do not have a MySQL database, either download MySQL for your operating system
or use the following Docker command:

```sh
docker run -d --name=quick_blog_example -p 3306:3306 -e MYSQL_DATABASE=quick_blog_example -e MYSQL_ROOT_PASSWORD=root mysql:5
```

Next, we'll fill out our `.env` file.

```properties
# ColdBox Environment
APPNAME=ColdBox
ENVIRONMENT=development

# Database Information
DB_CONNECTIONSTRING=jdbc:mysql://127.0.0.1:3306/quick_blog_example?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC&useLegacyDatetimeCode=true
DB_CLASS=com.mysql.jdbc.Driver
DB_BUNDLENAME=com.mysql.jdbc
DB_BUNDLEVERSION=5.1.38
DB_DRIVER=MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=quick_blog_example
DB_USER=root
DB_PASSWORD=root
```

Now, when we start our server, our datasource will be available.

Last, we will configure our new datasource as our default datasource in `Application.cfc`:

```cfc
// Application.cfc
component {
	// ...

	this.datasource = "quick_blog_example";

	// ...
}
```

## Step 3
Create a posts table

There are many different ways we could create a `posts` table in our database.
We are going to use commandbox-migrations and cfmigrations here, but you
can create this any way you please.

For our purposes we will install `commandbox-migrations` next.

```sh
box install commandbox-migrations
```

Next we will add the needed configuration to our `box.json`

```json
{
	"cfmigrations":{
        "schema":"${DB_SCHEMA}",
        "connectionInfo":{
            "password":"${DB_PASSWORD}",
            "connectionString":"${DB_CONNECTIONSTRING}",
            "class":"${DB_CLASS}",
            "username":"${DB_USER}",
            "bundleName":"${DB_BUNDLENAME}",
            "bundleVersion":"{DB_BUNDLEVERSION}"
        },
        "defaultGrammar":"AutoDiscover@qb"
    }
}
```

Now we will add a migration for posts using CommandBox.

```sh
box migrate create create_posts_table
```

Fill in the newly created migration file with the code to create the `posts` table.

```cfc
component {

    function up( schema, query ) {
        schema.create( "posts", function( table ) {
            table.increments( "id" );
            table.string( "title" );
            table.text( "body" );
            table.timestamp( "createdDate" );
            table.timestamp( "modifiedDate" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "posts" );
    }

}
```

And run the migration up.

```sh
box migrate install
box migrate up
```

## Step 4
Define a Post entity and show all posts.

Start by installing Quick.

```sh
box install quick
```

We then need to add the necessary configuration.  The first piece is adding a mapping to `Application.cfc`.

```cfc
// Application.cfc
component {
    // ...
	this.mappings[ "/quick" ] = COLDBOX_APP_ROOT_PATH & "/modules/quick";
    // ...
}
```

Now we define our first Quick entity - `models/Post.cfc`.

We start by extending `quick.models.BaseEntity` and adding all the
attributes we want to select from the database table.

```cfc
// models/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="createdDate";
    property name="modifiedDate";

}
```

With our entity created and some data in the table we can tie in Quick to ColdBox and show the data.
Let's create a `Posts` handler with an `index` action. (You can use CommandBox for this if you like.)

```sh
box coldbox create handler name=Posts actions=index --!integrationTests
```

```cfc
// handlers/Posts.cfc
component {

	function index( event, rc, prc ) {
		prc.posts = getInstance( "Post" ).all();
		event.setView( "Posts/index" );
	}

}
```

And lets customize the view a bit.

```cfm
<!-- views/posts/index.cfm -->
<cfoutput>
	<h1>Posts</h1>
	<cfloop array="#prc.posts#" index="post">
		<div class="card mb-3">
			<div class="card-body">
				<h5 class="card-title">#post.getTitle()#</h5>
				<p class="card-text">#post.getBody()#</p>
			</div>
		</div>
	</cfloop>
</cfoutput>

```

Reinit the app and voila!  You can see your posts!

For good measure, we'll change the default event to point at our new `Posts.index` route.

```cfc
// config/ColdBox.cfc
coldbox = {
    // ...
    defaultEvent = "Posts.index",
    // ...
}
```

## Step 5
Define the Posts.show route

To start, we need to add a new route to our router to handle showing a single Post.
This route can go anywhere above the convention route - `route( ":handler/:action?" ).end();`.

```cfc
// config/Router.cfc
function configure() {
    // ...
    get( "/posts/:postId", "Posts.show" );
    // ...
}
```

Next let's add the new `show` action to `Posts`.

```cfc
// handlers/Posts.cfc
function show( event, rc, prc ) {
    prc.post = getInstance( "Post" ).findOrFail( rc.postId );
    event.setView( "posts/show" );
}
```

Here's the content of the view:

```cfm
<!-- views/posts/show.cfm -->
<cfoutput>
	<article>
		<h2>#prc.post.getTitle()#</h2>
		<p>#prc.post.getBody()#</p>
	</article>
	<a href="#event.buildLink( "posts" )#">Back</a>
</cfoutput>
```

We also add a link from our Posts.index page to the individual show view.

```cfm
<cfoutput>
	<h1>Posts</h1>
	<cfloop array="#prc.posts#" index="post">
		<div class="card mb-3">
			<div class="card-body">
				<h5 class="card-title">#post.getTitle()#</h5>
				<p class="card-text">#post.getBody()#</p>
				<a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
			</div>
		</div>
	</cfloop>
</cfoutput>
```

We can now view each post individually.

## Step 6
Create route to create new posts.

First step is to add a couple new routes to our `Posts` handler.
One of the routes is for the GET request for the `/posts/new` action
while the other is the POST request to `/posts` to create the post.
The `/posts/new` route needs to go ABOVE the wildcard route we added
in the last section.  Otherwise the wildcard route will catch it.
The POST route needs to be merged with the already defined GET request.
Each route can only be defined once, so we need to define all the actions
on one route.

```diff
// config/Router.cfc
function configure() {
    // ...
    get( "/posts/new", "Posts.new" );
    get( "/posts/:postId", "Posts.show" );
    route( "/posts" ).withHandler( "Posts" ).toAction( { "GET": "index", "POST": "create" } );
    // ...
}
```

The router configuration is getting a bit more complicated.  We'll clean it up in the next step
by using ColdBox's `resources` conventions.

Next we define the `new` action which should show a form to create a new Post.

```
// handlers/Posts.cfc
function new( event, rc, prc ) {
    event.setView( "posts/new" );
}
```

```
<!-- views/posts/new.cfm -->
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
```

We'll add a link from the index page to the new page.

```cfm
<cfoutput>
	<h1>Posts</h1>
	<a href="#event.buildLink( "posts.new" )#">Write a new post</a>
	<cfloop array="#prc.posts#" index="post">
		<div class="card mb-3">
			<div class="card-body">
				<h5 class="card-title">#post.getTitle()#</h5>
				<p class="card-text">#post.getBody()#</p>
				<a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
			</div>
		</div>
	</cfloop>
</cfoutput>
```

Lastly, we add the `create` action to handle creating the new Post.

```
// handlers/Post.cfc
function create( event, rc, prc ) {
    getInstance( "Post" ).create( {
        "title": rc.title,
        "body": rc.body,
    } );
    relocate( "posts" );
}
```

Normally this endpoint would need to handle validation as well.  We may come back to that in a later step.

## Step 7
Refactor new post form to use blank Post.

The next step is to add the edit and update actions.
It would be nice to reuse the same form we created for `new`.
We know that the `edit` action will pass along the Post to edit,
and we'd rather not have a bunch of `cfif` tags in our view.
To mitigate this, let's pass a blank Post in to the form from
our `new` action.

First, let's edit the `new` action to pass a blank Post.

```cfc
// handlers/Posts.cfc
function new( event, rc, prc ) {
    prc.post = getInstance( "Post" );
    event.setView( "posts/new" );
}
```

Next, we will use the Post as the `value` for our form elements.

```cfm
<!-- views/posts/new.cfm -->
<cfoutput>
	<h2>Create a new post</h2>
	<form method="POST" action="#event.buildLink( "posts" )#">
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
	</form>
</cfoutput>
```

Finally, let's extract the form as a new view.  We'll call it `_form`.  In this case
the underscore represents a partial or a view that is not loaded directly from a handler
but rather from another view.  This is just a convention, not a requirement. In addition,
we need to accept the method and action as view arguments since this will change
between `create` and `update`.  We will also switch to using the `HTMLHelper` for our `form` tags
to help send the correct method. (Read why here: https://coldbox.ortusbooks.com/the-basics/routing/http-method-spoofing)

```cfm
<!-- views/posts/_form.cfm -->
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
```

```cfm
<!-- views/posts/new.cfm -->
<cfoutput>
	<h2>Create a new post</h2>
    #renderView( "posts/_form", {
		"method": "POST",
		"action": event.buildLink( "posts" )
	} )#
</cfoutput>

```

With our refactor done, we are now ready to move on to the edit and update actions.

## Step 8
Add edit and update actions for Posts.

Let's start with the Router.  We mentioned previously that we would clean up the routes file
using ColdBox's `resources` convention.  The `resources` convention creates seven different
routes for common CREATE, READ, UPDATE, and DELETE (CRUD) actions.
We can replace all our custom routes with this one call:

```
// config/Router.cfc
function configure() {
    // ...
    resources( resource = "posts", parameterName = "postId" );
    // ...
}

This creates the routes we previously had for posts as well as the routes we will need
for `edit`, `update`, and `delete`.  Now it's time to create the new `edit` action and view.

```cfc
// handlers/Posts.cfc
function edit( event, rc, prc ) {
    prc.post = getInstance( "Post" ).findOrFail( rc.postId );
    event.setView( "posts/edit" );
}
```

```cfm
<!-- views/posts/edit.cfm -->
<cfoutput>
	<h2>Edit Post ###prc.post.getId()#</h2>
    #renderView( "posts/_form", {
        "method": "PUT",
        "action": event.buildLink( "posts.#prc.post.getId()#" )
    } )#
</cfoutput>
```

Now we see our refactoring helping us out!

We need a way to get to the edit page.  Let's add a link from our index page.

```cfm
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
```

Lastly, we need to add an `update` action to handle persisting the changes to our database.
After saving, we will redirect to the `show` action for the edited Post.

```cfc
function update( event, rc, prc ) {
    var post = getInstance( "Post" ).findOrFail( rc.postId );
    post.update( {
        "title": rc.title,
        "body": rc.body
    } );
    relocate( "posts.#post.getId()#" );
}
```

Again, you would want validation on this endpoint before saving to the database, but this does the trick for now!

## Step 9
Allow deleting of Posts.

Let's round out the CRUD actions on posts by adding a delete button to the edit page.
We implement the delete action as a form so we can use the `DELETE` verb.

```cfm
<!-- views/posts/edit.cfm -->
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
```

Additionally, we add the action to the `Posts` handler.

```cfc
function delete( event, rc, prc ) {
    var post = getInstance( "Post" ).findOrFail( rc.postId );
    post.delete();
    relocate( "posts" );
}
```

That rounds out the CRUD actions!

## Step 10
Allow commenting on posts

This step adds a new form at the bottom of the `Posts.show` page to add a comment.

```cfm
<!-- views/posts/show.cfm -->
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
```

We will use a nested route for adding the comment here.  It could be added using
a top-level comments handler and passing a `postId` along with the comment body.
Both work and are valid.  Let's generate our `PostComments.cfc` handler with CommandBox.

```sh
box coldbox create handler name=PostComments actions=create --!integrationTests
```

```cfc
// handlers/PostComments.cfc
component {

	function create( event, rc, prc ) {
        getInstance( "Comment" ).create( {
            "postId": rc.postId,
            "body": rc.body
        } );
        relocate( "posts.#rc.postId#" );
	}

}
```

We also need to route to this new action.  This route needs to go above the other post routes.

```cfc
// config/Router.cfc
function configure() {
    // ...
    post( "/posts/:postId/comments", "PostComments.create" );
    // ... the other post routes
}
```

Finally we need a new Comment entity.

```
// models/Comment.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="body";
    property name="postId";
    property name="createdDate";
    property name="modifiedDate";

}
```

Now we will add a migration for comments using CommandBox.

```sh
box migrate create create_comments_table
```

Fill in the newly created migration file with the code to create the `posts` table.

```cfc
component {

    function up( schema, query ) {
        schema.create( "comments", function( table ) {
            table.increments( "id" );
            table.text( "body" );
            table.unsignedInteger( "postId" );
            table.timestamp( "createdDate" );
            table.timestamp( "modifiedDate" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "comments" );
    }

}
```

And now our new form works.  But we can't see it on the page yet!  We'll cover that next.

## Step 11
Display comments on the Posts.show page

Now that we have comments associated with a Post, let's show those comments on the Posts.show view.
We start by defining a relationship on Posts.

```cfc
// models/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="createdDate";
    property name="modifiedDate";

    function comments() {
        return hasMany( "Comment" );
    }

}
```

Since we are following Quick conventions, we don't have to specify the foreign and local keys.
We can now access the relationship and execute it by calling the relationship name
prefixed by `get` - `getComments()`.  We'll add a `<cfloop>` to the view to show the comments.

```cfm
<!-- views/posts/show.cfm -->
<cfoutput>
	<article>
		<h2>#prc.post.getTitle()#</h2>
		<p>#prc.post.getBody()#</p>
	</article>
	<a href="#event.buildLink( "posts" )#">Back</a>
    <hr />
    <h3>Comments</h3>
    <cfloop array="#prc.post.getComments()#" index="comment">
		<div class="card card-body bg-light mb-2">
			<small>#dateTimeFormat( comment.getCreatedDate(), "full" )#</small>
            <p>#comment.getBody()#</p>
        </div>
    </cfloop>
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
```

There we go!  Comments are now shown on each posts.  Note that we also include an empty state.
