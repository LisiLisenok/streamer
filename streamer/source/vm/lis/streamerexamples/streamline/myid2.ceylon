import ceylon.language.meta {

	type
}
import ceylon.json {

	JsonObject=Object
}
import vm.lis.streamer {

	IInputStreamline,
	StreamlineDeclaration,
	IOutputStreamline
}

"base interface used to access attributes at storing / restoring process"
interface IInfo<out Key>
{
	shared formal Key key;
	shared formal variable JsonObject info;
}

"class to be stored using declaration streamline"
class MyID2<Key>( key ) satisfies Comparable<MyID2<Key>>, IInfo<Key>
		given Key satisfies Comparable<Key>
{
	"key"
	shared actual Key key;
	
	"some usefull information"
	shared actual variable JsonObject info = JsonObject();
	
	shared actual Comparison compare( MyID2<Key> other ) => key.compare( other.key );
}

"declaration streamline - looks on declaration rather than type"
class MyID2Streamline() extends StreamlineDeclaration()
{
	"store object to the stream"
	shared actual void write( IOutputStreamline stream, Anything data ) {
		// store type info - union types are not supported!
		stream.writeOctad( stream.storeType( type( data ) ) );
		// store object data
		if ( is IInfo<Anything> data ) {
			stream.output.write( data.key );
			stream.output.write( data.info );
		}
	}
	
	"instantiate object using stored type data (union types are not supported) and initializaer arguments"
	shared actual Anything instantiate( IInputStreamline stream ) {
		if ( exists type = stream.getType( stream.readOctad() ) ) {
			return instantiateFrom( type, [stream.input.read()] );
		}
		return null;
	}
	
	"fill instantiated object"
	shared actual Anything fill( IInputStreamline stream, Anything instance ) {
		if ( is IInfo<Anything> instance ) {
			instance.info = stream.input.readOf<JsonObject>() else JsonObject();
		}
		return instance;
	}
	
}

"generating myID2"
MyID2<Key> generateID2<Key>( Key key, String param, String | Integer arg )
		given Key satisfies Comparable<Key>
		{
	MyID2<Key> id = MyID2<Key>( key );
	id.info = JsonObject{ 
		param -> arg
	};
	return id;
}
