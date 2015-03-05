import vm.lis.streamer {
	
	OutputStream,
	InputStream,
	streamer
}
import vm.lis.streamer.io {
	
	VMBuffer
}


"example of streamer using to store / restore iterable"
shared void longiterable() {
	
	streamer.initialize();

	Integer count = 20000;
	
	// iterables to be written
	value iterVal = { for( i in 0 : count ) 2 };
	

	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	print( "start writing" );
	// writing objects to the stream
	variable Integer msPrev = system.milliseconds;
	outputStream.write( iterVal );
	variable Integer msCur = system.milliseconds;
	print( "writing completed in ``msCur - msPrev`` ms" );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	msPrev = system.milliseconds;
	outputStream.flushTo( buffer );
	msCur = system.milliseconds;
	print( "flushing completed in ``msCur - msPrev`` ms" );
	
	msPrev = system.milliseconds;
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	msCur = system.milliseconds;
	print( "expanding completed in ``msCur - msPrev``, total bytes ``buffer.size``" );
	
	// restoring iterable object from the stream
	variable Integer n = 0;
	msPrev = system.milliseconds;
	if ( exists readVal = inputStream.readOf<{Integer*}>() ) {
		msCur = system.milliseconds;
		print( "reading completed in ``msCur - msPrev`` ms, number of read element ``readVal.size`` first element ``readVal.first else ""``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	VMBuffer buf = VMBuffer();
	msPrev = system.milliseconds;
	for ( i in 0 : count ) {
		buf.writeInteger( 2 );
	}
	msCur = system.milliseconds;
	print( "buffer writing time = ``msCur - msPrev`` ms" );
	
	msPrev = system.milliseconds;
	n = 0;
	for ( i in 0 : count ) {
		n = buf.readInteger();
	}
	msCur = system.milliseconds;
	print( "buffer readng time = ``msCur - msPrev`` ms, buffer size is ``buf.size``" );
	
}