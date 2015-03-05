import vm.lis.streamer {

	IInputStreamline
}

"iterable streamline"
by("Lisi")
shared object iterableStreamline extends IterableStreamline()
{}

"sequence streamline"
by("Lisi")
shared object sequenceStreamline extends IterableStreamline()
{	
	shared actual Anything fill( IInputStreamline stream, Anything instance ) {
		if ( is Iterable<Anything, Null | Nothing> data = super.fill( stream, instance ) ) {
			if ( data.empty ) { return []; }
			else { return data.sequence(); }
		}
		return null;
	}
}

"linkedList streamline"
by("Lisi")
shared object linkedlistStreamline extends CollectionStreamline()
{}

"array streamline"
by("Lisi")
shared object arraylistStreamline extends CollectionStreamline()
{	
	// arguments to be passed to initializer
	shared actual Anything[] arguments = [0, 1.5, {}];
}
