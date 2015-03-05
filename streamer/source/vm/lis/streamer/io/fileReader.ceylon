import ceylon.io {

	OpenFile,
	newOpenFile
}
import ceylon.io.buffer {

	ByteBuffer,
	newByteBuffer
}

"[[IReadBuffer]] with underlaying [[OpenFile]].
 read bytes are cached with size cacheSize.
 Reads count bytes starting from start position"
by("Lisi")
class FileReader( file, Integer cacheSize = 1024, Integer start = 0, Integer count = -1 )
		satisfies IReadBuffer
{
	OpenFile file;
	
	ByteBuffer cache = newByteBuffer( cacheSize );
	
	variable Integer cacheStart = start;
	file.position = start;
	
	Integer limit => count >= 0 && start + count <= file.size then start + count else file.size;
	shared actual Integer size = limit - start;
	
	shared actual Integer bytesAvailable => size - position > 0 then size - position else 0;
	shared actual Integer position => cacheStart + cache.position - start;
	assign position {
		if ( position < cacheStart || position >= cacheStart + cacheSize ) {
			file.position = position;
			reloadCache();
		}
		else {
			cache.position = position - cacheStart;
		}
	}
	
	void reloadCache() {
		if ( file.position < cacheStart || file.position >= cacheStart + cacheSize ) {
			cacheStart = file.position;
			file.read( cache );
			cache.position = 0;
		}
		else {
			cache.position = file.position - cacheStart;
		}
	}
	
	shared actual void flipEnd() => position = limit;
	shared actual void flipStart() => position = 0;
	
	shared actual Iterator<Byte> iterator() {
		object iter satisfies Iterator<Byte> {
			ByteBuffer cache = newByteBuffer( cacheSize );
			cache.limit = cacheSize;
			variable Integer currentPosition = outer.position;
			
			void reloadCache() {
				if ( currentPosition < file.size ) {
					Integer nPos = file.position;
					file.position = currentPosition;
					cache.limit = file.read( cache );
					cache.position = 0;
					currentPosition = file.position + cache.limit;
					print( "current ``currentPosition``, size ``file.size``, limit ``cache.limit``");
					file.position = nPos;
				}
				else {
					cache.position = cache.limit;
				}
			}
			
			shared actual Byte|Finished next() {
				if ( !cache.hasAvailable ) { reloadCache(); }
				if ( cache.hasAvailable) { return cache.get(); }
				else { return finished; }
			}
		}
		return iter;
	}
	
	shared actual Byte readByte() {
		if ( ! cache.hasAvailable ) {
			file.position = cache.position + cacheSize; 
			reloadCache();
		}
		return cache.getByte();
	}
	
	shared actual IReadBuffer shadow( Integer nStart, Integer nCount )
			=> FileReader( newOpenFile( file.resource ), cacheSize, nStart + this.start, nCount );
	
}
