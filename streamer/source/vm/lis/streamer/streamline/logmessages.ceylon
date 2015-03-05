import ceylon.language.meta.model {

	Type
}
import ceylon.language.meta.declaration {

	Declaration
}
import ceylon.time {

	systemTime
}
import ceylon.time.timezone {

	timeZone
}

"returns current system time in system time zone"
by("Lisi")
String currentTime() {
	return systemTime.instant().zoneDateTime( timeZone.system ).string;
}

"error messages"
by("Lisi")
shared object logMessages {
	
	// header
	shared String streamerHeader = "Streamer: ";
	
	/* info messages */
	shared String startLogging = streamerHeader +"start logging at " + currentTime() + "\n";
	shared String prioritySetTo( String priority ) => streamerHeader +"priority is set to ``priority``\n";
	
	/* error messages */
	
	shared String streamerNotInitialized => streamerHeader +"streamer hasn't been initialized\n";
	
	shared String streamlineAlreadyRegistered( Integer streamlineID )
		=> streamerHeader +"streamline with id ``streamlineID`` has been already registered\n";
	
	shared String incorrectStoringType( Type t ) => streamerHeader +
			"Incorrect type ``t`` of stored item. Must be one of:\n
			 \t- or Integer | Float | Byte | Boolean | String | Character | ByteArray | Entry | Tuple | JsonObject | JsonArray\n
			 \t- or subtype of Sequence or Iterable\n
			 \t- or declared with annotation stream with id of registered streamline\n";
	
	shared String incorrectRestoringType( Integer typeID ) => streamerHeader +
			"restoring type with id ``typeID`` cann't be determined\n";

	shared String incorrectStreamline( Type t ) => streamerHeader +
			"no streamline found to store / restore type ``t``\n";
	
	shared String incorrectBuffer = streamerHeader +
			"bytes buffer corrupted or is not in streamer format\n";
	
	shared String streamlineNotFound( Integer id ) => streamerHeader +
			"streamline ``id`` hasn't been found\n";

	shared String typeIDNotFound( Type t ) => streamerHeader +
			"no type id has been found for the type ``t``, declaration may to be stored in the buffer\n";
	
	shared String instantiatingNotClass( Type t ) => streamerHeader +
			"trying to instantiate not Class type ``t``\n";
	
	shared String objectNotRead( Type t ) => streamerHeader +
			"incorrect object type ``t`` when read\n";
	
	shared String objectUncompleteRead( Integer nRequired, Integer nActual ) => streamerHeader +
			"object has read just ``nActual`` bytes when expected ``nRequired``\n";
	
	shared String insufficientBytes( Integer nRequired, Integer nActual ) => streamerHeader +
			"to read object ``nRequired`` bytes required when actually ``nActual`` available\n";

	shared String streamableNotClass( Integer id ) => streamerHeader +
			"streamable restores only class types (id must be ``streamerStorage.typeIDs.idClass``, but not typeinfo id ``id``)\n";
	
	shared String moduleNotFound( String moduleName, String version ) => streamerHeader +
			"module ``moduleName``/``version`` has not been found\n";

	shared String packageNotFound( String moduleName, String version, String packageName ) => streamerHeader +
			"package ``packageName`` has not been found in ``moduleName``/``version``\n";

	shared String declarationNotFound( String moduleName, String version, String packageName,
		String declarationName ) => streamerHeader +
			"class ``declarationName`` has not been found in ``moduleName``/``version``::``packageName``\n";

	
	/* debug messages */
	
	shared String steamlineRegistered( Integer id, String t ) => streamerHeader +
			"steamline ``id`` with type ``t`` has been successfully registered";
	
	shared String flushingOutputStream( Integer nHeaderSize, Integer nModules, Integer nDeclarations,
		Integer nDeclarationSize, Integer nTypes, Integer nTypesSize, Integer nDataSize ) => streamerHeader +
			"output stream is flushed to raw bytes with: total size ``nHeaderSize + nDeclarationSize + nDataSize`` bytes, 
			 \n\ttotal streamline modules is ``nModules``, total declarations number is ``nDeclarations`` in ``nDeclarationSize`` bytes, total types ``nTypes`` in ``nTypesSize`` bytes, objects take ``nDataSize`` bytes"; 
	
	shared String expandingInputStream( Integer nTotalSize, Integer nCashedSize, Integer nRemainToExpand,
		Integer nModulesRead, Integer nDeclarationsRead, Integer nObjectsRead ) => streamerHeader +
			"expand input stream from raw bytes: ``nModulesRead`` modules containing streamlines, ``nDeclarationsRead`` declarations and ``nObjectsRead`` objects have been read from ``nTotalSize`` bytes,
			 \n\t``nCashedSize`` bytes has been chashed, still waiting ``nRemainToExpand`` bytes"; 
	
	shared String streamRemovedData => streamerHeader + "all objects have been removed from the stream";
	
	shared String streamClear => streamerHeader + "all declarations have been removed from the stream";
	
	/* trace messages */
	
	shared String streamlineFound( Integer id, Type t ) => streamerHeader +
			"streamline ``id`` for type ``t`` has been successfully found";
	
	shared String objectWritten( Type t, Integer size ) => streamerHeader +
			"object type ``t`` has been serialized to ``size`` bytes";
	
	shared String objectRead( Type t, Integer size ) => streamerHeader +
			"object type ``t`` has been read from ``size`` bytes";

	shared String declarationStored( Declaration t ) => streamerHeader +
			"declaration ``t`` has been stored in the stream";
	
	shared String declarationRestored( Declaration t ) => streamerHeader +
			"declaration ``t`` has been restored to the stream";

}