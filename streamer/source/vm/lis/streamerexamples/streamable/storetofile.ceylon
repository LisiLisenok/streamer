import vm.lis.streamer {

	streamer,
	InputStream
}
import ceylon.file {

	current
}
import vm.lis.streamer.io {

	FileFlusher,
	VMBuffer
}
import ceylon.io {

	newOpenFile,
	OpenFile
}
import ceylon.io.buffer {

	ByteBuffer,
	newByteBuffer
}


shared void storeToFile() {
	// initialize streamer at first
	streamer.initialize();
	
	// store data to the file
	FileFlusher file = FileFlusher( newOpenFile( current.childPath("datastorage.sds").resource ) );
	file.expand( storeOperations() );
	
	OpenFile openFile = newOpenFile( current.childPath("datastorage.sds").resource );
	ByteBuffer bytes = newByteBuffer( 3000 );
	bytes.limit = openFile.read( bytes );
	bytes.flip();
	restoreOperation( InputStream( VMBuffer( bytes ) ) );
	
}
