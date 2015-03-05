import vm.lis.streamer.streamline {

	streamerStorage,
	logMessages
}
import vm.lis.streamer.io {

	IReadBuffer
}
import ceylon.language.meta.model {

	Type
}

"implementation of [[IInputBuffer]]
 provides [[IInputStream]] interface when asked
 and [[IInputStreamline]] interface when works with streamlines"
by("Lisi")
shared class InputStream( "initial bytes pushed to the stream" IReadBuffer? data = null )
		satisfies IInputBuffer
{
	"buffer with objects and declarations, all read operations delegate to"
	StreamFormatReader buffer = StreamFormatReader();
	if ( exists data ) { buffer.expand( data ); }
	
	variable Integer nReadOperations = 0;
	variable Integer nSectionSize = 0;
	variable Integer nSectionStart = 0;
	
	"returns true if waits more bytes to be expanded, see [[expand]], so uncompleted bytes buffer has been read
	 and false if all possible bytes have been expanded from previous buffers"
	shared Boolean waitsMoreBytes => buffer.waitsMoreBytes;
	
	shared actual Integer bytesAvailable => buffer.bytesAvailable;
	
	"IInputStreamline behind this stream, used within streamlines to store objects"
	object streamLine satisfies IInputStreamline {
		shared actual {Byte*} bytes() => buffer;
		shared actual Byte readByte() => buffer.readByte();
		shared actual {Byte*} readBytes( Integer nCount ) => buffer.readBytes( nCount );
		shared actual {Byte*} readUpToEnd() => buffer.readUpToEnd();
		shared actual Integer readOctad() => buffer.readInteger();
		shared actual Integer readLowerBytes( Integer nBytes ) => buffer.readLowerBytes( nBytes );
		
		shared actual IInputStream input => outer;
		
		shared actual Type<Anything>? getType( Integer id ) => buffer.getType( id );
		
		shared actual Object? getObjectByReferenceID( Integer referenceID )
				=> buffer.getObjectByReferenceID( referenceID );
		
		shared actual void addObjectReference( Object obj, Integer referenceID )
				=> buffer.addObjectReference( obj, referenceID );
	}
	
	shared actual Anything read() {
		if ( nReadOperations == 0 ) {
			// skip bytes with section type and section size
			if ( buffer.bytesAvailable > formatDefinitions.sectionDefinitionSize ) {
				if ( buffer.readByte() != formatDefinitions.objects ) {
					// this not object section!
					streamer.error( logMessages.incorrectBuffer );
					return null;
				}
				nSectionSize = buffer.readInteger();
				if ( nSectionSize > buffer.bytesAvailable ) {
					// insufficient bytes to read the section
					streamer.error( logMessages.insufficientBytes( nSectionSize, buffer.bytesAvailable ) );
					buffer.flipEnd();
					return null;
				}
				nSectionStart = buffer.position;
			}
			else {
				// insufficient bytes - incorrect buffer
				buffer.flipEnd();
				streamer.error( logMessages.incorrectBuffer );
				return null;
			}
		}
		if ( buffer.bytesAvailable >= streamerStorage.bytesInCombinedID ) {
			// stremlineID - resolve module ID, reads just meaningful bytes
			if( exists streamlineID = buffer.resolveModuleID( buffer.readLowerBytes(
				streamerStorage.bytesInCombinedID ) ) )
			{
				if ( exists streamline = streamerStorage.streamlineGeneralByID( streamlineID ) ) {
					nReadOperations ++;
					Anything ret = streamline.readAny( streamLine );
					nReadOperations --;
					if ( nReadOperations == 0 && buffer.position - nSectionStart != nSectionSize ) {
						streamer.warn( logMessages.objectUncompleteRead( nSectionStart,
							buffer.position - nSectionStart ) );
						buffer.position = nSectionSize + nSectionStart;
					}
					return ret;
				}
			}
			else {
				// stremaline not found - shift the section
				buffer.position = nSectionSize + nSectionStart;
			}
		}
		else {
			// insufficient bytes - incorrect buffer
			buffer.flipEnd();
			streamer.error( logMessages.incorrectBuffer );
		}
		return null;
	}
	
	shared actual DataType? readOf<DataType>() {
		if ( is DataType t = read() ) {
			return t;
		}
		streamer.error( logMessages.objectNotRead( `DataType` ) );
		return null;
	}
	
	shared actual void expand( IReadBuffer addingBytes ) {
		buffer.expand( addingBytes );
	}
	
	shared actual void removeData() {
		nReadOperations = 0;
		buffer.removeData();
	}
	shared actual void clear() {
		nReadOperations = 0;
		buffer.clear();
	}	
	shared actual void flip() {
		nReadOperations = 0;
		buffer.flipStart();
	}
	
}
