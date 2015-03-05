

"streamline for objects which can be restored just calling its initializer
 when storing - collection of arguments to be provided and stored
 each argument must have registered streamline (or be predefined one) - to store them into the stream"
by("Lisi")
shared abstract class StreamlineInitializer<DataType, Arguments>() satisfies IStreamline<DataType>
	given Arguments satisfies Anything[]
{
	"get arguments to be stored"
	shared formal Arguments getArguments( DataType data );
	"instantiate object using read arguments"
	shared formal DataType? instantiateWith( Arguments args );
	
	shared actual DataType? instantiate( IInputStreamline stream ) {
		if ( exists args = stream.input.readOf<Arguments>() ) {
			return instantiateWith( args );
		}
		return null;
	}
	
	shared actual DataType? fill( IInputStreamline stream, DataType? instance ) => instance;
	
	shared actual void write( IOutputStreamline stream, DataType data )
		=> stream.output.write( getArguments( data ) );

}
