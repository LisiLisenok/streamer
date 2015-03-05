import vm.lis.streamer.io {

	VMBuffer,
	IReadBuffer
}
import vm.lis.streamer {

	OutputStream,
	InputStream
}


shared void restoreCars( IReadBuffer buffer ) {
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring streamable objects from the stream
	print( inputStream.readOf<Car>() else "ooops! wrong reading" );
	print( inputStream.readOf<Car>() else "ooops! wrong reading" );
	print( inputStream.readOf<Car>() else "ooops! wrong reading" );	
	print( inputStream.readOf<Car>() else "ooops! wrong reading" );	
	print( inputStream.readOf<Car>() else "ooops! wrong reading" );	
	print( inputStream.readOf<Car>() else "ooops! wrong reading" );	
}


shared IReadBuffer storeCars() {
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// objects to be serialized
	Truck truck1 = Truck( 1000.0 );
	truck1.tire = WinterTire( "Bridgestone", 100, true );
	Truck truck2 = Truck( 10000.0 );
	truck2.tire = SummerTire( "Michelin", 120, "hard" );
	Spider spider1 = Spider( 2 );
	spider1.tire = SummerTire( "Michelin", 200, "soft", true );
	Spider spider2 = Spider( 2 );
	spider2.tire = truck2.tire;
	Spider spider3 = Spider( 2 );
	spider3.tire = truck1.tire;
	Spider spider4 = Spider( 2 );
	spider4.tire = spider1.tire;
	
	// write objects to the stream	
	outputStream.write( spider1 );
	outputStream.write( truck1 );
	outputStream.write( truck2 );
	outputStream.write( spider2 );
	outputStream.write( spider3 );
	outputStream.write( spider4 );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	return buffer;
}