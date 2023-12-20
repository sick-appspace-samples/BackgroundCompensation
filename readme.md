## BackgroundCompensation

Compensates profiles with a background model.

### Description

Shows how the profile API can be used to "remove" the background. For example if the profiles are range measurements
on a conveyor which is tilted compared to the camera, how this can be compensated for to place the X-axis on the conveyor.
Set the 'compensationMethod' to 'rotate' to rotate and translate the profiles according to the background.
Set the 'compensationMethod' to 'subtract' to subtract the background model from the profiles.
In the examples it is enough to use a line to model the background, otherwise the 'polyOrder' can be used to model backgrounds which are curved.

### How to run

Starting this sample is possible either by running the app (F5) or
debugging (F7+F10). Setting breakpoint on the first row inside the 'main'
function allows debugging step-by-step after 'Engine.OnStarted' event.
Results can be seen in the DevicePage in AppStudio or by using a web browser.
To run this sample a device with SICK Algorithm API and AppEngine 2.10.1 or higher is necessary.
For example InspectorP or SIM4000 with latest firmware. Alternatively the
Emulator on AppStudio 3.1 or higher can be used.

### Topics

algorithm, profile, sample, sick-appspace