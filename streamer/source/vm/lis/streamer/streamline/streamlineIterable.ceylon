import ceylon.language.meta {

	type
}
import ceylon.language.meta.model {

	ClassOrInterface,
	InterfaceModel,
	Type
}
import ceylon.collection {

	ArrayList
}
import ceylon.language.meta.declaration {

	InterfaceDeclaration,
	ClassDeclaration
}


"base class fo streamlines which stores / restores [[Iterable]]'s"
by("Lisi")
shared class IterableStreamline() extends CollectionStreamline()
{
	
	// arguments to be passed to initializer
	shared actual Anything[] arguments = [0, 1.5, {}];

	ClassDeclaration listDeclaration = `class ArrayList`;
	
	// iterable type parameter name
	String iterableParameter = "Element";
	// iterable interface declaration and type parameter
	InterfaceDeclaration iterableDeclaration = `interface Iterable`;
	assert( exists iterableTypeParameter =
		iterableDeclaration.getTypeParameterDeclaration( iterableParameter ) );
	
	
	// find iterable interface within satisfied types
	InterfaceModel<Anything>? iterableInterface( ClassOrInterface type ) {
		for ( t in type.satisfiedTypes ) {
			if ( t.declaration == iterableDeclaration ) {
				return t;
			}
			else if ( exists tIterable = iterableInterface( t ) ) {
				return tIterable;
			}
		}
		return null;
	}
	
	shared actual ClassOrInterface? getCollectionType( Anything data ) 
		=> iterableInterface( type( data ) );
	
	shared actual Anything instantiateCollection( Type t ) {
		// declaration reading is required since typeArgument evaluates to <null> if not read
		// see https://github.com/ceylon/ceylon.language/issues/641
		// TODO: remove declaration when issue #641 closed 
		if ( is ClassOrInterface t, t.declaration == iterableDeclaration ) {
			if ( exists parameterType = t.typeArguments.get( iterableTypeParameter ) ) {
				return super.instantiateCollection( listDeclaration.apply<Anything>( parameterType ) );
			}
		}
		return super.instantiateCollection( t );
	}
	
	shared actual Anything transformFilled( Object instance ) {
		if ( is Iterable<Anything, Null | Nothing> data = instance ) {
			// return sequence of collection - in order to correct treat nested collections 
			return data.sequence();
		}
		return super.transformFilled( instance );
	}
	
}
