import ceylon.logging {

	info,
	addLogWriter,
	Priority,
	LogCategory=Category,
	debug
}
import ceylon.file {

	current,
	Nil,
	Resource,
	File
}
import vm.lis.streamer {

	FileLogWriter,
	streamer,
	OutputStream,
	InputStream
}
import vm.lis.streamer.io {

	VMBuffer
}

"streamer logging"
shared void logging() {
	
	// initialize streamer at first
	streamer.initialize();

	// log to file
	Resource res = current.childPath("streamer.log").resource;
	if (is File file = res ) {
		addLogWriter( FileLogWriter( file ).logWriter );		
	}
	else if ( is Nil file = res ) {
		addLogWriter( FileLogWriter( file ).logWriter );
	}
	
	// log to console
	addLogWriter {
		log = void (Priority p, LogCategory c, String m, Exception? e) {
			value print = p <= info then process.writeLine else process.writeError;
			print("[``system.milliseconds``] ``p.string`` ``m``");
			if (exists e) { printStackTrace(e, print); }
		};
	};
	
	// log priority - play with trace, debug or info
	streamer.priority = debug;
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// write something
	outputStream.write( 2 );
	outputStream.write( -3856287 );
	outputStream.write( -2871.125 );
	outputStream.write( "logging example" );
	outputStream.write( 2.3 );
	
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	InputStream inputStream = InputStream();
	inputStream.expand( buffer );
	
	// reading - put comments on some lines or modify types at inspect results
	print( inputStream.readOf<Integer>()?.string );
	print( inputStream.readOf<Integer>()?.string );
	print( inputStream.readOf<Float>()?.string );
	print( inputStream.readOf<String>() );
	print( inputStream.readOf<Float>()?.string );
	//print( inputStream.readOf<Float>()?.string );
	
}