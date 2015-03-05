import vm.lis.streamer.io {

	IExpandedBuffer
}


"output data stream interface - store objects.
 Objects are written one by one"
by("Lisi")
shared interface IOutputStream
{
	"write data to the stream"
	shared formal void write( Anything data );
}

"output buffer - [[IOutputStream]] + flush (store stream to the byte buffer)"
by("Lisi")
shared interface IOutputBuffer satisfies IOutputStream
{
	"flush stream to read buffer"
	shared formal void flushTo( IExpandedBuffer buffer );
}

