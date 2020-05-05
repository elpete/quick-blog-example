component {

	function create( event, rc, prc ) {
        getInstance( "Comment" ).create( {
            "postId": rc.postId,
            "body": rc.body
        } );
        relocate( "posts.#rc.postId#" );
	}

}
