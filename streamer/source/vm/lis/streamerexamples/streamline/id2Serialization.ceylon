import vm.lis.streamer.io {

	VMBuffer,
	IReadBuffer
}
import vm.lis.streamer {

	OutputStream,
	InputStream
}

void printID2s<Key>( {MyID2<Key>*} ids )
		given Key satisfies Comparable<Key>
{
	for ( id in ids ) {
		print( "``id.key``: ``id.info``" );
	}
}

IReadBuffer storeMyID2s( Integer count ) {
	// objects to be stored
	{MyID2<String>*} stringID = { for( i in 0 : count )
		generateID2<String>( i.string, "string parameter", "value = " + i.string ) };
	
	{MyID2<Integer>*} integerID = { for( i in 0 : count )
		generateID2<Integer>( i, "integer parameter", 10 * ( i + 1 ) ) };
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	// writing objects to the stream
	variable Integer msPrev = system.milliseconds;
	outputStream.write( stringID );
	outputStream.write( integerID );
	variable Integer msCur = system.milliseconds;
	print( "ID2 writing completed in ``msCur - msPrev`` ms" );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	return buffer;
}


void restoreMyID2s( IReadBuffer buffer ) {
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring streamable objects from the stream
	// writing objects to the stream
	variable Integer msPrev = system.milliseconds;
	{MyID2<String>*} stringID = inputStream.readOf<{MyID2<String>*}>() else {};
	{MyID2<Integer>*} integerID = inputStream.readOf<{MyID2<Integer>*}>() else {};
	variable Integer msCur = system.milliseconds;
	print( "ID2 reading completed in ``msCur - msPrev`` ms, number of MyID2<String> ``stringID.size``, number of MyID2<Integer> ``integerID.size``" );
	
	/*printID2s( stringID );
	 print( "\n" );
	 printID2s( integerID );*/
}

