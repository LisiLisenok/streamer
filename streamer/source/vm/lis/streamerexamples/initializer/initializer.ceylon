import vm.lis.streamer {
	
	OutputStream,
	InputStream,
	StreamlineInitializer,
	streamer
}
import vm.lis.streamer.io {
	
	VMBuffer
}


"class to be serialized - just initializer arguments to be serialized"
class Point( x, y, z )
{
	shared Float x;
	shared Float y;
	shared Float z;
	
	shared actual String string => "point = ``x`` ``y`` ``z``";
}

"point streamline.
 Marked with stream annotation with streamline id.
 To be registered within [[streamer]]"
class PointSerializer() extends StreamlineInitializer<Point, [Float, Float, Float]>()
{
	shared actual [Float, Float, Float] getArguments( Point data ) {
		return [ data.x, data.y, data.z ];
	}
	
	shared actual Point? instantiateWith( [Float, Float, Float] args ) {
		return Point( args[0], args[1], args[2] );
	}
}

"example of streamer using to store / restore objects using initializer streamline"
shared void initializer() {
	
	// initialize streamer at first
	streamer.initialize();

	// register streamline
	streamer.registerStreamline( 3, PointSerializer() );
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// write point to the stream
	outputStream.write( Point( 1.1, 2.2, 3.3 ) );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring point from the stream
	print( inputStream.readOf<Point>() else "ooops! wrong reading" );
	
}