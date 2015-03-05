"the package defines byte buffers with posiblities to convert simple types
 like Integer and Float to / from raw bytes.
 Buffers are separated by read / write operations: [[IReadBuffer]] and [[IWriteBuffer]]
 [[VMBuffer]] is implementation of [[IReadBuffer]] and [[IWriteBuffer]] based on
 [[Array]] as background byte storage.
 
 [[IExpandedBuffer]] is interface for buffer expansion oradding bytes to the buffer end
 
 [[FileFlusher]] is IExpandBuffer implementation to store bytes to a file"
by("Lisi")
shared package vm.lis.streamer.io;
