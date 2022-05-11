# QuizzBuzz

Qwizzzzz Buzzzzz Weeeeezzzzzzz

This is a project to turn widespread ["got talent" like quiz buzzers](https://www.amazon.fr/RanDal-Buzzer-Alarme-Loterie-Lumi%C3%A8re/dp/B082Y17FFG) and an iOS-based device into a fun wireless quiz game.

Requirements:
- An iOS device (iPhone/iPad) with iOS 15+
- Spotify app installed on the device (a paid subscription is strongly recommended to avoid ads and allow for skipping songs)
- Some buzzers
- XCode for iOS 15+ for the Quizzer app
- KiCad for the PCB files
- nRF Connect SDK 1.9.1+ for the firmware

# Buzzer HowTo

Press the Buzzer for 3 to power it up, indicator will flash quickly while it isn't connected to a QuizzBuzz app.
When connection establishes the indicator will switch off.

After 30 seconds unconnected, the Buzzer will automatically power off.
After 30 minutes connected without buzzing, the Buzzer will also automatically power off.

# Game HowTo

When the game starts, everyone is allowed to buzz while the music is playing. The fastest buzzing team will have its buzzer blinking (much slower than when unconnected) and can try a guess.
If the guess is incorrect, and game is configured not to allow multiple answers, the indicator will stay lit and you can't buzz until next song.
Upon moving to next song, indicators will switch off and everyone can play again.
