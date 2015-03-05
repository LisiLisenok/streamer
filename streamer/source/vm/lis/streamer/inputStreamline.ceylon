import ceylon.language.meta.model {

	Type
}


"
 input data stream interface:
 * reads raw byte data
 * [[input]] - [[IInputStream]] behind this inputStreamline
 * when byte is read the stream goes to the next one
 "
see( `interface IStreamline` )
by("Lisi")
shared interface IInputStreamline
{
	"underlying input stream"
	shared formal IInputStream input;
	
	"stream bytes iterable up to end, it doesn't create a copy of bytes from the buffer, just iterate them"
	shared formal {Byte*} bytes();
	"read byte"
	shared formal Byte readByte();
	"read bytes, if count greater than available bytes, then returns all available"
	shared formal {Byte*} readBytes( Integer nCount );
	"read all bytes in the stream"
	shared formal {Byte*} readUpToEnd();
	"octad == 8 bytes == Integer"
	shared formal Integer readOctad();
	"read nBytes lower bytes of Integer, for example nBytes = 2 reads word, nBytes = 8 reads whole Integer"
	shared formal Integer readLowerBytes( Integer nBytes );
	
	"get type by id"
	shared formal Type? getType( Integer id );
	
	"returns object if it has been restored previously"
	shared formal Object? getObjectByReferenceID( Integer referenceID );
	"store object referenceID if it hasn't been stored previously"
	shared formal void addObjectReference( Object obj, Integer referenceID );
}

