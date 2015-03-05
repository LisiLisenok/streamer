import java.lang {

	JavaDouble=Double
}



"write buffer == [[IBuffer]] + writing simple data.
 At writing operations the current io position is shifted on number of written bytes"
by("Lisi")
shared interface IWriteBuffer satisfies IBuffer
{
	"write a byte to the buffer"
	shared formal void writeByte( Byte byte );
	
	"write bytes - sinply iterate [[writeByte]]"
	shared default void writeBytes( {Byte*} bytes ) {
		for ( b in bytes ) {
			writeByte( b );
		}
	}
	
	"write Integer == 8 bytes"
	shared default void writeInteger( Integer octad ) {
		writeLowerBytes( bufferConstants.bytesInInteger, octad );
	}
	
	"write nBytes lower bytes of Integer octad, for example nBytes = 2 writes word, nBytes = 8 writes whole Integer"
	throws( `class AssertionError`, "nBytes must be > 0 and <= 8")
	shared default void writeLowerBytes( Integer nBytes, Integer octad ) {
		assert( nBytes > 0 && nBytes <= bufferConstants.bytesInInteger );
		variable Integer nCurrent = octad;
		for( i in 0 : nBytes ) {
			Integer n = nCurrent;
			nCurrent = nCurrent.rightLogicalShift( 8 );
			writeByte( Byte( n.and( #FF ) ) );
		}
	}
	
	"write Float == 8 bytes"
	shared default void writeFloat( Float f ) {
		writeInteger( JavaDouble.doubleToRawLongBits( f ) );
	}
	
	"write string, first 8 bytes is Integer == number of charcters in the string"
	shared default void writeUTF16String( String str ) {
		writeInteger( str.size );
		for ( c in str ) {
			writeInteger( c.integer );
		}
	}
	
	"flush - write data to specified buffer"
	shared formal void flushTo( IExpandedBuffer buffer );
}