import java.lang {

	ByteArray,
	JavaDouble=Double
}
import ceylon.interop.java {

	createJavaByteArray
}
import vm.lis.streamer {

	IStreamline,
	IOutputStreamline,
	IInputStreamline,
	StreamlineString
}
import ceylon.json {

	JsonObject = Object,
	JsonArray = Array
}

by("Lisi")
shared abstract class BuiltInStreamline<DataType>() satisfies IStreamline<DataType>
{
	shared actual DataType? instantiate( IInputStreamline stream ) => null;
}

"set of builtin streamlines - collected within a one object"
by("Lisi")
shared object builtInStreamlines {
	
	shared object nullStreamline extends BuiltInStreamline<Null>() {
		shared actual void write( IOutputStreamline stream, Null data ) {}
		
		shared actual Null fill( IInputStreamline stream, Null? instance )
				=> null;
	}

	shared object emptyStreamline extends BuiltInStreamline<Empty>() {
		shared actual void write( IOutputStreamline stream, Empty data ) {}
		
		shared actual Empty fill( IInputStreamline stream, Empty? instance )
				=> [];
	}
	
	shared object integerStreamline extends BuiltInStreamline<Integer>() {
		shared actual void write( IOutputStreamline stream, Integer data )
			=> stream.writeOctad( data );
		
		shared actual Integer fill( IInputStreamline stream, Integer? instance )
			=> stream.readOctad();
	}

	shared object floatStreamline extends BuiltInStreamline<Float>() {
		shared actual void write( IOutputStreamline stream, Float data ) 
			=> stream.writeOctad( JavaDouble.doubleToRawLongBits( data ) );
		
		shared actual Float fill( IInputStreamline stream, Float? instance ) 
			=> Float( JavaDouble.longBitsToDouble( stream.readOctad() ) );
	}

	shared object byteStreamline extends BuiltInStreamline<Byte>() {
		shared actual void write( IOutputStreamline stream, Byte data ) 
			=> stream.writeByte( data );
		
		shared actual Byte fill( IInputStreamline stream, Byte? instance )
			=> stream.readByte();
	}

	shared object booleanStreamline extends BuiltInStreamline<Boolean>() {
		shared actual void write( IOutputStreamline stream, Boolean data ) {
			if ( data ) { stream.writeByte( Byte ( 1 ) ); }
			else { stream.writeByte( Byte ( 0 ) ); }
		}
		shared actual Boolean fill( IInputStreamline stream, Boolean? instance )
			=> stream.readByte() != Byte( 0 );
	}

	shared object characterStreamline extends BuiltInStreamline<Character>() {
		shared actual void write( IOutputStreamline stream, Character data ) 
			=> stream.writeOctad( data.integer );
		
		shared actual Character fill( IInputStreamline stream, Character? instance ) 
			=> stream.readOctad().character;
	}

	shared object javaBytesStreamline  extends BuiltInStreamline<ByteArray>() {
		shared actual void write( IOutputStreamline stream, ByteArray data ) {
			stream.writeOctad( data.size );
			stream.writeBytes( data.iterable );
		}
		
		shared actual ByteArray fill( IInputStreamline stream, ByteArray? instance ) 
			=> createJavaByteArray( stream.readBytes( stream.readOctad() ) );
	}

	shared object stringStreamline extends StreamlineString<String>() {
		shared actual void write( IOutputStreamline stream, String data )
			=> writeUTF16String( stream, data );
		
		shared actual String? instantiate(IInputStreamline stream) => null;
		shared actual String fill( IInputStreamline stream, String? instance )
			=> readUTF16String( stream );
	}
	
	shared object jsonObjectStreamline satisfies IStreamline<JsonObject> {
		shared actual void write( IOutputStreamline stream, JsonObject data ) {
			// number of objects in the json
			stream.writeOctad( data.size );
			// key->objects
			for ( key->item in data ) {
				stream.output.write( key );
				stream.output.write( item );
			}
		}
		
		shared actual JsonObject? instantiate(IInputStreamline stream) => JsonObject();
		
		shared actual JsonObject? fill( IInputStreamline stream, JsonObject? instance ) {
			if ( exists instance ) {
				// number of objects in the json
				Integer nObjects = stream.readOctad();
				for ( i in 0 : nObjects ) {
					if ( exists strKey = stream.input.readOf<String>(),
						exists obj = stream.input.readOf<String|Boolean|Integer|Float|JsonObject|JsonArray>() )
					{
						instance.put( strKey, obj );
					}
				}
			}
			return instance;
		}
	}
	
	shared object jsonArrayStreamline satisfies IStreamline<JsonArray> {
		shared actual void write( IOutputStreamline stream, JsonArray data ) {
			// number of objects in the json
			stream.writeOctad( data.size );
			// array objects
			for ( item in data ) {
				stream.output.write( item );
			}
		}
		
		shared actual JsonArray? instantiate(IInputStreamline stream) => JsonArray();

		shared actual JsonArray? fill( IInputStreamline stream, JsonArray? instance ) {
			if ( exists instance ) {
				// number of objects in the json
				Integer nObjects = stream.readOctad();
				for ( i in 0 : nObjects ) {
					if ( exists obj = stream.input.readOf<String|Boolean|Integer|Float|JsonObject|JsonArray>() ) {
						instance.add( obj );
					}
				}
			}
			return instance;
		}
	}

}
