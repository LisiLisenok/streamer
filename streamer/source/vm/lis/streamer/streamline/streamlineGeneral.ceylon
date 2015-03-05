import vm.lis.streamer {

	IOutputStreamline,
	IInputStreamline,
	IStreamline,
	streamer,
	IStreamlineDeclaration
}
import ceylon.language.meta.model {

	IncompatibleTypeException,
	TypeApplicationException
}


"general streamline - used internaly, doesn't specify type of serialized item"
by("Lisi")
shared interface IStreamlineGeneral
{
	"write object to output stream"
	shared formal void writeAny( IOutputStreamline stream, Anything data );
	"read object from input stream"
	shared formal Anything readAny( IInputStreamline stream );
}

// next classes used internaly in streamerStorage in order to provide general treatment for any
// streamline types and store serializer ID before storing items and referenceresolve id

"base streamline"
by("Lisi")
abstract class StreamlineBase( streamlineType, resolveReference ) satisfies IStreamlineGeneral
{
	Integer streamlineType;
	shared Boolean resolveReference;
	
	shared actual default void writeAny( IOutputStreamline stream, Anything data ) {
		// resolve reference
		if ( exists data ) {
			// write just meaningful bytes of the id
			stream.writeLowerBytes( streamerStorage.bytesInCombinedID, streamlineType );
			if ( resolveReference ) {
				if ( exists referenceID = stream.getReferenceID( data ) ) {
					// reference exists - store just id
					stream.writeOctad( referenceID );
				}
				else {
					// not stored, store reference id + object
					stream.writeOctad( stream.storeReference( data ) );
					doWrite( stream, data );
				}
			}
			else { doWrite( stream, data ); }
		}
	}
	
	shared actual Anything readAny( IInputStreamline stream ) {
		try {
			if ( resolveReference ) {
				Integer referenceID = stream.readOctad();
				if ( exists obj = stream.getObjectByReferenceID( referenceID ) ) {
					// object has been read early - return it
					return obj;
				}
				else {
					// instantiate and read object
					Anything instance = instantiate( stream );
					if ( exists instance ) { stream.addObjectReference( instance, referenceID ); }
					return doRead( stream, instance );
				}
			}
			else { return doRead( stream, null ); }
		}
		// log an error
		catch ( IncompatibleTypeException e ) {
			streamer.fatal( e.message, e );
		}
		catch ( TypeApplicationException e ) {
			streamer.fatal( e.message, e );
		}
		catch ( AssertionError e ) {
			streamer.fatal( e.message );
		}
		return null;
	}
	
	shared formal void doWrite( IOutputStreamline stream, Anything data );
	shared formal Anything instantiate( IInputStreamline stream );
	shared formal Anything doRead( IInputStreamline stream, Anything instance );
	
}


"base streamline extension on declaration streamline"
by("Lisi")
class StreamlineDeclaratonBase( streamline, Integer streamlineType, Boolean resolveReference )
		extends StreamlineBase( streamlineType, resolveReference )
{
	IStreamlineDeclaration streamline;
	
	shared actual void doWrite( IOutputStreamline stream, Anything data ) 
		=> streamline.write( stream, data );
	
	shared actual Anything doRead( IInputStreamline stream, Anything instance ) 
		=> streamline.fill( stream, instance );
	
	shared actual Anything instantiate( IInputStreamline stream )
		=> streamline.instantiate( stream );
	
}

"base streamline extension on typed streamline"
by("Lisi")
class StreamlineTypeBase<DataType>( streamline, Integer streamlineType, Boolean resolveReference )
		extends StreamlineBase( streamlineType, resolveReference )
{
	IStreamline<DataType> streamline;

	shared actual void doWrite( IOutputStreamline stream, Anything data ) {
		if ( is DataType data ) { streamline.write( stream, data ); }
	}
	
	shared actual Anything doRead( IInputStreamline stream, Anything instance ) {
		if ( is DataType instance ) { return streamline.fill( stream, instance ); }
		else { return streamline.fill( stream, null ); }
	}
	
	shared actual Anything instantiate( IInputStreamline stream )
			=> streamline.instantiate( stream );
}


