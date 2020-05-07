# Build a Blog in 30 minutes with ColdBox and Quick

## Step 1
Add quick-with-auth template
We run `box coldbox create app skeleton=cbTemplate-quick-with-auth` and let CommandBox do its magic!

We use the `quick-with-auth` template to handle the boilerplate of setting up Quick,
setting up a datasource, as well as adding authentication and authorization to our app.

For this tutorial, we will disable the `csrf` token auto-validation.
Do so by running `box uninstall verify-csrf-interceptor`.

Lastly, start a server using `box server start cfengine=lucee@5`.

## Step 2
Set up datasource

To set up our datasource, we will use cfconfig and commandbox-dotenv.
These come pre-installed from our template.
You can configure an existing datasource if you prefer.

We are using MySQL for this blog, but any of the supported qb grammars will do.
If you do not have a MySQL database, either download MySQL for your operating system
or use the following Docker command:

```sh
docker run -d \
    --name=quick_blog_example \
    -p 3306:3306 \
    -e MYSQL_DATABASE=quick_blog_example \
    -e MYSQL_ROOT_PASSWORD=root \
    mysql:5
```

Next, we'll fill out our `.env` file.

```properties
# ColdBox Environment
APPNAME=ColdBox
ENVIRONMENT=development

# Database Information
DB_CONNECTIONSTRING=jdbc:mysql://127.0.0.1:3306/quick_blog_example?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC&useLegacyDatetimeCode=true
DB_CLASS=com.mysql.jdbc.Driver
DB_DRIVER=MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=quick_blog_example
DB_SCHEMA=quick_blog_example
DB_USER=root
DB_PASSWORD=root
DB_BUNDLENAME=com.mysql.jdbc
DB_BUNDLEVERSION=5.1.38
```

Now, when we start our server, our datasource will be available.

Last, we will configure our new datasource as our default datasource in `Application.cfc`:

```diff
// Application.cfc
component {
    // ...

-  this.datasource = "coldbox";
+  this.datasource = "quick_blog_example";

    // ...
}
```

Also with our template we get a migration for our users table.  We run it up using commandbox-migrations.

```sh
box migrate up
```

We can now play around with our site, register new users, and log in.

## Step 3
Create a posts table

There are many different ways we could create a `posts` table in our database.
We are going to use commandbox-migrations and cfmigrations here, as it comes
installed with the quick-with-auth template, but you can create this any way you please.

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
            table.unsignedInteger( "userId" )
                .references( "id" )
                .onTable( "users" )
                .onDelete( "CASCADE" );
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
box migrate up
```

## Step 4
Define a Post entity and show all posts.

Now we define our first Quick entity - `models/entities/Post.cfc`.

(Note that the `/models/entities` directory is chosen entirely for aesthetics.)

We start by extending `quick.models.BaseEntity` and adding all the attributes
we want to select from the database table.

```cfc
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

}
```

While we will make a way to create a post directly in the app, for now just create a Post directly
in the database.

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
        event.setView( "posts/index" );
    }

}
```

And let's customize the view a bit.

```cfm
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
                    <p class="card-text">#post.getBody()#</p>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

Reinit the app and voila!  You can see your posts!

For good measure, we'll change the default event to point at our new `Posts.index` route.

```diff
// config/ColdBox.cfc
coldbox = {
    // ...
-   defaultEvent : ""
+   defaultEvent : "Posts.index",
    // ...
}
```

## Step 5
Define the `Posts.show` route

To start, we need to add a new route to our router to handle showing a single Post.
This route can go anywhere above the convention route - `route( ":handler/:action?" ).end();`.

```diff
// config/Router.cfc
function configure() {
    // ...
+   get( "/posts/:postId", "Posts.show" );
    // ...
}
```

Next let's add the new `show` action to `Posts`.

```diff
// handlers/Posts.cfc
+ function show( event, rc, prc ) {
+     prc.post = getInstance( "Post" ).findOrFail( rc.postId );
+     event.setView( "posts/show" );
+ }
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

We also add a link from our `Posts.index` page to the individual show view.

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
                    <p class="card-text">#post.getBody()#</p>
+                   <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

We can now view each post individually.

## Step 6
Add a getExcerpt helper method to Post.

A Post body may be very long.  We don't want to display the entire body in the list of posts.
Instead, we'd like to just show an excerpt.  At the same time, we don't want to put that on
the User.  Instead, we'd like it to be programmatic.  Let's take a look at how we can accomplish this.

You can add any methods you want to a Quick entity.  Here, we'll add a `getExcerpt`
method to do the work we need.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

+   function getExcerpt() {
+       return variables._str.limitWords( this.getBody(), 30 );
+   }

}
```

We are lucky to have the Str helper library available in each Quick entity
already, so we'll go ahead and use its `limitWords` function to create
our excerpt. A simpler version could be `return left( this.getBody(), 100 );`

Next, we'll update the index view.

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
-                   <p class="card-text">#post.getBody()#</p>
+                   <p class="card-text">#post.getExcerpt()#</p>
                    <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

Now we've used a custom function with a Quick entity.

## Step 7
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
+   get( "/posts/new", "Posts.new" );
    get( "/posts/:postId", "Posts.show" );
+   route( "/posts" ).withHandler( "Posts" ).toAction( { "GET": "index", "POST": "create" } );
    // ...
}
```

The router configuration is getting a bit more complicated.  We'll clean it up in the next step
by using ColdBox's `resources` conventions.

Next we define the `new` action which should show a form to create a new Post.

```diff
// handlers/Posts.cfc
+  function new( event, rc, prc ) secured {
+      event.setView( "posts/new" );
+  }
```

(The `secured` annotation here ensure a user must be logged in to access the route.)

```cfm
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

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
+   <a href="#event.buildLink( "posts.new" )#">Write a new post</a>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
                    <p class="card-text">#post.getExcerpt()#</p>
                    <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

Lastly, we add the `create` action to handle creating the new Post.

```diff
// handlers/Posts.cfc
+  function create( event, rc, prc ) secured {
+      getInstance( "Post" ).create( {
+          "title": rc.title,
+          "body": rc.body,
+          "userId": auth().getUserId()
+      } );
+      relocate( "posts" );
+  }
```

Normally this endpoint would need to handle validation as well.  We may come back to that in a later step.

## Step 8
Fix textarea spacing using a custom setter.

When you create a new post, you may notice that your line breaks are not preserved.
We can fix this by replacing all newline characters with `<br>` tags when saving
a Post.  We don't want to just do this on this one endpoint, though.  We will also
need the same behavior when we eventually edit the Post.  Our solution is to
define a custom setter function.

To do this, we define a custom function called `setBody`.
Inside this method we will do the conversion needed on the body and
then call the `assignAttribute` function to store this attribute.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function getExcerpt() {
        return variables._str.limitWords( this.getBody(), 30 );
    }

+   function setBody( body ) {
+       arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
+       arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
+       assignAttribute( "body", arguments.body );
+       return this;
+   }

}
```

Now when we pass data to our `body` attribute it will be automatically converted
to be shown correctly later.

## Step 9
Refactor new post form to use blank Post.

The next step is to add the edit and update actions.
It would be nice to reuse the same form we created for `new`.
We know that the `edit` action will pass along the Post to edit,
and we'd rather not have a bunch of `cfif` tags in our view.
To mitigate this, let's pass a blank Post in to the form from
our `new` action.

First, let's edit the `new` action to pass a blank Post.

```diff
// handlers/Posts.cfc
function new( event, rc, prc ) secured {
+   prc.post = getInstance( "Post" );
    event.setView( "posts/new" );
}
```

Next, we will use the Post as the `value` for our form elements.

```diff
<!-- views/posts/new.cfm -->
<cfoutput>
    <h2>Create a new post</h2>
    <form method="POST" action="#event.buildLink( "posts" )#">
        <div class="form-group">
            <label for="title">Title</label>
+   		<input type="text" class="form-control" name="title" id="title" value="#prc.post.getTitle()#">
        </div>
        <div class="form-group">
            <label for="body">Body</label>
+   		<textarea class="form-control" name="body" id="body" rows="3">#prc.post.getBody()#</textarea>
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

```diff
<!-- views/posts/new.cfm -->
<cfoutput>
    <h2>Create a new post</h2>
+   #renderView( "posts/_form", {
+   	"method": "POST",
+       "action": event.buildLink( "posts" )
+   } )#
-   <form method="POST" action="#event.buildLink( "posts" )#">
-	    <div class="form-group">
-		    <label for="title">Title</label>
-   		<input type="text" class="form-control" name="title" id="title" value="#prc.post.getTitle()#">
-	    </div>
-	    <div class="form-group">
-		    <label for="body">Body</label>
-   		<textarea class="form-control" name="body" id="body" rows="3">#prc.post.getBody()#</textarea>
-	    </div>
-	    <a href="#event.buildLink( "posts" )#" class="btn btn-outline">Back</a>
-	    <button type="submit" class="btn btn-primary">Submit</button>
-   </form>
</cfoutput>
```

With our refactor done, we are now ready to move on to the edit and update actions.

## Step 10
Add edit and update actions for Posts.

Let's start with the Router.  We mentioned previously that we would clean up the routes file
using ColdBox's `resources` convention.  The `resources` convention creates seven different
routes for common CREATE, READ, UPDATE, and DELETE (CRUD) actions.
We can replace all our custom routes with this one call:

```diff
// config/Router.cfc
function configure() {
    // ...
+   resources( resource = "posts", parameterName = "postId" );
-   get( "/posts/new", "Posts.new" );
-   get( "/posts/:postId", "Posts.show" );
-   route( "/posts" ).withHandler( "Posts" ).toAction( { "GET": "index", "POST": "create" } );

    // ...
}

This creates the routes we previously had for posts as well as the routes we will need
for `edit`, `update`, and `delete`.  Now it's time to create the new `edit` action and view.

```diff
// handlers/Posts.cfc
+  function edit( event, rc, prc ) secured {
+      prc.post = getInstance( "Post" ).findOrFail( rc.postId );
+      event.setView( "posts/edit" );
+  }
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

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <a href="#event.buildLink( "posts.new" )#">Write a new post</a>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
                    <p class="card-text">#post.getExcerpt()#</p>
                    <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
+                   <a href="#event.buildLink( "posts.#post.getId()#.edit")#" class="card-link">Edit</a>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

When we add a relationship back to the User that wrote the post, we will come back
here to make the edit route on show up for the User that wrote it.

Lastly, we need to add an `update` action to handle persisting the changes to our database.
After saving, we will redirect to the `show` action for the edited Post.

```diff
// handlers/Posts.cfc
+  function update( event, rc, prc ) secured {
+      var post = getInstance( "Post" ).findOrFail( rc.postId );
+      post.update( {
+          "title": rc.title,
+          "body": rc.body
+      } );
+      relocate( "posts.#post.getId()#" );
+  }
```

Again, you would want validation on this endpoint before saving to the database, but this does the trick for now!

## Step 11
Allow deleting of Posts.

Let's round out the CRUD actions on posts by adding a delete button to the edit page.
We implement the delete action as a form so we can use the `DELETE` verb.

```diff
<!-- views/posts/edit.cfm -->
<cfoutput>
-   <h2>Edit Post ###prc.post.getId()#</h2>
+	<div class="d-flex">
+		<h2 class="mr-3">Edit Post ###prc.post.getId()#</h2>
+	    #html.startForm( method = "DELETE", action = event.buildLink( "posts.#prc.post.getId()#" ) )#
+	        <button type="submit" class="btn btn-outline-danger">Delete</button>
+	    #html.endForm()#
+	</div>
    #renderView( "posts/_form", {
        "method": "PUT",
        "action": event.buildLink( "posts.#prc.post.getId()#" )
    } )#
</cfoutput>
```

Additionally, we add the action to the `Posts` handler.

```diff
// handlers/Posts.cfc
+  function delete( event, rc, prc ) {
+      var post = getInstance( "Post" ).findOrFail( rc.postId );
+      post.delete();
+      relocate( "posts" );
+  }
```

That rounds out the CRUD actions!

## Step 12
Add in User information for each Post.

Let's take the next step and add a relationship from a Post to its author - a User.
This is done by adding a method to the Post entity.  We can name the method anything
we want - whatever makes sense for the domain.  In this case, we are choosing to use
`author` to represent the relationship between a Post and the User who wrote it.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function getExcerpt() {
        return variables._str.limitWords( this.getBody(), 30 );
    }

    function setBody( body ) {
        arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
        arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
        assignAttribute( "body", arguments.body );
        return this;
    }

+   function author() {
+       return belongsTo( "User" );
+   }

}
```

(Since we are following Quick conventions, we don't have to specify the foreign and local keys.)

We can access the User instance associated with a Post by prefixing the relationship
method name with `get` - `getAuthor` in this case.  Let's start by adding the
author's email to the `Posts.show` page.

```diff
<!-- views/posts/show.cfm -->
<cfoutput>
    <article>
        <h2>#prc.post.getTitle()#</h2>
+       <small class="mb-4">By #prc.post.getAuthor().getEmail()#</small>
        <p>#prc.post.getBody()#</p>
    </article>
    <a href="#event.buildLink( "posts" )#">Back</a>
</cfoutput>
```

Great!  Let's add it to our `Posts.index` view as well.

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <a href="#event.buildLink( "posts.new" )#">Write a new post</a>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
+                   <h6 class="card-subtitle mb-2 text-muted">By #post.getAuthor().getEmail()#</h6>
                    <p class="card-text">#post.getExcerpt()#</p>
                    <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
                    <a href="#event.buildLink( "posts.#post.getId()#.edit")#" class="card-link">Edit</a>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

## Step 13
Fix the eager loading problem of Post -> Author

We now run in to an interesting issue.  To see it better, let's do two things.

First, let's add a bunch more posts to our application.  At least 10.

Second, let's install the `cbdebugger` module.  We'll install it as a dev dependency.
It will allow us to see all the queries being executed and entities loaded by Quick.

```sh
box install cbdebugger --saveDev
```

Now load the `Posts.index` route and take a look at your queries.
If you have 10 posts, you will see 11 queries.  This is true even if
all the posts are written by the same User.  This isn't good.  You can see
how this can balloon out of control and slow down your application.  This problem
is called the N+1 problem, named for having one more query executed that the
number of entities returned.  We can solve this problem with eager loading.

Eager loading will grab all the needed related entities in one query and then
match them up to their parent entities.  It will reduce the number of queries we
run to 2, no matter how many Posts we are loading.

To use eager loading, you use the `with` method when executing your query.
`with` takes a single relationship method name or an array of relationship
method names.  Here's is our adjusted `Posts.index` action:

```diff
// handlers/Posts.cfc
function index( event, rc, prc ) {
-   prc.posts = getInstance( "Post" ).all();
+   prc.posts = getInstance( "Post" ).with( "author" ).all();
    event.setView( "posts/index" );
}
```

When you reload the page, you will notice that our queries is back down to two!  Well done!

## Step 14
Only show edit route for the user that wrote it.

We mentioned above that when we defined the relationship between a Post
and its author we would revisit the edit link on the index page.  We
only want that link appearing if the currently logged in user (if there
is one) is the author of that Post.

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <a href="#event.buildLink( "posts.new" )#">Write a new post</a>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
                    <h6 class="card-subtitle mb-2 text-muted">By #post.getAuthor().getEmail()#</h6>
                    <p class="card-text">#post.getExcerpt()#</p>
                    <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
+                   <cfif auth().check() && auth().user().isSameAs( post.getAuthor() )>
                       <a href="#event.buildLink( "posts.#post.getId()#.edit")#" class="card-link">Edit</a>
+                   </cfif>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

Great!  Now we will only see the edit link if the Post was written by the
logged in User.

(Of course, right now you could still manually go to the edit page.
cbguard can help with this, but that's for a different tutorial.)

## Step 15
Allow commenting on posts

This step adds a new form at the bottom of the `Posts.show` page to add a comment.

```diff
<!-- views/posts/show.cfm -->
<cfoutput>
    <article>
        <h2>#prc.post.getTitle()#</h2>
        <small class="mb-4">By #prc.post.getAuthor().getEmail()#</small>
        <p>#prc.post.getBody()#</p>
    </article>
    <a href="#event.buildLink( "posts" )#">Back</a>
+   <cfif auth().check()>
+       <hr />
+       #html.startForm( method = "POST", action = event.buildLink( "posts.#prc.post.getId()#.comments" ) )#
+ 	        <div class="form-group">
+ 		        <label for="body">Add a comment</label>
+     		    <textarea class="form-control" name="body" id="body" rows="3"></textarea>
+ 	        </div>
+ 	        <div class="form-group">
+ 		        <button type="submit" class="btn btn-primary">Comment</button>
+ 	        </div>
+       #html.endForm()#
+   </cfif>
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
component secured {

    function create( event, rc, prc ) {
        getInstance( "Comment" ).create( {
            "postId": rc.postId,
            "userId": auth().getUserId(),
            "body": rc.body
        } );
        relocate( "posts.#rc.postId#" );
    }

}
```

We also need to route to this new action.  This route needs to go above the other post routes.

```diff
// config/Router.cfc
function configure() {
    // ...
+   post( "/posts/:postId/comments", "PostComments.create" );
    // ... the other Post routes
}
```

Finally we need a new Comment entity.

```cfc
// models/entities/Comment.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="body";
    property name="postId";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function setBody( body ) {
        arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
        arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
        assignAttribute( "body", arguments.body );
        return this;
    }

    function commenter() {
        return belongsTo( "User" );
    }

}
```

Now we will add a migration for comments using commandbox-migrations.

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
            table.unsignedInteger( "postId" )
                .references( "id" )
                .onTable( "posts" )
                .onDelete( "CASCADE" );
            table.unsignedInteger( "userId" )
                .references( "id" )
                .onTable( "users" )
                .onDelete( "CASCADE" );
            table.timestamp( "createdDate" );
            table.timestamp( "modifiedDate" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "comments" );
    }

}
```

```sh
box migrate up
```

And now our new form works.  But we can't see existing comments on the page yet!
We'll cover that next.

## Step 16
Display comments on the `Posts.show` page

Now that we have comments associated with a Post, let's show those
comments on the `Posts.show` view.  We start by defining a relationship on Posts.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function getExcerpt() {
        return variables._str.limitWords( this.getBody(), 30 );
    }

    function setBody( body ) {
        arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
        arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
        assignAttribute( "body", arguments.body );
        return this;
    }

    function author() {
        return belongsTo( "User" );
    }

+   function comments() {
+       return hasMany( "Comment" );
+   }

}
```

(Since we are following Quick conventions, we don't have to specify the foreign and local keys.)

We can now access the relationship and execute it by calling the relationship name
prefixed by `get` - `getComments()`.  We'll add a `<cfloop>` to the view to show the comments.

```diff
<!-- views/posts/show.cfm -->
<cfoutput>
    <article>
        <h2>#prc.post.getTitle()#</h2>
        <small class="mb-4">By #prc.post.getAuthor().getEmail()#</small>
        <p>#prc.post.getBody()#</p>
    </article>
    <a href="#event.buildLink( "posts" )#">Back</a>
+   <hr />
+   <h3>Comments</h3>
+   <cfif prc.post.getComments().isEmpty()>
+       <div class="card card-body bg-light mb-2">
+           <p>No comments yet.</p>
+       </div>
+   <cfelse>
+       <cfloop array="#prc.post.getComments()#" index="comment">
+           <div class="card card-body bg-light mb-2">
+               <small>#dateTimeFormat( comment.getCreatedDate(), "full" )# by #comment.getCommenter().getEmail()#</small>
+               <p>#comment.getBody()#</p>
+           </div>
+       </cfloop>
+   </cfif>
    <cfif auth().check()>
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
    </cfif>
</cfoutput>
```

There we go!  Comments are now shown on each posts.
(Note that we also include an empty state. Good UI practice.)

## Step 17
Eager load commenters

Each comment has a User it belongs to referenced by the `commenter` relationship.
When we display each comment we also display the User's email that commented.
This creates another N+1 problem.  We can verify it in the cbdebugger panel.

With relationships, we're not limited to just the relationship function.  Each
relationship is a full builder that can be configured like any other entity.
That means we can add an eager load using the `with` method inside our `commenter`
relationship method.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function getExcerpt() {
        return variables._str.limitWords( this.getBody(), 30 );
    }

    function setBody( body ) {
        arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
        arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
        assignAttribute( "body", arguments.body );
        return this;
    }

    function author() {
        return belongsTo( "User" );
    }

    function comments() {
-       return hasMany( "Comment" );
+       return hasMany( "Comment" ).with( "commenter" );
    }

}
```

Sometimes it will make sense to default the relationship with an eager load
and other times it will not.  You will need to evaluate each use case individually.

## Step 18
Refactor create methods to use relationships.

Let's try something.  Using Postman or another tool like it send a POST request to
`/posts/:postId/comments` using a `postId` that does not exist.  If you have a
foreign key constraint on the `postId` column on the `comments` table, you should get
an error back.  This isn't the nicest behavior - we'd rather have a 404 returned
since the post does not exist.

Additionally, what if the column name changes from `postId` to something else?
What if additional constraints need to be applied to this relationship like checking
that a Post is published before allowing comments?  The power of Quick comes in
naming bits of SQL in concepts like relationships and scopes.  Let's use that to our advantage here.

First, let's create a relationship from User to Post.  Even though we aren't displaying
this in the UI right now, it can be useful to us.

```diff
// models/entities/User.cfc
component extends="quick.models.BaseEntity" {

    property name="bcrypt" inject="@BCrypt" persistent="false";

    property name="id";
    property name="email";
    property name="password";

+   function posts() {
+       return hasMany( "Post" );
+   }

    public User function setPassword( required string password ){
        return assignAttribute( "password", bcrypt.hashPassword( arguments.password ) );
    }

    public boolean function hasPermission( required string permission ){
        return true;
    }

    public boolean function isValidCredentials( required string email, required string password ){
        var user = newEntity().where( "email", arguments.email ).first();
        if ( !user.isLoaded() ) {
            return false;
        }
        return bcrypt.checkPassword( arguments.password, user.getPassword() );
    }

    public User function retrieveUserByUsername( required string email ){
        return newEntity().where( "email", arguments.email ).firstOrFail();
    }

    public User function retrieveUserById( required numeric id ){
        return newEntity().findOrFail( arguments.id );
    }

    public struct function getMemento(){
        return { "email" : variables.getEmail() };
    }

}
```

Next we swap the `Posts.create` action to use the relationship when creating the Post.

```diff
// handlers/Posts.cfc
function create( event, rc, prc ) secured {
-   getInstance( "Post" ).create( {
+   auth().user().posts().create( {
        "title": rc.title,
        "body": rc.body,
-       "userId": auth().getUserId()
    } );
    relocate( "posts" );
}
```

On first glance it doesn't seem very different at all.  But remember that
now the definition for how these models are related is stored in one place,
no matter how many different places use that relationship.

Let's apply the same treatment to our `PostComments.create` method.

```diff
// handlers/PostComments.cfc
function create( event, rc, prc ) {
+   var post = getInstance( "Post" ).findOrFail( rc.postId );
+   post.comments().create( {
-   getInstance( "Comment" ).create( {
-       "postId": rc.postId,
        "userId": auth().getUserId(),
        "body": rc.body
    } );
    relocate( "posts.#rc.postId#" );
}
```

This accomplishes the other goal we had in mind - this route will return
a 404 Not Found if an invalid `postId` is passed.

## Step 19
Introduce Tags.

A Tag showcases a new relationship type - a many-to-many or `belongsToMany`
relationship.  This is where a Post can be associated with 0 or more tags
and a Tag can be associated with 0 or more Posts.

(For this example, we will create the Tags in the database manually.)

Let's begin with a migration file.  Two migrations, actually.  That is
because to represent a many-to-many relationship you need an
intermediate or pivot table.  By default, Quick uses the table names of each
entity in alphabetical order separated by an underscore.  So for the table
between our Post entity and our Tag entity, Quick will use a default
of `posts_tags`.  You are, of course, free to use your own conventions.

```sh
box migrate create create_tags_table
```

```cfc
component {

    function up( schema, query ) {
        schema.create( "tags", function( table ) {
            table.increments( "id" );
            table.string( "name" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "tags" );
    }

}
```

```sh
box migrate create create_posts_tags_table
```

```cfc
component {

    function up( schema, query ) {
        schema.create( "posts_tags", function( table ) {
            table.unsignedInteger( "postId" )
                .references( "id" )
                .onTable( "posts" )
                .onDelete( "CASCADE" );
            table.unsignedInteger( "tagId" )
                .references( "id" )
                .onTable( "tags" )
                .onDelete( "CASCADE" );

            table.primaryKey( [ "postId", "tagId" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "posts_tags" );
    }

}
```

```sh
box migrate up
```

Let's create our Tag entity next.

```cfc
// models/entities/Tag.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function posts() {
        return belongsToMany( "Post" );
    }

}
```

(Since we are following Quick conventions, we don't have to specify the foreign and local keys.)

After that, let's add the tags relationship to our Post entity.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function getExcerpt() {
        return variables._str.limitWords( this.getBody(), 30 );
    }

    function setBody( body ) {
        arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
        arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
        assignAttribute( "body", arguments.body );
        return this;
    }

    function author() {
        return belongsTo( "User" );
    }

    function comments() {
        return hasMany( "Comment" );
    }

+   function tags() {
+       return belongsToMany( "Tag" );
+   }
+
+   function hasTag( tag ) {
+       if ( !this.isLoaded() ) {
+           return false;
+       }
+
+       return this.getTags().map( function( tag ) {
+           return tag.getId();
+       } ).contains( arguments.tag.getId() );
+   }
+
}
```

(Since we are following Quick conventions, we don't have to specify the foreign and local keys.)
We also added a helper function - `hasTag` - in our view to select the already selected tags.

Next, create some tags manually through a database UI.  Four or five should be enough.

```sql
INSERT INTO `tags` (`name`) VALUES ('coldbox'), ('testbox'), ('commandbox'), ('quick'), ('qb')
```

Let's show the available tags on our `Posts.new` and `Posts.edit` form.
The first step is to add all the tags to our `prc` in those actions.

```diff
// handlers/Posts.cfc
function new( event, rc, prc ) secured {
    prc.post = getInstance( "Post" );
+   prc.tags = getInstance( "Tag" ).all();
    event.setView( "posts/new" );
}

function edit( event, rc, prc ) secured {
    prc.post = getInstance( "Post" ).findOrFail( rc.postId );
+   prc.tags = getInstance( "Tag" ).all();
    event.setView( "posts/edit" );
}
```

Next we'll display the tags in a select field on the form.

```diff
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
+       <div class="form-group">
+           <label for="tags">Tags</label>
+           <select class="form-control" name="tags[]" multiple="true" id="tags">
+               <cfloop array="#prc.tags#" index="tag">
+                   <option
+                       value="#tag.getId()#"
+                       <cfif prc.post.hasTag( tag )>selected</cfif>
+                   >
+                       #tag.getName()#
+                   </option>
+               </cfloop>
+           </select>
+       </div>
        <a href="#event.buildLink( "posts" )#" class="btn btn-outline">Back</a>
        <button type="submit" class="btn btn-primary">Submit</button>
    #html.endForm()#
</cfoutput>
```

Last, our `create` and `update` actions need to process the tags.  To do this we'll use two
methods available on the `BelongsToMany` relationships - `attach` and `sync`.

Let's start with the `create` action:

```diff
// handlers/Posts.cfc
function create( event, rc, prc ) secured {
+   var post = auth().user().posts().create( {
        "title": rc.title,
        "body": rc.body,
    } );
+   post.tags().attach( rc.tags );
    relocate( "posts" );
}
```

Here we use the `attach` method.  It takes an array of ids or Tag entities to
associate with the Post.  These will be added to any already existing associations.
This is done after creating the Post because the Post needs to exist before we
can insert its `id` in the `post_tag` table.

Next, let's modify the `update` action:

```diff
// handlers/Posts.cfc
function update( event, rc, prc ) secured {
    var post = getInstance( "Post" ).findOrFail( rc.postId );
    post.update( {
        "title": rc.title,
        "body": rc.body
    } );
+   post.tags().sync( rc.tags );
    relocate( "posts.#post.getId()#" );
}
```

Here we use the `sync` method.  This method first deletes any existing Tag associations
for the given Post.  Then it creates the associations passed in.

(There is one more method not covered here - `detach`.  It is used to remove one or more associations.)

Last step - let's add the list of tags to the `Posts.show` and `Posts.index` action so we can verify our work.

```diff
<!-- views/posts/show.cfm -->
<cfoutput>
    <article>
        <h2>#prc.post.getTitle()#</h2>
-       <small class="mb-4">By #prc.post.getAuthor().getEmail()#</small>
+       <small>By #prc.post.getAuthor().getEmail()#</small>
+       <div class="mb-4">
+           <cfloop array="#prc.post.getTags()#"s index="tag">
+               <span class="badge badge-pill badge-info">#tag.getName()#</span>
+           </cfloop>
+       </div>
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

```diff
<!-- views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>
    <a href="#event.buildLink( "posts.new" )#">Write a new post</a>
    <cfif prc.posts.isEmpty()>
        <div class="card mb-3">
            <div class="card-body">
                <p class="card-text">No posts yet.</p>
            </div>
        </div>
    <cfelse>
        <cfloop array="#prc.posts#" index="post">
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">#post.getTitle()#</h5>
                    <h6 class="card-subtitle mb-2 text-muted">By #post.getAuthor().getEmail()#</h6>
+                   <div class="mb-2">
+                       <cfloop array="#post.getTags()#" index="tag">
+                           <span class="badge badge-pill badge-info">#tag.getName()#</span>
+                       </cfloop>
+                   </div>
                    <p class="card-text">#post.getExcerpt()#</p>
                    <a href="#event.buildLink( "posts.#post.getId()#" )#" class="card-link">Read</a>
                    <cfif auth().check() && auth().user().is( post.getAuthor() )>
                       <a href="#event.buildLink( "posts.#post.getId()#.edit")#" class="card-link">Edit</a>
                    </cfif>
                </div>
            </div>
        </cfloop>
    </cfif>
</cfoutput>
```

Step back and check out your work!

## Step 20
Eager load tags on `Posts.index`.

Check out your `Posts.index` action now.  If many of your Posts have tags,
you are going to see a lot of queries again.  The N+1 problem is back.
Let's reach for eager loading and the `with` method again.

```diff
// handlers/Posts.cfc
function index( event, rc, prc ) {
-   prc.posts = getInstance( "Post" ).with( "author" ).all();
+   prc.posts = getInstance( "Post" ).with( [ "author", "tags" ] ).all();
    event.setView( "posts/index" );
}
```

That's it!  N+1 problem solved.

## Step 21
Order by post created date using a `latest` scope.

Here's a simple one.  We want all the Posts on the `Posts.index` page
displayed in descending order.  That is the most recently created Post
should be on top.

You can use any qb method on a Quick entity.  That means we can do this to order the Posts.

```diff
// handlers/Posts.cfc
function index( event, rc, prc ) {
-   prc.posts = getInstance( "Post" ).with( [ "author", "tags" ] ).all();
+   prc.posts = getInstance( "Post" )
+       .with( [ "author", "tags" ] )
+       .orderByDesc( "createdDate" )
+       .get();
    event.setView( "posts/index" );
}
```

This works fine, but we can do better.  We mentioned earlier that one of
the main benefits of Quick was naming bits of SQL code.  This can be as small
as our order by call above.  Let's give it the name `latest` and introduce
it as a scope to our Post entity.

```diff
// models/entities/Post.cfc
component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title";
    property name="body";
    property name="userId";
    property name="createdDate";
    property name="modifiedDate";

    function getExcerpt() {
        return variables._str.limitWords( this.getBody(), 30 );
    }

    function setBody( body ) {
        arguments.body = replaceNoCase( arguments.body, chr( 13 ) & chr( 10 ), "<br>", "all" );
        arguments.body = replaceNoCase( arguments.body, chr( 10 ), "<br>", "all" );
        assignAttribute( "body", arguments.body );
        return this;
    }

    function author() {
        return belongsTo( "User" );
    }

    function comments() {
        return hasMany( "Comment" );
    }

    function tags() {
        return belongsToMany( "Tag" );
    }

    function hasTag( tag ) {
        if ( !this.isLoaded() ) {
            return false;
        }

        return this.getTags().map( function( tag ) {
            return tag.getId();
        } ).contains( arguments.tag.getId() );
    }

+   function scopeLatest( q ) {
+       q.orderByDesc( "createdDate" );
+   }

}
```

Scopes are special methods in Quick that receives the current builder instance as the first parameter.
Inside a scope you can configure your query in any way you need.

You call scopes without using the `scope` prefix, like so:

```diff
// handlers/Posts.cfc
function index( event, rc, prc ) {
    prc.posts = getInstance( "Post" )
        .with( [ "author", "tags" ] )
-       .orderByDesc( "createdDate" )
+       .latest()
        .get();
    event.setView( "posts/index" );
}
```

Seems like a simple change, right?  Maybe you are thinking it is only
useful for large chunks of SQL code.  But even this encapsulation is beneficial!
Now, when how we define the `latest` ordering changes, we have one place to change it.
Maybe you introduce the idea of promoted posts later and those need to be
first no matter what. You can make the change in your scope and any query
using that scope gets the new behavior automatically.  Scopes and relationships
really are the power behind Quick.

## Wrap up

We hope you've enjoyed this Build a Blog in 30 Minutes with ColdBox and Quick exercise.
To learn more about Quick, check out the [Quick documentation.](https://quick.ortusbooks.com/)s
