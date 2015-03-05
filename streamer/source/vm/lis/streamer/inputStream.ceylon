import vm.lis.streamer.io {

	IReadBuffer
}


"input data stream interface - read objects with this
 when object is read the stream goes to the next one"
by("Lisi")
shared interface IInputStream
{
	"available bytes in the stream"
	shared formal Integer bytesAvailable;
	"read stored object and move stream to the next object, returns null if no object"
	shared formal Anything read();
	"trying to read object of specified type and move stream to the next object,
	 return instance of DataType or null"
	shared formal DataType? readOf<out DataType>();
}


"input buffer - [[IInputStream]] + add bytes + clear"
by("Lisi")
shared interface IInputBuffer satisfies IInputStream
{
	"flip - stream is returned back to the initial state,
	 so the reading operations will be done from the first added object
	 after the latest [[clear]] or [[removeData]] call or the stream creation"
	shared formal void flip();
	
	"add bytes to the end of the stream"
	shared formal void expand( IReadBuffer addingBytes );
	
	"remove data but keep declarations"
	see( `function clear` )
	shared formal void removeData();
	
	"clear stream - remove data and declarations"
	see( `function removeData` )
	shared formal void clear();
}
