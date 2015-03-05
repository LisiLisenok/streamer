import vm.lis.streamer {

	IStorable,
	IOutputStream,
	IInputStream,
	StreamlineFactory,
	streamer,
	OutputStream,
	InputStream
}
import ceylon.collection {

	LinkedList
}
import vm.lis.streamer.io {

	VMBuffer
}


abstract class TreeObjects() satisfies IStorable {}

class ParentObject() extends TreeObjects() {
	
	shared LinkedList<ChildObject> childs = LinkedList<ChildObject>();
	
	shared void addChild( ChildObject child ) {
		childs.add( child );
		//child.parent = this;
	}
	
	shared actual default void restore( IInputStream stream ) {
		if( is {TreeObjects*} objects = stream.readOf<{TreeObjects*}>() ) {
			for ( obj in objects ) {
				if ( is ChildObject obj ) {
					addChild( obj );
				}
			}
		}
	}
	
	shared actual default void store( IOutputStream stream ) {
		stream.write( childs );
	}
	
	shared actual default String string {
		variable String str = "childs: \n";
		for ( child in childs ) {
			str += child.string;
		}
		return str;
	}
	
}

class ChildObject( name, parent ) extends ParentObject() {
	
	shared variable String name;
	shared variable ParentObject? parent;
	
	shared actual String string {
		variable String str = name + "\n";
		str += super.string + "\n";
		return str;
	}
	
	shared actual void restore(IInputStream stream) {
		super.restore( stream );
		name = stream.readOf<String>() else "";
		parent = stream.readOf<ParentObject>();
	}
	
	shared actual void store( IOutputStream stream ) {
		super.store( stream );
		stream.write( name );
		stream.write( parent );
	}
	
}

class ObjectsFactory() extends StreamlineFactory<TreeObjects | ParentObject | ChildObject>() {}


shared void circularreference() {
	
	// initialize streamer at first
	streamer.initialize();
	
	// register factory streamlines
	ObjectsFactory objectsFactory = ObjectsFactory();
	objectsFactory.registerFactory( 1, () => ParentObject() );
	objectsFactory.registerFactory( 2, () => ChildObject( "", null ) );
	streamer.registerStreamline( 6, objectsFactory );
	
	// tree
	ParentObject baseParent = ParentObject();
	baseParent.addChild( ChildObject( "child-1", baseParent ) );
	
	ChildObject child = ChildObject( "child-2", baseParent );
	baseParent.addChild( child );	
	child.addChild( ChildObject( "child-2-1", child ) );
	child.addChild( ChildObject( "child-2-2", child ) );
	
	ChildObject child1 = ChildObject( "child-2-3", child );
	child.addChild( child1 );	
	child1.addChild( ChildObject( "child-2-3-1", child1 ) );
	child1.addChild( ChildObject( "child-2-3-2", child1 ) );
	
	ChildObject child2 = ChildObject( "child-3", baseParent );
	baseParent.addChild( child2 );	
	child2.addChild( ChildObject( "child-3-1", child2 ) );
	
	//printParent( baseParent );
	
	// stream objects to be written to
	OutputStream outputStream = OutputStream();
	// write objects to the stream	
	outputStream.write( baseParent );
	// flushing stream to the byte buffer
	VMBuffer buffer = VMBuffer();
	outputStream.flushTo( buffer );
	
	// push buffer to the input stream
	InputStream inputStream = InputStream( buffer );
	
	// restoring streamable objects from the stream
	if ( exists readParent = inputStream.readOf<ParentObject>() ) {
		print( readParent );
		//printParent( readParent );
	}
	else {
		print( "ooops! wrong reading" );
	}
	
}

void printParent( ParentObject parent ) {
	print( "parent for:" );
	for ( obj in parent.childs ) {
		print( obj.name );
		printParent( obj );
	}
}