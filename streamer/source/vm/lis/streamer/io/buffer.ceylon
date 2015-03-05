
"some constants used within buffers"
by("Lisi")
shared object bufferConstants
{
	"number of bytes in Integer"
	shared Integer bytesInInteger = runtime.integerSize / 8; //integerAddressableSize / 8;
}


"buffer interface. Byte Iterable returns bytes from current io position and up to the end"
by("Lisi")
shared interface IBuffer satisfies Iterable<Byte>
{
	"current io position"
	shared variable formal Integer position;
	"available bytes in buffer - from current io position and up to end"
	shared formal Integer bytesAvailable;
	"flip the buffer to the start == set io position to zero, so reading operations ready"
	shared formal void flipStart();
	"flip the buffer to the end == set io position to end of the buffer, so writing operations ready"
	shared formal void flipEnd();
}
