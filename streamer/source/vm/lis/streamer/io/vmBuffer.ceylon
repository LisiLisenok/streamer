import java.lang {

	ByteArray
}
import ceylon.io.buffer {

	ByteBuffer
}


"buffer to read / write bytes
 iterator returns bytes from current io position and up to the buffer end,
 current io position is not modified by iterator.
 Also [[shadow]] buffer which referes to the same bytes and not modified this buffer position can be used
 Size is not expensive operation (no counting) since the value is stored within the buffer"
by("Lisi")
shared class VMBuffer( {Byte*} | ByteBuffer | ByteArray | VMBuffer | Null bytes = null,
	Integer initialCapacity = 0, growthFactor = 1.5 ) satisfies IReadBuffer, IWriteBuffer, IExpandedBuffer
{
	variable Integer limit = 0;
	variable Integer capacity = initialCapacity;
	Float growthFactor;
	variable Integer nPosition = 0;
	
	variable Array<Byte> buffer;
	
	if ( ! bytes exists ) {
		buffer = arrayOfSize<Byte>( capacity, Byte( 0 ) );
	}
	else {
		Integer nSize;
		{Byte*} fillTo;
		if ( is {Byte*} | ByteBuffer | VMBuffer bytes ) {
			nSize = bytes.size;
			fillTo = bytes;
		}		
		else if ( is ByteArray bytes ) {
			nSize = bytes.size;
			fillTo = bytes.iterable;
		}
		else {
			nSize = 0;
			fillTo = {};
		}
		if ( capacity > nSize ) {
			buffer = Array<Byte>( fillTo.chain( { for( i in 0 : capacity - nSize ) Byte(0) } ) );
		}
		else {
			buffer = Array<Byte>( fillTo );
			capacity = nSize;
		}
		limit = nSize;
	}
	
	void resizeTo( Integer newCapacity ) {
		capacity = newCapacity;
		buffer = Array<Byte>( buffer.chain( { for( i in 0 : capacity - buffer.size ) Byte(0) } ) );
	}
	void resize() {
		resizeTo( ( growthFactor * capacity ).integer + 1 );
	}
	
	"current read / write position to be not less zero and not greater limit,
	 if set to limit only writing to endof buffer is possible"
	shared actual Integer position => nPosition;
	assign position {
		if ( position < 0 ) { nPosition = 0; }
		else if ( position > limit ) { nPosition = limit; }
		else { nPosition = position; }
	}
	
	"available bytes in buffer - from current position and up to end"
	shared actual Integer bytesAvailable => limit - position;
	
	"total bytes in the buffer"
	shared actual Integer size => limit;
	
	"extract nCount bytes from the stream starting from position nPos, returns bytes + actualy read count"
	[{Byte*}, Integer] extractBytes( Integer nPos, Integer nCount ) {
		if( nCount > 0 ) {
			Integer nLength = nCount > bytesAvailable then bytesAvailable else nCount;
			return [buffer.span( nPos, nPos + nLength - 1 ), nLength];
		}
		return [{}, 0];
	}

	"byte iterator from current position and up to end"
	shared actual Iterator<Byte> iterator() {
		return ShadowBuffer( position, bytesAvailable ).iterator();
	}
	
	shared actual void flipStart() {
		position = 0;
	}
	shared actual void flipEnd() {
		position = limit;
	}
	
	shared void clear() {
		capacity = initialCapacity;
		buffer = arrayOfSize<Byte>( capacity, Byte( 0 ) );
		limit = 0;
		position = 0;
	}
	
	"shadow buffer class, if nCount < 0 reads up to end"
	throws( `class AssertionError`, "nStart must be greater or equal zero" )
	class ShadowBuffer( Integer nStart, Integer nCount ) satisfies IReadBuffer {
		assert( nStart >= 0 );
		Integer count = nCount >= 0 then nCount else outer.size - nStart;
		variable Integer nPosition = 0;

		shared actual Integer size = nStart + count > outer.size then outer.size - nStart else count;
		shared actual Integer bytesAvailable => size - nPosition;
		
		shared actual void flipStart() => nPosition = 0;
		shared actual void flipEnd() => nPosition = size - nStart;
		
		shared actual Iterator<Byte> iterator() {
			object bufferIterator satisfies Iterator<Byte> {
				variable Integer index = nStart + position;
				variable Integer nSize = nStart + size;
				shared actual Byte | Finished next() {
					if ( index < nSize ) {
						if ( exists b = buffer.get( index++ ) ) {
							return b;
						}
					}
					return finished;
				}
			}
			return bufferIterator;
		}
		
		shared actual Integer position => nPosition;
		assign position {
			if ( position < 0 ) { nPosition = 0; }
			else if ( position > count ) { nPosition = count; }
			else { nPosition = position; }
		}
		
		shared actual Byte readByte() {
			assert( bytesAvailable > 0, exists b = buffer[nStart + position] );
			position ++;
			return b;
		}
		shared actual {Byte*} readBytes( Integer nCount ) {
			value extract = extractBytes( nStart + position, nCount );
			position += extract[1];
			return extract[0];
		}
		shared actual IReadBuffer shadow( Integer nStart, Integer nCount )
			=> ShadowBuffer( this.nStart + nStart,
				nStart + nCount > this.count then this.count - nStart else nCount );
	}
	
	shared actual void expand( IReadBuffer bytes ) {
		Integer nPos = position;
		flipEnd();
		writeBytes( bytes );
		position = nPos;
	}
	
	throws( `class AssertionError`, "nStart must be greater or equal zero" )
	throws( `class AssertionError`, "nCount must be greater or equal zero" )
	shared actual IReadBuffer shadow( Integer nStart, Integer nCount ) {
		return ShadowBuffer( nStart, nCount );
	}

	// reading
	throws(`class AssertionError`, "reading outside buffer bounds")
	shared actual Byte readByte() {
		assert( bytesAvailable > 0, exists b = buffer.getFromFirst( position ) );
		position ++;
		return b;
	}
	shared actual {Byte*} readBytes( Integer nCount ) {
		value extract = extractBytes( position, nCount );
		position += extract[1];
		return extract[0];
	}
	
	// writing
	shared actual void writeByte( Byte byte ) {
		if ( position == limit ) {
			if ( limit == capacity ) { resize(); }
			limit ++;
		}
		buffer.set( position, byte );
		position ++;
	}
	shared actual void writeBytes( {Byte*} bytes ) {
		Integer nSize = size + bytes.size;
		if ( nSize > capacity ) {
			resizeTo( nSize );
		}
		super.writeBytes( bytes );
	}
	
	shared actual void flushTo( IExpandedBuffer expandedBuffer ) {
		expandedBuffer.expand( shadow( 0, size ) );
	}
	
}
