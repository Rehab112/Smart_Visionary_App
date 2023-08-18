# Smart Visionary Flutter App

#### Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Workflow](#workflow)
4. [Usage](#usage)
5. [Voice Commands](#voice-commands)
6. [Backend](#backend)

#### Overview
The frontend for the Smart Visionary application, designed to assist the visually impaired and blind. This Flutter application connects to the backend and facilitates user interaction via voice commands and taps.

#### Features
1. **Voice Commands** - Activate features using specific voice commands.
2. **Double-tap Capturing** - Double-tap on the screen to capture an image.
3. **Firebase Messaging** - For authentication and device token management.
4. **Audio Feedback** - Results from the backend are played back as audio.

#### Workflow
After choosing a model or feature to use, the user double-taps on the screen to capture an image. This image is sent to the backend server through the specified API for the chosen feature. The backend processes the image and returns the result as text within a JSON file. The Flutter application then converts this text into audio and plays it to the user.

#### Usage
1. Speak the trigger word to select a feature.
2. Double-tap to capture an image.
3. The app processes the image using the backend API and provides results accordingly.

#### Voice Commands
The app is able to recognize any sentence containing any of these trigger words
1. **Read** - Activates the reading mode used to read any text in either languages English or Arabic.
2. **Face** - Used to recognize familiar faces that have been saved before (friends or family of the user).
3. **Describe** - Activates the image captioning mode used to describe the scene in front of the user.
4. **Money** - Used to recognize Egyptian currency and calculate the sum.
5. **Introduction** - Used to display a how-to-use audio introduction.
6. **Arabi** - Used to translate the most recent audio output that has been displayed to the Arabic language.
7. **Skip** - Used when there is a stranger (a new face has been detected) and the user doesn't want to add him to the familiar faces list.



#### Backend
- [Backend Repository (Flask API and Deep Learning Models)](https://github.com/Rehab112/Smart_Visionary_Backend)


---
