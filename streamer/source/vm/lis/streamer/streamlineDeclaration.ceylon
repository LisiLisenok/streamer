import ceylon.language.meta.model {

	Type,
	Class,
	Applicable
}
import ceylon.language.meta {

	type
}
import vm.lis.streamer.streamline {

	logMessages
}


"
 * create instances of specified type, see [[instantiateFrom]]
 * call method - [[getMethod]]
 * get / set attributes [[getAttributeValue]] and [[setAttributeValue]]
 "
by("Lisi")
shared abstract class StreamlineDeclaration() satisfies IStreamlineDeclaration
{
	
	"instantiate using type, faster than instantiate, returns instance if successfull or null otherwise"
	shared Anything instantiateFrom( Type dataType, Anything[] arguments ) {
		if ( is Class<Anything, Nothing> dataType ) {
			return dataType.apply( *arguments );
		}
		streamer.error( logMessages.instantiatingNotClass( dataType ) );
		return null;
	}
	
	"return method with name name and type parameters typeArguments, the method is applied to specified container"
	shared Applicable<Return>? getMethod<out Return = Anything>( Object container,
		String name, Type<Anything>[] typeArguments = [] ) => type( container ).
			getMethod<Nothing, Return, Nothing>( name, *typeArguments )?.bind( container );
	
	"returns attribute value by container and attribute name, only shared attributes can be got"
	shared Object? getAttributeValue( Object container, String name )
		=> type( container ).getAttribute<Nothing, Anything, Nothing>( name )
		 	?.bind( container )?.get() else null;
	
	"sets new value of attribute Set type by container and attribute name, only shared variable attributes can be set"
	shared void setAttributeValue<Set>( Object container, String name, Set attribute )
		=> type( container ).getAttribute<Nothing, Anything, Set>( name )
			?.bind( container )?.set( attribute );
	
}
