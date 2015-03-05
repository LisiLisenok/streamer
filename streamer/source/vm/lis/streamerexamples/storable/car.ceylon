import vm.lis.streamer {

	IOutputStream,
	IStorable,
	IInputStream
}


"car class family utilizes [[IStorable]] interface"
shared abstract class Car() satisfies IStorable {
	shared variable Tire? tire = null;
	shared actual default void restore(IInputStream stream) {
		tire = stream.readOf<Tire>();
	}
	shared actual default void store(IOutputStream stream) {
		stream.write( tire );
	}
}

shared class Truck( cargo ) extends Car()
{	
	variable shared Float cargo;
	
	shared actual String string => "truck with cargo ``cargo`` and tire ``tire else ""``";
	
	shared actual void restore(IInputStream stream) {
		super.restore( stream );
		cargo = stream.readOf<Float>() else 0.0;
	}
	shared actual void store(IOutputStream stream) {
		super.store( stream );
		stream.write( cargo );
	}
}

shared class Spider( seaters ) extends Car()
{
	variable shared Integer seaters;
	
	shared actual String string => "``seaters`` seaters spider, tire ``tire else ""``";
	
	shared actual void restore(IInputStream stream) {
		super.restore( stream );
		seaters = stream.readOf<Integer>() else 0;
	}
	shared actual void store(IOutputStream stream) {
		super.store( stream );
		stream.write( seaters );
	}	
}
