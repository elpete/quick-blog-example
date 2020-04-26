component{

	function configure(){
		// Set Full Rewrites
		setFullRewrites( true );

		/**
		 * --------------------------------------------------------------------------
		 * App Routes
		 * --------------------------------------------------------------------------
		 *
		 * Here is where you can register the routes for your web application!
		 * Go get Funky!
		 *
		 */

		// A nice healthcheck route example
		route("/healthcheck",function(event,rc,prc){
			return "Ok!";
		});

		// A nice RESTFul Route example
		route( "/api/echo", function( event, rc, prc ){
			return {
				"error" : false,
				"data" 	: "Welcome to my awesome API!"
			};
		} );

		get( "/posts/new", "Posts.new" );
		get( "/posts/:postId", "Posts.show" );
		route( "/posts" ).withHandler( "Posts" ).toAction( { "GET": "index", "POST": "create" } );

		// Conventions based routing
		route( ":handler/:action?" ).end();
	}

}
