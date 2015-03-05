import ceylon.file {

	File,
	Nil,
	createFileIfNil,
	Writer
}
import ceylon.logging {

	Priority,
	LogCategory=Category
}

"log writer to file file. Overwrite existing file if overwrite is true, otherwise append to"
by("Lisi")
shared class FileLogWriter( File | Nil file, Boolean overwrite = true, String? encoding = null )
	satisfies Destroyable
{
	Writer logFileWriter = overwrite then createFileIfNil( file ).Overwriter( encoding )
		else createFileIfNil( file ).Appender( encoding );
	
	variable Integer messageNumber = 1;
	
	"close underlying file"
	shared void close() => logFileWriter.close();
	"flush all written logs to the underlying file system"
	shared void flush() => logFileWriter.flush();
	
	"automatically close when destory"
	see( `function close` )
	shared actual void destroy( Throwable? error ) => close();
	
	shared void logWriter( Priority p, LogCategory c, String m, Exception? e ) {
		logFileWriter.writeLine( "[``messageNumber``] ``p.string`` ``m``" );
		if( exists e ) { printStackTrace( e, logFileWriter.writeLine ); }
		messageNumber ++;
		flush();
	}
	
}