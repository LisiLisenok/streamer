import vm.lis.streamer.streamline {

	logMessages,
	streamerStorage
}
import ceylon.logging {

	Logger,
	Priority,
	logger,
	priorityDebug = debug
}
import ceylon.language.meta.declaration {

	Package,
	Module,
	ClassDeclaration
}


"streamer: control center
 * built-in types:
		* Integer | Float | Byte | Boolean  | String | Character | ByteArray | Entry | Tuple
		  | JsonObject | JsonArray | ArrayList | LinkedList 
		* objects satisfy [[Iterable]] or [[Sequence]]  
 * registering streamline to store another data type - [[registerStreamline]]
 * use [[IOutputStream]] and [[IOutputBuffer]] interfaces and implementation [[OutputStream]]
   to store data, after storing call [[IOutputBuffer.flushTo]] to get byte buffer with stored data.
   This buffer can be given to [[InputStream]] in order to restore data
 * use [[IInputStream]] and [[IInputBuffer]] interfaces and implementation [[InputStream]] to restore data
 * satisfies [[Logger]] interface. Log is doing for module category. LogWriter to be registered before using.
   set [[priority]] to modify current priority, defaultPriority is used at initialization 
"
by("Lisi")
shared object streamer satisfies Logger
{
	
	// logging
	Logger logStreamer = logger( `streamer`.declaration.containingModule );
	shared actual Module|Package category => `streamer`.declaration.containingModule;
	shared actual void log( Priority priority, String|String() message, Exception? exception ) {
		logStreamer.log( priority, message, exception );
	}
	logStreamer.priority = priorityDebug;
	shared actual Priority priority => logStreamer.priority;
	assign priority {
		logStreamer.priority = priority;
		logStreamer.info( logMessages.prioritySetTo( priority.string ) );
	}
	
	logStreamer.info( logMessages.startLogging );
	
	shared Integer typeUnknown => streamerStorage.typeIDs.idUnknown;
	shared Integer typeClass => streamerStorage.typeIDs.idClass;
	shared Integer typeUnion => streamerStorage.typeIDs.idUnion;
	shared Integer typeIntersection => streamerStorage.typeIDs.idIntersection;
	
	"streamer initialization - to be called before any usage"
	shared void initialize() {
		streamerStorage.initialize();
	}

	"register streamline with specified ID
	 * ID must be > 0 and < 256
	 * limitation of 255 streamlines is for a one module,
	 so another module may contain another 255 streamlines"
	throws( `class AssertionError`, "streamline ID must be > 0 and < 256" )
	throws( `class AssertionError`, "streamline must be marked with stream annotation" )
	see( `interface IStreamline`, `function registerStreamlineDeclaration` )
	shared void registerStreamline<DataType>( Integer streamlineID, IStreamline<DataType> streamline ) {
		// check streamline ID in annotation stream
		streamerStorage.addStreamline( streamlineID, streamline, true );
	}
	
	"register declaration streamline with specified ID
	 * ID must be > 0 and < 256
	 * limitation of 255 streamlines is for a one module,
	   so another module may contain another 255 streamlines"
	throws( `class AssertionError`, "streamline ID must be > 0 and < 256" )
	see( `function registerStreamline`, `interface IStreamlineDeclaration` )
	shared void registerStreamlineDeclaration( Integer streamlineID, ClassDeclaration declaration,
		 IStreamlineDeclaration streamline )
	{
		streamerStorage.addStreamlineDeclaration( streamlineID, declaration, streamline, true );
	}
		
}

