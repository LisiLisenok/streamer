import vm.lis.streamer {

	IStreamline,
	IStreamlineDeclaration,
	streamer,
	IStreamable
}
import ceylon.collection {

	TreeMap,
	ArrayList,
	LinkedList
}
import ceylon.language.meta.declaration {

	Declaration,
	Module,
	ClassDeclaration
}
import ceylon.language.meta.model {

	Type,
	ClassModel
}
import ceylon.language.meta {

	type
}

"internaly used streamlines storage"
by("Lisi")
class StreamerStorage()
{
	// mudule name -> id
	shared TreeMap<String, Integer> moduleIDs = TreeMap<String, Integer>(
		(String x, String y) => x.compare( y ) );
	// module id -> name
	shared TreeMap<Integer, String> moduleNames = TreeMap<Integer, String>(
		(Integer x, Integer y) => x.compare( y ) );
	
	// registered streamlines - module ID->streamlineID->streamline
	shared TreeMap<Integer, IStreamlineGeneral> streamlines = TreeMap<Integer, IStreamlineGeneral>(
		(Integer x, Integer y) => x.compare( y ) );
	
	// types for which streamlines are registered
	shared TreeMap<Integer, Type> streamlineTypes = TreeMap<Integer, Type>(
		(Integer x, Integer y) => x.compare( y ) );
	
	// types for which streamlines are registered, but not returned by getType
	shared TreeMap<Integer, Type> justStreamlineTypes = TreeMap<Integer, Type>(
		(Integer x, Integer y) => x.compare( y ) );

	// declarationClassName->id map
	shared TreeMap<String, Integer> declarations = TreeMap<String, Integer>(
		(String x, String y) => x.compare( y ) );
	
	// id->declaration map
	shared TreeMap<Integer, Declaration> declarationsID = TreeMap<Integer, Declaration>(
		(Integer x, Integer y) => x.compare( y ) );
}

"streamer storage - contains modules, streamlines, types, declarations and links between them"
by("Lis")
shared object streamerStorage
{
	
	variable Integer lastModuleID = 0;
	
	shared Integer bytesInID = 1;
	Integer bitsInID = 8 * bytesInID;
	shared Integer bytesInCombinedID = 2 * bytesInID;
	Integer idTemplate = #FF;
	
	"type IDs used by streamlines"
	shared object typeIDs {
		shared Integer idUnknown = 			0;
		shared Integer idNull = 			1;
		shared Integer idEmpty = 			2;
		shared Integer idInteger = 			3;
		shared Integer idFloat = 			4;
		shared Integer idByte = 			5;
		shared Integer idBoolean = 			6;
		shared Integer idString = 			7;
		shared Integer idCharacter = 		8;
		shared Integer idByteArray = 		9;
		shared Integer idJsonObject = 		10;
		shared Integer idJsonArray = 		11;
		shared Integer idEntry = 			12;
		shared Integer idTuple =	 		13;
		shared Integer idSequence = 		14;
		shared Integer idIterable = 		15;
		shared Integer idStreamable = 		16;
		shared Integer idArrayList = 		17;
		shared Integer idLinkedList = 		18;
		
		shared Integer idRegistered =		19;
		shared Integer idClass =	 		20;
		shared Integer idUnion =	 		21;
		shared Integer idIntersection =		22;
	}
	
	variable StreamerStorage? storage = null;
	
	shared void initialize() {
		
		if( ! storage exists ) {
			storage = StreamerStorage();
		
			// add typed streamlines
			addStreamline( typeIDs.idNull, builtInStreamlines.nullStreamline, false );
			addStreamline( typeIDs.idEmpty, builtInStreamlines.emptyStreamline, false );
			addStreamline( typeIDs.idInteger, builtInStreamlines.integerStreamline, false );
			addStreamline( typeIDs.idFloat, builtInStreamlines.floatStreamline, false );
			addStreamline( typeIDs.idByte, builtInStreamlines.byteStreamline, false );
			addStreamline( typeIDs.idCharacter, builtInStreamlines.characterStreamline, false );
			addStreamline( typeIDs.idBoolean, builtInStreamlines.booleanStreamline, false );
			addStreamline( typeIDs.idString, builtInStreamlines.stringStreamline, false );
			addStreamline( typeIDs.idByteArray, builtInStreamlines.javaBytesStreamline, true );
			addStreamline( typeIDs.idJsonObject, builtInStreamlines.jsonObjectStreamline, true );
			addStreamline( typeIDs.idJsonArray, builtInStreamlines.jsonArrayStreamline, true );
	
			// add streamline without types (iterable,sequence, streamable)
			putStreamlineWithModule( typeIDs.idSequence, type( sequenceStreamline ).declaration.containingModule,
				`Sequential<Anything>` );
			putStreamlineDeclaration( typeIDs.idSequence, sequenceStreamline, true );
			putStreamlineWithModule( typeIDs.idIterable, type( iterableStreamline ).declaration.containingModule,
				`Iterable<Anything>` );
			putStreamlineDeclaration( typeIDs.idIterable, iterableStreamline, true );
			putStreamlineWithModule( typeIDs.idStreamable, type( streamableStreamline ).declaration.containingModule,
				`IStreamable` );
			putStreamlineDeclaration( typeIDs.idStreamable, streamableStreamline, true );
	
			// add declaration streamlines
			addStreamlineDeclaration( typeIDs.idEntry, `class Entry`, entryStreamline, false );
			addStreamlineDeclaration( typeIDs.idTuple, `class Tuple`, tupleStreamline, true );
			addStreamlineDeclaration( typeIDs.idArrayList, `class ArrayList`, arraylistStreamline, true );
			addStreamlineDeclaration( typeIDs.idLinkedList, `class LinkedList`, linkedlistStreamline, true );
	
		}
	}
	
	shared Integer? moduleIDByName( String moduleName ) => storage?.moduleIDs?.get( moduleName );
	Integer? moduleID( Module mod ) => moduleIDByName( mod.name );
	
	"register module, returns module id, if module has been registered before just return id"
	Integer? registerModule( Module mod ) {
		if ( exists s = storage ) {
			if ( exists id = moduleID( mod ) ) {
				// module registered - return id
				return id;
			}
			// store new module
			lastModuleID++;
			lastModuleID = lastModuleID.and( idTemplate );
			s.moduleIDs.put( mod.name, lastModuleID );
			s.moduleNames.put( lastModuleID, mod.name );
			return lastModuleID;
		}
		return null;
	}
	
	Integer clearModuleID( Integer combinedID ) {
		return combinedID.and( idTemplate );
	}
	
	shared Integer combineModuleStreamlineIDs( Integer moduleID, Integer streamlineID )
		=> moduleID.leftLogicalShift( bitsInID ).or( clearModuleID( streamlineID ) );
	shared String? moduleTotalNameFromID( Integer moduleID )
		=> storage?.moduleNames?.get( moduleID );
	shared Integer moduleIDFromCombinedID( Integer combinedID )
		=> combinedID.rightLogicalShift( bitsInID );
	
	shared String getDeclarationClassName( Declaration declaration )
		=> declaration.qualifiedName.replace( "::", "." );
	
	void putStreamlineWithModuleID( Integer streamlineID, Integer moduleID, Type type ) 
		=> storage?.justStreamlineTypes?.put( combineModuleStreamlineIDs( moduleID, streamlineID ), type );
	
	void putStreamlineWithModule( Integer streamlineID, Module mod, Type type ) {
		if ( exists moduleID = registerModule( mod ) ) {
			putStreamlineWithModuleID( streamlineID, moduleID, type );
		}
	}

	void checkStreamlineID( Integer streamlineID ) {
		 assert( streamlineID > 0 && streamlineID < 256 );
	}
	
	"add [[IStreamline]]"
	throws( `class AssertionError`, "streamline ID must be > 0 and < 256" )
	see( `function addStreamlineDeclaration`, `interface IStreamline` )
	shared void addStreamline<DataType>( Integer streamlineID, IStreamline<DataType> streamline,
		Boolean resolveReference )
	{
		checkStreamlineID( streamlineID );
		if ( exists st = storage ) {
			if ( exists moduleID = registerModule( type( streamline ).declaration.containingModule ) ) {
				// combinedID - module + streamline
				Integer nCombinedID = combineModuleStreamlineIDs( moduleID, streamlineID );
				if ( st.streamlines.defines( nCombinedID ) ) {
					streamer.error( logMessages.streamlineAlreadyRegistered( streamlineID ) );
				}
				else {
					Type t = `DataType`;
					// put id->type
					st.streamlineTypes.put( nCombinedID, t );
					// background Streamline added - to store streamline ID before writing and resolve references
					st.streamlines.put( nCombinedID, StreamlineTypeBase<DataType>(
						streamline, nCombinedID, resolveReference ) );
					streamer.debug( logMessages.steamlineRegistered( nCombinedID, t.string ) );
				}
			}
		}
		else {
			streamer.fatal( logMessages.streamerNotInitialized );
		}
	}
	
	void putStreamlineDeclaration( Integer streamlineID, IStreamlineDeclaration streamline,
	Boolean resolveReference ) {
		if ( exists st = storage ) {
			if ( exists moduleID = registerModule( type( streamline ).declaration.containingModule ) ) {
				// combinedID - module + streamline
				Integer nCombinedID = combineModuleStreamlineIDs( moduleID, streamlineID );
				if ( st.streamlines.defines( nCombinedID ) ) {
					streamer.error( logMessages.streamlineAlreadyRegistered( streamlineID ) );
				}
				else {
					// backround Streamline added - to store streamline ID before writing 
					st.streamlines.put( nCombinedID, StreamlineDeclaratonBase(
						streamline, nCombinedID, resolveReference ) );
					streamer.debug( logMessages.steamlineRegistered( nCombinedID, "" ) );
				}
			}
		}
		else {
			streamer.fatal( logMessages.streamerNotInitialized );
		}
	}
	
	"add [[IStreamlineDeclaration]]"
	throws( `class AssertionError`, "streamline ID must be > 0 and < 256" )
	see( `function addStreamline`, `interface IStreamlineDeclaration` )
	shared void addStreamlineDeclaration( Integer streamlineID, ClassDeclaration declaration,
		IStreamlineDeclaration streamline, Boolean resolveReference )
	{
		checkStreamlineID( streamlineID );
		if ( exists st = storage ) {
			if ( exists moduleID = registerModule( type( streamline ).declaration.containingModule ) ) {
				// combinedID - module + streamline
				Integer nCombinedID = combineModuleStreamlineIDs( moduleID, streamlineID );
				if ( st.streamlines.defines( nCombinedID ) ) {
					streamer.error( logMessages.streamlineAlreadyRegistered( streamlineID ) );
				}
				else {
					// store declarations
					st.declarationsID.put( nCombinedID, declaration );
					st.declarations.put( getDeclarationClassName( declaration ), nCombinedID );
					// backround Streamline added - to store streamline ID before writing 
					st.streamlines.put( nCombinedID, StreamlineDeclaratonBase( streamline, nCombinedID,
						resolveReference ) );
					streamer.debug( logMessages.steamlineRegistered( nCombinedID, declaration.string ) );
				}
			}
		}
		else {
			streamer.fatal( logMessages.streamerNotInitialized );
		}
	}
	
	
	"get general streamline by id"
	shared IStreamlineGeneral? streamlineGeneralByID( Integer streamlineID ) 
		=> storage?.streamlines?.get( streamlineID );
	
	"get type by its id"
	shared Type? typeByID( Integer nID ) => storage?.streamlineTypes?.get( nID );
	
	"true if typeID is declaration type"
	shared Boolean isDeclaration( Integer typeID )
			=> storage?.declarationsID?.defines( typeID ) else false;
	
	Integer? searchTypeID( Type dataType, Map<Integer, Type> types ) {
		for ( key->item in types ) {
			if ( item.supertypeOf( dataType ) ) {
				return key;
			}
		}
		return null;
	}
	
	"get type / streamline id by instance"
	shared Integer? idByType( Type<Anything> instanceType ) {
		// look declarations first
		if ( is ClassModel instanceType, exists id = storage?.declarations
			?.get( getDeclarationClassName( instanceType.declaration ) ) )
		{
			return id;
		}
		
		if ( exists st = storage, exists id = searchTypeID( instanceType, st.streamlineTypes ) ) {
			return id;
		}
		
		return null;
	}
	
	"get type / streamline id by instance"
	Integer? idByInstance( Anything instance ) {
		// look declarations first
		if ( exists instance, exists id = storage?.declarations?.get( className( instance ) ) ) {
			return id;
		}
		if ( exists st = storage ) {
			Type t = type( instance );
			// look streamlines with type
			if ( exists id = searchTypeID( t, st.streamlineTypes ) ) {
				return id;
			}
			// look streamlines have no type (streamable)
			if ( exists id = searchTypeID( t, st.justStreamlineTypes ) ) {
				return id;
			}
		}
		return null;
	}
	
	"returns streamline id if it applied to specified type:
	 * annotation stream( streamlineID ), if ID is zero, returns default streamline
	 * type is one of: Integer | Float | Byte | Boolean | String | Character | JsonObject | JsonArray | ByteArray | Entry | Tuple
	 * type is subtype of [[Iterable]] or [[Sequence]]"
	shared Integer? streamlineIDByInstance( Anything instance ) {
		if ( exists s = idByInstance( instance ) ) {
			//streamer.trace( logMessages.streamlineFound( s, dataType ) );
			return s;
		}
		streamer.error( logMessages.incorrectStreamline( type( instance ) ) );
		return null;
	}
	 
}


