import ceylon.io {

	OpenFile
}
import ceylon.io.buffer {

	ByteBuffer,
	newByteBuffer
}

"flush bytes to the [[OpenFile]]"
see(`function IWriteBuffer.flushTo`)
by("Lisi")
shared class FileFlusher( file, Integer cacheSize = 1024, Boolean overwrite = true )
		satisfies IExpandedBuffer
{
	"file behind this flusher"
	OpenFile file;
	
	"append bytes to the end of file if overwrite is false or overwrite file otherwise"
	shared actual void expand( IReadBuffer bytes ) {
		if ( overwrite ) { file.truncate( 0 ); }
		ByteBuffer buffer = newByteBuffer( cacheSize );
		while( bytes.bytesAvailable != 0 ) {			
			for ( i in 0 : cacheSize ) {
				if ( bytes.bytesAvailable == 0 ) { break; } 
				buffer.putByte( bytes.readByte() );
			}
			buffer.flip();
			if( buffer.hasAvailable ) {
				file.writeFully( buffer );
			}
			buffer.flip();
		}
	}
	
}
