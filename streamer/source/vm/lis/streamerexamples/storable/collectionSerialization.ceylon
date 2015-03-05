import vm.lis.streamer.io {

	VMBuffer,
	IReadBuffer
}
import vm.lis.streamer {

	OutputStream,
	InputStream
}

Truck createTruck( Integer i ) {
	Truck ret = Truck( 100.0 * i );
	ret.tire = WinterTire( "Pirelli", 0 );
	return ret;
}

IReadBuffer storeCarsCollection( Integer nCount ) {
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// write objects to the stream
	{Truck*} cars = { for ( i in 0 : nCount ) createTruck( i ) };
	
	variable Integer msPrev = system.milliseconds;
	outputStream.write( cars );
	variable Integer msCur = system.milliseconds;
	print( "\ncollection writing is completed in ``msCur - msPrev`` ms" );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	return buffer;
	
}

void restoreCarsCollection( IReadBuffer buffer ) {
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring streamable objects from the stream
	variable Integer msPrev = system.milliseconds;
	{Car*} cars = inputStream.readOf<{Car*}>() else {};
	variable Integer msCur = system.milliseconds;
	print( "collection reading is completed in ``msCur - msPrev`` ms" );
	print( "cars number ``cars.size``" );
}

