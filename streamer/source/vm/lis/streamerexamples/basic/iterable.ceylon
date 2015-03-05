import vm.lis.streamer {
	
	OutputStream,
	InputStream,
	streamer
}
import vm.lis.streamer.io {
	
	VMBuffer
}
import ceylon.collection {

	ArrayList,
	LinkedList
}
import ceylon.json {
	
	JsonArray=Array
}



"example of streamer using to store / restore iterable"
shared void iterable() {
	
	// initialize streamer at first
	streamer.initialize();

	// iterables to be written
	value iterVal = { "this", "is", "streamer", "iterable", "example" };
	value iterValCompose = { {1, 2, 3}, {4, 5, 6}, {7, 8, 9} };
	// map
	value iterMap = { 1->2.2, 2->3.3, 3->4.4, 4->5.5, 6->7.7, 7->8.8, 8->9.9};
	// array list
	value arrayVal = ArrayList<String>( 0, 1.5, {"array", "list", " string", "collection", "example"} );
	// linked list
	value linkVal = LinkedList<JsonArray>( {
		JsonArray( { "John", 10 } ),
		JsonArray( { "Kenny", 14 } ),
		JsonArray( { "Lola", 12 } ),
		JsonArray( { "Renat", 8 } ),
		JsonArray( { "Dennis", 16 } ),
		JsonArray( { "Ian", 11 } )
		} );
	
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// writing objects to the stream
	outputStream.write( iterVal );
	outputStream.write( iterValCompose );
	outputStream.write( iterMap );
	outputStream.write( arrayVal );
	outputStream.write( linkVal );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring iterable object from the stream
	if ( exists readVal = inputStream.readOf<{String*}>() ) {
		print( "String collection is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	// read compose iterable
	if ( exists readVal = inputStream.readOf<{{Integer*}*}>() ) {
		print( "collection of collections is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	// read map
	if ( exists readVal = inputStream.readOf<{<Integer->Float>*}>() ) {
		print( "Integer->Float collection is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	// read array list
	if ( exists readVal = inputStream.readOf<ArrayList<String>>() ) {
		print( "ArrayList of Strings is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	// read map
	if ( exists readVal = inputStream.readOf<LinkedList<JsonArray>>() ) {
		print( "LinkedList of Json arrays is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}

}