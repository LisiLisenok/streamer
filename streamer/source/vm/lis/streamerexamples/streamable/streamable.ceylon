import vm.lis.streamer {
	
	OutputStream,
	InputStream,
	IStreamable,
	IOutputStream,
	IInputStream,
	streamer
}
import vm.lis.streamer.io {
	
	VMBuffer,
	IReadBuffer
}


"class to be serialized using streamable interface"
class Operands<Type>( x, y ) satisfies IStreamable
	given Type  of Float | Integer satisfies Numeric<Type>
{
	shared Type x;
	shared Type y;
	variable Type z = x + y;
	variable String operationType = "+";
	
	shared void doOperation( String type, Type operation(Type first, Type second) ) {
		z = operation( x, y );
		operationType = type;
	}
	
	shared actual String string => "``x`` ``operationType`` ``y`` = ``z``";
	
	"streamline asks arguments send to initializer at serialization"
	shared actual Anything[] initializerArguments() => [x, y];
	
	"storing own data"	
	shared actual void store(IOutputStream stream) {
		stream.write( z );
		stream.write( operationType );
	}
	
	"restoring own data"
	shared actual void restore( IInputStream stream ) {
		z = stream.readOf<Type>() else x + y;
		operationType = stream.readOf<String>() else "+";
	}
	
}


"example of streamer using to store / restore objects using streamable streamline:
 * objects to be satisfy [[IStreamable]] interface
 * serialization - object type information, intializer arguments and anything an object wants
 * deserialization - object instantiated with stored initializer arguments and then reads stored data"
shared void streamable() {
	
	// initialize streamer at first
	streamer.initialize();
	
	// push buffer to the input stream
	restoreOperation( InputStream( storeOperations() ) );
	
}

void restoreOperation( InputStream inputStream ) {
	// restoring streamable objects from the stream
	print( inputStream.readOf<Operands<Float>>() else "ooops! wrong reading" );
	print( inputStream.readOf<Operands<Integer>>() else "ooops! wrong reading" );
	print( inputStream.readOf<Operands<Integer>>() else "ooops! wrong reading" );
	print( inputStream.readOf<{Operands<Float>*}>() else "ooops! wrong reading" );
}

IReadBuffer storeOperations() {
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	
	// write streamables to the stream
	
	Operands<Float> operandFirst = Operands<Float>( 3.0, 5.0 );
	operandFirst.doOperation( "/", (Float first, Float second) => first / second );
	outputStream.write( operandFirst );
	
	Operands<Integer> operandSecond = Operands<Integer>( 15, 30 );
	operandSecond.doOperation( "-", (Integer first, Integer second) => first - second );
	outputStream.write( operandSecond );
	
	Operands<Integer> operandThird = Operands<Integer>( 15, 30 );
	outputStream.write( operandThird );
	
	{Operands<Float>*} floatOperands = { for( i in 0 : 10 ) Operands<Float>( i * 0.5, ( i - 3 ) * 2.1 )};
	outputStream.write( floatOperands );
	
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	return buffer;
	
}