import vm.lis.streamer {

	IOutputStream,
	IStorable,
	IInputStream
}

"tire class family utilizes [[IStorable]] interface"
shared abstract class Tire( manufacturer, speedLimit ) satisfies IStorable {
	variable shared String manufacturer;
	variable shared Integer speedLimit;
	shared actual default void restore(IInputStream stream) {
		manufacturer = stream.readOf<String>() else "";
		speedLimit = stream.readOf<Integer>() else 0;
	}
	shared actual default void store(IOutputStream stream) {
		stream.write( manufacturer );
		stream.write( speedLimit );
	}
}

shared class WinterTire( String manufacturer, Integer speedLimit, snow = false )
		extends Tire( manufacturer, speedLimit )
{
	
	shared variable Boolean snow;
	
	shared actual String string => "manufacturer is ``super.manufacturer``, speed is limited to ``super.speedLimit``, is snow? ``snow``";	
	
	shared actual void restore(IInputStream stream) {
		super.restore( stream );
		snow = stream.readOf<Boolean>() else false;
	}
	shared actual void store(IOutputStream stream) {
		super.store( stream );
		stream.write( snow );
	}
	
}

shared class SummerTire( String manufacturer, Integer speedLimit, compound = "soft", rain = false )
		extends Tire( manufacturer, speedLimit )
{
	
	shared variable String compound;
	shared variable Boolean rain;
	
	shared actual String string => "manufacturer is ``super.manufacturer``, speed is limited to ``super.speedLimit``, compound is ``compound``, is rain? ``rain``";
	
	shared actual void restore(IInputStream stream) {
		super.restore( stream );
		compound = stream.readOf<String>() else "";
		rain = stream.readOf<Boolean>() else false;
	}
	shared actual void store(IOutputStream stream) {
		super.store( stream );
		stream.write( compound );
		stream.write( rain );
	}
	
}