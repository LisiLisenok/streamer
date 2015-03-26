import java.io {

	RandomAccessFile
}
import java.lang {

	ByteArray
}


"file cache reader"
class FileCache( String fileName, Integer cacheSize = 1024 ) {
	
	"underlaying file"
	RandomAccessFile file = RandomAccessFile( fileName, "r" );
	"position within file"
	variable Integer filePosition = 0;
	
	"underlaying cache buffer"
	ByteArray cache = ByteArray( cacheSize, Byte( 0 ) );
	"begining fo cache buffer relative to file"
	variable Integer cacheStart = 0;
	"current position within cache"
	variable Integer cachePosition = 0;
	"actual cache size"
	variable Integer cacheActualSize = 0;
	
	"total file size in bytes"
	shared Integer size => file.length();
	"available bytes (fromcurrent position and up to the file end)"
	shared Integer bytesAvailable => size - position > 0 then size - position else 0;
	"position within file"
	shared Integer position => filePosition;
	assign position {
		if ( position < 0 ) { filePosition = 0; }
		else if ( position > size ) { filePosition = size; }
		else { filePosition = position; }
	}
	
	"if queried byte is outside cache - reload cache"
	void reloadCache() {
		cacheStart = filePosition;
		file.seek( filePosition );
		cacheActualSize = file.read( cache, 0, cacheSize );
		if ( cacheActualSize < 0 ) {
			cacheActualSize = file.length() - filePosition;
		}
		cachePosition = 0;
	}
	
	shared void flipEnd() => position = size;
	shared void flipStart() => position = 0;
	
	shared Byte readByte() {
		if ( filePosition < cacheStart || filePosition >= cacheStart + cacheActualSize ) {
			reloadCache();
		}
		Integer n = cachePosition;
		cachePosition ++;
		filePosition ++;
		return cache.get( n );
	}
	
}

"[[IReadBuffer]] reads from file with name fileName.
 [[RandomAccessFile]] is used to access file.
 Read bytes are cached with size cacheSize."
by("Lisi")
shared class FileReader( String fileName, Integer cacheSize = 1024 )
		satisfies IReadBuffer
{	
	"underlaying file"
	FileCache file = FileCache( fileName, cacheSize );
	
	"shadow buffer representation"
	class ShadowReader( Integer nStart, Integer nCount ) satisfies IReadBuffer {
		
		variable Integer nPosition = 0;
				
		Integer count = nCount >= 0 then nCount else file.size - nStart;
		shared actual void flipEnd() => nPosition = count;
		shared actual void flipStart() => nPosition = 0;
		
		shared actual Integer size = nStart + count > file.size then file.size - nStart else count;
		shared actual Integer bytesAvailable => size - nPosition;

		shared actual Integer position => nPosition;
		assign position {
			if ( position < 0 ) { nPosition = 0; }
			else if ( position > count ) { nPosition = count; }
			else { nPosition = position; }
		}
		
		shared actual Byte readByte() {
			Integer nPos = file.position;
			file.position = nStart + nPosition;
			Byte b = file.readByte();
			file.position = nPos;
			nPosition ++;
			return b;
		}
		
		shared actual Iterator<Byte> iterator() {
			object iter satisfies Iterator<Byte> {
				variable Integer nPos = position;
				shared actual Byte|Finished next() {
					Integer nPosStore = nPosition;
					nPosition = nPos;
					if ( bytesAvailable > 0 ) {
						Byte b = readByte();
						nPosition = nPosStore;
						nPos ++;
						return b;
					}
					else { return finished; }
				}
			}
			return iter;
		}		

		shared actual IReadBuffer shadow( Integer nStart, Integer nCount )
			=> ShadowReader( this.nStart + nStart,
				nStart + nCount > this.count then this.count - nStart else nCount );
	}
	
	shared actual Integer size => file.size;
	
	shared actual Integer bytesAvailable => file.bytesAvailable;
	shared actual Integer position => file.position;
	assign position {
		file.position = position;
	}
	
	shared actual void flipEnd() => file.flipEnd();
	shared actual void flipStart() => file.flipStart();
	
	shared actual Iterator<Byte> iterator() => ShadowReader( position, bytesAvailable ).iterator();
	
	shared actual Byte readByte() => file.readByte();
	
	shared actual IReadBuffer shadow( Integer nStart, Integer nCount )
		=> ShadowReader( nStart, nCount );
	
}
