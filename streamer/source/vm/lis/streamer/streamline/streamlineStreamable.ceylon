import ceylon.language.meta {
	
	type
}
import vm.lis.streamer {

	streamer,
	IStreamable,
	IInputStreamline,
	IOutputStreamline,
	StreamlineDeclaration
}


"store / restore items which satisfies [[IStreamable]] interface"
by("Lisi")
shared object streamableStreamline extends StreamlineDeclaration()
{
	shared actual void write( IOutputStreamline stream, Anything data ) {
		if ( is IStreamable streamable = data ) {
			// store type of stored object
			stream.writeOctad( stream.storeType( type( streamable ) ) );
			// initializer arguments
			value args = streamable.initializerArguments();
			// store number of arguments
			stream.writeOctad( args.size );
			// store arguments
			for ( arg in args ) {
				stream.output.write( arg );
			}
			// ask streamable to store additional information
			streamable.store( stream.output );
		}
	}

	shared actual Anything instantiate( IInputStreamline stream ) {
		Integer id = stream.readOctad();
		if ( exists t = stream.getType( id ) ) {
			// initializer arguments number
			Integer nArgs = stream.readOctad();
			// restore initializer arguments
			value arguments = [ for ( i in 0 : nArgs ) stream.input.read() ];
			// instantiate object
			return instantiateFrom( t, arguments );
		}
		else {
			streamer.error( logMessages.streamableNotClass( id ) );
			return null;
		}
	}

	shared actual Anything fill( IInputStreamline stream, Anything instance ) {
		if ( is IStreamable instance ) { instance.restore( stream.input ); }
		return instance;
	}
	
}