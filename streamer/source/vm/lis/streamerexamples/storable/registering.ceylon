import vm.lis.streamer {

	streamer,
	IStorable,
	StreamlineFactory
}

"factory - to create [[Tire]] and [[Car]], creation is done by registered functions, see [[registerStreamlines]]"
shared class ExampleFactory<Type>() extends StreamlineFactory<Type>()
		given Type satisfies IStorable {}


shared void registerStreamlines() {
	// register factory streamlines
	ExampleFactory<Tire> tireFactory = ExampleFactory<Tire>();
	tireFactory.registerFactory( 1, () => WinterTire( "Pirelli", 0 ) );
	tireFactory.registerFactory( 2, () => SummerTire( "Pirelli", 0 ) );
	streamer.registerStreamline( 4, tireFactory );
	
	ExampleFactory<Car> carFactory = ExampleFactory<Car>();
	carFactory.registerFactory( 1, () => Truck( 0.0 ) );
	carFactory.registerFactory( 2, () => Spider( 0 ) );
	streamer.registerStreamline( 5, carFactory );
}
