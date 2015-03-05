import vm.lis.streamer.io {

	VMBuffer,
	IReadBuffer,
	IExpandedBuffer
}
import vm.lis.streamer.streamline {

	logMessages,
	streamerStorage
}
import ceylon.collection {

	TreeMap
}
import ceylon.language.meta.model {

	Type
}


"reader of the stream:
 * when bytes added - reads sections to restore declarations
 * object section is copied into underlying [[IReadBuffer]]
 * if no underlying buffer provided for initializer, VMBuffer is used
"
by("Lisi")
class StreamFormatReader()
		extends StreamFormat()
		satisfies IExpandedBuffer, IReadBuffer
{
	"underlying buffer to store / restore data"
	shared actual VMBuffer dataBuffer = VMBuffer();
	
	"uncompleted buffer - with uncomplete section, waiting next data portion to store"
	VMBuffer uncompleteData = VMBuffer();
	"uncomplete section size"
	variable Integer uncompleteSectionSize = 0;
	
	"module id resolver => storedID->actualID"
	TreeMap<Integer, Integer> moduleResolver = TreeMap<Integer, Integer>(
		(Integer x, Integer y) => x.compare( y ) );
	
	"object reference resolver => storedID->object"
	TreeMap<Integer, Object> referenceResolver = TreeMap<Integer, Object>(
		(Integer x, Integer y) => x.compare( y ) ); 

	"number of modules read"
	variable Integer nModulesRead = 0;
	"number of declarations read"
	variable Integer nDeclarationsRead = 0;
	"number of objects read"
	variable Integer nObjectsRead = 0;
	
	"size to be expanded in bytes"
	variable Integer nExpandSize = 0;
	"actualy expanded bytes number"
	variable Integer nActualyExpanded = 0;
	
	"returns true if waits more bytes to be expanded, see [[expand]], so uncompleted bytes buffer has been read
	 and false if all possible has been expanded from previous buffers"
	shared Boolean waitsMoreBytes => nExpandSize != nActualyExpanded;
	
	
	shared actual Byte readByte() => dataBuffer.readByte();
	shared actual void skipBytes( Integer nBytes ) => dataBuffer.skipBytes( nBytes );
	shared actual void skipOctads( Integer nOctads ) => dataBuffer.skipOctads( nOctads );
	"doesn't make a copy of bytes - use shadow"
	shared actual {Byte*} readBytes( Integer nCount ) {
		{Byte*} ret = dataBuffer.shadow( dataBuffer.position, nCount );
		dataBuffer.position += nCount;
		return ret;
	}
	shared actual {Byte*} readUpToEnd() => dataBuffer.readUpToEnd();
	shared actual Integer readInteger() => dataBuffer.readInteger();
	shared actual Float readFloat() => dataBuffer.readFloat();
	shared actual String readUTF16String() => dataBuffer.readUTF16String();
	shared actual IReadBuffer shadow( Integer nStart, Integer nCount )
			=> dataBuffer.shadow( nStart, nCount );
	
	"remove data but keep declarations"
	shared void removeData() {
		dataBuffer.clear();
		uncompleteData.clear();
		streamer.debug( logMessages.streamRemovedData );
	}
	shared void clear() {
		clearStream();
		removeData();
	}
	
	"resolve module ID => replace stored module ID with actual one"
	shared Integer? resolveModuleID( Integer streamlineID ) {
		if ( exists actualModuleID = moduleResolver.get( streamerStorage.moduleIDFromCombinedID(
			streamlineID ) ) )
		{
			return streamerStorage.combineModuleStreamlineIDs( actualModuleID, streamlineID );
		}
		return null;
	}

	// reference resolver
	"get object by id or null if doesn't exists"
	shared Object? getObjectByReferenceID( Integer referenceID )
			=> referenceResolver.get( referenceID );
	"add object reference with id"
	shared void addObjectReference( Object obj, Integer referenceID )
			=> referenceResolver.put( referenceID, obj );
	
	"add bytes to the stream:
	 header section - performs checking if buffer is acceptable
	 declaration section - store declaration descriptions
	 object section - bytes are added to the buffer and, current read / write position is unchanged
	 returns number of read sections
	 if not whole section read - store unclomplete section data into dummy buffer and waits for the next data portion"
	shared actual void expand( IReadBuffer bytes ) {
		nModulesRead = 0;
		nDeclarationsRead = 0;
		nObjectsRead = 0;
		Integer nBytes = bytes.bytesAvailable + uncompleteData.bytesAvailable;
		if ( uncompleteData.size > 0 ) {
			Integer nPos = bytes.position;
			try {
				readUncomplete( bytes );
			}
			catch ( AssertionError e ) {
				streamer.fatal( e.message );
			}
			nActualyExpanded += bytes.position - nPos;
		}
		if ( bytes.bytesAvailable > 0 ) {
			Integer nPos = bytes.position;
			try {
				readSections( bytes );
			}
			catch ( AssertionError e ) {
				streamer.fatal( e.message );
			}
			nActualyExpanded += bytes.position - nPos;
		}
		streamer.debug( logMessages.expandingInputStream( nBytes - uncompleteData.size, uncompleteData.size,
			nExpandSize - nActualyExpanded, nModulesRead, nDeclarationsRead, nObjectsRead ) );
	}
	
	void readUncomplete( IReadBuffer bytes ) {
		if ( uncompleteData.size <= formatDefinitions.sectionDefinitionSize ) {
			// section size was not completely read at previous readings (addBytes)
			if ( bytes.bytesAvailable > formatDefinitions.sectionDefinitionSize
				- uncompleteData.size )
			{
				// write new bytes
				uncompleteData.writeBytes( bytes.readBytes(
					formatDefinitions.sectionDefinitionSize - uncompleteData.size ) );
				// read section size
				uncompleteData.flipStart();
				uncompleteData.skipBytes();
				uncompleteSectionSize = uncompleteData.readInteger();
				uncompleteData.flipEnd();
			}
			else {
				// section size still not completely read
				uncompleteData.writeBytes( bytes );
				bytes.position = bytes.size;
				return;
			}
		}
		if ( uncompleteSectionSize - uncompleteData.size > bytes.bytesAvailable ) {
			// still not whole section is available
			uncompleteData.writeBytes( bytes );
			bytes.position = bytes.size;
		}
		else {
			// read uncomplete data
			uncompleteData.flipStart();
			VMBuffer support = VMBuffer( uncompleteData );
			support.flipStart();
			uncompleteData.clear();
			support.position = support.size;
			// read bytes only for the uncompleted section
			Integer nRead = uncompleteSectionSize + formatDefinitions.sectionDefinitionSize - support.size;
			support.writeBytes( bytes.shadow( bytes.position, nRead ) );
			bytes.position += nRead;
			support.flipStart();
			readSections( support );
		}
	}
	
	void readSections( IReadBuffer bytes ) {
		// read sections
		uncompleteSectionSize = 0;
		while( readNextSection( bytes ) ) {}
		// if section is uncompleted - store it in uncompleteData buffer and wait next data portion
		if ( bytes.bytesAvailable > 0 ) {
			uncompleteData.writeBytes( bytes );
			bytes.flipEnd();
		}
	}
	
	Boolean readNextSection( IReadBuffer bytes ) {
		if ( bytes.bytesAvailable > formatDefinitions.sectionDefinitionSize ) {
			Byte sectionType = bytes.readByte();
			Integer sectionSize = bytes.readInteger();
			if ( sectionSize > bytes.bytesAvailable ) {
				uncompleteSectionSize = sectionSize;
				// not full section is available - add to uncompleted buffer and wait next data portion
				uncompleteData.writeByte( sectionType );
				uncompleteData.writeInteger( sectionSize );
			}
			else {
				if ( sectionSize > 0 ) {
					// read sections
					if ( sectionType == formatDefinitions.header ) {
						// read header section
						readHeaderSection( bytes );
					}
					else if ( sectionType == formatDefinitions.moduleResolve ) {
						// read declarations
						readModuleResolverSection( bytes );
					}
					else if ( sectionType == formatDefinitions.declarations ) {
						// read declarations
						readDeclarationSection( bytes );
					}
					else if ( sectionType == formatDefinitions.types ) {
						// read declarations
						readTypeSection( bytes );
					}
					else if ( sectionType == formatDefinitions.objects ) {
						// read objects
						readObjectSection( bytes, sectionSize );
					}
					else {
						// undefined section
						streamer.fatal( logMessages.incorrectBuffer );
						return false;
					}
				}
				return true;
			}
		}
		return false;
	}
	
	Boolean readHeaderSection( IReadBuffer bytes ) {
		// header section - check if header acceptable == streamer module name stored in buffer the same as here
		String streamerName = bytes.readUTF16String();
		if( streamerName != `value streamer`.containingModule.name ) {
			streamer.fatal( logMessages.incorrectBuffer );
			return false;
		}
		// total size to be expanded in bytes
		nExpandSize = bytes.readInteger();
		nActualyExpanded = 0;
		return true;
	}
	
	void readModuleResolverSection( IReadBuffer bytes ) {
		// section with module resolve id->name - restore it
		// number of modules
		nModulesRead = bytes.readInteger();
		// read modules id->name
		for (i in 0 : nModulesRead ) {
			Integer nModuleID = bytes.readInteger();
			if ( exists nActualID = streamerStorage.moduleIDByName( bytes.readUTF16String() ) ) {
				moduleResolver.put( nModuleID, nActualID );
			}
		}
	}
	
	void readDeclarationSection( IReadBuffer bytes ) {
		// section with declarations - restore it
		// number of declarations
		Integer nDeclarations = bytes.readInteger();
		// read declarations
		for (i in 0 : nDeclarations ) {
			addDeclaration( bytes.readInteger(), bytes.readUTF16String(),
				bytes.readUTF16String(), bytes.readUTF16String(), bytes.readUTF16String() );
		}
		nDeclarationsRead += nDeclarations;
	}
	
	void readTypeSection( IReadBuffer bytes ) {
		// section with types - restore it
		// number of types
		Integer nTypes = bytes.readInteger();
		// read declarations
		for (i in 0 : nTypes ) {
			Integer nID = bytes.readInteger();
			addType( nID, restoreTypeInfo( bytes ) );
		}
	}
	
	void readObjectSection( IReadBuffer bytes, Integer sectionSize ) {
		// section with objects - copy to buffer
		Integer nPos = dataBuffer.position;
		dataBuffer.position = dataBuffer.size;
		// add section type and size
		VMBuffer support = VMBuffer();
		support.writeByte( formatDefinitions.objects );
		support.writeInteger( sectionSize );
		support.flipStart();
		dataBuffer.expand( support );
		// add section bytes
		dataBuffer.expand( bytes.shadow( bytes.position, sectionSize ) );
		bytes.position += sectionSize;
		dataBuffer.position = nPos;
		nObjectsRead ++;
	}	
	
	Type[] restoreTypeSequence( IReadBuffer buffer ) {
		Integer nTypeArguments = buffer.readInteger();
		variable Type[] arguments = [];
		// read all types even if not exists to move buffer position into appropriate point
		for ( i in 0 : nTypeArguments ) {
			arguments = arguments.append( [restoreTypeInfo( buffer )] );
		}
		return arguments;
	}
	shared Type restoreTypeInfo( IReadBuffer buffer ) {
		Integer nType = buffer.readInteger();
		if ( nType == streamerStorage.typeIDs.idClass ) {
			return applyClass( buffer.readInteger(), restoreTypeSequence( buffer ) );
		}
		else if ( nType == streamerStorage.typeIDs.idRegistered ) {
			if ( exists t = streamerStorage.typeByID( buffer.readInteger() ) ) {
				return t;
			}
		}
		else if ( nType == streamerStorage.typeIDs.idUnion ) {
			restoreTypeSequence( buffer );
			// TODO: add type union when available
		}
		else if ( nType == streamerStorage.typeIDs.idIntersection) {
			restoreTypeSequence( buffer );
			// TODO: add type intersection when available
		}
		streamer.error( logMessages.incorrectRestoringType( nType ) );
		return `Nothing`;
	}
	
}
