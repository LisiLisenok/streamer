import ceylon.language.meta {

	type
}
import ceylon.language.meta.model {

	Type,
	Class
}
import vm.lis.streamer {

	IOutputStreamline,
	IInputStreamline,
	StreamlineDeclaration
}

"store / restore [[Tuple]]"
by("Lisi")
shared object tupleStreamline extends StreamlineDeclaration()
{
	String tupleWithLeadingMethod = "withLeading";

	shared actual void write( IOutputStreamline stream, Anything data ) {
		if ( is Tuple<Anything, Anything, Anything[] | []> d = data ) { 
			// store first
			stream.output.write( d.first );
			// store rest
			stream.output.write( d.rest );
		}
	}
	
	shared actual Anything instantiate( IInputStreamline stream ) => null;

	shared actual Anything fill( IInputStreamline stream, Anything instance ) {		
		// restore first and rest
		Anything first = stream.input.read();
		Anything rest = stream.input.read();
		
		Type<Anything> typeFirst = type( first );
		// method withLeading is used in order to produce correct type of tuple 
		if ( exists rest, is Class typeRest = type( rest ) ) {
			if ( exists withLeadingMethod = getMethod<Anything>( rest, tupleWithLeadingMethod,
				[typeFirst] ) )
			{
				return withLeadingMethod.apply( first );
			}
		}
		return null;
	}
}