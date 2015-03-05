import vm.lis.streamer.streamline {

	streamerStorage
}
import vm.lis.streamer.io {

	IExpandedBuffer,
	bufferConstants
}
import ceylon.language.meta.model {

	ClassOrInterface
}


"implementation of [[IOutputBuffer]]
 provides [[IOutputStream]] interface when asked
 and [[IOutputStreamline]] interface when works with streamlines"
by("Lisi")
shared class OutputStream() satisfies IOutputBuffer
{
	"buffer with objects and declarations, all write operations delegate to"
	StreamFormatWriter buffer = StreamFormatWriter();
	
	variable Integer nWriteOperations = 0;
	variable Integer nSectionPosition = 0;
	
	"outputStreamline behind this stream, used within streamlines to store objects information"
	object streamLine satisfies IOutputStreamline {
		shared actual void writeByte( Byte byte ) => buffer.writeByte( byte );
		shared actual void writeBytes( {Byte*} bytes ) => buffer.writeBytes( bytes );
		shared actual void writeOctad( Integer octad ) => buffer.writeInteger( octad );
		shared actual void writeLowerBytes( Integer nBytes, Integer octad )
				=> buffer.writeLowerBytes( nBytes, octad );
		shared actual IOutputStream output => outer;
		
		shared actual Integer? getReferenceID( Object obj ) => buffer.getReferenceID( obj );
		
		shared actual Integer storeReference( Object obj ) => buffer.storeReference( obj );
		
		shared actual Integer storeType( ClassOrInterface instanceType ) => buffer.storeType( instanceType );
	}
	
	
	shared actual void write( Anything data ) {
		if ( exists streamlineID = streamerStorage.streamlineIDByInstance( data ),
			exists streamline = streamerStorage.streamlineGeneralByID( streamlineID ) ) {
			// store streamline module
			buffer.storeStreamlineModule( streamlineID );
			// start section if not already started
			if ( nWriteOperations == 0 ) {
				// store section position
				buffer.writeByte( formatDefinitions.objects );
				nSectionPosition = buffer.position;
				buffer.writeInteger( 0 );
			}
			// store object
			nWriteOperations ++;
			streamline.writeAny( streamLine, data );
			nWriteOperations --;
			// complete section
			if ( nWriteOperations == 0 ) {
				// store number of written bytes
				Integer nWrittenBytes = buffer.size - nSectionPosition - bufferConstants.bytesInInteger;
				buffer.position = nSectionPosition;
				buffer.writeInteger( nWrittenBytes );
				buffer.position = buffer.size;
				//streamer.trace( logMessages.objectWritten( type( data ), nWrittenBytes ) );
			}
		}
	}
	
	"flush - write stream (declarations + objects) into the byte buffer.
	 underlying buffer stays unchanged"
	shared actual void flushTo( IExpandedBuffer readBuffer ) => buffer.flushTo( readBuffer );
	
}

