import ceylon.language.meta.declaration {

	ClassOrInterfaceDeclaration
}
import ceylon.collection {

	TreeMap
}
import ceylon.language.meta {

	modules
}
import vm.lis.streamer.io {

	IBuffer,
	bufferConstants
}
import vm.lis.streamer.streamline {

	logMessages,
	streamerStorage
}
import ceylon.language.meta.model {

	Type,
	ClassOrInterface
}

"stream format constants"
by("Lisi")
object formatDefinitions
{
	shared Byte header		 		=	Byte( 21 );
	shared Byte moduleResolve 		=	Byte( 22 );
	shared Byte declarations 		=	Byte( 23 );
	shared Byte types 				=	Byte( 24 );
	shared Byte objects				=	Byte( 25 );
	
	shared Integer sectionDefinitionSize = 1 + bufferConstants.bytesInInteger;	
}


"store / restore data in streamer format, use dynamic sections - so it can be added at any time
 if added bytes doesn't contain complete section - add them to dummy buffer and waits next data portion
 used as background buffer in [[InputStream]] and [[OutputStream]]"
by("Lisi")
abstract class StreamFormat() satisfies IBuffer
{
	"underlying buffer to store / restore data"
	shared formal IBuffer dataBuffer;
	
	"last declaration ID - next added declaration Id is lastID ++"
	variable Integer lastDeclarationID = 0;
	
	"map to fast search declarations by id - used in restoring"
	TreeMap<Integer, ClassOrInterfaceDeclaration> declarationsStorage = TreeMap<Integer, ClassOrInterfaceDeclaration>(
		(Integer x, Integer y) => x <=> y );
	
	"array to fast search of declarations id by declaration definition - used in storing"
	TreeMap<String, Integer> itemDeclarations = TreeMap<String, Integer>(
		(String x, String y) => x.compare( y ) );
	
	shared {<Integer->ClassOrInterfaceDeclaration>*} declarations => declarationsStorage;
	
	"last stored type ID - next added declaration Id is lastID ++"
	variable Integer lastTypeID = 0;
	
	"id->stored types"
	TreeMap<Integer, Type> classIDs = TreeMap<Integer, Type>(
		(Integer x, Integer y) => x <=> y );
	
	shared object classes satisfies {<Integer->Type>*} {
		shared actual Integer size => classIDs.size;
		shared actual Iterator<Integer->Type> iterator() => classIDs.iterator();
	}
	
	"type storing"
	TreeMap<String, Integer> classTypes = TreeMap<String, Integer>(
		(String x, String y) => x.compare( y ) );
	
	// buffer operations
	shared actual Integer position => dataBuffer.position;
	assign position {
		dataBuffer.position = position;
	}
	shared actual Integer size => dataBuffer.size;
	shared actual Integer bytesAvailable => dataBuffer.bytesAvailable;
	shared actual void flipStart() => dataBuffer.flipStart();
	shared actual void flipEnd() => dataBuffer.flipEnd();
	shared actual Iterator<Byte> iterator() => dataBuffer.iterator();


	"apply class type by stored declaration id and generic parameter types"
	shared Type applyClass( Integer declarationID, Type[] parameterTypes ) {
		if ( exists declaration = declarationsStorage.get( declarationID ) ) {
			// not applied - apply new class
			return declaration.apply<Anything>( *parameterTypes );
		}
		return `Nothing`;
	}
	
	"find declration id by declaration"
	shared Integer? idByDeclaration( ClassOrInterfaceDeclaration declaration ) {
		return itemDeclarations.get( declaration.qualifiedName );
	}
	
	"add declaration specified by id and names, if not already exists"
	shared void addDeclaration( Integer nID, String moduleName, String moduleVersion,
		String packageName, String declarationName )
	{
		if ( !declarationsStorage.defines( nID ) ) {
			if ( exists objectModule = modules.find( moduleName, moduleVersion ) ) {
				if ( exists objectPackage = objectModule.findPackage( packageName ) ) {
					if ( exists declaration = objectPackage.getClassOrInterface( declarationName ) ) {
						declarationsStorage.put( nID, declaration );
						itemDeclarations.put( declaration.qualifiedName, nID );
						streamer.trace( logMessages.declarationRestored( declaration ) );
					}
					else {
						streamer.error( logMessages.declarationNotFound( moduleName, moduleVersion,
							packageName, declarationName ) );
					}
				}
				else {
					streamer.error( logMessages.packageNotFound( moduleName, moduleVersion, packageName ) );
				}
			}
			else {
				streamer.error( logMessages.moduleNotFound( moduleName, moduleVersion ) );
			}
		}
	}
	
	"store declaration, returns ID of added declaration,
	 if declaration has been stored previously just return id"
	shared Integer storeDeclaration( ClassOrInterfaceDeclaration declaration ) {
		if ( exists id = idByDeclaration( declaration ) ) {
			return id;
		}
		lastDeclarationID ++;
		declarationsStorage.put( lastDeclarationID, declaration );
		itemDeclarations.put( declaration.qualifiedName, lastDeclarationID );
		streamer.trace( logMessages.declarationStored( declaration ) );
		return lastDeclarationID;
	}
	
	"clear stream - remove declarations and data"
	shared void clearStream() {
		itemDeclarations.clear();
		declarationsStorage.clear();
		lastDeclarationID = 0;
		streamer.trace( logMessages.streamClear );
	}
	
	"store declaration + type of instance"
	shared Integer storeType( ClassOrInterface instanceType ) {
		String strClass = instanceType.string;
		if ( exists id = classTypes.get( strClass ) ) {
			return id;
		}
		lastTypeID ++;
		classIDs.put( lastTypeID, instanceType );
		classTypes.put( strClass, lastTypeID );
		storeAllDeclarations( instanceType );
		return lastTypeID;
	}
	
	void storeAllDeclarations( ClassOrInterface instanceType ) {
		storeDeclaration( instanceType.declaration );
		for ( arg in instanceType.typeArguments ) {
			if ( is ClassOrInterface item = arg.item, exists id = streamerStorage.idByType( arg.item ) ) {
				if ( streamerStorage.isDeclaration( id ) ) {
					storeAllDeclarations( item );
				}
			}
			else if ( is ClassOrInterface item = arg.item ){
				storeAllDeclarations( item );
			}
		}
		
	}
	
	shared Type? getType( Integer id ) => classIDs.get( id );
	
	shared void addType( Integer nID, Type type ) {
		classIDs.put( nID, type );
	}
	
}
