
"streamline interface - to read / write objects of specified type"
by("Lisi")
shared interface IStreamline<DataType>
{
	"write object to output stream"
	shared formal void write( IOutputStreamline stream, DataType data );
	
	"instantiate object from input stream"
	shared formal DataType? instantiate( IInputStreamline stream );
	"fill object from stream"
	shared formal DataType? fill( IInputStreamline stream, DataType? instance );
}


"declaration streamline, doesn't specify type of serialized item, stores / restores declarations"
by("Lisi")
shared interface IStreamlineDeclaration
{
	"write object to output stream"
	shared formal void write( IOutputStreamline stream, Anything data );
	
	"instantiate object from input stream"
	shared formal Anything instantiate( IInputStreamline stream );
	"fill object from stream"
	shared formal Anything fill( IInputStreamline stream, Anything instance );
}


