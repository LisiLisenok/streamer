import ceylon.language.meta {

	type
}
import vm.lis.streamer {

	IInputStreamline,
	StreamlineDeclaration,
	IOutputStreamline
}
import ceylon.language.meta.model {

	Type,
	ClassOrInterface
}


"base class for collection streamlines:
 * [[writeCollection]] - stores collection items to the stream
 * [[readCollection]] - restores collection items putting them to the collection via specified add function
 * [[addMethodName]] - String name of method used to add element to the collection,
   must take only when argument - collection element
 * [[arguments]] - collection initializer arguments
 * [[getCollectionType]] has to return collection type to be stored
 * reading sequence:
 	* [[instantiateCollection]] with stored type
 	* [[fill]] -[[readCollection]] using method specified by name [[addMethodName]]
 	* return [[transformFilled]]
 "
by("Lisi")
shared abstract class CollectionStreamline() extends StreamlineDeclaration()
{
	shared default String addMethodName = "add";
	shared default Anything[] arguments = [{}];
	
	
	Integer writeCollection( IOutputStreamline stream, Anything collection ) {
		if ( is Iterable<Anything, Null | Nothing> collection ) {
			// number of items in iterable
			Integer nCount = collection.size;
			stream.writeOctad( nCount );
			// store each item
			for ( item in collection ) {
				stream.output.write( item );
			}
			return nCount;
		}
		return 0;
	}
	
	"takes stream and function to add read element to collection"
	Integer readCollection( IInputStreamline stream, Anything ( Anything ) add ) {
		// number of items in collection
		Integer nCount = stream.readOctad();
		for( i in 0 : nCount ) {
			add( stream.input.read() );
		}
		return nCount;
	}
	
	"actual type of collection to be stored"
	shared default ClassOrInterface? getCollectionType( Anything data ) => type( data );
	
	shared actual default void write( IOutputStreamline stream, Anything data ) {
		if ( exists collectionType = getCollectionType( data ) ) {
			stream.writeOctad( stream.storeType( collectionType ) );
			writeCollection( stream, data );
		}
	}
	
	"instantiate collection from stored type"
	shared default Anything instantiateCollection( Type t ) => instantiateFrom( t, arguments );
	
	shared actual default Anything instantiate( IInputStreamline stream ) {
		if ( exists t = stream.getType( stream.readOctad() ) ) {
			return instantiateCollection( t );
		}
		else { return {}; }
	}
	
	"collection can be transformed after filled"
	shared default Anything transformFilled( Object instance ) => instance;
	
	shared actual default Anything fill( IInputStreamline stream, Anything instance ) {
		if ( exists instance ) {
			// fill collection using specified method with addMethodName - must take onle one parameter - object of collection type
			if ( exists addMethod = getMethod<Anything>( instance, addMethodName ) ) {
				readCollection( stream, addMethod.apply );
				return transformFilled( instance );
			}
			else {
				readCollection( stream, ( Anything obj ) => null );
				return transformFilled( instance );
			}
		}
		return {};
	}
	
}
