import vm.lis.streamer.io {

	VMBuffer,
	IWriteBuffer,
	bufferConstants,
	IExpandedBuffer
}
import vm.lis.streamer.streamline {

	logMessages,
	streamerStorage
}
import ceylon.collection {

	TreeMap,
	LinkedList
}
import ceylon.language.meta.model {

	Type,
	ClassOrInterface,
	UnionType,
	IntersectionType
}


"writer to the stream:
 * declaration section stored separetly using StreamFormat 
 * object section is stored in underlying [[VMBuffer]]
 * call flush to store data in streamer format into IExpandedBuffer - see [[IExpandedBuffer.expand]]:
 	* header section
 	* declaration section
 	* object sections
 "
by("Lisi")
class StreamFormatWriter() extends StreamFormat() satisfies IWriteBuffer
{
	"underlying buffer to store / restore data"
	shared actual IWriteBuffer dataBuffer = VMBuffer();
	
	"module id->name resolver"
	TreeMap<Integer, String> actualModules = TreeMap<Integer, String>(
		(Integer x, Integer y) => x.compare( y ) );
		
	"id of last added reference resolver"
	variable Integer lastResolverID = 0;
	"reference resolver item"
	class ResolverItem( obj, id ) {
		shared Object obj;
		shared Integer id;
	}
	
	"reference resolver"
	TreeMap<Integer, LinkedList<ResolverItem>> referenceResolver = TreeMap<Integer, LinkedList<ResolverItem>>(
		(Integer x, Integer y) => x.compare( y ) ); 
	
	"add module id by streamline id"
	shared void storeStreamlineModule( Integer streamlineID ) {
		Integer moduleID = streamerStorage.moduleIDFromCombinedID( streamlineID );
		if ( !actualModules.defines( moduleID ) ) {
			if ( exists moduleName = streamerStorage.moduleTotalNameFromID( moduleID ) ) {
				actualModules.put( moduleID, moduleName );
			}
		}
	}
	
	// reference resolve
	
	shared Integer? getReferenceID( Object obj ) {
		if ( exists list = referenceResolver.get( obj.hash ) ) {
			for( elem in list ) {
				if ( elem.obj == obj ) {
					return elem.id;
				}
			}
		}
		return null;
	}
	
	shared Integer storeReference( Object obj ) {
		lastResolverID ++;
		if ( exists list = referenceResolver.get( obj.hash ) ) {
			list.add( ResolverItem( obj, lastResolverID ) );
		}
		else {
			referenceResolver.put( obj.hash, LinkedList<ResolverItem>(
				{ResolverItem( obj, lastResolverID )} ) );
		}
		return lastResolverID;
	}
		
	"write a byte to the buffer"
	shared actual void writeByte( Byte byte ) => dataBuffer.writeByte( byte );
	shared actual void writeBytes( {Byte*} bytes ) => dataBuffer.writeBytes( bytes );
	shared actual void writeInteger( Integer octad ) => dataBuffer.writeInteger( octad );
	shared actual void writeFloat( Float f ) => dataBuffer.writeFloat( f );
	shared actual void writeUTF16String( String str ) => dataBuffer.writeUTF16String( str );

	"flush - write data into the read buffer"
	shared actual void flushTo( IExpandedBuffer buffer ) {
		Integer nDeclarations = declarations.size;
		VMBuffer flushBuffer = VMBuffer( null, dataBuffer.size + nDeclarations * 64 );
		// header section: id + section size + streamer module name
		flushBuffer.writeByte( formatDefinitions.header );
		variable Integer nPos = flushBuffer.position; 
		flushBuffer.writeInteger( 0 );
		// streamer mark
		flushBuffer.writeUTF16String( `value streamer`.containingModule.name );
		// total buffer size in bytes
		Integer nTotalSizePos = flushBuffer.position; 
		flushBuffer.writeInteger( 0 );
		// header section size
		variable Integer nBytes = flushBuffer.size - nPos - bufferConstants.bytesInInteger;
		flushBuffer.position = nPos;
		flushBuffer.writeInteger( nBytes );
		flushBuffer.flipEnd();
		Integer nHeaderSize = flushBuffer.size;
		
		// module id resolver section
		flushBuffer.writeByte( formatDefinitions.moduleResolve );
		nPos = flushBuffer.position;
		flushBuffer.writeInteger( 0 );
		Integer nModules = actualModules.size;
		flushBuffer.writeInteger( nModules );
		for ( key->item in actualModules ) {
			flushBuffer.writeInteger( key );
			flushBuffer.writeUTF16String( item );
		}
		nBytes = flushBuffer.size - nPos - bufferConstants.bytesInInteger;
		flushBuffer.position = nPos;
		flushBuffer.writeInteger( nBytes );
		flushBuffer.flipEnd();
				
		// declaration section: id + section size + number of declarations + declarations:
		// Integer declrationID, String module, String module version, String package, String declaration name
		flushBuffer.writeByte( formatDefinitions.declarations );
		nPos = flushBuffer.position;
		flushBuffer.writeInteger( 0 );
		flushBuffer.writeInteger( nDeclarations );
		for ( key->declaration in declarations ) {
			flushBuffer.writeInteger( key );
			flushBuffer.writeUTF16String( declaration.containingModule.name );
			flushBuffer.writeUTF16String( declaration.containingModule.version );
			flushBuffer.writeUTF16String( declaration.containingPackage.name );
			flushBuffer.writeUTF16String( declaration.name );
		}
		nBytes = flushBuffer.size - nPos - bufferConstants.bytesInInteger;
		flushBuffer.position = nPos;
		flushBuffer.writeInteger( nBytes );
		flushBuffer.flipEnd();
		Integer nDeclarationsSize = flushBuffer.size - nHeaderSize;
		
		// types section: types number, for each type: id + type description
		flushBuffer.writeByte( formatDefinitions.types );
		nPos = flushBuffer.position;
		flushBuffer.writeInteger( 0 );
		{<Integer->Type>*} types = classes;
		Integer nTypes = types.size;
		flushBuffer.writeInteger( nTypes );
		for( key->item in types ) {
			flushBuffer.writeInteger( key );
			storeTypeInfo( flushBuffer, item );
		}
		nBytes = flushBuffer.size - nPos - bufferConstants.bytesInInteger;
		flushBuffer.position = nPos;
		flushBuffer.writeInteger( nBytes );
		flushBuffer.flipEnd();
		Integer nTypesSize = flushBuffer.size - nDeclarationsSize;
		
		// put stored bytes
		nPos = dataBuffer.position;
		dataBuffer.flipStart();
		flushBuffer.writeBytes( dataBuffer );
		// store actual size in bytes
		flushBuffer.position = nTotalSizePos;
		flushBuffer.writeInteger( flushBuffer.size );
		flushBuffer.flipStart();
		// expand bytes on the flushed buffer
		dataBuffer.position = nPos;
		buffer.expand( flushBuffer );
		
		streamer.debug( logMessages.flushingOutputStream( nHeaderSize, nModules, nDeclarations,
			nDeclarationsSize, nTypes, nTypesSize, flushBuffer.size - nHeaderSize - nDeclarationsSize - nTypesSize ) );
		
	}
	
	"store info about type: info id + type id + the same for each type argument typeArguments"
	void storeTypeInfo( IWriteBuffer buffer, Type dataType ) {
		if ( exists id = streamerStorage.idByType( dataType ) ) {
			if ( streamerStorage.isDeclaration( id ) ) {
				// declaration
				storeDeclaration( buffer, dataType );
			}
			else {
				// builtin types
				buffer.writeInteger( streamerStorage.typeIDs.idRegistered );
				buffer.writeInteger( id );
			}
		}
		else {
			// store declaration if nothing found
			storeDeclaration( buffer, dataType );
		}
	}
	
	"store type info for collection"
	void storeTypeSequence( IWriteBuffer buffer, {Type*} dataTypes ) {
		buffer.writeInteger( dataTypes.size );
		for ( arg in dataTypes ) {
			storeTypeInfo( buffer, arg );
		}
	}
	"store declaration parameters"
	void storeDeclaration( IWriteBuffer buffer, Type dataType ) {
		if ( is ClassOrInterface dataType ) {
			if ( exists nID = idByDeclaration( dataType.declaration ) ) {
				buffer.writeInteger( streamerStorage.typeIDs.idClass );
				buffer.writeInteger( nID );
				storeTypeSequence( buffer, dataType.typeArguments.items );
			}
			else {
				buffer.writeInteger( streamerStorage.typeIDs.idUnknown );
			}
		}
		else if ( is UnionType dataType ) {
			buffer.writeInteger( streamerStorage.typeIDs.idUnion );
			storeTypeSequence( buffer, dataType.caseTypes );
		}
		else if ( is IntersectionType dataType ) {
			buffer.writeInteger( streamerStorage.typeIDs.idIntersection );
			storeTypeSequence( buffer, dataType.satisfiedTypes );
		}
		else {
			buffer.writeInteger( streamerStorage.typeIDs.idUnknown );
		}
	}
	
}

