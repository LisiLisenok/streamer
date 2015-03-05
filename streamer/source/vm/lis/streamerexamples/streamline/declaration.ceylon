import vm.lis.streamer {

	streamer
}


shared void declaration() {
	// initialize streamer at first
	streamer.initialize();
	// register streamline
	streamer.registerStreamlineDeclaration( 1, `class MyID`, MyIDStreamline() );	
	streamer.registerStreamlineDeclaration( 2, `class MyID2`, MyID2Streamline() );	
	
	restoreMyIDs( storeMyIDs( 200 ) );
	restoreMyID2s( storeMyID2s( 200 ) );
}

