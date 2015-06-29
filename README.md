
streamer is a serializer written on Ceylon
 
#terminology
  
 
  * streamer (object defined in vm.lis.streamer) is control center of the streamer serializer
  * streamline is serialization / deserialization logic, which identifies how to serialize / deserialize
	  an object of specific type, see interface IStreamline
  * input and output (or io) streams (<code>IInputStream</code> and <code>IOutputStream</code>) are read / write streams of objects
  * streamlines operates by specific types of io streams - <code>IInputStreamline</code> and <code>IOutputStreamline</code>,
	  which have a little bit more capabilities on managing bytes in the stream than general io streams  
  * byte buffers (see package <code>vm.lis.streamer.io</code>) is intended to store / restore raw bytes
  * serialization process - storing objects data onto output stream with followed flushing into bytes buffer
  * deserialization process - transfering bytes buffer onto input stream with followed
	  objects restoring from the stream
 
#serialization
 
* register streamlines within the streamer - streamer.registerStreamline (some of streamlines are registered automaticaly
 by streamer - see section [streamlines](#streamlines) below
* create an instance of OutputStream and serialize objects onto using <code>OutputStream.write()</code>
* repeat writing as many times as needed
* flush serialized objects into a byte buffer
 
Example:
 	
    Integer myInt = 1;
    OutputStream stream = OutputStream();
    stream.write( myInt );
 
The objects are written to the stream using streamlines registered in the streamer,
see section [streamlines](#streamlines) below.
Once objects are written the raw bytes can be stored within <code>vm.lis.streamer.io:IExpandedBuffer</code>
using <code>IOutputBuffer.flushTo()</code> function, see section [buffers](#buffers) below.
This byte buffer can be used to store data in file or sending via network or another purpuses.
 
#deserialization
 
* register streamlines within the streamer - streamer.registerStreamline
* obtain a byte buffer with serialized objects
* create an instance of InputStream. Put bytes onto the stream using <code>InputStream.expand()</code>
* read objects from the stream using <code>InputStream.read()</code> or <code>InputStream.readOf()</code>
 
#buffers
represents raw bytes stored as sequence and provides read / write operations of bytes or basic types like <code>Integer</code> or <code>Float</code>.
Interfaces <code>vm.lis.streamer.io::IReadBuffer</code> and <code>vm.lis.streamer.io::IWriteBuffer</code>
are used within streamer to operate with bytes buffer. Additionaly <code>vm.lis.streamer.io::IExpandedBuffer</code>
which allows to expand read buffer (or add some bytes to the buffer end) is used to provide bytes transfer and chunk. 
The buffer interfaces are implemented in[vm.lis.streamer.io::VMBuffer which used within streamer by default.
 
#output stream
the objects are serialized onto output stream, which contains information about serialized objects
and objects data as bytes sequence. <code>IOutputStream</code> interface provides objects serialization in a buffer.
<code>IOutputBuffer</code> is an output stream + data storing into byte buffer, see <code>IOutputBuffer.flushTo()</code>.
<code>OutputStream</code> is implementation of <code>IOutputBuffer</code>. Data can be stored into any buffer which
satisfies <code>vm.lis.streamer.io::IExpandedBuffer</code> interface. So, some crypthographic or compression
or another storing logic can be added. By default <code>vm.lis.streamer.io::VMBuffer</code> is used.

#input stream
<code>IInputStream</code> interface provides objects deserialization background.
<code>IInputBuffer</code> interface adds to <code>IInputStream</code> some capabilities,
for example, adding new bytes to the end of the stream, see <code>IInputBuffer.expand()</code>.
<code>InputStream</code> is implementation of <code>IInputBuffer</code>. Input stream contains information
about metamodel declarations (see package <code>ceylon.language.meta</code>) and objects data as bytes sequence.
When some objects data no longer needed it can be removed using <code>IInputBuffer.removeData()</code>, which
removes only objects data but keeping declarations as is, so they can be used for further reading operations.
If stream is cleaned calling <code>IInputBuffer.clear()</code> declarations are removed as well as data.
So, following data reading operation will not see declarations and may be not deserialized correctly.

#streamlines
provide serialization / deserialization logic for the particular type. Represented via <code>IStreamline</code> 
or <code>IStreamlineDeclaration</code> interfaces. The streamline is to be registered within streamer, 
see <code>streamer.registerStreamline()</code>. The same streamlines with the same id's have to be registered
at both serialization and deserialization sides. Once streamline is registered all objects
which are subtypes of a supertype streamline is registered for are serialized / deserialized using this streamline.

Some streamlines are registered automaticaly and provides serialization / deserialization of basic types.

####built-in streamlines
* basic types: Integer, Float, Boolean, Byte, Character and String
* java ByteArray (java Byte[])
* JSON ceylon.json::Object and ceylon.json::Array 
* Entry with Key and Item to be serialized by registered streamlines
* Iterable with elements to be serialized by registered streamlines. Any object satisfies Iterable
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

* Sequence - the same as Iterable
* Tuple each tuple element has to be serialized by some registered streamlines.
	
Example:
		
    OutputStream outputStream = OutputStream();
    // serialize tuple
    outputStream.write( [1, 2.5, \"SomeString\", 30] );
    IntputStream intputStream = IntputStream();
    outputStream.flushTo( inputStream );
    // deserialize tuple
    [Integer,Float,String,Integer]? tuple = inputStream.readOf<[Integer,Float,String,Integer]>();
    
* ceylon.collection::ArrayList and ceylon.collection::LinkedList. Union or Intersection types are not supported.
  Restored using default initializer arguments (ceylon.collection::ArrayList.growthFactor = 1.5)
* <code>IStreamable</code> interface, which delegates serialization / deserialization to the object themself. This doesn't require additional streamlines to be registered. Just implement <code>IStreamable</code> interface.
  Object type information is stored in the stream, which requires additional bytes. Initializer arguments
  are stored as well. At deserialization the instance will be created automaticaly by this info
  and stored initializer arguments. Then stream is passed to the <code>IStreamable.restore()</code> method
  and the instance can restore particular values. To store this values <code>IStreamable.store()</code>
  method is used during serialization process. Alternatively streamline <code>StreamlineFactory</code> and
  <code>IStorable</code> interface can be used. This way requires factories to be registered within
  <code>StreamlineFactory</code> instance for any storing / restoring types. And streamline
  (<code>StreamlineFactory</code>) registered within the streamer. More classes and instancies required
  to follow this way, but it doesn't require type information to be stored within the stream and is more
  flexible to store classes family, see section [external streamlines](#external streamlines) below
   
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
external streamlines are registered within streamer using <code>streame.registerStreamline()</code> function.
Streamlines have to satisfy <code>IStreamline</code> or <code>IStreamlineDeclaration</code> interfaces.
Each streamline contained in particular module has it own unique id. ID has to be greater than 0 and less than 256.
Streamline id has to be specified at registration using <code>streamer.registerStreamline()</code> function.
 
Example:
 
    class MyStreamline() satisfies IStreamline {...}
    
<code>IStreamline</code> is indended to store / restore objects of particular type and contains three methods:
* <code>IStreamline.write()</code> - objects serialization. Takes instance to be serialized and <code>IOutputStreamline</code> stream, some extension under <code>IOutputStream</code>, which allows to store some raw data about seriazlizing objects and provides access to output stream (<code>IOutputStream</code>) used to store objects with registered streamlines
* <code>IStreamline.instantiate()</code> - used at deserialization proccess to instantiate an object
* <code>IStreamline.fill()</code> - fill instantiated object with stored data. Takes <code>IInputStreamline</code> stream and allows restore data stored using <code>IStreamline.write()</code> method in the same order it was stored
 
<code>IStreamlineDeclaration</code> is indended to store / restore objects base on them declaration
and more suit to store generics. But these streamlines operates by objects of <code>Anything</code> type and
requires more resources then <code>IStreamline</code> based on object type. Contains the same
<code>IStreamlineDeclaration.write()</code>, <code>IStreamlineDeclaration.instantiate()</code> and <code>IStreamlineDeclaration.fill()</code>
methods as IStreamline but uses Anything object type. Absract class <code>StreamlineDeclaration</code> can be used
as a base for streamlines based on declarations.

In order to implement streamline logic following raw classes can be extended:
* <code>StreamlineString</code> allows to store / restore Strings
* <code>StreamlineInitializer</code> allows to store / restore objects that require only initializers data to be stored. It asks initializer arguments at serialization and pass them back to the instance initializer at deserialization
* <code>StreamlineFactory</code> uses factory to create new instance at deserialization. The factory creates instance
  using some default arguments. The instance is responsible to store / restore all data it requires.
  The objects serialized / deserialized by this streamline have to satisfy <code>IStorable</code> interface
  and implements they own storing logic. This streamline is similar to used with <code>IStreamable</code> objects, 
  but it asks factory to create instance instead of storing information about object type. The factories
  must be registered with unique factory id using <code>StreamlineFactory.registerFactory()</code>.

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
not yet supported. At the same time objects of Tuple type are fully supported. 
 
#iterables, IStorable / IStreamable interfaces and inheritance
The type parameter of stored / restored Iterable (or ceylon.collection::ArrayList, or ceylon.collection::LinkedList)
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
<code>InputStream.expand()</code> method. Each byte block must be added one after another according to their appearance in the source array.

The stream treat added bytes to contain only full information on the object. If there is incomplete data to restore
object, stream put the bytes into cash and waits next portion of bytes. Inspect <code>InputStream.bytesAvailable</code>
in order to check if some objects are available in the stream.

Inspect <code>InputStream.waitsMoreBytes</code> to check if the stream still waits some bytes to be expanded into 

#compression, encryption etc
implement <code>vm.lis.streamer.io::IReadBuffer</code>, which used by input stream <code>IInputStream</code>
to restore objects from raw bytes.
implement <code>vm.lis.streamer.io::IExpandedBuffer</code>, which used by output stream (<code>IOutputStream</code>)
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
 
streamer satisfies <code>ceylon.logging::Logger</code> interface and can be used itself to log.
logerWriter is to be registered before logging, follow module <code>ceylon.logging</code>.
Simple <code>FileLogWriter</code> class can be used to log into file. 
 
#exceptions
Streamer is minimized exceptions instead writing errors to the log and put deserialized object to null
 
#examples:
see module <code>vm.lis.streamerexamples</code>
