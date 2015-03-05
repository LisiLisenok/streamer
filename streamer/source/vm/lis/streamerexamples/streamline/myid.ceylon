import ceylon.language.meta {

	type
}
import ceylon.language.meta.declaration {

	ValueDeclaration
}
import ceylon.json {

	JsonObject=Object
}
import vm.lis.streamer {

	IInputStreamline,
	StreamlineDeclaration,
	IOutputStreamline
}


"class to be stored using declaration streamline"
class MyID<Key>( key ) satisfies Comparable<MyID<Key>>
		given Key satisfies Comparable<Key>
{
	"key"
	shared Key key;
	
	"some usefull information"
	shared variable JsonObject info = JsonObject();
	
	shared actual Comparison compare( MyID<Key> other ) => key.compare( other.key );
}

"declaration streamline - looks on declaration rather than type"
class MyIDStreamline() extends StreamlineDeclaration()
{
	ValueDeclaration valKey = `value MyID.key`;
	ValueDeclaration valInfo = `value MyID.info`;
	
	"store object to the stream"
	shared actual void write( IOutputStreamline stream, Anything data ) {
		// store type info - union types are not supported!
		stream.writeOctad( stream.storeType( type( data ) ) );
		// store object data
		if ( is Object data ) {
			if ( exists key = valKey.memberGet( data ) ) {
				stream.output.write( key );
			}
			if ( exists info = valInfo.memberGet( data ) ) {
				stream.output.write( info );
			}
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
		if ( is Object instance ) {
			valInfo.memberSet( instance, stream.input.readOf<JsonObject>() else JsonObject() );
		}
		return instance;
	}
	
}

"generating myID"
MyID<Key> generateID<Key>( Key key, String param, String | Integer arg )
		given Key satisfies Comparable<Key>
		{
	MyID<Key> id = MyID<Key>( key );
	id.info = JsonObject{ 
		param -> arg
	};
	return id;
}
