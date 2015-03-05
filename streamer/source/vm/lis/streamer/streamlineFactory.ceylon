import ceylon.collection {

	TreeMap
}
import vm.lis.streamer {

	IStorable
}
import vm.lis.streamer.streamline {

	streamerStorage
}
import ceylon.language.meta.model {

	ClassOrInterface
}


"factorized streamline, uses factory to create objects rather than store type information.
 Just factory ID is stored. Register factories (creator function) before using - [[registerFactory]].
 Stored element must satisfies [[IStorable]]. This abstract class and has to be extended, but
 no methods to be refined (it can be but all works by default). This is required in order to resolve
 same streamline id's from different modules"
see( `interface IStorable`, `interface IStreamline` )
by("Lisi")
shared abstract class StreamlineFactory<Element>() satisfies IStreamline<Element>
	given Element satisfies IStorable
{
	// factories
	TreeMap<String, Integer> factories = TreeMap<String, Integer>(
		(String x, String y) => x.compare( y ) );
	TreeMap<Integer, Element()> factoryIDs = TreeMap<Integer, Element()>(
		(Integer x, Integer y) => x.compare( y ) );
	
	"register factory with specified factory ID
	 the factory is used to create elements when restoring"
	shared default void registerFactory<SubElement>( Integer factoryID, SubElement() createElement )
		given SubElement satisfies Element
	{
		if ( is ClassOrInterface t = `SubElement` ) {
			factories.put( streamerStorage.getDeclarationClassName( t.declaration ), factoryID );
			factoryIDs.put( factoryID, createElement );
		}
	}
	
	"create element with factory specified by ID"
	Element? createElement( Integer factoryID ) {
		if ( exists creator = factoryIDs.get( factoryID ) ) {
			return creator();
		}
		 return null;
	}
	
	shared actual default Element? instantiate( IInputStreamline stream )
			=> createElement( stream.readOctad() );

	shared actual default Element? fill( IInputStreamline stream, Element? instance ) {
		if ( exists instance ) { instance.restore( stream.input ); }
		return instance;
	}
	
	shared actual default void write( IOutputStreamline stream, Element element ) {
		// store factory id
		/*if ( is IFactorized element ) {
			stream.writeOctad( element.factoryID );
		}
		else if ( exists ann = optionalAnnotation( `FactoryAnnotation`, type( element ).declaration ) ) {
			stream.writeOctad( ann.factoryID );
		}*/
		if ( exists id = factories.get( className( element ) ) ) {
			// store factory id
			stream.writeOctad( id );
			// store element
			element.store( stream.output );
		}
	}
	
}

