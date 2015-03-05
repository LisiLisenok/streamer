import ceylon.language.meta {

	type
}
import vm.lis.streamer {

	IOutputStreamline,
	IInputStreamline,
	StreamlineDeclaration
}


"store / restore [[Entry]]"
by("Lisi")
shared object entryStreamline extends StreamlineDeclaration()
{
	shared actual void write( IOutputStreamline stream, Anything data ) {
		if ( is Entry<Object, Anything> d = data ) {
			Integer n = stream.storeType( type( d ) );
			stream.writeOctad( n );
			stream.output.write( d.key );
			stream.output.write( d.item );
		}
	}
	
	shared actual Anything instantiate( IInputStreamline stream ) => null;
	
	shared actual Anything fill( IInputStreamline stream, Anything instance ) {
		Integer typeID = stream.readOctad();
		Anything key = stream.input.read();
		Anything item = stream.input.read();
		if ( exists t = stream.getType( typeID ) ) {
			return instantiateFrom( t, [key, item] );
		}
		return null;
	}
}