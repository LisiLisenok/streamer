import ceylon.json {
	
	JsonObject=Object
}
import vm.lis.streamer {

	streamer,
	OutputStream,
	InputStream
}
import vm.lis.streamer.io {

	VMBuffer
}
import ceylon.collection {

	ArrayList
}

"data receiver"
class Receiver( InputStream stream ) {
	
	ArrayList<JsonObject> objects = ArrayList<JsonObject>(); 
	
	shared void receive() {
		variable Integer receiveCount = 0;
		variable Integer receiveEmpty = 0;
		while ( stream.bytesAvailable > 0 ) {
			if ( exists obj = stream.readOf<JsonObject>() ) {
				objects.add( obj );
			}
			else { receiveEmpty ++; }
			receiveCount ++;
		}
		print( "``receiveCount`` objects have been received  and ``receiveEmpty`` of them are empty" );
	}
	
	shared void validateObjects() {
		print( "total objects number is ``objects.size``, last is ``objects.last else "empty"``, is still waiting -> ``stream.waitsMoreBytes``" );
	}
	
}

"chunk: divide byte buffer into several piecies and read one-by-one"
shared void chunk() {
	Integer count = 50;
	{JsonObject*} objects = storingData( count );
	
	// initialize streamer at first
	streamer.initialize();
	// stream objects to be written to
	OutputStream outputStream = OutputStream();	
	// writing objects to the stream
	for ( obj in objects ) {
		outputStream.write( obj );
	}
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	InputStream inputStream = InputStream();
	Receiver receiver = Receiver( inputStream );
	
	// send objects dividing total buffer on nBufs piecies
	Integer nBufs = 5;
	Integer totalSize = buffer.size;
	Integer size = totalSize / nBufs + 1;
	for ( i in 0 : nBufs ) {
		// shadow buffer (without bytes copying)is used to divide buffer
		inputStream.expand( buffer.shadow( i * size, size ) );
		// notify receiver
		receiver.receive();
		receiver.validateObjects();
		print( "\n" );
	}
	
}

"collect json objects"
{JsonObject*} storingData( Integer count ) {
	return { for ( i in 0 : count ) fillObject( i + 1 ) };
}

"fill json object"
JsonObject fillObject( Integer id ) {
	return JsonObject {
		"id" -> id,
		"name" -> id.string
	};
}