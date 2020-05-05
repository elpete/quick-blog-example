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

		post( "/posts/:postId/comments", "PostComments.create" );
		resources( resource = "posts", parameterName = "postId" );

		// Conventions based routing
		route( ":handler/:action?" ).end();
	}

}
