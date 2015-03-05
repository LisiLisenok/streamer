import java.lang {

	JavaDouble=Double
}

"read buffer == [[IBuffer]] + reading simple data.
 At reading operations the current io position is shifted on number of read bytes"
by("Lisi")
shared interface IReadBuffer satisfies IBuffer
{
	"shadow buffer, which refers to the same bytes, with io position starting from nStart
	 and available bytes are limited to nCount or max possible.
	 When reading shadow buffer initial buffer io position is not modified.
	 If nCount < 0 reads up to the end"
	shared formal IReadBuffer shadow( Integer nStart, Integer nCount = -1);
	
	"read byte at current io position"
	throws(`class AssertionError`, "reading outside buffer bounds")
	shared formal Byte readByte();
	
	"skip nBytes bytes - current io position is moved on nBytes"
	shared default void skipBytes( Integer nBytes = 1 ) {
		position += nBytes;
	}
	"skip nOctads octads, octad is 8 bytes - current io position is moved on 8 * nOctads"
	shared default void skipOctads( Integer nOctads = 1 ) {
		position += nOctads * bufferConstants.bytesInInteger;
	}
	
	"read nCount bytes from current io position, if nCount less than available bytes reads all available
	 by default siply iterate [[readByte]]"
	shared default {Byte*} readBytes( Integer nCount ) {
		if( nCount > 0 ) {
			Integer nLength = nCount > bytesAvailable then bytesAvailable else nCount;
			return { for ( i in 0 : nLength ) readByte() };
		}
		return {};
	}
	
	"read bytes from current io position and up to the buffer end"
	shared default {Byte*} readUpToEnd() => readBytes( bytesAvailable );
	
	"read Integer == 8 bytes"
	shared default Integer readInteger() {
		return readLowerBytes( bufferConstants.bytesInInteger );
	}
	
	"read nBytes lower bytes of Integer, for example nBytes = 2 reads word, nBytes = 8 reads whole Integer"
	throws( `class AssertionError`, "nBytes must be > 0 and <= 8")
	shared default Integer readLowerBytes( Integer nBytes ) {
		assert( nBytes > 0 && nBytes <= bufferConstants.bytesInInteger );
		{Byte*} bytes = shadow( position, nBytes );
		variable Integer nOctad = 0;
		Iterator<Byte> iter = bytes.iterator();
		for( i in 0 : nBytes ) {
			if ( is Byte b = iter.next() ) {
				nOctad = nOctad.or( b.unsigned.leftLogicalShift( 8 * i ) );
			}
			else {
				break;
			}
		}
		position += nBytes;
		return nOctad;
	}	
	
	"read Float == 8 bytes"
	shared default Float readFloat() {
		return Float( JavaDouble.longBitsToDouble( readInteger() ) );
	}
	
	"read string, first Integer is number of charcters in the string"
	shared default String readUTF16String() {
		Integer nLength = readInteger();
		variable String str = "";
		for ( i in 0 : nLength ) {
			str += readInteger().character.string;
		}
		return str;
	}
}

"expanded buffer"
by("Lisi")
shared interface IExpandedBuffer
{
	"add bytes to the end of the buffer, no changes to io position"
	shared formal void expand( IReadBuffer bytes );
}

