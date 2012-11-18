function handler()
{
	server.log("my test handler");
}

imp.configure("Small", [], [], {period = 10.0});
imp.wakeup(imp.configparams.period, handler);
server.log("Voltage: " + hardware.voltage());
server.log("ID: " + hardware.getimpeeid());
