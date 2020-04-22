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
