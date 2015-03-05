import vm.lis.streamer.io {

	VMBuffer,
	IReadBuffer
}
import vm.lis.streamer {

	OutputStream,
	InputStream
}

void printIDs<Key>( {MyID<Key>*} ids )
		given Key satisfies Comparable<Key>
		{
	for ( id in ids ){
		print( "``id.key``: ``id.info``" );
	}
}

void restoreMyIDs( IReadBuffer buffer ) {
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring streamable objects from the stream
	// writing objects to the stream
	variable Integer msPrev = system.milliseconds;
	{MyID<String>*} stringID = inputStream.readOf<{MyID<String>*}>() else {};
	{MyID<Integer>*} integerID = inputStream.readOf<{MyID<Integer>*}>() else {};
	variable Integer msCur = system.milliseconds;
	print( "ID reading completed in ``msCur - msPrev`` ms, number of MyID<String> ``stringID.size``, number of MyID<Integer> ``integerID.size``" );
	
	/*printIDs( stringID );
	 print( "\n" );
	 printIDs( integerID );*/
}

IReadBuffer storeMyIDs( Integer count ) {
	// objects to be stored
	{MyID<String>*} stringID = { for( i in 0 : count )
		generateID<String>( i.string, "string parameter", "value = " + i.string ) };
	
	{MyID<Integer>*} integerID = { for( i in 0 : count )
		generateID<Integer>( i, "integer parameter", 10 * ( i + 1 ) ) };
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	// writing objects to the stream
	variable Integer msPrev = system.milliseconds;
	outputStream.write( stringID );
	outputStream.write( integerID );
	variable Integer msCur = system.milliseconds;
	print( "ID writing completed in ``msCur - msPrev`` ms" );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	return buffer;
}
