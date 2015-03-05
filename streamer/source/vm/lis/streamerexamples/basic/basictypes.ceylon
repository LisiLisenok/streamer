import vm.lis.streamer {

	OutputStream,
	InputStream,
	streamer
}
import vm.lis.streamer.io {

	VMBuffer
}



"example of streamer using with basic type: Integer, Float, String, Boolean, Character, Entry, Tuple"
shared void basictypes() {
	
	// initialize streamer at first
	streamer.initialize();
	
	// objects to be written
	Integer intVal = 1;
	Float floatVal = -2.5;
	String strVal = "streamer";
	Boolean boolVal = true;
	Character charVal = 's';
	<Integer->String> entryVal = 1->"streamer";
	[Float, Float, String] tupleVal = [0.0, 0.0, "origin"];

	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// writing objects to the stream
	outputStream.write( intVal );
	outputStream.write( floatVal );
	outputStream.write( strVal );
	outputStream.write( boolVal );
	outputStream.write( charVal );
	outputStream.write( entryVal );
	outputStream.write( tupleVal );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring objects from the stream in the same order as they were storing:
	// Integer, Float, String, Boolean, Character, Entry, Tuple
	
	if ( exists readVal = inputStream.readOf<Integer>() ) {
		print( "Integer is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	if ( exists readVal = inputStream.readOf<Float>() ) {
		print( "Float is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	if ( exists readVal = inputStream.readOf<String>() ) {
		print( "String is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	if ( exists readVal = inputStream.readOf<Boolean>() ) {
		print( "Boolean is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	if ( exists readVal = inputStream.readOf<Character>() ) {
		print( "Character is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	if ( exists readVal = inputStream.readOf<Integer->String>() ) {
		print( "Integer->String is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
	if ( exists readVal = inputStream.readOf<[Float,Float,String]>() ) {
		print( "Tuple is ``readVal``" );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
}