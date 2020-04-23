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
