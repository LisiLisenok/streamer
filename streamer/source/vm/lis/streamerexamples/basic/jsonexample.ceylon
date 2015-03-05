import vm.lis.streamer {
	
	OutputStream,
	InputStream,
	streamer
}
import vm.lis.streamer.io {
	
	VMBuffer
}
import ceylon.json {

	JsonObject=Object,
	JsonArray=Array
}

"example of streamer using to store / restore JSON object and array, see [[module ceylon.json]]"
shared void jsonexample() {
	
	// initialize streamer at first
	streamer.initialize();

	// json object to be written
	JsonObject jsonObject = JsonObject( {
		"name"-> "Adam",
		"id" -> 10,
		"additional" -> JsonArray( { "car", "house" } ),
		"parameters" -> JsonObject( { "greater" -> 2, "less" -> 4 } ),
		"weight" -> 34.5
	} );
	
	// json array
	JsonArray jsonArray = JsonArray( { "name", 10, 0.5, "title" } );
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// writing json objects to the stream
	outputStream.write( jsonObject );
	outputStream.write( jsonArray );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring json object and json array object from the stream
	if ( exists readJsonObject = inputStream.readOf<JsonObject>() ) {
		print( readJsonObject );
	}
	if ( exists readJsonArray = inputStream.readOf<JsonArray>() ) {
		print( readJsonArray );
	}
	
}