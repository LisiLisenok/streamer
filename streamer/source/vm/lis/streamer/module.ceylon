"
 streamer is a serializer written on Ceylon
 
 #terminology
 
	* [[streamer]] (object defined in vm.lis.streamer) is control center of the streamer serializer
	* streamline is serialization / deserialization logic, which identifies how to serialize / deserialize
	  an object of specific type, see interface [[IStreamline]]
	* input and output (or io) streams ([[IInputStream]] and [[IOutputStream]]) are read / write streams of objects
	* streamlines operates by specific types of io streams - [[IInputStreamline]] and [[IOutputStreamline]],
	  which have a little bit more capabilities on managing bytes in the stream than general io streams  
	* byte buffers (see [[package vm.lis.streamer.io]]) is intended to store / restore raw bytes
	* serialization process - storing objects data onto output stream with followed flushing into bytes buffer
	* deserialization process - transfering bytes buffer onto input stream with followed objects restoring from the stream
 
 #serialization
 
 * register streamlines within the [[streamer]] - [[streamer.registerStreamline]] (some of streamlines are registered automaticaly
   by streamer - see section [streamlines](#streamlines) below
 * create an instance of [[OutputStream]] and serialize objects onto using [[OutputStream.write]]
 * repeat writing as many times as needed
 * flush serialized objects into a byte buffer
 
 Example:
 	Integer myInt = 1;
 	OutputStream stream = OutputStream();
 	stream.write( myInt );
 
 The objects are written to the stream using streamlines registered in the [[streamer]],
 see section [streamlines](#streamlines) below.
 Once objects are written the raw bytes can be stored within [[vm.lis.streamer.io:IExpandedBuffer]]
 using [[IOutputBuffer.flushTo]] function, see section [buffers](#buffers) below.
 This byte buffer can be used to store data in file or sending via network or another purpuses.
 
 #deserialization
 
 * register streamlines within the [[streamer]] - [[streamer.registerStreamline]]
 * obtain a byte buffer with serialized objects
 * create an instance of [[InputStream]]. Put bytes onto the stream using [[InputStream.expand]]
 * read objects from the stream using [[InputStream.read]] or [[InputStream.readOf]]
 
 #buffers
 represents raw bytes stored as sequence and provides read / write operations of bytes or basic types like [[Integer]] or [[Float]].
 defined in [[package vm.lis.streamer.io]]. Interfaces [[vm.lis.streamer.io::IReadBuffer]] and [[vm.lis.streamer.io::IWriteBuffer]]
 used within streamer to operate with bytes. Additionaly [[vm.lis.streamer.io::IExpandedBuffer]]
 which allows to expand read buffer (or add some bytes to the buffer end) is used to provide bytes transfer and chunk. 
 The buffer interfaces are implemented in [[vm.lis.streamer.io::VMBuffer]] which used within streamer by default.
 
 #output stream
 the objects are serialized onto output stream, which contains information about serialized objects
 and objects data as bytes sequence. [[IOutputStream]] interface provides objects serialization in  buffer.
 [[IOutputBuffer]] is an output stream + data storing into byte buffer, see [[IOutputBuffer.flushTo]].
 [[OutputStream]] is implementation of [[IOutputBuffer]]. Data can be stored into any buffer
 satisfies [[vm.lis.streamer.io::IExpandedBuffer]] interface. So, some crypthographic or compression
 or another storing logic can be added. By default [[vm.lis.streamer.io::VMBuffer]] is used.
 
 #input stream
 [[IInputStream]] interface provides objects deserialization background.
 [[IInputBuffer]] interface adds to [[IInputStream]] some capabilities,
 for example, adding new bytes to the end of the stream, see [[IInputBuffer.expand]]
 [[InputStream]] is implementation of [[IInputBuffer]]. Input stream contains information
 about metamodel declarations (see [[package ceylon.language.meta]]) and objects data as bytes sequence.
 When some objects data no longer needed it can be removed using [[IInputBuffer.removeData]], which
 removes only objects data but keeping declarations as is, so they can be used for further reading operations.
 If stream is cleaned calling [[IInputBuffer.clear]] declarations are removed as well as data.
 So, following data reading operation will not see declarations and may be not deserialized correctly.

 #streamlines
 provide serialization / deserialization logic for the particular type. Represented via [[IStreamline]] 
 or [[IStreamlineDeclaration]] interfaces. The streamline is to be registered within [[streamer]], 
 see [[streamer.registerStreamline]]. The same streamlines with the same id's have to be registered
 at both serialization and deserialization sides. Once streamline is registered all objects
 which are subtypes of a supertype streamline is registered for are serialized / deserialized using this streamline.
 
 Some streamlines are registered automaticaly and provides serialization / deserialization of basic types.
 ####built-in streamlines
 * basic types: [[Integer]], [[Float]], [[Boolean]], [[Byte]], [[Character]] and [[String]]
 * java ByteArray (java Byte[])
 * JSON [[ceylon.json::Object]] and [[ceylon.json::Array]] 
 * [[Entry]] with Key and Item to be serialized by registered streamlines
 * [[Iterable]] with elements to be serialized by registered streamlines. Any object satisfies Iterable
   interface can be serialized using this streamline, but it is deserialized as Iterable
   but not exact collection type it was serialized. Elements of the collection are serialized using
   some of registered streamlines and they types are defined by they serialization.
   Union and Intersection types are not supported.
   
	Example:
		OutputStream outputStream = OutputStream();
 		// serialize {Float*} collection
		outputStream.write( {1.2, 2.67, 3.5, -4.02} );
 		// serialize {Integer->String*} map
		outputStream.write( {1->\"One\", 2->\"Two\", 3->\"Three\", 4->\"Four\"} )
		IntputStream intputStream = IntputStream();
		outputStream.flushTo( inputStream );
 		// deserialize {Float*} collection
		{Float*}? collection = inputStream.readOf<{Integer|Float*}>();
 		// deserialize {Integer->String*} map
		{Entry<Integer,String>*}? map = inputStream.readOf<{Entry<Integer,String>*}>();
 * [[Sequence]] - the same as Iterable
 * [[Tuple]] each tuple element has to be serialized by some registered streamlines.
	
	Example:
		OutputStream outputStream = OutputStream();
		// serialize tuple
		outputStream.write( [1, 2.5, \"SomeString\", 30] );
		IntputStream intputStream = IntputStream();
		outputStream.flushTo( inputStream );
		// deserialize tuple
		[Integer,Float,String,Integer]? tuple = inputStream.readOf<[Integer,Float,String,Integer]>();

 * [[ceylon.collection::ArrayList]] and [[ceylon.collection::LinkedList]]. Union or Intersection types are not supported.
   Restored using default initializer arguments ([[ceylon.collection::ArrayList.growthFactor]] = 1.5)
 * [[IStreamable]] interface, which delegates serialization / deserialization to the object themself. This doesn't
   require additional streamlines to be registered. Just implement [[IStreamable]] interface.
   Object type information is stored in the stream, which requires additional bytes. Initializer arguments
   are stored as well. At deserialization the instance will be created automaticaly by this info
   and stored initializer arguments. Then stream is passed to the [[IStreamable.restore]] method
   and the instance can restore particular values. To store this values [[IStreamable.store]]
   method is used during serialization process. Alternatively streamline [[StreamlineFactory]] and
   [[IStorable]] interface can be used. This way requires factories to be registered within
   [[StreamlineFactory]] instance for any storing / restoring types. And streamline
   ([[StreamlineFactory]]) registered within the streamer. More classes and instancies required
   to follow this way, but it doesn't require type information to be stored within the stream and is more
   flexible to store classes family, see section `external streamlines` below
   
	Example:
		// class Point to be serialized: satisfies IStreamable interface
		stream class Point<TypeData>( x, y ) satisfies IStreamable
 			given TypeData of Integer | Float satisfies Numeric<TypeData>
		{
 			shared TypeData x;
 			shared TypeData y;
 			shared variable TypeData someManipulation = x + y;
 			
 			// initializer arguments, asked during serialization process
 			shared actual Anything[] initializerArguments() {
				return [x, y];
 			}
 			// restoring object particular data
			shared actual void restore( IInputStream stream ) {
 				someManipulation = stream.readOf<TypeData>() else x + y;
			}
			// storing object particular data
 			shared actual void store( IOutputStream stream ) {
 				stream.write( someManipulation );
			}
		}
		OutputStream outputStream = OutputStream();
		// serialize Point<Integer>
		outputStream.write( Point<Integer>( 1, 2 ) );
		IntputStream intputStream = IntputStream();
		outputStream.flushTo( inputStream );
		// deserialize Point<Integer>
		Point<Integer>? point = inputStream.readOf<Point<Integer>>();
 
 ####external streamlines
 external streamlines are registered within streamer using registerStreamline function.
 Streamlines have to satisfy [[IStreamline]] or [[IStreamlineDeclaration]] interfaces.
 Each streamline contained in particular module has it own unique id. ID has to be greater 0 and less 256
 Streamline id has to be specified at registration using [[streamer.registerStreamline]] function
 
 Example:
		class MyStreamline() satisfies IStreamline {...}

 [[IStreamline]] is indended to store / restore objects of particular type and contains three methods:
 * [[IStreamline.write]] - objects serialization. Takes instance to be serialized and [[IOutputStreamline]] stream, some
   extension under [[IOutputStream]], which allows to store some raw data about seriazlizing objects
   and provides access to output stream ([[IOutputStream]]) used to store objects with registered streamlines
 * [[IStreamline.instantiate]] - used at deserialization proccess to instantiate an object
 * [[IStreamline.fill]] - fill instantiated object with stored data. Takes [[IInputStreamline]] stream
   and allows restore data stored using [[IStreamline.write]] method in the same order it was stored
 
 [[IStreamlineDeclaration]] is indended to store / restore objects base on them declaration
 and more suit to store generics. But these streamlines operates by objects of Anything type and
 requires more resources then [[IStreamline]] based on object type. Contains the same
 [[IStreamlineDeclaration.write]], [[IStreamlineDeclaration.instantiate]] and [[IStreamlineDeclaration.fill]]
 methods as [[IStreamline]] but uses Anything object type. Absract class [[StreamlineDeclaration]] can be used
 as a base for streamlines based on declarations.
 
 In order to implement streamline logic following raw classes can be extended:
 * [[StreamlineString]] allows to store / restore Strings
 * [[StreamlineInitializer]] allows to store / restore objects that require only initializers data to be stored.
   It asks initializer arguments at serialization and pass them back to the instance initializer at deserialization
 * [[StreamlineFactory]] uses factory to create new instance at deserialization. The factory creates instance
   using some default arguments. The instance is responsible to store / restore all data it requires.
   The objects serialized / deserialized by this streamline have to satisfy [[IStorable]] interface
   and implements they own storing logic. This streamline is similar to used with [[IStreamable]] objects, 
   but it asks factory to create instance instead of storing information about object type. The factories
   must be registered with unique factory id using [[StreamlineFactory.registerFactory]].

	Example:
		// to be stored object classes
		abstract class MyObjectBase() satisfies IStorable {
		}
		
		class MyObjectOne() extends MyObjectBase() {
			shared actual void store( IOutputStream stream ) { // storing }
			shared actual void restore( IInputStream stream ) { // restoring }
		}
		class MyObjectTwo() extends MyObjectBase() {
			shared actual void store( IOutputStream stream ) { // storing }
			shared actual void restore( IInputStream stream ) { // restoring }
		}
		// factory classes
		class MyObjectOneFactory() satisfies IFactory<MyObjectBase> {
 			shared actual Element createElement() => MyObjectOne(); 
		}
		class MyObjectTwoFactory() satisfies IFactory<MyObjectBase> {
			shared actual Element createElement() => MyObjectTwo(); 
		}
		// streamline
		class MyStreamlineFactory() extends StreamlineFactory<MyObjectBase>();
 		MyStreamlineFactory streamline = MyStreamlineFactory();
		streamline.registerFactory( 1, MyObjectOneFactory() );
		streamline.registerFactory( 2, MyObjectTwoFactory() );
		streamer.registerStreamline( YYY, MyObjectFactory() );
		// serializing
		OutputStream outputStream = OutputStream();
		outputStream.write( MyObjectOne() );
		outputStream.write( MyObjectTwo() );

 #union and intersection types
 not yet supported. At the same time objects of [[Tuple]] type are fully supported. 
 
 #iterables, [[IStorable]] / [[IStreamable]] interfaces and inheritance
 The type parameter of stored / restored [[Iterable]] (or [[ceylon.collection::ArrayList]], or [[ceylon.collection::LinkedList]])
 is to be exactly the same as type of streamline registered for. Union type is not supported!
 Example, using MyObjects form example above:
 
		outputStream.write( { MyObjectOne(), MyObjectTwo() } );
		...
		inputStream.readOf<{MyObjectBase*}>(); // returns null
 
		outputStream.write( { MyObjectOne(), MyObjectOne() } );
		...
		inputStream.readOf<{MyObjectOne*}>(); // ok
 
		outputStream.write( { MyObjectOne(), MyObjectOne() } );
		...
		inputStream.readOf<{MyObjectBase*}>(); // ok
		
		outputStream.write( Array<MyObjectBase>{ MyObjectOne(), MyObjectTwo() } );
		...
		inputStream.readOf<{MyObjectBase*}>(); // ok
		
 
 #referencies and circular referencies
 treated automatically
 
 #chunk
 when reading some big files or sending huge amount of data via net chunk or cutting of byte array on blocks can be used.
 Larger byte array can be cut on any number of blocks with any length. The bytes are added to the stream using
 [[InputStream.expand]] method. Each byte block must be added one after another according to their appearance in the source array.
 
 The stream treat added bytes to contain only full information on the object. If there is incomplete data to restore
 object, stream put the bytes into cash and waits next portion of bytes. Inspect [[InputStream.bytesAvailable]]
 in order to check if some objects are available in the stream.
 
 Inspect [[InputStream.waitsMoreBytes]] to check if the stream still waits some bytes to be expanded into 
 
 #compression, encryption etc
 implement [[vm.lis.streamer.io::IReadBuffer]], which used by input stream [[IInputStream]]
 to restore objects from raw bytes.
 implement [[vm.lis.streamer.io::IExpandedBuffer]], which used by output stream ([[IOutputStream]])
 to store serialized objects as raw bytes
 
 #logging
 Streamer logs following data:
 * info - starting time, log priority and registered streamlines
 * serialization errors:
 	* no streamline registered for serialized object
 * deserialization errors:
 	* no streamline registered for deserialized object
 	* module, package or declaration not found.
 	  Occurs when module used in serilization context is not loaded at deserialization one
 	* byte buffer has been corrupted or not streamer buffer
 	* incorrect object type or more bytes required to restore object then actualy exists.
 	  Occurs when read order is not consistent with writing order
 * debug - general information on stored / restored objects
 * trace - detailed information on stored / restored objects
 
 [[streamer]] satisfies [[ceylon.logging::Logger]] interface and can be used itself to log.
 logerWriter is to be registered before logging, follow [[module ceylon.logging]].
 Simple [[FileLogWriter]] class can be used to log into file. 
 
 #exceptions
 Streamer is minimized exceptions instead writing errors to the log and put deserialized object to null
 
 #examples:
 see module vm.lis.streamerexamples
 
"
by("Lisi")
module vm.lis.streamer "1.0.0" {
	shared import ceylon.interop.java "1.1.0";
	shared import ceylon.io "1.1.0";
	shared import ceylon.logging "1.1.0";
	shared import ceylon.time "1.1.0";
	shared import ceylon.json "1.1.0";
}
