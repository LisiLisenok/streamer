import ceylon.language.meta.model {

	ClassOrInterface
}

"output data stream interface:
 * writes raw byte data
 * [[output]] - [[IOutputStream]] behind this outputStreamline
 "
see( `interface IStreamline` )
shared interface IOutputStreamline
{
	"underlying output stream"
	shared formal IOutputStream output;
	
	shared formal void writeByte( Byte byte );
	shared formal void writeBytes( {Byte*} bytes );
	"octad == 8 bytes == Integer"
	shared formal void writeOctad( Integer octad );
	"write nBytes lower bytes of Integer octad, for example nBytes = 2 writes word, nBytes = 8 writes whole Integer"
	shared formal void writeLowerBytes( Integer nBytes, Integer octad );
	
	shared formal Integer storeType( ClassOrInterface instanceType );
	
	"returns reference id if object has been stored previously"
	shared formal Integer? getReferenceID( Object obj );
	"store reference on object, returns reference id"
	shared formal Integer storeReference( Object obj );
}
