CustomBrightness
================

A full featured, customisable replacement for iOS auto brightness

##What is CustomBrightness?

CustomBrightness is a replacement for the default auto brightness feature of iOS. It allows you to specify the display backlight level of the iDevice for the current ambient light. The app always runs in the background and adjusts the display brightness as the ambient light changes.

## How to use it?

Launch the CustomBrightness app from the home screen. Then follow these steps:

1.	Start in a very dark place
2.	Disable AutoBrightness and manually set the brightness to minimum
3.	Open CustomBrightness and toggle the _Enabled_ switch to the off position
5.	Slowly move to a brighter area
6.	When you think the display is too dark for the current ambient light, use the brightness slider to increase the display brightness
7.	When it feels okay, press the _Save_ button. This saves your preference for the current ambient light.
8.	Repeat steps 6 and 7, moving to a brighter area
9.	Finally, choose an extremely bright spot (direct sunlight/lamp) and again use the brightness slider to specify the display brightness and save it. This will be max brightness that will ever be set.
10.	When you are happy with your settings, press the _Apply_ button. This will enable the auto adjustment feature. You can quit the app at this point.
12. You can enable/disable CustomBrightness using the _Enabled_ switch.

### Editing your settings

Pressing the _Edit_ button takes you to a new screen which lists your current saved settings. You can individually delete them using the standard swipe-to-delete gesture, or you can delete all of them using the _Delete all_ button.

Make sure you go back to the main screen and press _Apply_ to save your changes.

## Advanced settings

### Manual override

Manual override disables CustomBrightness when you manually change the brightness from Control Center or from the Settings app. 

Manual override disables CustomBrightness temporarily and is intended as a convenience feature. If you want to permanently disable CustomBrightness, use the _Enabled_ switch in the app or the Flipswitch.

### Ambient light threshold

Use this slider to specify the minimum change in the ambient light after which CustomBrightness will adjust the display brightness. Higher values will prevent frequent changes in the display brightness.

### Linear adjustment

When enabled, CustomBrightness will continuously adjust the display brightness as the ambient light level changes (similar to iOS auto brightness).

For example, consider your settings are as follows:

>		Ambient Light (Lux)		Display Brightness (min 0, max 1.0)
>		-----------------------------------------------------------
>				100								0.0
>				200								0.2

If the current ambient light were 150 lux and linear adjustment was disabled, the brightness would be set to 0.2. But if linear adjustment is enabled, the brightness will be set to 0.1.

Note that linear adjustment will still obey the threshold you have set.

### Polling interval

This allows you to adjust how frequently CustomBrightness polls the ambient light sensor. CustomBrightness will react to ambient light changes faster if you set a low polling interval.

## Tips

-	The ambient light sensor is located near the front facing camera of your iDevice. _The iPod touch 5th generation does not have it_. So the app will not work on it.
-	On an iPhone 5, the reported minimum and maximum values for the ambient light (in lux) are 0 and 5000, respectively.
-	For step 9, you can use the LED flash/torch of another phone to get the highest possible lux value from the sensor.
-	You typically don't ever need to open the app again if you are satisfied with your settings. But you can add a new setting at any time using the app.
-	You can disable the app using the _Disable_ button. You can re-enable by pressing the _Done_ button.
-	Its generally best to keep a gap of at least 30 lux between the settings, to avoid constant changes in the backlight level.


## How does it work?

The app uses a continuously running background process (or a daemon) to adjust the brightness automatically. The daemon polls the ambient light sensor every 3 seconds and reads the current ambient light. It then compares it with your settings and determines the brightness value to set.

For example, consider your settings are as follows:

>		Ambient Light (Lux)		Display Brightness (min 0, max 1.0)
>		-----------------------------------------------------------
>				100								0.0
>				200								0.1
>				500								0.3
>				600								0.35
>				1000							0.4
>				2000							0.5
>				3000							0.7
>				4000							0.8

When the ambient light is less than 100 lux, the backlight will be set to 0.0. If the ambient light is more than 100, the brightness will be set to 0.1, and so on. If the ambient light is more than 4000, the brightness will be set to the max possible value (hence, to avoid this, step 9 is important).

---

_v1.2 -- March 5, 2014_
