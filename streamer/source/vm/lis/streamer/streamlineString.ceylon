import vm.lis.streamer {

	IOutputStreamline,
	IStreamline,
	IInputStreamline
}


"provides String read / write operations"
by("Lisi")
shared abstract class StreamlineString<DataType>() satisfies IStreamline<DataType>
{
	"store UTF16 string in the stream"
	shared void writeUTF16String( IOutputStreamline stream, String str ) {
		stream.writeOctad( str.size );
		for ( c in str ) {
			stream.writeOctad( c.integer );
		}
	}
	"restore UTF16 string from the stream"	
	shared String readUTF16String( IInputStreamline stream ) {
		Integer nLength = stream.readOctad();
		variable String str = "";
		for ( i in 0 : nLength ) {
			str += stream.readOctad().character.string;
		}
		return str;
	}
}
