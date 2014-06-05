/*
 * Basic code structure
 * http://devwiki.electricimp.com/doku.php?id=basiccodestructure
 *
 * Garbage collector problems
 * http://devwiki.electricimp.com/doku.php?id=garbagecollectorproblems
 *
 * Squirrel 3.0 Reference Manual
 * http://squirrel-lang.org/doc/squirrel3.html
 *
 */

function info()
{
    server.log("Voltage: " + hardware.voltage());
    server.log("ID: " + hardware.getimpeeid());
	server.log("WiFi strength: " + imp.rssi());
	server.log("MAC: " + imp.getmacaddress());
}

function bool(value)
{
	return value ? true : false;
}

function xor(lhs, rhs)
{
	return (lhs && !rhs) || (!lhs && rhs);
}

class Led
{
	pin = null;
	activeOnLevel = null;
	state = null;
	
	constructor (pin, activeOnLevel = 0)
	{
		this.pin = pin;
		this.activeOnLevel = bool(activeOnLevel);
	}
	
	function init()
	{
		pin.configure(DIGITAL_OUT_OD_PULLUP);
	}
	
	function set(state)
	{
		this.state = bool(state);
		local ledValue = xor(this.state, activeOnLevel) ? 0 : 1;
		pin.write(ledValue);
	}
	
	function get()
	{
		return state;
	}
	
	function on()
	{
		set(true);
	}
	
	function off()
	{
		set(false);
	}
	
	function reverse()
	{
		set(!state);
	}
}


class Blinker
{
	PeriodTime = 1.0;
	OnlineStateTime = 0.05;
	OfflineStateTime = null;
	
	leds = null;
	direction = null;
	ledState = false;	
	actualLed = 0;
	detectDirectionPin = null;
	
	constructor(ledPins, detectDirectionPin, activeOnLevel)
	{
		this.detectDirectionPin = detectDirectionPin;
		setDirection(true);
		OfflineStateTime = PeriodTime / ledPins.len() - OnlineStateTime;
		init(ledPins, activeOnLevel);
	}
	
	function start()	
	{
		blink();
	}
	
	function changeDirection()
	{
		direction = -direction;
	}
	
	function setDirection(normal)
	{
		local newDirection = normal ? 1 : -1;
		if (newDirection != direction)
		{
			direction = newDirection;
			server.log("Change direction: " + direction);
			server.show(direction ? "forward" : "backward");
		}
	}
	
	function init(ledPins, activeOnLevel)
	{
		if (detectDirectionPin != null)
		{
			detectDirectionPin.configure(DIGITAL_IN_PULLUP, detectDirection.bindenv(this));
		}
		leds = []
		foreach(index, ledLine in ledPins)
		{
			local led = Led(ledLine, activeOnLevel);
			led.init();
			leds.append(led);
		}
	}
	
	function detectDirection()
	{
		local state = detectDirectionPin.read();
		setDirection(state);
	}
	
	function blink()
	{
		ledState = !ledState;
		leds[actualLed].set(ledState);
		local delay = ledState ? OnlineStateTime : OfflineStateTime;
		if (!ledState)
		{
			actualLed = (actualLed + direction) % leds.len();
			if (actualLed < 0)
			{
				actualLed += leds.len();
			}
		}
		imp.wakeup(delay, blink.bindenv(this));
	}	
}

imp.configure("Blinker", [], []);
info();
if (hardware.getimpeeid() == "23402d3643fc42ee")
{
    local ledPins = [
        hardware.pin1,
    	hardware.pin2,
        hardware.pin5,
        hardware.pin7
    ];
    blinker <- Blinker(ledPins, hardware.pin9, 1);
}
else
{
    local ledPins = [
        hardware.pin9,
    	hardware.pin8,
    ];
    blinker <- Blinker(ledPins, null, 0);
}
blinker.start();



