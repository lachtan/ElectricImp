function measureDone(data)
{
	local msg = format("%s %0.2f Celsius", data.id, data.celsius);
	server.log(msg);
	
	local url = "https://byt13.fnet.cz/~lachtan/rsj/temperature/insert.php";
	local headers = {};
	local payload = {
		"user": "rsj",
		"pass": "*****",
		"device": data.id,
		"temperature": data.celsius
	};
	local body = http.urlencode(payload);
	
	local request = http.post(url, headers, body);
	local response = request.sendsync();
	
	server.log(format("Status: %d", response.statuscode));
	//headers	table	Squirrel table of returned HTTP headers
	server.log(format("Body: %s", response.body));
}

device.on("temp", measureDone);
