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
class Point2<Type>( x, y, z )
	given Type  of Float | Integer satisfies Object
{
	shared Type x;
	shared Type y;
	shared Type z;
	
	shared actual String string => "point = ``x`` ``y`` ``z``";
}

"point streamline.
 Not marked with stream annotation since several streamlines with different Type can be registered,
 instead use direct id specification when register.
 To be registered within [[streamer]]"
class PointSerializer2<Type>() extends StreamlineInitializer<Point2<Type>, [Type, Type, Type]>()
	given Type  of Float | Integer satisfies Object
{
	shared actual [Type, Type, Type] getArguments( Point2<Type> data ) {
		return [ data.x, data.y, data.z ];
	}
	
	shared actual Point2<Type>? instantiateWith( [Type, Type, Type] args ) {
		return Point2<Type>( args[0], args[1], args[2] );
	}
}

"example of streamer using to store / restore objects using initializer streamline"
shared void initializer2() {
	
	// initialize streamer at first
	streamer.initialize();

	// register streamlines
	streamer.registerStreamline( 1, PointSerializer2<Integer>() );
	streamer.registerStreamline( 2, PointSerializer2<Float>() );
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// write point to the stream
	outputStream.write( Point2( 1.1, 2.2, 3.3 ) );
	outputStream.write( Point2( 1, 2, 3 ) );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring points from the stream
	print( inputStream.readOf<Point2<Float>>() else "ooops! wrong reading" );
	print( inputStream.readOf<Point2<Integer>>() else "ooops! wrong reading" );
	
}