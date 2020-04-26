component {

	function index( event, rc, prc ) {
		prc.posts = getInstance( "Post" ).all();
		event.setView( "posts/index" );
	}

	function show( event, rc, prc ) {
		prc.post = getInstance( "Post" ).findOrFail( rc.postId );
		event.setView( "posts/show" );
	}

	function new( event, rc, prc ) {
		prc.post = getInstance( "Post" );
		event.setView( "posts/new" );
	}

	function create( event, rc, prc ) {
		getInstance( "Post" ).create( {
			"title": rc.title,
			"body": rc.body,
		} );
		relocate( "posts" );
	}

	function edit( event, rc, prc ) {
		prc.post = getInstance( "Post" ).findOrFail( rc.postId );
		event.setView( "posts/edit" );
	}

	function update( event, rc, prc ) {
		var post = getInstance( "Post" ).findOrFail( rc.postId );
		post.update( {
			"title": rc.title,
			"body": rc.body
		} );
		relocate( "posts.#post.getId()#" );
	}

	function delete( event, rc, prc ) {
		var post = getInstance( "Post" ).findOrFail( rc.postId );
		post.delete();
		relocate( "posts" );
	}

}
