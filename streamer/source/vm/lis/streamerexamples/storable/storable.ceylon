import vm.lis.streamer {
	
	streamer
}
import vm.lis.streamer.io {
	
	IReadBuffer,
	FileFlusher
}
import ceylon.file {

	current
}
import ceylon.io {

	newOpenFile
}


"example of storing / restoring objects with storable interface and factory streamline"
shared void storable() {
	
	// initialize streamer at first
	streamer.initialize();

	// register factory streamlines
	registerStreamlines();
	
	IReadBuffer buffer = storeCars();
	restoreCars( buffer );
	
	// store data to the file
	buffer.flipStart();
	FileFlusher file = FileFlusher( newOpenFile( current.childPath("cars.sds").resource ) );
	file.expand( buffer );

	// store / restore cars collection
	IReadBuffer bufferCollection = storeCarsCollection( 1000 );
	restoreCarsCollection( bufferCollection );

}
