
"storable - store / restore to / from stream"
see( `interface IInputStream`, `interface IOutputStream` )
by("Lisi")
shared interface IStorable
{
	"store object - written items must be
	 * one of following types Integer | Float | Byte | Boolean  | String | Character | ByteArray | Entry | Tuple
	  | JsonObject | JsonArray | ArrayList | LinkedList 
	 * or objects satisfy [[Iterable]] or [[Sequence]] 
	 * or another if streamline is registered for
	 "
	shared formal void store( IOutputStream stream );
	
	"restore previously stored object - read all fields in order they have been stored"
	shared formal void restore( IInputStream stream );
}


"streamable: objects satisfied this interface can be read / write to from [[IInputStream]] / [[IOutputStream]] streams
 the class satisfies IStreamable is to be marked with stream annotation with streamline to be used parameter specified"
see( `interface IInputStream`, `interface IOutputStream` )
by("Lisi")
shared interface IStreamable satisfies IStorable
{
	"arguments to be passed to class initializer when read, written by streamline before calling [[store]].
	 Must return values for all arguments taking by initializer including defualt ones.
	 Each argument must be:
	 * one of following types Integer | Float | Byte | Boolean  | String | Character | ByteArray | Entry | Tuple
	  | JsonObject | JsonArray | ArrayList | LinkedList 
	 * or objects satisfy [[Iterable]] or [[Sequence]] 
	 * or another if streamline is registered for
	 
	 Union or intersection types are not supported"
	shared formal Anything[] initializerArguments();
}

